/* derived from Adafruit  GPSLogger_v2.1  */

#include "AF_SDLog.h"
#include "util.h"
#include <avr/pgmspace.h>
#include <avr/sleep.h>
#include <Streaming.h>
#include <PString.h>
// 20292 = baseline
// 20432 = added chkmem, resulted in:
// chkMem free= 411, memory used=1637  
// (note that chkMem showed as little as 190 before simply cutting strings down, but before Flash lib)
//
// Flash has to come after Streaming because of conflicting definition of endl
#include <Flash.h>
// adding a single Serial.println(F(" ")); resulting in 20602 compiled bin size
// 90% conversion resulted in 21420 size, but:
// chkMem free= 855, memory used=1193


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
#define powerPin 2
#define battSensePin 3      // *analog* battery woltage sense pin


#define BUFFSIZE 100
char buffer[BUFFSIZE];
char buffer2[BUFFSIZE];
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
int lastSnapMinute = 77;
int nowHour = 55;
int nowMinute = 55;


//****************************************************************
//****************************************************************

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
/* *******************************
/* BEGIN nikon L11 cam control stuff */
#define oneWirePin 16
#define btnPin 14
//#define fastPinSw 14
//#define BLUE 3
//#define GREEN 4
//#define RED 5
#define BLUE 2
#define GREEN 3
#define RED 4
#define camRegulator 8
#define powerSw 7
#define focusSw 6
#define shutterSw 5
#define powerSwHoldTime 1200
#define warmupTime 3000
#define focusSwHoldTime 1200
#define shutterSwHoldTime 2000
#define waitAfterExposure 3000
#define longPicPeriod 120000
#define shortPicPeriod 10000
// photoresistor is on ANALOG pin 1 (aka D15 or atmega328 phys pin 24)
#define photoResistor 1 
// photoresistor is on ANALOG pin 3 (aka D17 or atmega328 phys pin 26)
#define periodPot 3

#define lowLightLevel 560
#define highLightLevel 580
boolean okToShoot = false;
boolean writes_enabled = true;  // backwards... its currently true unless something goes wrong.
int photoLevel = 0;
int rtcPicPeriod = 10;

int blinkTime = 100;
long previousMillis = 0;
long interval = 60000;
boolean powerOff = true;

//****************************************************************
void sleepWithBeacon(int dur) {

  int i;
  dur = dur / 4; // assumes sleep mode 8, 4s per period
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
         Serial.print(i);
         Serial.println(dur);
         Serial.print(F("chkmem inside sleep:"));
         chkMem();
         Serial.print(F("chkBtn inside sleep:"));
       */
      chkBtn();
      rtcTest();
      brightEnough();
      //rtcTest set hours and minutes for us
      if (((nowMinute % rtcPicPeriod) == 0) && (nowMinute != lastSnapMinute)) {
        Serial.print(F("minute seems to indicate we should take a picture... min = "));
        Serial.println(nowMinute, DEC);
        lastSnapHour = nowHour;
        lastSnapMinute = nowMinute;
        break;
      }
      
      digitalWrite(actLed,HIGH);  // let led blink
      delay(40);
      digitalWrite(actLed,LOW);
      system_sleep();
    }

//  }
}




void camSetup()
{
  pinMode(btnPin, INPUT);
  //pinMode(fastPinSw, INPUT);
  pinMode(photoResistor, INPUT);
  digitalWrite(btnPin, HIGH);    // turn on pullups
//  digitalWrite(fastPinSw, HIGH); // turn on pullups
  // no pullup for photoResistor
  
  pinMode(RED, OUTPUT);
  pinMode(GREEN, OUTPUT);
  pinMode(BLUE, OUTPUT);
  pinMode(camRegulator, OUTPUT);
  pinMode(powerSw, OUTPUT);
  pinMode(focusSw, OUTPUT);
  pinMode(shutterSw, OUTPUT);
  digitalWrite(camRegulator, HIGH);
  digitalWrite(powerSw, LOW);
  digitalWrite(focusSw, HIGH);
  digitalWrite(shutterSw, HIGH);
  
  if (rtcPicPeriod < 1) rtcPicPeriod = 1;
  if (rtcPicPeriod > 30) rtcPicPeriod = 30;  // so we dont get stuck on 0 or a number larger than 30 that will only occur once an hour
  

}

boolean leftOff = true;

void shoot() {
  if (okToShoot) {
    if (leftOff) {
      Serial.println(F("s001:pwr bus"));
      digitalWrite(RED, HIGH);
      digitalWrite(camRegulator, LOW);  //(EN pin on regulator goes low to turn on)
      delay(powerSwHoldTime*2);
      Serial.println(F("s002:cam power button"));
      digitalWrite(powerSw, HIGH);
      delay(powerSwHoldTime);
      digitalWrite(RED, HIGH);
      digitalWrite(powerSw, LOW);
      Serial.println(F("s003:settle"));
      delay(warmupTime);
      digitalWrite(RED, LOW);
    } else {
      Serial.println(F("s001:already on"));
    }
    
    //focus
    Serial.println(F("s004:focus"));
    digitalWrite(BLUE, HIGH);
    digitalWrite(focusSw, LOW);
    delay(focusSwHoldTime);
    
    //shoot
    Serial.println(F("s005:SHOOT!"));
    digitalWrite(GREEN, HIGH);
    digitalWrite(shutterSw, LOW);
    delay(shutterSwHoldTime);
  
    //wait for cam to write to SD card
    Serial.println(F("s006:waitWrite"));
    digitalWrite(RED, HIGH);
    digitalWrite(shutterSw, HIGH);
    //delay(shutterSwHoldTime/20);
    digitalWrite(focusSw, HIGH);
    delay(waitAfterExposure);
    digitalWrite(RED, LOW);
    digitalWrite(GREEN, LOW);
    digitalWrite(BLUE, LOW);
  
    if (powerOff) {
      Serial.println(F("s007:camOff"));
      digitalWrite(RED, HIGH);
      digitalWrite(BLUE, HIGH);
      digitalWrite(powerSw, HIGH);
      delay(powerSwHoldTime);
      digitalWrite(powerSw, LOW);
      digitalWrite(BLUE, LOW);
      delay(powerSwHoldTime *2);
      Serial.println(F("s007b:camRegulatorOff"));
      digitalWrite(camRegulator, HIGH);  //(EN pin on regulator goes high to turn OFF)
      digitalWrite(RED, LOW);
    
      leftOff = true;
    } else {
      Serial.println(F("s008:fast,NOTcamOff"));
      leftOff = false;
    }
  } else {
     Serial.println(F("s009=noshot"));
  }  



  Serial.println(F("s010:done!"));    

}


boolean brightEnough() {
  //okToShoot is global, since we need it next time, cant just simply return
  photoLevel = analogRead(photoResistor);
  if (okToShoot && (photoLevel < lowLightLevel)) {
    // changing from ok to tooDark state
    Serial.print(F("bright: OK->tooDark "));
    okToShoot = false;
  } else {
    if ((! okToShoot) && (photoLevel > highLightLevel )) {
      // changing from tooDark back to OK
      Serial.print(F("bright: tooDark->OK "));
      okToShoot = true;
    } else {
      Serial.print(F("bright: no change "));
    }
  }

  Serial.println(photoLevel);

  return(okToShoot);
  
}




void chkBtn () {
  if ( ! digitalRead(btnPin)) {
    Serial.println(F("btn pushed!?!"));
    digitalWrite(RED, LOW);
    digitalWrite(GREEN, LOW);
    digitalWrite(BLUE, LOW);
    //powerOff=false;
      // read a new value for interval from attached pot:
    int val = analogRead(periodPot);
    rtcPicPeriod = map(val, 0, 1023, 1, 30);
    Serial.print(F("chkBtn: interval now set to minutes that are divisible by: "));
    Serial.println(rtcPicPeriod);

    shoot();
  } else {
    //Serial.println(".");
    delay(blinkTime);
  }
    
}


/*
void camPoopLoop() {
  long m = millis();
  
  if (! digitalRead(fastPinSw)) {
    Serial.println("fast=ON");
    interval = shortPicPeriod;
    blinkTime = 100;
    powerOff = false;
  } else {
    Serial.println("fast=OFF");
    interval = longPicPeriod;
    powerOff = true;
    blinkTime = 400;
  }
  
  Serial.println(m);
  if (m - previousMillis > interval) {    
    //if (digitalRead(btnPin)) {
    shoot();
    previousMillis = millis();         
    Serial.print(interval);
    Serial.println(" ms til next cam shot");
    //}
  } else {
    // play with the LEDs
    chkBtn();
   }
}

*/




/* END nikon L11 cam control stuff
*****************************************/


/* RTC stuff */
void rtcSetup() {
    Wire.begin();
    RTC.begin();
    // use RTC_setter_prog once instead of doing it in here where its easy to run again accidentally
    //RTC.adjust(DateTime("Aug 17 2010", "20:33:00"));
}


void rtcTest () {
    //chkMem();
    DateTime now = RTC.now();
 
    // FIXMEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
    nowHour = int(now.hour());
    nowMinute = int(now.minute());
 
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
//    Serial.print(F(" unix= "));
//    Serial.println(now.unixtime());
    //Serial.print("s = ");
    //Serial.print(now.unixtime() / 86400L);
    //Serial.println("d");
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
OneWire ds(oneWirePin);
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
    Serial.print(F("No more sensors\n"));
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
      Serial.print(F("sensor returned invalid CRC!\n"));
      return(-273.16);
  }
  
  if ( addr[0] != 0x28) {
      Serial.print(F("device is not a DS18B20 family device.\n"));
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
  writes_enabled = false;
  Serial.print(F("continuing anyway after error number:"));
  Serial.println(errno, DEC);
  /* while(1) {
    for (i=0; i<errno; i++) {
      digitalWrite(actLed, HIGH);
      delay(1000);
      digitalWrite(actLed, LOW);
      delay(50);
    }
    for (; i<40; i++) {
      delay(100);
    }
  }
  */
}


// memory monitor crap

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

// end memory monitor crap



void setup()
{
  Serial.begin(57600);
  //chkMem();
  setupWatchdog();
  Serial.println(F("camController init...."));
  pinMode(actLed, OUTPUT);

  pinMode(battSensePin, INPUT);
  analogReference(DEFAULT);  
  
  camSetup();
  sdCardSetup();
  rtcSetup();
}

void sdCardSetup() {
  if (!card.init_card()) {
    Serial.print(F("Card init. failed!"));
    error(1);
  }
  if (!card.open_partition()) {
    Serial.print(F("No partition!"));
    error(2);
  }
  if (!card.open_filesys()) {
    Serial.print(F("Can't open filesys"));
    int foo = card.open_filesys();
    Serial.println(foo);
    error(3);
  }
  if (!card.open_dir("/")) {
    Serial.print(F("Can't open /"));
    error(4);
  }

  strcpy(buffer, "CAMLOG00.TXT");
  for (buffer[6] = '0'; buffer[6] <= '9'; buffer[6]++) {
    for (buffer[7] = '0'; buffer[7] <= '9'; buffer[7]++) {
      Serial.print(F("\ntrying to open "));
      Serial.println(buffer);
      f = card.open_file(buffer);
      if (!f)
        break;
      card.close_file(f);
    }
    if (!f)
      break;
  }

  if(!card.create_file(buffer)) {
    Serial.print(F("couldnt create "));
    Serial.println(buffer);
    error(5);
  }
  f = card.open_file(buffer);
  if (!f) {
    Serial.print(F("error opening "));
    Serial.println(buffer);
    card.close_file(f);
    error(6);
  }
  Serial.print(F("writing to "));
  Serial.println(buffer);
  Serial.println(F("ready!"));

  delay(250);
  
}



long iterations = 0;
long ts = millis();
PString str(buffer, sizeof(buffer));

int bv = 0;

void loop()
{
  chkMem();
  str.begin();
  //Serial.println(Serial.available(), DEC);
  char c;
  uint8_t sum;
  //chkMem();
  // Serial.println(F("trying to read the sensor..."));
  //tempLoop();
  iterations++;
  ts = millis() / 1000;
  
  //float temp = getDS18B20_Celsius();
  //Serial << F("floaty celsius reading is ") << temp << F("C.") << endl;
  float temp = getDS18B20_Fahrenheit();
  //Serial << F("floaty fahrenheit reading is ") << temp << F("F") << endl;

  bv=analogRead(battSensePin);
  //chkMem();
  if (temp < -273 ) {
    Serial.println(F("poop, horked"));
    digitalWrite(actLed, LOW); 
    return;
  }
  
  rtcTest();

  boolean poop = brightEnough();

  str << rtcString << " picMins=" << rtcPicPeriod << ", batt=" << bv << ", i=" << iterations << ", t=" << temp << ", sun=" << photoLevel;
  if (poop) {
    str << F(" OK, shooting\n");
    Serial.print(str);
    shoot(); 
  } else {
    str << F(" too dark\n");
    Serial.print(str);
    //digitalWrite(actLed, LOW); 
    
  }
  //chkMem();
  
  
  buffer[str.length()+1] = 0; // terminate it
  if (writes_enabled) {
    if(card.write_file(f, (uint8_t *) buffer, str.length()) != str.length()) {
       Serial.println(F("can't write!"));
       digitalWrite(actLed, HIGH); 
       //return;  // no need to return, lets just sleep like usual instead of draining battery
    } else {
      Serial.println(F("wrote ok"));
    }
    //chkMem();
    sd_raw_sync();
    Serial.println(F("synced ok"));
    //chkMem();
  } else {
    Serial.println(F("writes not enabled, check SD card and perform reset"));
  }
  
  Serial.println(F("rtc done"));
  // delay for SD to finish, dont need to if running camera after this
  delay(600);

  
  
  sleepWithBeacon(1800);  //(60 = 86 seconds between shots)
  Serial.print(F("loop done "));
  Serial.println(iterations);
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
