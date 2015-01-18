// changing entire scheme of this thing:
//   server changes:
//      a. server will use only the ack functions built into the library,
//         rather than ack receipt by sending entire string back to client
//      b. server will keep stats on packet traffic by client adrs #
//      c. server will print (to log page) it's own stats along with stats and
//         other info  reported by the client(s) 
//   client chenges:
//      a. client will at regular intervals offer to send stats/info to server,
//         soas to not tie up client with having to listen for server requests
//      b. client will respond to server's requests for stats or other info
//      c. client will keep stats on packets sent and acks rcv'd
//      d. client will track signal quality and report avg rssi when requested
// 
//    -- sbs, 5/12/14, updated 5/13/14
//
//
// use board: ATmega328 on breadboard ...


////////////////////////////////////////////////////////////////////////////////
//  begin ...                                                                 //
////////////////////////////////////////////////////////////////////////////////

#include <Wire.h>
#include <RHReliableDatagram.h>
#include <RH_RF22.h>
#include <SPI.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <Mcp23s17.h>
// may explicitly include some of this later ...
// #include <stdlib.h>
// #include <Streaming.h>
// #include <PString.h>
// Flash has to come after Streaming because of conflicting definition of endl
// #include <Flash.h>

// #define DEBUG   // define for expanded debug information

// radio ...
#define CLIENT_ADDRESS 2  // for radio
#define SERVER_ADDRESS 0  // for radio
// #define  RH_RF22_MAX_MESSAGE_LEN 50  // defaults to 50

// onewire ...
// #define TEMPERATURE_PRECISION 12
#define TEMPERATURE_PRECISION 10
#define NUMBER_OF_SENSORS 5
#define MAX_1WIRE_SENSORS 4

// reserved pin numbers and other defines ...
#define actLed 5
// #define rssiLed 8

#define RADIO_RESET_PIN 8
#define ONE_WIRE_BUS_PIN 7
#define MCP23S17_SLAVE_SELECT_PIN 3   // SPI Slave Select -> MCP23S17 CS pin 11
// #define SERIAL_BAUD_RATE 57600
#define SERIAL_BAUD_RATE 115200
#define NUMBER_OF_RSSI_TO_AVG 10
#define FREQ_OF_RSSI_CHK 10

/////////////// variables ///////////////

// Unfortunately, to make efficient use of limited memory, parameters are little used,
// and most variables are global.  This obviously makes for difficulty in uderstanding
// what's going on in the code, but works adequately for something this size, while
// encouraging programming in a way that's a bit repuslive and spaghetti-like ...

// for checking memory ...
int availMem;

// misc ...
uint8_t sensorNumber;        // for stepping through array of measurements
uint16_t prtStatsCtr = 1;    // for printing stats now and then

// for onewire sensors ...
DeviceAddress onewireAdrs[MAX_1WIRE_SENSORS] = {0};  // array of device addresses
uint8_t onewireDevices;             // Number of temperature devices found
uint8_t onewireIndex;               // loop counter used during setup
float tempC, tempF;                 // decl here b/c commented out below
char devAdrsStr[17] = "\0";         // for char string version of device adrs
char dateTimeStr[17] = "\0";        // for date/time string function

// for radio ...
char stringToSend[ RH_RF22_MAX_MESSAGE_LEN+1] = "\0"; // don't bother to chg this to uint8_t
uint8_t buf[ RH_RF22_MAX_MESSAGE_LEN+1];              // used for radio to rcv returned string
uint32_t loopCtr = 0;
uint32_t packets = 0;
uint32_t success = 0;
uint32_t failures = 0;
uint16_t rssiCtr = 0;
uint16_t rssiAvg = 0;
uint8_t  rssi[NUMBER_OF_RSSI_TO_AVG] = {0};

uint16_t maxWait = 200;

//////////// instantiations before following function defs ////////////

// RF22ReliableDatagram rf22(CLIENT_ADDRESS);  // instantiate radio client

RH_RF22 driver;     // instance of the radio driver
// Class to manage message delivery and receipt, using the driver declared above
// RHReliableDatagram manager(driver, CLIENT_ADDRESS);
RHReliableDatagram rf22(driver, CLIENT_ADDRESS);

MCP23S17 Mcp23s17_7 = MCP23S17(MCP23S17_SLAVE_SELECT_PIN,0x7);  // gpio chip
OneWire oneWire(ONE_WIRE_BUS_PIN);          // instantiate oneWire bus
DallasTemperature oneWireBus(&oneWire);     // pass oneWire to DallasTemperature


/////////////// functions ///////////////

// function to convert deviceAddress to char[]
void cnvrtDevAdrToStr(DeviceAddress deviceAddress) {
   for (int i=0; i<8; i++)
      sprintf(&devAdrsStr[i*2], "%02X", deviceAddress[i]);
}


// bool validateOnewireSensor(uint8_t);  // prototype only

void keepWatchdogAwake() {  // and blink actLed
  return;
    pinMode(actLed,OUTPUT);
    digitalWrite(actLed, HIGH);
    delay(20);
    digitalWrite(actLed, LOW);
    pinMode(actLed,INPUT);
}

int availableMemory() {
    int size = 2048;
    byte *buffer;
    while ((buffer = (byte *) malloc(--size)) == NULL);
    free(buffer);
    return size;
}

// the following function allows string representation of an int in binary format,
// which it seems can't be done with sprintf ...

#define CHECK_BIT(var,pos) ((var) & (1<<(pos)))
char binstr[17] = "\0";

void intToBinStr(uint16_t i) {
  for (int b=15; b>=0; b--) {
    // if (bit(i,b))  // doesn't exist?
    if (CHECK_BIT(i, b))
      binstr[15-b] = '1';
    else  
      binstr[15-b] = '0';
  }
  binstr[17] = '\0';
}

// following dragged over from the server sw to be used for formatting
// strings for when server requests stats from client
  /*
  // if requst to print stats was received, print info now ...
  if (prtStatsFlag) {
    Serial.print(serverAdrs);
    Serial.print(F("stats: packets_rcvd = "));
    Serial.println(received);      
    Serial.print(serverAdrs);
    Serial.print(F("       ack_fails = "));
    Serial.println(failures);
    Serial.print(serverAdrs);
    Serial.print(F("       successes = "));
    Serial.println(success);
    prtStatsFlag = false;
  }
  */

// unsigned int maxWait = 500;
unsigned int buff[10] = {0};
unsigned int waitTime = 10;

/*
/////////// random function ////////////
unsigned long t1 = 0, t2 = 0;
unsigned long rnd() {
  unsigned long b;
  b = t1 ^ (t1 >> 2) ^ (t1 >> 6) ^ (t1 >> 7);
  t1 = (t1 >> 1) | (~b << 31);
  b = (t2 << 1) ^ (t2 << 2) ^ (t1 << 3) ^ (t2 << 4);
  t2 = (t2 << 1) | (~b >> 31);
  return t1 ^ t2;
}
*/

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// setup()                                                                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

void setup() { 
  delay(100);
  Serial.begin(SERIAL_BAUD_RATE);
  availMem = availableMemory();
  Serial.println("\nsetup() started ...\n");  
  Serial.print(F("file: "));
  Serial.print(F(__FILE__));
  Serial.print(F(", date/time: "));
  Serial.print(F(__DATE__));
  Serial.print("/");
  Serial.println(F(__TIME__));
  Serial.print(F("chkMem free= "));
  Serial.print(availMem);
  Serial.print(F(", memory used=")); 
  Serial.println(2048-availMem);
  //Serial.println(F("started with file: basement_lcd_1wire_radio_crashboard_b_works"));
  //Serial.println(F("will attempt merging other stuff until it breaks\n"));  

  Wire.begin();       // init the i2c bus
 
   // init radio ...
  pinMode(RADIO_RESET_PIN, OUTPUT);
//  digitalWrite(RADIO_RESET_PIN, LOW);
//  delay(100);
//  digitalWrite(RADIO_RESET_PIN, HIGH);
  digitalWrite(RADIO_RESET_PIN, HIGH);
  delay(200);
  digitalWrite(RADIO_RESET_PIN, LOW);

  if (!rf22.init()) {
    Serial.println(F("RF22 init failed"));
    // do sonething reasonable here, such as run in circles, scream, shout, rather
    // than ignore the fact that the radio won't work and go along fat, dumb, happy.
  }
 else {
    Serial.println("passed ...");
    // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
    // chg data rate: FSK,   Rb = 125kbs,  Fd = 125kHz
    driver.setModemConfig(RH_RF22::FSK_Rb125Fd125);
    // change center frequency to 436 MHz, double pullin range from 0.05 to 0.10
    driver.setFrequency(436.000, 0.10);
    // default after init is 8 dbm (set it anyhow) - see .h file for valid choices
    //driver.setTxPower(RH_RF22_TXPOW_8DBM);
    driver.setTxPower(RH_RF22_TXPOW_20DBM);
    // driver.setTxPower(RH_RF22_TXPOW_2DBM);
    // set retries to lower than 10 since this isn't critical data
    rf22.setRetries(2); 
  }
  // avoid termination problems, init this string before first use ...  
  for (int i=0; i< RH_RF22_MAX_MESSAGE_LEN+1; i++)  stringToSend[i] = 0;
  sprintf(stringToSend, "client sw file:  %s", __FILE__);
  sendToServer();
  sprintf(stringToSend, "          date:  %s", __DATE__);
  sendToServer();
  sprintf(stringToSend, "          F_CPU: ");
  long fcpu = F_CPU;
  ltoa(fcpu, &stringToSend[17],10);
  sprintf(&stringToSend[strlen(stringToSend)], " Hz");
  sendToServer();

//char buf[12]; // "-2147483648\0"
//lcd.printIn(itoa(random(1024)-512, buf, 10));

  // assumed that the SPI has been set up by radio initialization ...
  // SPI.begin();  // init the SPI
  SPI.setClockDivider(SPI_CLOCK_DIV4);  // 2MHz SPI clock if 8MHz system    
  
  // Aurduino input D4 (pin6) drives mcp23s17 reset (pin 18) low to reset ...
  pinMode(4,OUTPUT);
  digitalWrite(4,HIGH);   // added to insure we start from hi state, likely useless
  delay(2);               // added to insure we start from hi state, likely useless
  digitalWrite(4,LOW);
  delay(1);
  digitalWrite(4,HIGH); 
  noInterrupts();   // turn off while messing with gpio
  // set all pins as inputs ...
  for (int pinNumber=0; pinNumber<16; pinNumber++)
     Mcp23s17_7.pinMode(pinNumber,INPUT);
  // turn on pullups
  Mcp23s17_7.setPullups(0xFFFF);  
  interrupts();     // done messing with gpio so rtn to previous state
  
  // zero out the receive data string ...  
  // shouldn't be needed since cleared after each use ...
  // for (int i=0; i< RH_RF22_MAX_MESSAGE_LEN+1; i++)  buf[i] = 0;

  // init activity and rssi led pins ...
  pinMode(actLed, OUTPUT);
  // pinMode(rssiLed, OUTPUT);

  keepWatchdogAwake();  // check later: don't enable watchdog device until setup completed
 
  // Start the 1wire bus ...
  oneWireBus.begin();
  // oneWireBus.setWaitForConversion(false);
  //oneWireBus.setWaitForConversion(true);

  // locate devices on the bus
  Serial.print(F("Locating devices ... "));
  onewireDevices = oneWireBus.getDeviceCount();
  Serial.print(F("Found "));
  Serial.print(onewireDevices, DEC);
  Serial.println(F(" devices."));

  if (onewireDevices != MAX_1WIRE_SENSORS) {   // something's amiss, report ...
    Serial.print(F("\n*** Error: found "));
    Serial.print(onewireDevices, DEC);
    Serial.print(F(" devices, but expected "));
    Serial.println(MAX_1WIRE_SENSORS, DEC);
    onewireDevices = ((onewireDevices < MAX_1WIRE_SENSORS) ? onewireDevices : MAX_1WIRE_SENSORS);
    Serial.print(F("continuing with "));
    Serial.print(onewireDevices, DEC);
    Serial.println(F(" devices\n"));
    }

  #ifdef DEBUG
  // report parasitic power requirements
  Serial.print(F("Parasitic power mode is: "));
  if (oneWireBus.isParasitePowerMode())
     Serial.println("ON\n");
  else
     Serial.println("OFF\n");
  #endif
  
  // iterate through the devices and collect addresses for the onewireAdrs[] array ...
  for(onewireIndex=0; onewireIndex<onewireDevices; onewireIndex++) {
    keepWatchdogAwake(); 
    // not thinking any more testing is really needed here ...
    // if(oneWireBus.isConnected(onewireAdrs[currentSensor.chanNumber])) { 
    if(oneWireBus.getAddress(onewireAdrs[onewireIndex], onewireIndex)) {     
      cnvrtDevAdrToStr(onewireAdrs[onewireIndex]);
      #ifdef DEBUG
      Serial.print(F("Found device "));
      Serial.print(onewireIndex, DEC);
      Serial.print(F(" with address: "));
      Serial.println(devAdrsStr);
      Serial.print(F("Setting resolution to "));
      Serial.println(TEMPERATURE_PRECISION, DEC);
      //delay(100);
      #endif
      // set the resolution to TEMPERATURE_PRECISION bits
      oneWireBus.setResolution(onewireAdrs[onewireIndex], TEMPERATURE_PRECISION);
      delay(50);		
      #ifdef DEBUG
      Serial.print(F("Resolution actually set to: "));
      Serial.print(oneWireBus.getResolution(onewireAdrs[onewireIndex]), DEC); 
      Serial.println();
      #endif
      sprintf (stringToSend, "1wire dev #%#2d", onewireIndex);
      sprintf(&stringToSend[strlen(stringToSend)], " found, adrs %s", devAdrsStr);
      // sprintf(&stringToSend[strlen(stringToSend)], "");
      // Serial.print(F("strlen(stringToSend): "));
      // Serial.println(strlen(stringToSend));
      sendToServer();
    }
    else {
      // hmmm ... could we ever get here, given the behavior of the getAddress func used?
      Serial.print(F("Found ghost device number "));
      Serial.print(onewireIndex, DEC);
      Serial.println(F(", can't read address\n"));
    }
  }
Serial.print(F("\nEnd of setup()\n"));
      sprintf (stringToSend, "end of setup()");
      sendToServer();
      sprintf (stringToSend, "");
      sendToServer();
 
}


////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// loop() consists of: sequencing through the various sensors named,          //
// reading them, and transmit the data to the server                          //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

void loop()
{
  keepWatchdogAwake();
  availMem = availableMemory();
  Serial.print(F("\nloop() started ...\nchkMem free= "));
  Serial.println(availMem);
//  Serial.print(F("F_CPU: "));
//  Serial.println(F_CPU);
//  Serial.print(F("sizeof(F_CPU): "));
//  Serial.println(sizeof(F_CPU));
  long fcpu = F_CPU;
//  Serial.print(F("sizeof(fcpu): "));
//  Serial.println(sizeof(fcpu));
  Serial.print(F("fcpu: "));
  Serial.println(fcpu);

  /*
  Serial.print(F("file: "));
  Serial.print(F(__FILE__));
  Serial.print(F(", date/time: "));
  Serial.print(F(__DATE__));
  Serial.print("/");
  Serial.println(F(__TIME__));
  Serial.print(F("chkMem free= "));
  Serial.print(availMem);
  Serial.print(F(", memory used=")); 
  Serial.println(2048-availMem);
  */

  
  // keep this for now, but later will change it to print only when rqst by server ...
  /*
  if (prtStatsCtr++ % 60 == 0) {
  // if (prtStatsCtr++ % 2 == 0) {
    sprintf(stringToSend, "client sw file:  %s", __FILE__);
    sendToServer();
    sprintf(stringToSend, "          date:  %s", __DATE__);
    sendToServer();
    sprintf(stringToSend, "          time:  %s", __TIME__);
    sendToServer();
    sprintf(stringToSend, "          F_CPU: %d", (uint16_t)fcpu);
    sendToServer();
  }
*/

typedef struct {
    const char sensorType;    // only G, W, A, P are meaningful, see below
    const uint8_t chanNumber; // channel # or onewireSensor index (into onewireAdrs[])
    const char* sensorName;   // char* to element of sensorName[] containing name
  } SENSOR;

// define sensor abbreviations for the sensorTable definition that follows ...
const char* sensorName[]  = {
  "gpio states",    // states all read at once, individual states not enumerated here
  "store tank top", // solar storage tank top
  "store tank bot", // solar storage tank bottom
  "coll supply",    // collector supply (cooler)
  "coll return",    // collector return (hot, hopefully)
  "boil tnk",       // boiler tank bottom
  "rad sup"        // radiant loop supply
//  "rad rtn",        // radiant loop return
//  "hw sply",        // hot water supply
//  "hw rtn",         // not water return from circulator
//  "heat exch",      // pump state: heat excange pump
//  "rad pump",       // state
//  "well pump",      // state
//  "blr blwr",       // state
//  "pres tnk",       // 
//  "pres flt",       // 
//  "propane",        // 
//  "batt volt",      // 
// "line volt",      // 
//  "\0",             // 
//  "\0"              // 
};

// sensorTypes defined:
//   G: reading of states via gpio, such as zone active (or not) and motor run state
//   W: one wire temp sensor data
//   A: analog reads for voltages and motor currents via 74HC4066 switches
//   P: possibly, raw AVR pin reads/writes for special purposes, if needed
// sensorTable rows consist of sensorType, chanNumber, and *sensorName[]
// for sensorType='W', the chanNumber is an index into the onewire device table
const SENSOR sensorTable[] = {
  'G',0,sensorName[0],            // 0
  'W',0,sensorName[1],            // 1
  'W',1,sensorName[2],            // 2  
  'W',2,sensorName[3],            // 3  
  'W',3,sensorName[4],            // 4  
  'W',4,sensorName[5],            // 5  
  'W',5,sensorName[6],            // 6  
  'A',1,sensorName[7],            // 7
  'A',2,sensorName[8],            // 8
  'A',3,sensorName[9],            // 9
  'A',4,sensorName[10],           // 10
  'A',5,sensorName[10],           // 11
  'A',6,sensorName[11],           // 12
  'A',7,sensorName[12],           // 13
  'P',12,sensorName[13],          // 14
  'P',13,sensorName[14]           // 15
  };
  

  // this asks temp devices to start temperature acquisition
  // note that the results are read later in the loop below ...
  // research time needed for full conversion resolution using this mass conversion request
  noInterrupts();
  oneWireBus.requestTemperatures(); // start acquistion of temperature data
  interrupts();
  #ifdef DEBUG
  Serial.println(F("1wire: requesting temps"));
  #endif

  // top level loop to read all sensors ...
  for (sensorNumber=0; sensorNumber<NUMBER_OF_SENSORS; sensorNumber++) {
    SENSOR currentSensor = sensorTable[sensorNumber];
    #ifdef DEBUG
    Serial.print(F("sensorNumber:"));
    Serial.print(sensorNumber);
    Serial.print(F(", sensorType:"));
    Serial.print(currentSensor.sensorType);
    Serial.print(F(", chanNumber:"));
    Serial.print(currentSensor.chanNumber);
    Serial.print(F(", sensorName:"));
    Serial.println(currentSensor.sensorName);
    #endif

    switch (currentSensor.sensorType) {
      case 'G':  // gpio chip state reads
        // Read states via gpio chip, send as int to server, to be decoded on other end.
        // Send only those data that represent a change of state since the last read.
        // Let server do the time-stamping until this device has RTC and memory connected,
        // then time-stamping can be done here.
        ///////////////////////////////////////
        // for now, the stuff here is copied into the foo delay loop at end of file ...
        /*
        char outstr[17];
        uint16_t pinstate = Mcp23s17_7.port();
        intToBinStr(pinstate);
        Serial.println(binstr);
        delay(100);
        */
        ///////////////////////////////////////        
        // Serial.println("do nothing for now\n");      // put gpio read stuff here
        break;
      case 'W':  // one wire temp sensor data
       // Verify that currentSensor.chanNumber <= to MAX_1WIRE_SENSORS and
       // that it still exists on bus.  These checks against possible  
       // table errors, disconnections, or device failure.
       if (currentSensor.chanNumber > MAX_1WIRE_SENSORS - 1) {
         // error: out of range
         Serial.println(F("*** Error: onewireAdrs index out of range, chk chanNumber for this sensor"));
         break;
       }
       // test onewireAdrs that we're about to use ...
       noInterrupts();
       cnvrtDevAdrToStr(onewireAdrs[currentSensor.chanNumber]);  // safe since only reading
       interrupts();
       if (devAdrsStr[0] == '0' && devAdrsStr[1] == '0') {
         Serial.println(F("*** Error: device adrs 0 encountered, check sensors table"));
         break;
       }
       // valid index, proceed ...
       // check that device is still here ...
       noInterrupts();   // turn off while messing with 1wire
       if(oneWireBus.isConnected(onewireAdrs[currentSensor.chanNumber])) {
         tempF = oneWireBus.getTempF(onewireAdrs[currentSensor.chanNumber]);
         interrupts();
         if ((loopCtr % 100) == 0) {
           /*
           sprintf (stringToSend, "sensor #%#2d", onewireIndex);
           sprintf(&stringToSend[strlen(stringToSend)], " found at adrs %s", devAdrsStr);
           sendToServer();
           sprintf(stringToSend, " is 1wire dev %02d/", sensorNumber);
           sprintf(&stringToSend[strlen(stringToSend)], "%c", currentSensor.sensorType);
           sprintf(&stringToSend[strlen(stringToSend)], "%02d, ", currentSensor.chanNumber);
           sprintf(&stringToSend[strlen(stringToSend)], "function: %s", currentSensor.sensorName);
           sendToServer();
           */
           sprintf (stringToSend, "sensor #%#2d:", onewireIndex);
           sprintf(&stringToSend[strlen(stringToSend)], " 1wire dev %02d/", sensorNumber);
           sprintf(&stringToSend[strlen(stringToSend)], "%c", currentSensor.sensorType);
           sprintf(&stringToSend[strlen(stringToSend)], "%02d, found at adrs", currentSensor.chanNumber);
           sendToServer();
           sprintf(&stringToSend[strlen(stringToSend)], "  %s", devAdrsStr);
           sprintf(&stringToSend[strlen(stringToSend)], ", function: %s", currentSensor.sensorName);
           sendToServer();
         }
         Serial.print(F("Temp for 1wire device "));
         Serial.print(currentSensor.chanNumber,DEC);
         // Serial.print(F(" with addr: "));
         // Serial.print(devAdrsStr);
         Serial.print(F(" = "));
         Serial.println(tempF);
         // format msg to server, starting with very clean string ...
         //   (this string cleaning operation is likely redundant) ...
         for (int i=0; i< RH_RF22_MAX_MESSAGE_LEN+1; i++)  stringToSend[i] = 0;
         // format string to send to server ...
         sprintf(stringToSend, "sensor %02d/", sensorNumber);
         sprintf(&stringToSend[10], "%c", currentSensor.sensorType);
         sprintf(&stringToSend[11], "%02d:", currentSensor.chanNumber);
         dtostrf((double)tempF, 6, 2, &stringToSend[14]);
         //sprintf(&stringToSend[19], "F adrs %s", devAdrsStr);
         sprintf(&stringToSend[20], "F");
         sendToServer();
       }
       else {
         // report failure ...
         interrupts();
         Serial.print(F("sensorType:W, chanNumber:"));
         Serial.print(currentSensor.chanNumber);
         Serial.print(F(" not found at adrs "));
         Serial.println(devAdrsStr);
         sprintf(stringToSend, "sensor%02d/", sensorNumber);
         sprintf(&stringToSend[9], "%c", currentSensor.sensorType);
         sprintf(&stringToSend[10], "%02d:", currentSensor.chanNumber);
         sprintf(&stringToSend[13], " not found, %s", devAdrsStr);
         sendToServer();
       }
       break;
      case 'A':  // analog reads for voltages and motor currents via 74HC4066 switches
         // setSwitchToChan(chanNumber);
         // fetchReading();
         // sendToServer();
        break;
      case 'P':  // raw AVR pin reads for some analog inputs
        // setAppropriateAvrPin(s)(chanNumber);
        // readAnalog(chanNumber);
        // sendToServer();
        break;
        
    }  // end of switch
    
  }  // end of for (sensorNumber ...) loop
 
  loopCtr++;  // times through the loop
  #ifdef DEBUG
  Serial.println();
  Serial.print(F("times through the loop: "));
  Serial.println(loopCtr);
  #endif
  Serial.println(F("--- done with loop ---\n"));
  
/*
unsigned long randXX = rnd();
  maxWait = maxWait - 4;
  unsigned int waitTime = maxWait + 10;
  waitTime += (((int)randXX) % 20);
  Serial.print("randXX: ");
  Serial.print(randXX);
  Serial.print(" (randXX % 20): ");
  Serial.print((randXX % 20));
  Serial.print(" maxWait: ");
  Serial.print(maxWait);
  Serial.print(" waitTime: ");
  Serial.println(waitTime);
*/
  //waitTime = waitTime % 479;
  //Serial.print(" waitTime: ");
  //Serial.println(waitTime);

  int foo = 0;
  // while (foo < 60)  // waste some time until: foo counts seconds
  while (foo < 2)  // waste some time until: foo counts seconds
    {
    keepWatchdogAwake();
    delay(200);
    for (int d=0; d<10; d++) {    
      //delay(979);
      char outstr[17];
      // uint16_t laststate = 0;
      uint16_t laststate;
      noInterrupts();
      uint16_t pinstate = Mcp23s17_7.port();
      interrupts();
      intToBinStr(pinstate);
      if (pinstate != laststate)
        Serial.println(binstr);
      laststate = pinstate;
      strcpy(stringToSend, binstr);
      sendToServer();
      

      // interrupts();
      // delay(100 * CLIENT_ADDRESS );
      // delay(waitTime);
      delay(20);
    }

    foo++;
  }
  sprintf(stringToSend, "rssiAverage: %0d: ",rssiAvg);
  sendToServer();

}   // end loop

 
void sendToServer() {
  //pinMode(actLed,OUTPUT);
  //digitalWrite(actLed, HIGH);
  
  // likely won't use this string anylonger, but clear it as long as it's here ...
  // zero buf used for receiving the acknowledge string ...  
  for (int i=0; i< RH_RF22_MAX_MESSAGE_LEN+1; i++)  buf[i] = 0;

  #ifdef DEBUG  
  Serial.print(F("  Sending to server: "));
  Serial.println(stringToSend);
  Serial.print(F("  strlen(stringToSend): "));
  Serial.println(strlen(stringToSend));
  #endif
  // Send to rf22_server ...
  packets++;
  //if (!rf22.sendtoWait((uint8_t*) &(stringToSend[0]), strlen(stringToSend), SERVER_ADDRESS)) {
  if (!rf22.sendtoWait((uint8_t*) stringToSend, strlen(stringToSend), SERVER_ADDRESS)) {
    failures++;
    Serial.print(F(" sendtoWait failed, failures: "));
    Serial.println(failures, DEC);
    pinMode(actLed, INPUT);
    // analogWrite(rssiLed, 0);
    }
  else {
    success++;
    // check rssi for every nth successful packet sent ...
    if ((success % FREQ_OF_RSSI_CHK) == 0) {
      rssi[rssiCtr++] = driver.lastRssi();
      if ((rssiCtr % NUMBER_OF_RSSI_TO_AVG) == 0) rssiCtr=0;
      uint16_t nonzeroRssi = 0, rssiTotal = 0;
      for (uint8_t i=0; i<NUMBER_OF_RSSI_TO_AVG; i++) {
        rssiTotal += rssi[i];
        if (rssi[i]) nonzeroRssi++;  // increment counter only if valid value
      }
    rssiAvg = rssiTotal / nonzeroRssi;
    /*
    #ifdef DEBUG
    Serial.println(F("success/rssiCtr/rssi[rssiCtr]/rssiTotal/rssiAvg/nonzeroRssi:"));
    Serial.println(success, DEC);
    Serial.println(rssiCtr, DEC);
    Serial.println(rssi[rssiCtr], DEC);
    Serial.println(rssiTotal, DEC);
    Serial.println(rssiAvg, DEC);
    Serial.println(nonzeroRssi, DEC);
    #endif
    */
    }
  }
    
  // once string has been sent or tries exhausted, leave string very clean ...  
  for (int i=0; i< RH_RF22_MAX_MESSAGE_LEN+1; i++)  stringToSend[i] = 0;
}  // end sendToServer
 

  /* 
  else 
    {
    // Now wait for a reply from the server
    // changes follow  vvvvv
    pinMode(actLed, INPUT);  // needed??  (yes? turns led off?)
    // repl following lines with keepWatchdogAwake(); ??
    /*
    delay(10);
    pinMode(actLed, OUTPUT);
    digitalWrite(actLed, HIGH);
    delay(10);
    pinMode(actLed, INPUT);
    delay(10);
    /*
    keepWatchdogAwake();  // added, see last comment above
    pinMode(actLed, OUTPUT);  // needed??
    // changes above  ^^^^^
    digitalWrite(actLed, HIGH);
    #ifdef DEBUG
    Serial.println(F(" OK! ackRSSI was: "));
    uint8_t rssi = driver.lastRssi();
    Serial.print(rssi, DEC);
    Serial.println("/255");
    #endif
    // how come drive led with analogwrite? ...
    // analogWrite(rssiLed, driver.lastRssi());   // what's this for?
    
    uint8_t len = sizeof(buf);
    uint8_t from;   
    if (rf22.recvfromAckTimeout(buf, &len, 2000, &from))
      {
      digitalWrite(actLed, LOW);
      success++;
      #ifdef DEBUG
      Serial.print(F("  got reply, success #: "));
      Serial.print(success, DEC);
      Serial.print(" : ");
      Serial.println((char*)buf);
      #endif
      }
    else {
      pinMode(actLed, INPUT);
      noReply++;
      Serial.print(F("  No reply, server running?\n  no reply count: "));
      Serial.println(noReply, DEC);
    }    
  // once string has been sent, leave it very clean ...  
  for (int i=0; i< RH_RF22_MAX_MESSAGE_LEN+1; i++)  stringToSend[i] = 0;
  }   
}  // end sendToServer
*/





