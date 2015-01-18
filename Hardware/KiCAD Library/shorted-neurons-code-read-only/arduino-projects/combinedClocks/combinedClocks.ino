#define TARGET_35BITCLOCK
//#define DEBUG_DMESG_TO_SERIAL
//#define MEMDEBUG 1

#include <stdio.h>
#include "RotaryEncoder.h"
#include <Streaming.h>
#include <PString.h>

// Flash has to come after Streaming because of conflicting definition of endl
#include <Flash.h>



/* EEPROM serialization stuff... really want to move this to a library */

#include <EEPROM.h>
#include "EEPROMAnything.h"

struct config_t
{
  uint16_t eeprom_length;
  uint64_t eeprom_checksum;
  short bright[4];
  short blankHour;
  short blankMinute;
  short unblankHour;
  short unblankMinute;
  short displaysDuringBlanking;
  short secondsDuringBlanking;
  short alarmTune;
  short colonsType;
  short bitsMSB;
  short homeOffset;
  short awayOffset;
  short homeDaylight;
  short awayDaylight;
  short hoursTwelve;
  short leadingZeroes;
  short brightest;
  short dimmest;
  short bMonth;
  short bDay;
} config;

void commit_config()
{

  Serial.println("saving!");
  EEPROM_writeAnything(0, config);

}




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
 
 
#ifdef TARGET_FLOWERCLOCK
  LedControl LEDs=LedControl(8,9,10,3);
  LedControl debug=LedControl(15,16,17,1);
#define rtcInterruptPin 2
#define btn1 7
#define btn2 12 
#define debugDigits 0
#define rearLEDs 0
#define clockDigits 1
#define flowerLEDs 2
#define spkPin 6
#define h1pin 3
#define h2pin 5
#define h3pin 4
#define photoResistor A0
#define opLed 6
#define errLed 6
#define homeOffset 0
#define awayOffset -7
#define debugPower 10
#define digitsPower 15
#define shinerPower 0
#define flowerPower 0
#define rearPower 1

#endif

#ifdef TARGET_35BITCLOCK
  LedControl LEDs=LedControl(13,12,11,3);
  LedControl debug=LedControl(55,56,57,1);
#define rtcInterruptPin 2
#define btnPin 2
#define btn1 3
#define btn2 4
#define debugDigits 1
#define rearLEDs 1
#define clockDigits 2
#define flowerLEDs 0
#define spkPin 5
#define h1pin 6
#define h2pin 10
#define h3pin 9
#define photoResistor A0
#define opLed 7
#define errLed 8
#define homeOffset 0
#define awayOffset +7

#define debugPower 10
#define digitsPower 10
#define shinerPower 10
#define flowerPower 10
#define rearPower 10

#endif

RotaryEncoder knob(h1pin,h2pin,h3pin);

#define digitOnTime 0
#define waitForChips 2
#define dimTime 20
#define helloTime 250
#define oneSec 500
#define blank B00000000
#define colorInterval 10



#define rLed 6
#define gLed 6
#define bLed 6

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
  WHITE, YELLOW, WHITE, YELLOW, WHITE, YELLOW, WHITE, YELLOW,
  BLUE, RED, WHITE, BLUE, RED, WHITE, BLUE, RED,
  WHITE, RED, WHITE, RED, WHITE, RED, WHITE, RED,
  MAGENTA, WHITE, MAGENTA, WHITE, MAGENTA, WHITE, YELLOW, MAGENTA,
  BLUE, YELLOW, BLUE, YELLOW, BLUE, YELLOW, WHITE, BLUE,
  WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, 
  BLUE, GREEN, BLUE, GREEN, BLUE, GREEN, BLUE, GREEN, 
  RED, WHITE, BLUE, RED, WHITE, BLUE, RED, WHITE,
  YELLOW, MAGENTA, YELLOW, MAGENTA, YELLOW, MAGENTA, YELLOW, MAGENTA, 
  BLUE, RED, WHITE, BLUE, RED, WHITE, BLUE, OFF,
};

byte frontLEDs[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };
byte backLEDs[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };


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
  B00000001 //.
};

const int timer = 1000;           // The higher the number, the slower the timing.

int opLedState = LOW;
int colons = 0;

long previousMillis = 0;
volatile byte flowerState = 1;
volatile byte rearState = 1;
volatile byte shinerState = 1;

volatile boolean rtcInterrupt = false;



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
#define delaytime 1000

int lastRotary = 0;
int nowRotary = 0;
boolean h1last = 0;
int lastf = 0;




/************************************************
 startup and loop below
*/


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

  EEPROM_readAnything(0, config);
  dmesg(2);
  Serial.println(F("config read from EEPROM:"));
  Serial << F("config.bright[0] = ") << config.bright[0] << endl;
  Serial << F("config.bright[1] = ") << config.bright[1] << endl;
  Serial << F("config.bright[2] = ") << config.bright[2] << endl;
  Serial << F("config.homeDaylight = ") << config.homeDaylight << endl;
  Serial << F("config.awayDaylight = ") << config.awayDaylight << endl;

  
  // Set the brightness to a medium values
  debug.setIntensity(0,debugPower);
  
  LEDs.setIntensity(rearLEDs,rearPower);
  LEDs.setIntensity(clockDigits,digitsPower);
  LEDs.setIntensity(flowerLEDs,flowerPower);

  dmesg(3);
  rotarySetup();

  dmesg(4);
  rtcSetup(); 

  dmesg(5);
  setAlarms();  
  //rtcGrab(); 

  
  pinMode(rtcInterruptPin, INPUT);
  digitalWrite(rtcInterruptPin, HIGH); //turn on pullup
  pinMode(opLed, OUTPUT);
  pinMode(errLed, OUTPUT);
//  pinMode(rLed, OUTPUT);
//  pinMode(gLed, OUTPUT);
//  pinMode(bLed, OUTPUT);
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
  delay(waitForChips);
  LEDs.shutdown(0,false);
  LEDs.shutdown(1,false);
  LEDs.shutdown(2,false);
  single();
  setStartupColors();

  dmesg(8);
  RTTLsetup();

  dmesg(9);
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
        //Serial.print(F("RTC chip interrupt, needs service: "));
        Serial.print(F("RTC interrupt: "));
	serviceClock();
  } else {
        //Serial.print(".");
  	dmesg(10019);
  }

  dmesg(10020);
  x = checkRotary();
  if (x) {
    dmesg(10022);
    updatePretties(x);
  }

  dmesg(10040);
  //rtcGrab();  

  dmesg(10050);
  updateLEDs();

  dmesg(10060);
  updateBrightness();  

  dmesg(10070);
  //setAlarms();  
  //checkAlarms();  

  dmesg(10080);
  checkButtons();


  dmesg(10998);

}
