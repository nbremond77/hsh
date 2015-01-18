/* derived from Adafruit  GPSLogger_v2.1  */

#include "AF_SDLog.h"
#include "util.h"
#include <avr/pgmspace.h>
#include <avr/sleep.h>
//#include <Streaming.h>
#include <PString.h>
// Flash has to come after Streaming because of conflicting definition of endl
#include <Flash.h>


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

#define BUFFSIZE 200
char buffer[BUFFSIZE];
#define RTCBUFFERSIZE 20
char rtcBuffer[RTCBUFFERSIZE];
uint8_t bufferidx = 0;
uint8_t fix = 0; // current fix data
uint8_t i;
PString rtcString(rtcBuffer, sizeof(rtcBuffer));

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

  config_watchdog(7);
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
/* *******************************
/* BEGIN nikon L11 cam control stuff */
#define oneWirePin 8
#define btnPin 3
//#define fastPinSw 14
//#define BLUE 3
//#define GREEN 4
//#define RED 5
#define BLUE 9
#define GREEN 9
#define RED 9
#define winkTime 30
#define camRegulator 4
#define powerSw 7
#define focusSw 6
#define shutterSw 5
#define powerSwHoldTime 500
#define warmupTime 3000
#define powerDownHoldTime 3000
#define focusSwHoldTime 2000
#define shutterSwHoldTime 2000
#define waitAfterExposure 3000
#define defaultPicPeriod 15 // minutes divisible by
#define minPicPeriod 1 // minutes divisible by 
#define maxPicPeriod 60 // minutes divisible by
#define periodIncrement 1 // minutes
#define periodRoundToMax 30 // if greater than this number of minutes, we round up to max

// photoresistor is on ANALOG pin 1 (aka D15 or atmega328 phys pin 24)
#define photoResistor 1 
// periodPot is on ANALOG pin 0 (aka D14 or atmega328 phys pin 23)
#define periodPot 0
#define lowLightLevel 480 // 580
#define highLightLevel 540 //640

boolean okToShoot = false;
boolean writes_enabled = true;  // backwards... its currently true unless something goes wrong.
int photoLevel = 0;
int rtcPicPeriod = defaultPicPeriod;

// battery related bits
long batteryMilliVolts = 0;
float batteryVolts = 0;
#define battSensePin A3      // *analog* battery woltage sense pin
#define AREFSource EXTERNAL

// MAX6030 precision 3.000V reference
#define AREFvolts 3.000
#define AREFscaler 4.33
#define AREFmult 1268 // 1268 ~= 100 * 3000 / 1024 * 4.33;
#define AREFdiv 100 // divide afterwards to get back to an INT
#define batteryThresholdMilliVolts 3550

// alternate if we want to use DEFAULT AVCC voltage reference
//#define AREFmult 14 // 14 ~= 3311 / 1024 * 4.33;

// alternate if we want to use the INTERNAL voltage reference
//#define AREFmult 465 // 465 ~= 100 * 1100 / 1024 * 4.33;
//#define AREFdiv 100 // divide afterwards to get back to an INT
//#define batteryThresholdMilliVolts 3550

int blinkTime = 50;
long previousMillis = 0;
long interval = 60000;
boolean powerOff = false;

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
         Serial.print(i);
         Serial.println(dur);
         Serial.print(F("chkmem inside sleep:"));
         chkMem();
         Serial.print(F("chkBtn inside sleep:"));
       */
      if (chkBtn() ) break;
      rtcTest();
      brightEnough();
      //rtcTest set hours and minutes for us
      
//      if (((nowMinute % rtcPicPeriod) == 0) && ((rtcPicPeriod == 60 ) || (nowMinute != lastSnapMinute))) {
        if (((nowMinute % rtcPicPeriod) == 0) && ((unixMinute != lastSnapMinute))) {
        Serial.print(F("minute seems to indicate we should take a picture... min = "));
        Serial.println(nowMinute, DEC);
        Serial << ", unixMinute=" << unixMinute 
               << ", lastSnapMinute=" << lastSnapMinute << endl;
               
        lastSnapHour = nowHour;
        lastSnapMinute = unixMinute;

        break;
      }
      
      //winking
      digitalWrite(actLed,HIGH);  // let led blink
      delay(winkTime);
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
  
  if (rtcPicPeriod < minPicPeriod) rtcPicPeriod = minPicPeriod;
  if (rtcPicPeriod > periodRoundToMax) rtcPicPeriod = maxPicPeriod;  // so we dont get stuck on 0 or a number larger than 30 that will only occur once an hour
  

}

boolean leftOff = true;

void shoot() {
  if (okToShoot) {
    if (leftOff) {
      //unfloat the switches to avoid power leak
      pinMode(powerSw, OUTPUT);
      pinMode(focusSw, OUTPUT);
      pinMode(shutterSw, OUTPUT);
      digitalWrite(powerSw, LOW);
      digitalWrite(focusSw, HIGH);
      digitalWrite(shutterSw, HIGH);
      
      Serial.println(F("s001:pwr bus"));
      digitalWrite(RED, HIGH);
      digitalWrite(camRegulator, LOW);  //(EN pin on regulator goes low to turn on)
      Serial.println(F("s001:pwr bus... wait"));
      delay(warmupTime);
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
      delay(powerDownHoldTime);
      Serial.println(F("s007b:camRegulatorOff"));
      digitalWrite(camRegulator, HIGH);  //(EN pin on regulator goes high to turn OFF)
      digitalWrite(RED, LOW);

      //float the switches to avoid power leak
      pinMode(powerSw, INPUT);
      pinMode(focusSw, INPUT);
      pinMode(shutterSw, INPUT);
      digitalWrite(powerSw, LOW);
      digitalWrite(focusSw, LOW);
      digitalWrite(shutterSw, LOW);
    
      leftOff = true;
    } else {
      Serial.println(F("s008:fast,NOTcamOff"));
      leftOff = false;
    }
  } else {
     Serial.println(F("s009=noshot"));
  }  

  lastSnapMinute = unixMinute;
  Serial.println(F("s010:done!"));    

}

boolean batteryOk(int threshold) {

  /*    
      (277 * 3311 / 1024 ) * 4.33
      3878.1701

      (3878.1701 / 4.33) * 1024 / 3311
      276.9999

  */
  unsigned int bvRaw=analogRead(battSensePin);
  delay(2);
  bvRaw=analogRead(battSensePin);  // twice since first from ADC after wakeup is often noisy per datasheet
  //Serial << "bvRaw=" << bvRaw << endl;
  /* voltage in mV = raw reading * reference voltage / range * divider ratio */
  batteryMilliVolts = long(bvRaw) * AREFmult;
  batteryMilliVolts = batteryMilliVolts / AREFdiv;
  
  batteryVolts = float(bvRaw) * AREFvolts * AREFscaler / 1024;
  
  //Serial << ", batteryMv=" << batteryMilliVolts;
  //Serial << ", batteryVolts=" << batteryVolts << endl;
  
  /*Serial << ", batteryV=" << (batteryMilliVolts/1000) << "." 
         << ((batteryMilliVolts % 1000) / 100) 
         << ((batteryMilliVolts % 100) / 10) 
         << (batteryMilliVolts % 10) << endl; */

  if (batteryMilliVolts >= threshold) {
    // battery above threshold, OK
    return(true);
  } else {
    // battery below threshold, not OK
    return(false);
  }
  
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
      //} else {
      //  Serial.print(F("bright: no change "));
    }
  }

  //Serial.println(photoLevel);

  return(okToShoot);
  
}




boolean chkBtn () {
  if ( ! digitalRead(btnPin)) {
    Serial.println(F("btn pushed!?!"));
    digitalWrite(RED, LOW);
    digitalWrite(GREEN, LOW);
    digitalWrite(BLUE, LOW);

    // read a new value for interval from attached pot:
    Serial.print(F("chkBtn: interval was minutes divisible by: "));
    Serial.println(rtcPicPeriod);
    
    int val = analogRead(periodPot);
    
    /* so we take pot reading 0-1024, and map it into a 
       multiplier of the increment we want.
       For instance, if periodIncrement = 15 minutes, 60/15 = 4, 
       so map 1 to 4, then multiply by 15 to get to a number of 15 
       minute increments... grok?
      */
    rtcPicPeriod = (map(val, 0, 1023, 1, (60/periodIncrement))) * periodIncrement;

    // if there is some kinda malfunction, dont want to wind up with zero or something
    if (rtcPicPeriod < minPicPeriod) rtcPicPeriod = minPicPeriod;

    // we dont want to get stuck with say, 32 minute which will only happen
    // once per hour, so if we are over periodRoundToMax, we round up to max so it
    // makes more sense.
    // this also takes care of accidental very large values
    if (rtcPicPeriod > periodRoundToMax) rtcPicPeriod = maxPicPeriod;
        
    Serial.print(F("chkBtn: interval now set to minutes that are divisible by: "));
    Serial.println(rtcPicPeriod);

    //shoot();
    return(true);
    
  } else {
    //Serial.println(".");
    delay(blinkTime);
    return(false);
  }
    
}


/* END nikon L11 cam control stuff
*****************************************/


/* RTC stuff */
void rtcSetup() {
    Wire.begin();
    RTC.begin();
    // use RTC_setter_prog once instead of doing it in here where its easy to run again accidentally
}


void rtcTest () {
    //chkMem();
    DateTime now = RTC.now();
 
    nowHour = int(now.hour());
    nowMinute = int(now.minute());
    unixMinute = now.unixtime() / 60L;
 
    rtcString.begin();    
    rtcString << now.year();

    if (now.month() < 10 ) {
      rtcString << "0" << int(now.month());
    } else {
      rtcString << int(now.month());
    }
    
    if (now.day() < 10 ) {
      rtcString << "0" << int(now.day()) << '-'; 
    } else {
      rtcString << int(now.day()) << '-'; 
    }
    
    if (now.hour() < 10 ) {
      rtcString << "0" << int(now.hour()) << ':'; 
    } else {
      rtcString << int(now.hour()) << ':'; 
    }
    
    if (now.minute() < 10 ) {
      rtcString << "0" << int(now.minute()) << ':' ;
    } else {
      rtcString << int(now.minute()) << ':'; 
    }
    
    if (now.second() < 10 ) {
      rtcString << "0" << int(now.second());
    } else {
      rtcString << int(now.second());
    }
    
    rtcBuffer[rtcString.length()+1] = 0; // terminate it


//    Serial.print(F(" unix= "));
//    Serial.println(now.unixtime());
    
}




/*************** ds2450 compass */

#include <OneWire.h>
#include <DS2450.h>
OneWire oneWire(8);

DeviceAddress COMPASS = { 0x20, 0x48, 0xC6, 0x0, 0x0, 0x0, 0x0, 0x85 };
//20 48 C6 0 0 0 0 85
int vrange = 1;        // 0 = 2.56v, 1 = 5.12v
int rez = 2;           // rez = 0-f bits where 0 = 16
bool parasite = 0;     // parasite power?
float vdiv = 0.5;      // voltage divider circuit value?



ds2450 my2450(&oneWire, COMPASS, vrange, rez, parasite, vdiv);

void compassSetup(void) {
  my2450.begin();
}

int8_t compass = -2;
char compassChars[8];
PString compassString(compassChars, sizeof(compassChars));


void grabCompass(void) {
  my2450.measure();
  //Serial.print("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");
/*
    with 2-bits precision, shift right 14 bits, 2=L, 3=H 0=M
    
    chA = 3     chB = 3     chC = 0     chD = 3        N
    chA = 3     chB = 0     chC = 0     chD = 3        NNE
    chA = 3     chB = 0     chC = 3     chD = 3        NE
    chA = 0     chB = 0     chC = 3     chD = 3        ENE
    chA = 0     chB = 3     chC = 3     chD = 3        E
    chA = 0     chB = 3     chC = 3     chD = 2        ESE
    chA = 3     chB = 3     chC = 3     chD = 2        SE
    chA = 3     chB = 3     chC = 2     chD = 2        SSE
    chA = 3     chB = 3     chC = 2     chD = 3        S
    chA = 3     chB = 2     chC = 2     chD = 3        SSW
    chA = 3     chB = 2     chC = 3     chD = 3        SW
    chA = 2     chB = 2     chC = 3     chD = 3        WSW
    chA = 2     chB = 3     chC = 3     chD = 3        W
    chA = 2     chB = 3     chC = 3     chD = 0        WNW
    chA = 3     chB = 3     chC = 0     chD = 0        NW
    chA = 3     chB = 3     chC = 0     chD = 3        NNW
    
*/
//  works at 4 bits rez
  unsigned int a = (((unsigned int)my2450.voltChA()) >> 8);
  unsigned int b = (((unsigned int)my2450.voltChB()) >> 10);
  unsigned int c = (((unsigned int)my2450.voltChC()) >> 12);
  unsigned int d = (((unsigned int)my2450.voltChD()) >> 14);
  unsigned int u=(a+b+c+d);

  compassString.begin();      
  switch (u) {
    case 243:
      compassString << "N";
      compass=0;
      break;
    case 195:
      compassString << "NNE";
      compass=1;
      break;
    case 207:
      compassString << "NE";
      compass=2;
      break;
    case 15:
      compassString << "ENE";
      compass=3;
      break;
    case 63:
      compassString << "E";
      compass=4;
      break;
    case 62:
      compassString << "ESE";
      compass=5;
      break;
    case 254:
      compassString << "SE";
      compass=6;
      break;
    case 250:
      compassString << "SSE";
      compass=7;
      break;
    case 251:
      compassString << "S";
      compass=8;
      break;
    case 235:
      compassString << "SSW";
      compass=9;
      break;
    case 239:
      compassString << "SW";
      compass=10;
      break;
    case 175:
      compassString << "WSW";
      compass=11;
      break;
    case 191:
      compassString << "W";
      compass=12;
      break;
    case 188:
      compassString << "WNW";
      compass=13;
      break;
    case 252:
      compassString << "NW";
      compass=14;
      break;
    case 240:
      compassString << "NNW";
      compass=15;
      break;
    case 51:
      compassString << "N";
      compass=0;
      break;
    case 1950:
      compassString << "NNE";
      compass=1;
      break;
    case 2070:
      compassString << "NE";
      compass=2;
      break;
    case 1500:
      compassString << "ENE";
      compass=3;
      break;
    case 630:
      compassString << "E";
      compass=4;
      break;
    case 620:
      compassString << "ESE";
      compass=5;
      break;
    case 14:
      compassString << "SE";
      compass=6;
      break;
    case 10:
      compassString << "SSE";
      compass=7;
      break;
    case 11:
      compassString << "S";
      compass=8;
      break;
    case 43:
      compassString << "SSW";
      compass=9;
      break;
    case 47:
      compassString << "SW";
      compass=10;
      break;
    case 1750:
      compassString << "WSW";
      compass=11;
      break;
    case 143:
      compassString << "W";
      compass=12;
      break;
    case 1880:
      compassString << "WNW";
      compass=13;
      break;
    case 60:
      compassString << "NW";
      compass=14;
      break;
    case 510:
      compassString << "NNW";
      compass=15;
      break;

    default:
      compassString << (u, DEC);
      compass=-1;
      //Serial << "!u=" << u << endl;
      break;
  }

  //Serial << " Compass direction = " << compass << ", ";  
  //Serial.print(compassString);

/*
  Serial.print("chA = ");
  Serial.print(((unsigned int)my2450.voltChA()) >> 14);
  Serial.print("     chB = ");
  Serial.print(((unsigned int)my2450.voltChB()) >> 14);
  Serial.print("     chC = ");
  Serial.print(((unsigned int)my2450.voltChC()) >> 14);
  Serial.print("     chD = ");
  Serial.print(((unsigned int)my2450.voltChD()) >> 14);
  Serial.print("        ");
  delay(100);

*/

}




/************ end ds2450 compass */

/* ********************************  begin anemometer   */
#include <DS2423.h>

DeviceAddress counter = { 0x1D, 0xE4, 0x7E, 0x01, 0x0, 0x0, 0x0, 0x76 };
//1D E4 7E 1 0 0 0 76

ds2423 myCounter(&oneWire, counter);

/*
uint32_t a1 = 0;
uint32_t a2 = 0;
uint32_t b1 = 0;
uint32_t b2 = 0;
uint32_t diffA = 0;
uint32_t diffB = 0;
*/

signed int a1 = 0;
signed int a2 = 0;
signed int b1 = 0;
signed int b2 = 0;
int diffA = 0;
int diffB = 0;
int secondsPerSample = 1;
//float cupRadius = 2.875; //radius of cup rotation in inches
float cupCirc = PI * (2 * 2.785); //circumference in inches
float feetPerRev = cupCirc / 12;
#define mile 5280

/*
void anemometerSetup()
{
  
  Serial.begin(57600);
  Serial.print("\ncupRadius=");
  Serial.println(cupRadius, DEC);
  Serial.print("cupCirc=");
  Serial.println(cupCirc,DEC);
  Serial.print("feetPerRev=");
  Serial.println(feetPerRev,DEC);
  Serial.print("secondsPerSample=");
  Serial.println(secondsPerSample,DEC);
}
*/


void grabWindspeed(void)
{ 
  oneWire.reset();
  a1 = 255;
  a2 = 255;
  short tries=0;
  while ((tries <= 10) && ((a1 >250) || (a2 > 250))) {
    Serial << "windspeed tr=" << tries << " " ;
    a1=(signed int)myCounter.readCounter(1);
    //b1=(unsigned int)myCounter.readCounter(2);
    delay(secondsPerSample * 1000);
    //delay(10);
    a2=(signed int)myCounter.readCounter(1);
    //b2=(unsigned int)myCounter.readCounter(2);
    tries ++;
  }

  diffA = abs(a2-a1);
  //diffB = abs(b2-b1);
  
  /* A and B each get one count per RPM, 
         therefore divide by two,
         multiply by 60 seconds in a minute,
         then divide by numer of seconds we sample
  */
  //float rpm = float((diffA + diffB) /2) * 60 / secondsPerSample;
  float rpm = (float(diffA) /2) * 60 / secondsPerSample;
  float mph = rpm * feetPerRev * 60 / mile;
  
  //Serial.print("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");  
  Serial.print("a1=");
  Serial.print(a1,DEC);
  Serial.print(",a2=");
  Serial.print(a2,DEC);
  //Serial.print(",b1=");
  //Serial.print(b1,DEC);
  //Serial.print(",b2=");
  //Serial.print(b2,DEC);
  Serial.print("  A=");
  Serial.print(diffA);
  //Serial.print(", B=");
  //Serial.print(diffB);
  /*
  */
  Serial.print(", rpm=");
  Serial.print(rpm);
  Serial.print(", mph=");
  Serial.println(mph);  
  //Serial.println("             ");
  //delay(secondsPerSample * 1000);
  //delay(100);
}

/* end anemometer */

/********************************* begin lib based temp ****/
/*
#include <DallasTemperature.h>

// Data wire is plugged into port 2 on the Arduino
#define ONE_WIRE_BUS 8
#define TEMPERATURE_PRECISION 9

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

int numberOfDevices; // Number of temperature devices found

DeviceAddress tempDeviceAddress; // We'll use this variable to store a found device address

void sensorSetup()
{

  // Start up the library
  sensors.begin();
  
  // Grab a count of devices on the wire
  numberOfDevices = sensors.getDeviceCount();
  
  // locate devices on the bus
  Serial.print("Locating devices...");
  
  Serial.print("Found ");
  Serial.print(numberOfDevices, DEC);
  Serial.println(" devices.");

  // report parasite power requirements
  Serial.print("Parasite power is: "); 
  if (sensors.isParasitePowerMode()) Serial.println("ON");
  else Serial.println("OFF");
  
  // Loop through each device, print out address
  for(int i=0;i<numberOfDevices; i++)
  {
    // Search the wire for address
    if(sensors.getAddress(tempDeviceAddress, i))
	{
		Serial.print("Found device ");
		Serial.print(i, DEC);
		Serial.print(" with address: ");
		printAddress(tempDeviceAddress);
		Serial.println();
		
		Serial.print("Setting resolution to ");
		Serial.println(TEMPERATURE_PRECISION,DEC);
		
		// set the resolution to 9 bit (Each Dallas/Maxim device is capable of several different resolutions)
		sensors.setResolution(tempDeviceAddress, TEMPERATURE_PRECISION);
		
		 Serial.print("Resolution actually set to: ");
		Serial.print(sensors.getResolution(tempDeviceAddress), DEC); 
		Serial.println();
	}else{
		Serial.print("Found ghost device at ");
		Serial.print(i, DEC);
		Serial.print(" but could not detect address. Check power and cabling");
	}
  }

}

// function to print the temperature for a device
void printTemperature(DeviceAddress deviceAddress)
{
  // method 1 - slower
  //Serial.print("Temp C: ");
  //Serial.print(sensors.getTempC(deviceAddress));
  //Serial.print(" Temp F: ");
  //Serial.print(sensors.getTempF(deviceAddress)); // Makes a second call to getTempC and then converts to Fahrenheit

  // method 2 - faster
  float tempC = sensors.getTempC(deviceAddress);
  Serial.print(":");
  Serial.print(tempC);
  Serial.print("C, ");
  Serial.print(DallasTemperature::toFahrenheit(tempC)); // Converts tempC to Fahrenheit
  Serial.print("F   ");
}

void grabTemp(void)
{ 
  // call sensors.requestTemperatures() to issue a global temperature 
  // request to all devices on the bus
  //Serial.print("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");
  //Serial.print("Requesting temperatures...");
  sensors.requestTemperatures(); // Send the command to get temperatures
  
  
  // Loop through each device, print out temperature data
  for(int i=0;i<numberOfDevices; i++)
  {
    // Search the wire for address
    if(sensors.getAddress(tempDeviceAddress, i))
	{
		// Output the device ID
		Serial.print("  T");
		Serial.print(i,DEC);
		
		// It responds almost immediately. Let's print out the data
		printTemperature(tempDeviceAddress); // Use a simple function to print out the data
	} 
	//else ghost device! Check your power requirements and cabling
	
  }
}

// function to print a device address
void printAddress(DeviceAddress deviceAddress)
{
  for (uint8_t i = 0; i < 8; i++)
  {
    if (deviceAddress[i] < 16) Serial.print("0");
    Serial.print(deviceAddress[i], HEX);
  }
}

*/

/* end temp library based bits */


/**********************************
   DS18S20 Temperature chip i/o */
   

int qsensors, HighByte, LowByte, TReading, SignBit, Tc_100, Whole, Fract, Tf_100, fWhole, fFract;

byte smac[8];
float floaty = -32.86;

float getDS18B20_Celsius() {
  floaty = floaty + 0.01;
  byte i;
  byte present = 0;
  byte data[12];
  byte addr[8];
  
  if ( !oneWire.search(addr)) {
    Serial.print(F("No more sensors\n"));
    oneWire.reset_search();
    delay(250);
    qsensors=0;
    return(-273.15);
  } else {
    qsensors++;
  }
  oneWire.search(addr);
  
  
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

  oneWire.reset();
  oneWire.select(addr);
  oneWire.write(0x44,1);         // start conversion, with parasite power on at the end
  delay(800);     // maybe 750ms is enough, maybe not
  // we might do a oneWire.depower() here, but the reset will take care of it.
  
  present = oneWire.reset();
  oneWire.select(addr);    
  oneWire.write(0xBE);         // Read Scratchpad

  //dbgSerial.print("P=");
  //dbgSerial.print(present,HEX);
  //dbgSerial.print(" ");
  for ( i = 0; i < 9; i++) {           // we need 9 bytes
    data[i] = oneWire.read();
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
  chkMem();
  setupWatchdog();
  Serial.println(F("camController init...."));
  pinMode(actLed, OUTPUT);

  pinMode(battSensePin, INPUT);
  analogReference(AREFSource);  
  
  camSetup();
  sdCardSetup();
  rtcSetup();
  compassSetup();
  //anemometerSetup();
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
  delay(500);
  chkMem();
  str.begin();
  //Serial.println(Serial.available(), DEC);
  char c;
  uint8_t sum;

  iterations++;
  ts = millis() / 1000;
  
  float temp = getDS18B20_Fahrenheit();
  //Serial << F("floaty fahrenheit reading is ") << temp << F("F") << endl;

  //grabCompass();
  //grabWindspeed();

  //chkMem();
  if (temp < -273 ) {
    Serial.println(F("poop, horked"));
    digitalWrite(actLed, LOW); 
  }
  
  rtcTest();

  boolean lightOk = brightEnough();
  boolean battOk = batteryOk(batteryThresholdMilliVolts);
  short lightOkPrintable = 0;
  short battOkPrintable = 0;
  if (lightOk) lightOkPrintable=1;
  if (battOk) battOkPrintable=1;

  str << rtcString << " picMins=" << rtcPicPeriod
     << ", batt=";
  str.print(batteryVolts,2); // doesnt work with << operator
  str << "V, i=" << iterations 
     << ", t=" << temp
     << ", windDir=" << compassString
     << ", sun=" << photoLevel
     << ", lightOk=" << lightOkPrintable
     << ", battOk=" << battOkPrintable;
     
  if (lightOk && battOk) {
    str << F(", light and battery OK, shooting\n");
    Serial.print(str);
    shoot(); 
  } else {
    if (!lightOk && battOk) {
      str << F(", too dark\n");
    } else {
      if (lightOk && !battOk) {
        str << F(", battery too low\n");
      } else {
        str << F(", too dark, and battery too low?");
        if (!lightOk && !battOk) {
          str << "correct\n";
        } else {
          str << "YIKES! how did we get here?\n";
        }
                
      }
    }
    Serial.print(str);    
    
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

  
  
  sleepWithBeacon(30000);  //(60 = 86 seconds between shots)
  Serial.print(F("loop done "));
  Serial.println(iterations);
}


/* EOF */
