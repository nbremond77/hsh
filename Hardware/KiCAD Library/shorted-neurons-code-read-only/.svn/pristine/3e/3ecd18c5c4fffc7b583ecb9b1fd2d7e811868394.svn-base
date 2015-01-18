#define debug false

#include <stdio.h>
#include <Streaming.h>
#include <PString.h>

// Flash has to come after Streaming because of conflicting definition of endl
#include <Flash.h>

//LedControl stuff
#include "LedControl.h"
/*
 Now we need a LedControl to work with.
 ***** These pin numbers will probably not work with your hardware *****
 pin 11 is connected to the DataIn 
 pin 13 is connected to the CLK 
 pin  9 is connected to LOAD 
 We have only a single MAX7221.
 */
LedControl LEDs=LedControl(11,13,9,1);

#define digitOnTime 0
#define dimTime 20
#define helloTime 250
#define oneSec 500
#define blank B00000000
#define homeOffset 0
#define awayOffset -7
#define colorInterval 10

#define rtcInterruptPin 2
#define opLed 6
#define errLed 6
#define rLed 6
#define gLed 6
#define bLed 6
#define btn1 7
#define btn2 12
#define clockDigits 0

//loopy helpers
uint8_t i = 0;
uint8_t j = 0;
uint8_t x = 0;
byte colon1 = 0;
byte colon2 = 0;
byte decimalA = 0;
byte decimalB = 0;


boolean dvmError=true;

const int timer = 1000;           // The higher the number, the slower the timing.

int digitsPower = 15;

int opLedState = LOW;
int colons = 0;

long previousMillis = 0;
volatile long periodCount = 0;
volatile long nowCount = 0;

volatile boolean rtcInterrupt = false;



volatile long starttime = 94702;
int seconds = 50;
int minutes = 59;
int hours = 0;
int hrs1 = 0;
int hrs2 = 0;
int hrs3 = 0;
int hrs4 = 0;
int mins1 = 0;
int mins2 = 0;
int sec = 0;
int secs1 = 9;
int secs2 = 0;
int one = 10;
int two = 10;
int three = 10;
int four = 10;
int five = 10;
char ascii[6];
byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
int homeHour, awayHour;

byte digits[8] ;


boolean hoursTwelve = false;
boolean leadingZeroes = false;


/* we always wait a bit between updates of the display */
const int delaytime=1000;

int lastRotary = 0;
int nowRotary = 0;
boolean h1last = 0;
int lastf = 0;

#define h1pin 3
#define h2pin 5
#define h3pin 4
#define photoResistor A3


/************************************************
 startup and loop below
*/

#define waitForChips 2
#define MEMDEBUG 1
void setup() {
  delay(waitForChips);
  // The MAX72XX is in power-saving mode on startup,
  // we have to do a wakeup call
  LEDs.shutdown(0,true);

#ifdef MEMDEBUG
  chkMem();
#endif

  delay(waitForChips);
  LEDs.clearDisplay(0);

  Serial.begin(115200);
  dmesg(1);
  
  // Set the brightness to a medium values
  LEDs.setIntensity(clockDigits,digitsPower);

  dmesg(2);
  rotarySetup();

  dmesg(3);
  rtcSetup(); 

  dmesg(4);
  setAlarms();  
  //rtcGrab(); 

  
  pinMode(rtcInterruptPin, INPUT);
  digitalWrite(rtcInterruptPin, HIGH); //turn on pullup
  pinMode(opLed, OUTPUT);
  pinMode(errLed, OUTPUT);
  pinMode(rLed, OUTPUT);
  pinMode(gLed, OUTPUT);
  pinMode(bLed, OUTPUT);
  dmesg(5);
  

  delay(waitForChips);

  delay(helloTime);
  x = checkRotary();
  dmesg(6);
  //LEDs.clearDisplay(1);
  delay(waitForChips);
  LEDs.shutdown(0,false);
  single();

  dmesg(7);


  dmesg(8);
  serviceClock();


  dmesg(999);

#ifdef MEMDEBUG
  chkMem();
#endif

}


int sensorValue=0;
int lastSensorValue=0;
int brightness=0;
int lastBright=0;
int lowLight=40;
boolean colorShutoff=false;




void loop() { 
  dmesg(10000);
#ifdef MEMDEBUG
  dmesg(10005);
  chkMem();
#endif

  dmesg(10010);
  if (rtcInterrupt) {
  	dmesg(10015);
	serviceClock();
  } else {
        Serial.print(".");
  	dmesg(10019);
  }

  dmesg(10020);
  x = checkRotary();
  if (x) {
    dmesg(10022);
  }

  dmesg(10040);
  rtcGrab();  
  volts();

  dmesg(10050);
  updateLEDs();
delay(200);
  dmesg(10060);
  //updateBrightness();  

  dmesg(10070);
  //setAlarms();  
  //checkAlarms();  

  dmesg(10080);
  checkButtons();


  dmesg(10998);

}
