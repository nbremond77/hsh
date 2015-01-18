// Configure some values in EEPROM for easy config of the RF12 later on.
// 2009-05-06 <jcw@equi4.com> http://opensource.org/licenses/mit-license.php
// $Id: RF12demo.pde 7686 2011-05-19 13:07:57Z jcw $

// this version adds flash memory support, 2009-11-19


#include <Ports.h>
#include <RF12.h>
#include <util/crc16.h>
#include <util/parity.h>
#include <avr/eeprom.h>
#include <avr/pgmspace.h>


#define DATAFLASH   0   // check for presence of DataFlash memory on JeeLink
#define FLASH_MBIT  16  // support for various dataflash sizes: 4/8/16 Mbit

#define LED_PIN     9   // activity LED

#define COLLECT 0x20 // collect mode, i.e. pass incoming without sending acks

//byte remote_node = 0x15;

#define RF12_SLEEP 0
#define RF12_WAKEUP -1
//void rf12_sleep(byte value);
//rf12_sleep(RF12_SLEEP);
//rf12_sleep(RF12_WAKEUP);

#define AREFmult 2930
#define AREFdiv 2      // ADC voltage divider is ratio 2:1
#define battSensePin 14
#define solarSensePin 15
#define solarThreshold 2500
#define chargerPin 8
#define chargerOff HIGH
#define chargerOn LOW
#define batteryMax 3360

#include <OneWire.h>
#include <DallasTemperature.h>

// Data wire is plugged into port 2 on the Arduino
#define ONE_WIRE_BUS 7

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

// arrays to hold device address
DeviceAddress insideThermometer;

// function to print a device address
void printAddress(DeviceAddress deviceAddress)
{
  for (uint8_t i = 0; i < 8; i++)
  {
    if (deviceAddress[i] < 16) Serial.print("0");
    Serial.print(deviceAddress[i], HEX);
  }
}

int batteryMillivolts = 0;
int solarMillivolts = 0;
char chargeStat = '-';
int getMv(int apin) {
   long v = analogRead(apin);
      //Serial.println(v);
   v = v * AREFdiv * AREFmult / 1000;
      //Serial.println(apin);
      Serial.println(v);
   return int(v);
}

void tempsetup(void)
{
  // start serial port
  //Serial.begin(57600);
  Serial.println("Dallas Temperature IC Control Library Demo");

  // locate devices on the bus
  Serial.print("Locating devices...");
  sensors.begin();
  Serial.print("Found ");
  Serial.print(sensors.getDeviceCount(), DEC);
  Serial.println(" devices.");

  // report parasite power requirements
  Serial.print("Parasite power is: "); 
  if (sensors.isParasitePowerMode()) Serial.println("ON");
  else Serial.println("OFF");
  
  // assign address manually.  the addresses below will beed to be changed
  // to valid device addresses on your bus.  device address can be retrieved
  // by using either oneWire.search(deviceAddress) or individually via
  // sensors.getAddress(deviceAddress, index)
  //insideThermometer = { 0x28, 0x1D, 0x39, 0x31, 0x2, 0x0, 0x0, 0xF0 };

  // Method 1:
  // search for devices on the bus and assign based on an index.  ideally,
  // you would do this to initially discover addresses on the bus and then 
  // use those addresses and manually assign them (see above) once you know 
  // the devices on your bus (and assuming they don't change).
  if (!sensors.getAddress(insideThermometer, 0)) Serial.println("Unable to find address for Device 0"); 
  
  // method 2: search()
  // search() looks for the next device. Returns 1 if a new address has been
  // returned. A zero might mean that the bus is shorted, there are no devices, 
  // or you have already retrieved all of them.  It might be a good idea to 
  // check the CRC to make sure you didn't get garbage.  The order is 
  // deterministic. You will always get the same devices in the same order
  //
  // Must be called before search()
  //oneWire.reset_search();
  // assigns the first address found to insideThermometer
  //if (!oneWire.search(insideThermometer)) Serial.println("Unable to find address for insideThermometer");

  // show the addresses we found on the bus
  Serial.print("Device 0 Address: ");
  printAddress(insideThermometer);
  Serial.println();

  // set the resolution to 9 bit (Each Dallas/Maxim device is capable of several different resolutions)
  sensors.setResolution(insideThermometer, 12);
 
  Serial.print("Device 0 Resolution: ");
  Serial.print(sensors.getResolution(insideThermometer), DEC); 
  Serial.println();
}

float tempC = 0;
// function to print the temperature for a device
void printTemperature(DeviceAddress deviceAddress)
{
  // method 1 - slower
  //Serial.print("Temp C: ");
  //Serial.print(sensors.getTempC(deviceAddress));
  //Serial.print(" Temp F: ");
  //Serial.print(sensors.getTempF(deviceAddress)); // Makes a second call to getTempC and then converts to Fahrenheit

  // method 2 - faster
  tempC = sensors.getTempC(deviceAddress);
  Serial.print("Temp C: ");
  Serial.print(tempC);
  Serial.print(" Temp F: ");
  Serial.println(DallasTemperature::toFahrenheit(tempC)); // Converts tempC to Fahrenheit
}

void temploop(void)
{ 
  // call sensors.requestTemperatures() to issue a global temperature 
  // request to all devices on the bus
  Serial.print("Requesting temperatures...");
  sensors.requestTemperatures(); // Send the command to get temperatures
  Serial.println("DONE");
  
  // It responds almost immediately. Let's print out the data
  printTemperature(insideThermometer); // Use a simple function to print out the data
}




static unsigned long now () {
    // FIXME 49-day overflow
    return millis() / 1000;
}

static void activityLed (byte on) {
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, on);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// RF12 configuration setup code

typedef struct {
    byte nodeId;
    byte group;
    char msg[RF12_EEPROM_SIZE-4];
    word crc;
} RF12Config;

static RF12Config config;

static char cmd;
static byte value, stack[RF12_MAXDATA], top, sendLen, dest, quiet;
static byte testbuf[RF12_MAXDATA];

static void addCh (char* msg, char c) {
    byte n = strlen(msg);
    msg[n] = c;
}

static void addInt (char* msg, word v) {
    if (v >= 10)
        addInt(msg, v / 10);
    addCh(msg, '0' + v % 10);
}

static void saveConfig () {
    // set up a nice config string to be shown on startup
    memset(config.msg, 0, sizeof config.msg);
    strcpy(config.msg, " ");
    
    byte id = config.nodeId & 0x1F;
    addCh(config.msg, '@' + id);
    strcat(config.msg, " i");
    addInt(config.msg, id);
    if (config.nodeId & COLLECT)
        addCh(config.msg, '*');
    
    strcat(config.msg, " g");
    addInt(config.msg, config.group);
    
    strcat(config.msg, " @ ");
    static word bands[4] = { 315, 433, 868, 915 };
    word band = config.nodeId >> 6;
    addInt(config.msg, bands[band]);
    strcat(config.msg, " MHz ");
    
    config.crc = ~0;
    for (byte i = 0; i < sizeof config - 2; ++i)
        config.crc = _crc16_update(config.crc, ((byte*) &config)[i]);

    // save to EEPROM
    for (byte i = 0; i < sizeof config; ++i) {
        byte b = ((byte*) &config)[i];
        eeprom_write_byte(RF12_EEPROM_ADDR + i, b);
    }
    
    if (!rf12_config())
        Serial.println("config save failed");
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// OOK transmit code

// Turn transmitter on or off, but also apply asymmetric correction and account
// for 25 us SPI overhead to end up with the proper on-the-air pulse widths.
// With thanks to JGJ Veken for his help in getting these values right.
static void ookPulse(int on, int off) {
    rf12_onOff(1);
    delayMicroseconds(on + 150);
    rf12_onOff(0);
    delayMicroseconds(off - 200);
}

static void fs20sendBits(word data, byte bits) {
    if (bits == 8) {
        ++bits;
        data = (data << 1) | parity_even_bit(data);
    }
    for (word mask = bit(bits-1); mask != 0; mask >>= 1) {
        int width = data & mask ? 600 : 400;
        ookPulse(width, width);
    }
}

static void fs20cmd(word house, byte addr, byte cmd) {
	byte sum = 6 + (house >> 8) + house + addr + cmd;
	for (byte i = 0; i < 3; ++i) {
		fs20sendBits(1, 13);
		fs20sendBits(house >> 8, 8);
		fs20sendBits(house, 8);
		fs20sendBits(addr, 8);
		fs20sendBits(cmd, 8);
		fs20sendBits(sum, 8);
		fs20sendBits(0, 1);
		delay(10);
	}
}

static void kakuSend(char addr, byte device, byte on) {
    int cmd = 0x600 | ((device - 1) << 4) | ((addr - 1) & 0xF);
    if (on)
        cmd |= 0x800;
    for (byte i = 0; i < 4; ++i) {
        for (byte bit = 0; bit < 12; ++bit) {
            ookPulse(375, 1125);
            int on = bitRead(cmd, bit) ? 1125 : 375;
            ookPulse(on, 1500 - on);
        }
		ookPulse(375, 375);
		delay(11); // approximate
    }
}


char helpText1[] PROGMEM = 
    "\n"
    "Available commands:" "\n"
    "  <nn> i     - set node ID (standard node ids are 1..26)" "\n"
    "               (or enter an uppercase 'A'..'Z' to set id)" "\n"
    "  <n> b      - set MHz band (4 = 433, 8 = 868, 9 = 915)" "\n"
    "  <nnn> g    - set network group (RFM12 only allows 212, 0 = any)" "\n"
    "  <n> c      - set collect mode (advanced, normally 0)" "\n"
    "  t          - broadcast max-size test packet, with ack" "\n"
    "  ...,<nn> a - send data packet to node <nn>, with ack" "\n"
    "  ...,<nn> s - send data packet to node <nn>, no ack" "\n"
    "  <n> l      - turn activity LED on PB1 on or off" "\n"
    "  <n> q      - set quiet mode (1 = don't report bad packets)" "\n"
    "Remote control commands:" "\n"
    "  <hchi>,<hclo>,<addr>,<cmd> f     - FS20 command (868 MHz)" "\n"
    "  <addr>,<dev>,<on> k              - KAKU command (433 MHz)" "\n"
;
char helpText2[] PROGMEM = 
    "Flash storage (JeeLink v2 only):" "\n"
    "  d                                - dump all log markers" "\n"
    "  <sh>,<sl>,<t3>,<t2>,<t1>,<t0> r  - replay from specified marker" "\n"
    "  123,<bhi>,<blo> e                - erase 4K block" "\n"
    "  12,34 w                          - wipe entire flash memory" "\n"
;

static void showString (PGM_P s) {
    for (;;) {
        char c = pgm_read_byte(s++);
        if (c == 0)
            break;
        if (c == '\n')
            Serial.print('\r');
        Serial.print(c);
    }
}

static void showHelp () {
    showString(helpText1);

    Serial.println("Current configuration:");
    rf12_config();
}

static void handleInput (char c) {
    if ('0' <= c && c <= '9')
        value = 10 * value + c - '0';
    else if (c == ',') {
        if (top < sizeof stack)
            stack[top++] = value;
        value = 0;
    } else if ('a' <= c && c <='z') {
        Serial.print("> ");
        Serial.print((int) value);
        Serial.println(c);
        switch (c) {
            default:
                showHelp();
                break;
            case 'i': // set node id
                config.nodeId = (config.nodeId & 0xE0) + (value & 0x1F);
                saveConfig();
                break;
            case 'b': // set band: 4 = 433, 8 = 868, 9 = 915
                value = value == 8 ? RF12_868MHZ :
                        value == 9 ? RF12_915MHZ : RF12_433MHZ;
                config.nodeId = (value << 6) + (config.nodeId & 0x3F);
                saveConfig();
                break;
            case 'g': // set network group
                config.group = value;
                saveConfig();
                break;
            case 'c': // set collect mode (off = 0, on = 1)
                if (value)
                    config.nodeId |= COLLECT;
                else
                    config.nodeId &= ~COLLECT;
                saveConfig();
                break;
            case 't': // broadcast a maximum size test packet, request an ack
                cmd = 'a';
                sendLen = RF12_MAXDATA;
                dest = 0;
                for (byte i = 0; i < RF12_MAXDATA; ++i)
                    testbuf[i] = i;
                break;
            case 'a': // send packet to node ID N, request an ack
            case 's': // send packet to node ID N, no ack
                cmd = c;
                sendLen = top;
                dest = value;
                memcpy(testbuf, stack, top);
                break;
            case 'l': // turn activity LED on or off
                activityLed(value);
                break;
            case 'f': // send FS20 command: <hchi>,<hclo>,<addr>,<cmd>f
                rf12_initialize(0, RF12_868MHZ);
                activityLed(1);
                fs20cmd(256 * stack[0] + stack[1], stack[2], value);
                activityLed(0);
                rf12_config(); // restore normal packet listening mode
                break;
            case 'k': // send KAKU command: <addr>,<dev>,<on>k
                rf12_initialize(0, RF12_433MHZ);
                activityLed(1);
                kakuSend(stack[0], stack[1], value);
                activityLed(0);
                rf12_config(); // restore normal packet listening mode
                break;

            case 'q': // turn quiet mode on or off (don't report bad packets)
                quiet = value;
                break;
        }
        value = top = 0;
        memset(stack, 0, sizeof stack);
    } else if ('A' <= c && c <= 'Z') {
        config.nodeId = (config.nodeId & 0xE0) + (c & 0x1F);
        saveConfig();
    } else if (c > ' ')
        showHelp();
}

int seq = 0;

void setup() {
    Serial.begin(57600);
    Serial.print("\n[RF12demo.7]");



Serial.println("tempsetup next");
delay(39);
    tempsetup();
Serial.println("tempsetup next1.2");
delay(39);
    showHelp();
Serial.println("tempsetup next2");
delay(39);
    if (rf12_config()) {
        config.nodeId = eeprom_read_byte(RF12_EEPROM_ADDR);
Serial.println("tempsetup next3");
delay(39);        
        config.group = eeprom_read_byte(RF12_EEPROM_ADDR + 1);
    } else {
        config.nodeId = 0x41; // node A1 @ 433 MHz
        config.group = 0xD4;
        saveConfig();
    }
Serial.println("tempsetup next4");
delay(39);    
    // begin populating bits to make it transmit first time thru loop
    cmd = 'a';
    sendLen = RF12_MAXDATA;
    dest = 0;
    for (byte i = 0; i < RF12_MAXDATA; ++i)
        testbuf[i] = i;
    // end init broadcast

    pinMode(battSensePin, INPUT);    
    pinMode(solarSensePin, INPUT);
    digitalWrite(solarSensePin, LOW); // make sure pullup is turned off so that we dont oscillate the thing
    pinMode(chargerPin, OUTPUT);
    digitalWrite(chargerPin, chargerOn);
    
    
}
 int foo=0;
void loop() {
    if (Serial.available())
        handleInput(Serial.read());


   if (foo >= 60) {
    foo = 0;
    rf12_sleep(RF12_WAKEUP);
    activityLed(1);
    delay(20);
    activityLed(0);
        
    if (rf12_recvDone()) {
        byte n = rf12_len;
        if (rf12_crc == 0) {
            Serial.print("OK");
        } else {
            if (quiet)
                return;
            Serial.print(" ?");
            if (n > 20) // print at most 20 bytes if crc is wrong
                n = 20;
        }
        if (config.group == 0) {
            Serial.print("G ");
            Serial.print((int) rf12_grp);
        }
        Serial.print(' ');
        Serial.print((int) rf12_hdr);
        for (byte i = 0; i < n; ++i) {
            Serial.print(' ');
            Serial.print((int) rf12_data[i]);
        }
        Serial.println();
        
        if (rf12_crc == 0) {
            activityLed(1);
            

            if (RF12_WANTS_ACK && (config.nodeId & COLLECT) == 0) {
                Serial.println(" -> ack");
                rf12_sendStart(RF12_ACK_REPLY, 0, 0);
            }
            
            activityLed(0);
        }
    }

    if (cmd && rf12_canSend()) {
        activityLed(1);

        Serial.print(" -> ");
        Serial.print((int) sendLen);
        Serial.println(" b");
        byte header = cmd == 'a' ? RF12_HDR_ACK : 0;
        if (dest)
            header |= RF12_HDR_DST | dest;
        rf12_sendStart(header, testbuf, sendLen);
        cmd = 0;

        activityLed(0);
    }

        seq++;
        temploop();
        //byte header = 0 | RF12_HDR_DST | remote_node;
        //byte header = 0 | RF12_HDR_DST | 0x15;
        byte header = 0;
        //char payload[] = {'B', 'L', 'I', 'N', 'K', remote_node, remote_pin, set_state};
        
        float tempF = DallasTemperature::toFahrenheit(tempC);
        Serial.print("tempF is");
        Serial.println(tempF);
        int tempF100 = (DallasTemperature::toFahrenheit(tempC)) *100;
        char payload[60] = "                                                           ";
        int n=sprintf (payload, "i=%d,t=%d.%02d,b=%dmV,s=%dmV,c=%c ", seq, tempF100/100, tempF100%100, batteryMillivolts,solarMillivolts,chargeStat);
        
/*        char payload[] = {'t', '=',
            ((tempC100 / 1000)+48),
         ((tempC100 / 100 %10)+48), 
                               '.',
         ((tempC100 / 10 % 10)+48),
              ((tempC100 % 10)+48),
                               ',',
     ((batteryMillivolts/1000)+48),
 ((batteryMillivolts/100 % 10)+48),
  ((batteryMillivolts/10 % 10)+48),
     ((batteryMillivolts % 10)+48),
                           'm','V',
                           
        };
*/        
        Serial.print("Sending: ");
        Serial.print(header);
        for (byte i = 0; i < sizeof payload; ++i)
            Serial.print(payload[i]);
        Serial.println();
        rf12_sendStart(header, payload, sizeof payload);
        activityLed(1);
        delay(20);
        activityLed(0);

        //again
        rf12_sendStart(header, payload, sizeof payload);
        activityLed(1);
        delay(20);
        activityLed(0);

        rf12_sleep(RF12_SLEEP);
    } else {
      foo++;
        //pinMode(chargerPin, OUTPUT);
        digitalWrite(chargerPin, chargerOff);
        delay(10);
        batteryMillivolts = getMv(battSensePin);
        delay(10);
        solarMillivolts = getMv(solarSensePin);
        if (batteryMillivolts < batteryMax) {
          if (solarMillivolts > solarThreshold) {

            chargeStat = '+';
            //pinMode(chargerPin, OUTPUT);
            digitalWrite(chargerPin, chargerOn);
          } else {
            chargeStat = '-';
            //leave it however it was?
            //digitalWrite(chargerPin, chargerOff);
            // or go high impedance:
            //pinMode(chargerPin, INPUT);
            digitalWrite(chargerPin, chargerOn); // turn off the pullup
          }
        } else {
          chargeStat = 'F';          
          //pinMode(chargerPin, OUTPUT);
          digitalWrite(chargerPin, chargerOff);
        }
        Serial.print(chargeStat);
        delay(1000);
    }      
            
}
