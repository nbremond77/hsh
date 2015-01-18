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
 pin  8 is connected to the DataIn 
 pin  9 is connected to the CLK 
 pin 10 is connected to LOAD 
 We have only a single MAX72XX.
 */
LedControl LEDs=LedControl(8,9,10,3);
LedControl debug=LedControl(15,16,17,1);




#define digitOnTime 0
#define dimTime 20
#define helloTime 250
#define oneSec 500
#define blank B00000000
#define homeOffset 0
#define awayOffset -7
#define colorInterval 10

#define opLed 6
#define errLed 6
#define rLed 6
#define gLed 6
#define bLed 6
#define btn1 7
#define btn2 12
#define debugDigits 0
#define rearLEDs 0
#define clockDigits 1
#define flowerLEDs 2

//loopy helpers
uint8_t i = 0;
uint8_t j = 0;
uint8_t x = 0;
byte colon1 = 0;
byte colon2 = 0;

// reminder colons attached to final bit of digit 1 and 5
// reminder apostrophes attached to final bit of digit 2 and 6
byte digMap[] = { 
  B11111100, //0
  B01100000, //1
  B11011010, //2
  B11110010, //3
  B01100110, //4
  B10110110, //5
  B00111110, //6
  B11100000, //7
  B11111110, //8
  B11100110, //9
  B00000000, // 
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001 //.
};

#define OFF 0
#define BLUE 1
#define GREEN 2
#define CYAN 3
#define RED 4
#define MAGENTA 5
#define YELLOW 6
#define WHITE 7



byte flowerMap[] = {
  WHITE, GREEN, WHITE, GREEN, WHITE, GREEN, GREEN, WHITE, 
  WHITE, BLUE, RED, WHITE, BLUE, RED, WHITE, OFF,
  BLUE, RED, WHITE, BLUE, RED, WHITE, BLUE, OFF,
  WHITE, RED, WHITE, RED, WHITE, RED, RED, OFF,
  MAGENTA, WHITE, MAGENTA, WHITE, MAGENTA, WHITE, YELLOW, OFF,
  BLUE, YELLOW, BLUE, YELLOW, BLUE, YELLOW, WHITE, OFF,
  WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, 
  BLUE, GREEN, BLUE, GREEN, BLUE, GREEN, BLUE, GREEN, 
  RED, WHITE, BLUE, RED, WHITE, BLUE, RED, OFF,
  BLUE, RED, WHITE, BLUE, RED, WHITE, BLUE, OFF,
  BLUE, RED, WHITE, BLUE, RED, WHITE, BLUE, OFF,
  BLUE, RED, WHITE, BLUE, RED, WHITE, BLUE, OFF,
  BLUE, RED, WHITE, BLUE, RED, WHITE, BLUE, OFF,
  BLUE, RED, WHITE, BLUE, RED, WHITE, BLUE, OFF,
};

byte frontLEDs[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };


byte charMap[] = {
  B11101110, //A
  B00111110, //b
  B00011010, //c
  B01111010, //d
  B10011110, //E
  B10001110, //F
  B10111100, //G
  B01101110, //H
  B00100000, //i
  B00000010, //j (none)
  B00000010, //k (none)
  B00011100, //L
  B00000010, //m (none)
  B00101010, //n
  B00111010, //o
  B11001110, //p
  B00000010, //q (none)
  B00001010, //r
  B10110110, //S (looks like five)
  B11100000, //T
  B00111000, //u
  B00000010, //v (none)
  B00000010, //w (none)
  B00000010, //x (none)
  B01001110, //y
  B00000010,  //z (none)
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001 //.
};

const int timer = 1000;           // The higher the number, the slower the timing.

int debugPower = 10;
int digitsPower = 15;
int shinerPower = 0;
int flowerPower = 0;
int rearPower = 1;

int opLedState = LOW;
int colons = 0;

long previousMillis = 0;
volatile long periodCount = 0;
volatile long nowCount = 0;
volatile byte flowerState = 1;
volatile byte rearState = 1;
volatile byte shinerState = 1;



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


boolean hoursTwelve = false;
boolean leadingZeroes = false;


/* we always wait a bit between updates of the display */
const int delaytime=2000;

int lastRotary = 0;
int nowRotary = 0;
boolean h1last = 0;
int lastf = 0;

#define h1pin 3
#define h2pin 5
#define h3pin 4
#define photoResistor A0


/************************************************
 startup and loop below
*/

#define waitForChips 2
void setup() {
  delay(waitForChips);
  // The MAX72XX is in power-saving mode on startup,
  // we have to do a wakeup call
  debug.shutdown(0,true);
  LEDs.shutdown(0,true);
  LEDs.shutdown(1,true);
  LEDs.shutdown(2,true);

#ifdef MEMDEBUG
  chkMem();
#endif

  delay(waitForChips);
  debug.clearDisplay(0);
  LEDs.clearDisplay(0);
  LEDs.clearDisplay(1);
  LEDs.clearDisplay(2);

  Serial.begin(57600);
  dmesg(1);
  
  // Set the brightness to a medium values
  debug.setIntensity(0,debugPower);
  LEDs.setIntensity(rearLEDs,rearPower);
  LEDs.setIntensity(clockDigits,digitsPower);
  LEDs.setIntensity(flowerLEDs,flowerPower);

  dmesg(2);
  rotarySetup();

  dmesg(3);
  rtcSetup(); 

  dmesg(4);
  //rtcGrab(); 

  dmesg(5);

  
  //attachInterrupt(0, upCount, RISING);
  pinMode(opLed, OUTPUT);
  pinMode(errLed, OUTPUT);
  pinMode(rLed, OUTPUT);
  pinMode(gLed, OUTPUT);
  pinMode(bLed, OUTPUT);
  dmesg(6);
  

  delay(waitForChips);

  debug.setRow(0,0,mapCharDpFirst("h"));
  debug.setRow(0,1,mapCharDpFirst("e"));
  debug.setRow(0,2,mapCharDpFirst("l"));
  debug.setRow(0,3,mapCharDpFirst("l"));
  debug.setRow(0,4,mapCharDpFirst("o"));

  debug.setRow(0,1,B01001111);
  debug.setRow(0,2,B00001110);
  debug.setRow(0,3,B00001110);
  debug.setRow(0,4,B00011101);

  debug.shutdown(0,false);
  delay(helloTime);
  x = checkRotary();
  dmesg(7);
  //LEDs.clearDisplay(1);
  dmesg(8);
  setStartupColors();
  delay(waitForChips);
  LEDs.shutdown(0,false);
  LEDs.shutdown(1,false);
  LEDs.shutdown(2,false);
  dmesg(9);

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
  x = checkRotary();
  if (x) {
    dmesg(10012);
    updatePretties(x);
  }

  dmesg(10040);
  rtcGrab();  

  dmesg(10060);
  updateBrightness();  

  dmesg(10998);
  delay(50);

}
