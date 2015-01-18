/* Code starts here - call it GPSLogger_v2.1 :) */

// this is a generic logger that does checksum testing so the data written should be always good
// Assumes a sirf III chipset logger attached to pin 0 and 1

#include "AF_SDLog.h"
#include "util.h"
#include <avr/pgmspace.h>
#include <avr/sleep.h>
#include <Streaming.h>
#include <PString.h>
// Date and time functions using a DS1307 RTC connected via I2C and Wire lib
#include <Wire.h>
#include "RTClib.h"

RTC_DS1307 RTC;

// power saving modes
#define SLEEPDELAY 0
#define TURNOFFGPS 0
#define LOG_RMC_FIXONLY 1

AF_SDLog card;
File f;

#define actLed 9
#define led2Pin 7
#define powerPin 2
#define battSensePin 3      // *analog* battery woltage sense pin

#define BUFFSIZE 80
char buffer[BUFFSIZE];
char buffer2[40];
uint8_t bufferidx = 0;
uint8_t fix = 0; // current fix data
uint8_t i;
PString rtcString(buffer2, sizeof(buffer2));

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
  Serial.println("debug: in setupWatchdog");

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

  config_watchdog(8);
}

byte del;
int cnt;
byte state=0;
int light=0;


//****************************************************************
//****************************************************************
//****************************************************************
void sleepWithBeacon(int dur) {

  int i;
  dur = dur / 4; // assumes sleep mode 8, 4s per period
//  if (f_wdt==1) {  // wait for timed out watchdog / flag is set when a watchdog timeout occurs
//    f_wdt=0;       // reset flag
//    nint++;
//    Serial << "Sleeping " << dur << endl;
//    Serial.println(nint );
//    delay(2);               // wait until the last serial character is send

    //pinMode(pinLed,INPUT); // set all used port to input to save power

    for ( i=0; i<=dur; i++) {
      Serial.println(millis());
      rtcTest();
      digitalWrite(actLed,HIGH);  // let led blink
      delay(40);
      digitalWrite(actLed,LOW);
      system_sleep();
    }

//  }
}

//****************************************************************  
// set system into the sleep state 
// system wakes up when wtchdog is timed out
void system_sleep() {

  cbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter OFF

  set_sleep_mode(SLEEP_MODE_PWR_DOWN); // sleep mode is set here
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
  Serial << "config_watchdog(" << ww << ")" << endl;

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





void rtcSetup() {
    Wire.begin();
    RTC.begin();
    // use RTC_setter_prog once instead of doing it in here where its easy to run again accidentally
    //RTC.adjust(DateTime("Aug 17 2010", "20:33:00"));
}

void rtcTest () {
    //chkMem();
    DateTime now = RTC.now();
    rtcString.begin();    
    rtcString << now.year() << int(now.month())
           << int(now.day()) << '-' 
           << int(now.hour()) << ':' 
           << int(now.minute()) << ':' 
           << int(now.second());

    buffer2[rtcString.length()+1] = 0; // terminate it

    Serial << now.year() << '/' << int(now.month()) << '/'
           << int(now.day()) << ' ' 
           << int(now.hour()) << ':' 
           << int(now.minute()) << ':' 
           << int(now.second()) << '\n' ;
/*    Serial.print('/');
    Serial.print(now.month(), DEC);
    Serial.print('/');
    Serial.print(now.day(), DEC);
    Serial.print(' ');
    Serial.print(now.hour(), DEC);
    Serial.print(':');
    Serial.print(now.minute(), DEC);
    Serial.print(':');
    Serial.print(now.second(), DEC);
    Serial.println();
*/  
    Serial.print(" since midnight 1/1/1970 = ");
    Serial.print(now.unixtime());
    Serial.print("s = ");
    Serial.print(now.unixtime() / 86400L);
    Serial.println("d");
    //chkMem();
/*    
    // calculate a date which is 7 days and 30 seconds into the future
    DateTime future (now.unixtime() + 7 * 86400L + 30);
    
    Serial.print(" now + 7d + 30s: ");
    Serial.print(future.year(), DEC);
    Serial.print('/');
    Serial.print(future.month(), DEC);
    Serial.print('/');
    Serial.print(future.day(), DEC);
    Serial.print(' ');
    Serial.print(future.hour(), DEC);
    Serial.print(':');
    Serial.print(future.minute(), DEC);
    Serial.print(':');
    Serial.print(future.second(), DEC);
    Serial.println();
    Serial.println();
    //chkMem();
    */
    
}












/**********************************
   DS18S20 Temperature chip i/o */
#include <OneWire.h>
OneWire ds(8);  // on pin 8
int qsensors, HighByte, LowByte, TReading, SignBit, Tc_100, Whole, Fract, Tf_100, fWhole, fFract;

byte smac[8];
float floaty = -32.86;

float getDS18B20_Celsius() {
  floaty = floaty + 0.01;
  byte i;
  byte present = 0;
  byte data[12];
  byte addr[8];
  
  if ( !ds.search(addr)) {
    Serial.print("No more sensors found on 1-wire bus.\n");
    ds.reset_search();
    delay(250);
    qsensors=0;
    return(-273.15);
  } else {
    qsensors++;
  }
  ds.search(addr);
  
  
  //dbgSerial.print("R=");
  for( i = 0; i < 8; i++) {
    //dbgSerial.print(addr[i], HEX);
    //dbgSerial.print(" ");
    smac[i] = addr[i];
  }

  if ( OneWire::crc8( addr, 7) != addr[7]) {
      Serial.print("sensor returned invalid CRC!\n");
      return(-273.16);
  }
  
  if ( addr[0] != 0x28) {
      Serial.print("discovered device is not a DS18B20 family device.\n");
      return(-273.17);
  }

  // The DallasTemperature library can do all this work for you!

  ds.reset();
  ds.select(addr);
  ds.write(0x44,1);         // start conversion, with parasite power on at the end
  delay(800);     // maybe 750ms is enough, maybe not
  // we might do a ds.depower() here, but the reset will take care of it.
  
  present = ds.reset();
  ds.select(addr);    
  ds.write(0xBE);         // Read Scratchpad

  //dbgSerial.print("P=");
  //dbgSerial.print(present,HEX);
  //dbgSerial.print(" ");
  for ( i = 0; i < 9; i++) {           // we need 9 bytes
    data[i] = ds.read();
    //dbgSerial.print(data[i], HEX);
    //dbgSerial.print(" ");
  }
//dbg  Serial.print(" CRC=");
//dbg  Serial.print( OneWire::crc8( data, 8), HEX);
//dbg  Serial.println();
  
  LowByte = data[0];
  HighByte = data[1];
  TReading = (HighByte << 8) + LowByte;
  SignBit = TReading & 0x8000;  // test most sig bit
  if (SignBit) // negative
  {
    TReading = (TReading ^ 0xffff) + 1; // 2's comp
  }

  Tc_100 = (6 * TReading) + TReading / 4;    // multiply by (100 * 0.0625) or 6.25

    if (SignBit) { // negative
    floaty = 0 - (float(Tc_100) / 100);
  } else {
    floaty = float(Tc_100) / 100;
  }
  
  //Serial << "floaty celsius reading is" << floaty << "." << endl;
  
  return(floaty);
}


float getDS18B20_Fahrenheit() {
  floaty = (getDS18B20_Celsius() * 9/5) + 32;
  //dbgSerial << "floaty fahrenheit reading is" << floaty << "." << endl;
  return(floaty);
}


/* END DS18S20 stuff */

/***********************************
 Generic Functions
*/
   
// read a Hex value and return the decimal equivalent
uint8_t parseHex(char c) {
  if (c < '0')
    return 0;
  if (c <= '9')
    return c - '0';
  if (c < 'A')
    return 0;
  if (c <= 'F')
    return (c - 'A')+10;
}

// blink out an error code
void error(uint8_t errno) {
  while(1) {
    for (i=0; i<errno; i++) {
      digitalWrite(actLed, HIGH);
      digitalWrite(led2Pin, HIGH);
      delay(1000);
      digitalWrite(actLed, LOW);
      digitalWrite(led2Pin, LOW);
      delay(50);
    }
    for (; i<40; i++) {
      delay(100);
    }
  }
}



void setup()
{
  Serial.begin(57600);
  setupWatchdog();
  putstring_nl("tempLogger!");
  pinMode(actLed, OUTPUT);
  pinMode(led2Pin, OUTPUT);

  pinMode(battSensePin, INPUT);
  analogReference(DEFAULT);  
  

  sdCardSetup();
  rtcSetup();
}

void sdCardSetup() {
  if (!card.init_card()) {
    putstring_nl("Card init. failed!");
    error(1);
  }
  if (!card.open_partition()) {
    putstring_nl("No partition!");
    error(2);
  }
  if (!card.open_filesys()) {
    putstring_nl("Can't open filesys");
    int foo = card.open_filesys();
    Serial.println(foo);
    error(3);
  }
  if (!card.open_dir("/")) {
    putstring_nl("Can't open /");
    error(4);
  }

  strcpy(buffer, "TMPLOG00.TXT");
  for (buffer[6] = '0'; buffer[6] <= '9'; buffer[6]++) {
    for (buffer[7] = '0'; buffer[7] <= '9'; buffer[7]++) {
      putstring("\ntrying to open ");Serial.println(buffer);
      f = card.open_file(buffer);
      if (!f)
        break;
      card.close_file(f);
    }
    if (!f)
      break;
  }

  if(!card.create_file(buffer)) {
    putstring("couldnt create ");
    Serial.println(buffer);
    error(5);
  }
  f = card.open_file(buffer);
  if (!f) {
    putstring("error opening ");
    Serial.println(buffer);
    card.close_file(f);
    error(6);
  }
  putstring("writing to ");
  Serial.println(buffer);
  putstring_nl("ready!");

  delay(250);
  
}



// memory monitor crap
void chkMem() {
  Serial.print("chkMem free= ");
  Serial.print(availableMemory());
  Serial.print(", memory used=");
  Serial.println(2048-availableMemory());

}

int availableMemory() {
 int size = 2048;
 byte *buf;
 while ((buf = (byte *) malloc(--size)) == NULL);
 free(buf);
 return size;
} 
// end memory monitor crap

long iterations = 0;
long ts = millis();
PString str(buffer, sizeof(buffer));

int bv = 0;

void loop()
{
  //chkMem();
  str.begin();
  //Serial.println(Serial.available(), DEC);
  char c;
  uint8_t sum;
  //chkMem();
  // Serial.println("trying to read the sensor...");
//  tempLoop();
  iterations++;
  ts = millis() / 1000;
  //float temp = getDS18B20_Celsius();
  //Serial << "floaty celsius reading is " << temp << "C." << endl;
  float temp = getDS18B20_Fahrenheit();
  //Serial << "floaty fahrenheit reading is " << temp << "F" << endl;

  bv=analogRead(battSensePin);
  //chkMem();
  if (temp < -273 ) {
    Serial.println("poop, something is wrong, its absolute zero!.  Turning the heater off and skipping everything else.");
    digitalWrite(actLed, LOW); 
    return;
  }
  
  rtcTest();

  if (temp <80 ) {
    str << rtcString << " uptime=" << ts << " sec, batt=" << bv << ", i=" << iterations << ", " << temp << "F, trig=ON" << endl; 
    //digitalWrite(actLed, HIGH); 
  } else {
    str << rtcString << " uptime=" << ts << " sec, batt=" << bv << ", i=" << iterations << ", " << temp << "F, trig=off" << endl; 
    //digitalWrite(actLed, LOW); 
    
  }
  //chkMem();
  
  Serial.print(str);
  buffer[str.length()+1] = 0; // terminate it
  if(card.write_file(f, (uint8_t *) buffer, str.length()) != str.length()) {
     putstring_nl("can't write!");
     digitalWrite(actLed, HIGH); 
     //return;  // no need to return, lets just sleep like usual instead of draining battery
  } else {
    Serial.println("wrote ok");
  }
  //chkMem();
  sd_raw_sync();
  Serial.println("synced ok");
  //chkMem();
  
  Serial.println("rtc done");
  // delay for SD to finish
  delay(600);
  
  
  sleepWithBeacon(8);

}


/************************
    adafruit's idea of sleeping.  not sure i like it as much as other one above
    
void sleep_sec(uint8_t x) {
  while (x--) {
     // set the WDT to wake us up!
    WDTCSR |= (1 << WDCE) | (1 << WDE); // enable watchdog & enable changing it
    WDTCSR = (1<< WDE) | (1 <<WDP2) | (1 << WDP1);
    WDTCSR |= (1<< WDIE);
    set_sleep_mode(SLEEP_MODE_PWR_DOWN);
    sleep_enable();
    sleep_mode();
    sleep_disable();
  }
}

SIGNAL(WDT_vect) {
  WDTCSR |= (1 << WDCE) | (1 << WDE);
  WDTCSR = 0;
}
*********** end adafruit sleeping **********/

/* EOF */
