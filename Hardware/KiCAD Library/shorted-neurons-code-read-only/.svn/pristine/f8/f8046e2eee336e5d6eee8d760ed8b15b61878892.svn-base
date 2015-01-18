// Configure some values in EEPROM for easy config of the RF12 later on.
// 2009-05-06 <jcw@equi4.com> http://opensource.org/licenses/mit-license.php
// $Id: RF12demo.pde 7686 2011-05-19 13:07:57Z jcw $

// this version adds flash memory support, 2009-11-19
//#define RECV_MODE 1

#include <Ports.h>
#include <RF12.h>
#include <util/crc16.h>
#include <util/parity.h>
#include <avr/eeprom.h>
#include <avr/pgmspace.h>
#include <avr/sleep.h>
#include <Streaming.h>
#include <PString.h>
// Flash has to come after Streaming because of conflicting definition of endl
#include <Flash.h>
#include <WProgram.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <FreqCount.h>
#include <Wire.h>
#include <Adafruit_MPL115A2.h>

Adafruit_MPL115A2 mpl115a2;


#define DATAFLASH   0   // check for presence of DataFlash memory on JeeLink
#define FLASH_MBIT  16  // support for various dataflash sizes: 4/8/16 Mbit

#define LED_PIN     9   // activity LED
#define actLed 9

#define COLLECT 0x20 // collect mode, i.e. pass incoming without sending acks

//byte remote_node = 0x15;

#define RF12_SLEEP 0
#define RF12_WAKEUP -1
//void rf12_sleep(byte value);
//rf12_sleep(RF12_SLEEP);
//rf12_sleep(RF12_WAKEUP);

#define AREFSource EXTERNAL
#define AREFmult 3000
#define AREFdiv 2      // ADC voltage divider is ratio 2:1
//#define battSensePin 14
//#define solarSensePin 15
const int battSensePin = A0;
const int solarSensePin = A1;
const int chargePumpEnablePin = 6;
#define solarThreshold 1880
#define faultLED 8
#define chargerPin 17
#define chargerOff LOW
#define chargerOn HIGH
#define batteryMax 3360
#define batteryOverCharged 3700
#define batteryMinForHumidity 3200 // battery should be in good shape for humidity since it costs more juice
#define winkTime 30

/**********************************
 watchdog timer sleeping stuff  */

/*
    Note that for newer devices (ATmega88 and newer, effectively any
 AVR that has the option to also generate interrupts), the watchdog
 timer remains active even after a system reset (except a power-on
 condition), using the fastest prescaler value (approximately 15
 ms).  It is therefore required to turn off the watchdog early
 during program startup, the datasheet recommends a sequence like
 the following:
 */

#include <stdint.h>
#include <avr/wdt.h>

uint8_t mcusr_mirror __attribute__ ((section (".noinit")));

void get_mcusr(void) \
  __attribute__((naked)) \
  __attribute__((section(".init3")));

void get_mcusr(void) {
  // this MUST be called by setup() first!!!! see above
  mcusr_mirror = MCUSR;
  MCUSR = 0;
  wdt_disable();
}

// end preemptive disable of WDT


//****************************************************************
/*
 * Watchdog Sleep Example 
 * Demonstrate the Watchdog and Sleep Functions
 * Photoresistor on analog0 Piezo Speaker on pin 10
 * 
 
 * KHM 2008 / Lab3/  Martin Nawrath nawrath@khm.de
 * Kunsthochschule fuer Medien Koeln
 * Academy of Media Arts Cologne
 
 */
//****************************************************************

#include <avr/sleep.h>
#include <avr/wdt.h>

#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

int nint;

volatile boolean f_wdt=1;


void setupWatchdog(){
  get_mcusr();
  //  Serial.begin(57600);
  Serial.println(F("debug: in setupWatchdog"));

  // CPU Sleep Modes 
  // SM2 SM1 SM0 Sleep Mode
  // 0    0  0 Idle
  // 0    0  1 ADC Noise Reduction
  // 0    1  0 Power-down
  // 0    1  1 Power-save
  // 1    0  0 Reserved
  // 1    0  1 Reserved
  // 1    1  0 Standby(1)

  cbi( SMCR,SE );      // sleep enable, power down mode
  cbi( SMCR,SM0 );     // power down mode
  sbi( SMCR,SM1 );     // power down mode
  cbi( SMCR,SM2 );     // power down mode

  config_watchdog(6);
}

byte del;
int cnt;
byte state=0;
int light=0;
int lastSnapHour = 55;
long lastSnapMinute = 77;
int nowHour = 55;
int nowMinute = 55;
long unixMinute = 1234567890;


//****************************************************************
//****************************************************************

//****************************************************************  
// set system into the sleep state 
// system wakes up when wtchdog is timed out
void system_sleep() {

  cbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter OFF

  set_sleep_mode(SLEEP_MODE_PWR_DOWN); // sleep mode is set here
  //set_sleep_mode(SLEEP_MODE_IDLE); // sleep mode is set here

  sleep_enable();

  sleep_mode();                        // System sleeps here

    sleep_disable();                     // System continues execution here when watchdog timed out 
  sbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter ON
}

//****************************************************************
// 0=16ms, 1=32ms,2=64ms,3=128ms,4=250ms,5=500ms
// 6=1 sec,7=2 sec, 8=4 sec, 9= 8sec
void config_watchdog(int ii) {

  byte bb;
  int ww;
  if (ii > 9 ) ii=9;
  bb=ii & 7;
  if (ii > 7) bb|= (1<<5);
  bb|= (1<<WDCE);
  ww=bb;
  Serial << F("config_watchdog(") << ww << F(")") << endl;

  MCUSR &= ~(1<<WDRF);
  // start timed sequence
  WDTCSR |= (1<<WDCE) | (1<<WDE);
  // set new watchdog timeout value
  WDTCSR = bb;
  WDTCSR |= _BV(WDIE);

}

//****************************************************************  
// Watchdog Interrupt Service / is executed when  watchdog timed out
ISR(WDT_vect) {
  f_wdt=1;  // set global flag
}



/* END watchdog sleep stuff
 *****************************************/

int blinkTime = 50;
long previousMillis = 0;
long interval = 60000;
boolean powerOff = true;

//****************************************************************
void sleepWithBeacon(int dur) {

  int i;
  //  dur = dur / 4; // assumes sleep mode 8, 4s per period
  //  if (f_wdt==1) {  // wait for timed out watchdog / flag is set when a watchdog timeout occurs
  //    f_wdt=0;       // reset flag
  //    nint++;
  //    Serial << F("Sleeping ") << dur << endl;
  //    Serial.println(nint );
  //    delay(2);               // wait until the last serial character is send

  //pinMode(pinLed,INPUT); // set all used port to input to save power

  for ( i=0; i<=dur; i++) {
    /* Serial.print(F("sleep:"));
      Serial.print(millis());
      Serial.print(" ");
      Serial.print(i);
      Serial.print(" ");
      Serial.println(dur);
    */

    //winking
    digitalWrite(actLed,HIGH);  // let led blink
    delay(winkTime);
    digitalWrite(actLed,LOW);
    system_sleep();
  }

  //  }
}



/* -------------------------------------------------------------- */

// Set the TMP Address and Resolution here
int tmpAddress = B1001000;
int ResolutionBits = 12;
float tmp101 = -442.42;

#define rhSensorPower 4 // pin D7 in arduinospeak

// Display TMP100 readout to serial
// Fork Robotics 2012
//

float getTemperature(){
#ifdef RECV_MODE 
  return(-442.00);
#else
  Wire.requestFrom(tmpAddress,2);
  byte MSB = Wire.receive();
  byte LSB = Wire.receive();

  int TemperatureSum = ((MSB << 8) | LSB) >> 4;

  float celsius = TemperatureSum*0.0625;
  //float fahrenheit = (1.8 * celsius) + 32;
  tmp101 = (1.8 * celsius) + 32;
  /*
    Serial.print("TMP101 temp=");
    Serial.print(celsius);
    Serial.print("C, ");
    Serial.print(tmp101);
    Serial.println("F");
  */
  return(tmp101);
#endif
}

void SetResolution(){

  if (ResolutionBits < 9 || ResolutionBits > 12) exit;
  Wire.beginTransmission(tmpAddress);
  Wire.send(B00000001); //addresses the configuration register
  Wire.send((ResolutionBits-9) << 5); //writes the resolution bits
  Wire.endTransmission();

  Wire.beginTransmission(tmpAddress); //resets to reading the temperature
  Wire.send((byte)0x00);
  Wire.endTransmission();
}

/*-----------------------------------------------------------------*/




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
char pumpStat = '_';
long v = 0;
int getMv(int apin) {
  v = analogRead(apin);
  Serial.print("apin is ");
  Serial.print(apin);
  Serial.print(" value=");
  Serial.print(v);
  // mv = raw * 2 * 3000 / 1024
    // 512 * 2 * 3000
  v = v * AREFdiv * AREFmult / 1024;
  //Serial.println(apin);
  //Serial.println(v);
  Serial.print(" mv=");
  Serial.println(int(v));
  return int(v);
}

void tempsetup(void)
{
  // start serial port
  //Serial.begin(57600);
  Serial.println(F("Dallas Temperature IC Control Library Demo"));

  // locate devices on the bus
  Serial.print(F("Locating devices..."));
  sensors.begin();
  Serial.print(F("Found "));
  Serial.print(sensors.getDeviceCount(), DEC);
  Serial.println(" devices.");

  // report parasite power requirements
  Serial.print(F("Parasite power is: ")); 
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
  //Serial.print("Requesting temperatures...");
  sensors.requestTemperatures(); // Send the command to get temperatures
  //Serial.println("DONE");

  // It responds almost immediately. Let's print out the data
  //printTemperature(insideThermometer); // Use a simple function to print out the data
  tempC = sensors.getTempC(insideThermometer);
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
} 
RF12Config;

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
  static word bands[4] = { 
    315, 433, 868, 915   };
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

  Serial.println(F("Current configuration:"));
  rf12_config();
}


static void handleInput (char c) {
  if ('0' <= c && c <= '9')
    value = 10 * value + c - '0';
  else if (c == ',') {
    if (top < sizeof stack)
      stack[top++] = value;
    value = 0;
  } 
  else if ('a' <= c && c <='z') {
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
  } 
  else if ('A' <= c && c <= 'Z') {
    config.nodeId = (config.nodeId & 0xE0) + (c & 0x1F);
    saveConfig();
  } 
  else if (c > ' ')
    showHelp();
}



int seq = 0;
float relativeHumidity = 0.01;

void setup() {
  pinMode(faultLED, OUTPUT);
  digitalWrite(faultLED, HIGH);
  Serial.begin(57600);
  Serial.print("\n[RF12demo.7]");
  analogReference(AREFSource);
  setupWatchdog();
  //Serial.println(" done.");

  pinMode(actLed, OUTPUT);
    activityLed(0);
    delay(20);
    activityLed(1);

  //Serial.println(" 1wire... ");
  Wire.begin();        // join i2c bus (address optional for master)
  pinMode(rhSensorPower, OUTPUT);
  digitalWrite(rhSensorPower, HIGH);
  delay(10);
  //Serial.println(" SetResolution");
    activityLed(0);
    delay(20);
    activityLed(1);

  SetResolution(); //set TMP101 sensor resolution

  //Serial.println(" tempsetup");
  tempsetup();
  showHelp();
    activityLed(0);
    delay(20);
    activityLed(1);

  if (rf12_config()) {
    config.nodeId = eeprom_read_byte(RF12_EEPROM_ADDR);
    config.group = eeprom_read_byte(RF12_EEPROM_ADDR + 1);
  } 
  else {
    config.nodeId = 0x41; // node A1 @ 433 MHz
    config.group = 0xD4;
    saveConfig();
  }
  quiet = 1;
  // begin populating bits to make it transmit first time thru loop
  cmd = 'a';
  sendLen = RF12_MAXDATA;
  dest = 0;
  for (byte i = 0; i < RF12_MAXDATA; ++i)
    testbuf[i] = i;
  // end init broadcast

  pinMode(battSensePin, INPUT);    
  pinMode(solarSensePin, INPUT);
  //pinMode(chargePumpEnablePin, INPUT);
  //digitalWrite(battSensePin, LOW); // make sure pullup is turned off so that we dont oscillate the thing
  //digitalWrite(solarSensePin, LOW); // make sure pullup is turned off so that we dont oscillate the thing

  mpl115a2.begin();
  
  pinMode(chargerPin, OUTPUT);
  digitalWrite(chargerPin, chargerOn);

  digitalWrite(faultLED, LOW);

}


float rhloop() {


  //digitalWrite(rhSensorPower, HIGH);  // this is now done in main loop so that i2c bus doesnt get hosed 
  activityLed(0);
  delay(20);
  activityLed(1);
  delay(80);
    
  FreqCount.begin(1000);

  //delay(2500);
  for (int x=0; x <25; x++) {
    activityLed(0);
    delay(20);
    activityLed(1);
    delay(80);
  }
  

  if (FreqCount.available()) {
    unsigned long count = FreqCount.read();
    Serial.print(F(", frequency= "));
    Serial.print(count);
    
    Serial.print("Hz, RH = ");
    Serial.print(", RH = ");
    Serial.print( ( (float) (7658-count)*364)/4096.0);
    Serial.println("%");
    relativeHumidity = (((float) (7658-count)*364)/4096.0);

  }
  FreqCount.end();
  //digitalWrite(rhSensorPower, LOW);  // this is now done in main loop so that i2c bus doesnt get hosed
  delay(100);
  Serial.println("leaving RH...");
  return(relativeHumidity);
}



  
void chkMem() {
  Serial.print(F("chkMem free= "));
  Serial.print(availableMemory());
  Serial.print(F(", memory used="));
  Serial.println(2048-availableMemory());

}

int availableMemory() {
 int size = 2048;
 byte *buf;
 while ((buf = (byte *) malloc(--size)) == NULL);
 free(buf);
 return size;
} 



int foo=60;
unsigned long currentMillis = 0;
//unsigned long chargePumpHighPulseWidth = 0;
//unsigned long chargePumpLowPulseWidth = 2;
unsigned long cph = 0;
unsigned long cpl = 1;
int cpr = -1;

long tempInterval = 60000;   


void loop() {
  if (Serial.available())
    handleInput(Serial.read());

  //chkMem();
#ifndef RECV_MODE
    rf12_sleep(RF12_WAKEUP);
    activityLed(1);

    //pinMode(chargerPin, OUTPUT);
    //digitalWrite(chargerPin, chargerOff);

    activityLed(0);
    delay(20);
    batteryMillivolts = getMv(battSensePin);
    activityLed(1);
    delay(20);
    solarMillivolts = getMv(solarSensePin);

    activityLed(0);
    delay(20);
    
    cph = pulseIn(chargePumpEnablePin, HIGH);
    Serial.print("chargeHigh is ");
    Serial.println(cph);

    activityLed(1);
    delay(20);


    cpl = pulseIn(chargePumpEnablePin, LOW);
    Serial.print("chargeLow is ");
    Serial.println(cpl);
    if ((cph == 0) && (cpl == 0 )){
      // cant get a pulse on LOW or high... assume it is LOW all the time
      cpr = 0; 
      if (digitalRead(chargePumpEnablePin)) {
        // could not get a pulse width on either, but pump is high, that means its FULL on
        cpr = 100;
      }
    } else {
      cpr = (int)(float(float(cph)/float(cph+cpl))*100);
    }

    
#endif
    if (batteryMillivolts > batteryOverCharged) {
      digitalWrite(faultLED, HIGH);
    } else {
      digitalWrite(faultLED, LOW);
    }
    if (batteryMillivolts < batteryMax) {
      if (solarMillivolts > solarThreshold) {

        chargeStat = '+';
        //pinMode(chargerPin, OUTPUT);
        digitalWrite(chargerPin, chargerOn);
      } 
      else {
        chargeStat = '-';
        //leave it however it was?
        digitalWrite(chargerPin, chargerOff);
        // or go high impedance:
        //pinMode(chargerPin, INPUT);
        //digitalWrite(chargerPin, chargerOn); // turn off the pullup
      }
    } 
    else {
      chargeStat = 'F';          
      //pinMode(chargerPin, OUTPUT);
      digitalWrite(chargerPin, chargerOff);
    }
    //Serial.print(chargeStat);



    if (rf12_recvDone()) {
      byte n = rf12_len;
      if (rf12_crc == 0) {
        Serial.print("OK ");
      } 
      else {
        if (quiet)
          return;
        Serial.print(" ?");
        if (n > 20) // print at most 20 bytes if crc is wrong
          n = 20;
      }
      if (config.group == 0) {
        Serial.print("G ");
        Serial.print((int) rf12_grp);
        Serial.print(' ');
      }

      Serial.print((int) rf12_hdr);
      Serial.print(' ');      
      for (byte i = 0; i < n; ++i) {
        Serial.print(rf12_data[i]);
        //Serial.print(' ');
        //Serial.print((int) rf12_data[i]);
      }
      Serial.println();

      if (rf12_crc == 0) {
        if (RF12_WANTS_ACK && (config.nodeId & COLLECT) == 0) {
          Serial.println(" -> ack");
          rf12_sendStart(RF12_ACK_REPLY, 0, 0);
        }
      }
    }

    if (cmd && rf12_canSend()) {

      Serial.print(" -> ");
      Serial.print((int) sendLen);
      Serial.println(" b");
      byte header = cmd == 'a' ? RF12_HDR_ACK : 0;
      if (dest)
        header |= RF12_HDR_DST | dest;
      rf12_sendStart(header, testbuf, sendLen);
      cmd = 0;
    }


#ifdef RECV_MODE
    currentMillis = millis();
 
    if(currentMillis - previousMillis > tempInterval) {
      // save the last time you blinked the LED 
      previousMillis = currentMillis;    
#endif
    seq++;    
    temploop();
    digitalWrite(rhSensorPower, HIGH); // have to turn power on so i2c doesnt get hosed     
    if (batteryMillivolts > batteryMinForHumidity ){ 
      // spin up the sensor and do a humidity reading
      digitalWrite(rhSensorPower, HIGH);  
#ifndef RECV_MODE
      rhloop();
#endif

    } else {
      //skip power hungry humidity reading
#ifndef RECV_MODE
      Serial.println(F("battery is too low, skipping humidity check"));
#endif      
      relativeHumidity = -1;
    }
    

    getTemperature();
    
    float pressureKPA = 0, temperatureF = 0;    

    pressureKPA = mpl115a2.getPressure();  
    Serial.print("Pressure (kPa): "); Serial.print(pressureKPA, 4); Serial.println(" kPa");

    temperatureF = (1.8 * mpl115a2.getTemperature()) +32;  
    Serial.print("Temp (*F): "); Serial.print(temperatureF, 1); Serial.println(" *F");
  
    int tempFm2 = temperatureF * 100;
    int pressure2 = pressureKPA;
    int pressure3 = (long)(pressureKPA * 10000) % 10000;
    

    
    
    digitalWrite(rhSensorPower, LOW);      
    
    //byte header = 0 | RF12_HDR_DST | remote_node;
    //byte header = 0 | RF12_HDR_DST | 0x15;
    byte header = 0;
    //char payload[] = {'B', 'L', 'I', 'N', 'K', remote_node, remote_pin, set_state};

    float tempF = DallasTemperature::toFahrenheit(tempC);
    //Serial.print("tempF is ");
    //Serial.println(tempF);
    int tempF100 = (DallasTemperature::toFahrenheit(tempC)) *100;
    int tmp101100 = (tmp101 * 100);
    int rh100 = (relativeHumidity * 100);
    char payload[64] = "                                                               ";
#ifdef RECV_MODE
    int n=sprintf (payload, "i=%d,t1=%d.%02d ", seq, tempF100/100, tempF100%100);
#else
    int n=sprintf (payload, "%d,%d.%02d,%d.%02d,%d.%02d,%d.%04d,%d%%,%dmV,%dmV,%c,cpo=%d ",
                              seq, tempF100/100, tempF100%100, tmp101100/100, tmp101100%100,
                              tempFm2/100, tempFm2%100, pressure2,pressure3,
                              rh100/100,
                              batteryMillivolts,solarMillivolts,chargeStat,cpr);
#endif
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
#ifdef RECV_MODE
    Serial.print("Receiver local:");
#else
    Serial.print("Sending: ");
    Serial.print(header);
#endif

    for (byte i = 0; i < sizeof payload; ++i)
      Serial.print(payload[i]);
      Serial.println();
#ifdef RECV_MODE
    } // done with millis based interval timing
#endif
    
#ifndef RECV_MODE
    rf12_sendStart(header, payload, sizeof payload);
    activityLed(0);
    delay(20);
    activityLed(1);

    //again
    rf12_sendStart(header, payload, sizeof payload);
    activityLed(0);
    delay(20);
    activityLed(1);

    rf12_sleep(RF12_SLEEP);


    delay(20);
    activityLed(0);
        
  if (seq >=10) sleepWithBeacon(49);  //(26 = ~60 seconds between shots)
#endif
  //sleepWithBeacon(1);  //(26 = ~60 seconds between shots)
  
}

