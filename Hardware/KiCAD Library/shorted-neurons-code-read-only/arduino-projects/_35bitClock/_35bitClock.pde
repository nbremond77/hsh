#include <stdio.h>
#include "RotaryEncoder.h"
#include "Wire.h"
#include "RTClib.h"

RTC_DS1307 RTC;

RotaryEncoder knob(6,10,9);

#include <Streaming.h>
#include <PString.h>
// Flash has to come after Streaming because of conflicting definition of endl
#include <Flash.h>
char buffer2[64];
PString rtcString(buffer2, sizeof(buffer2));
byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
boolean trashBool = false;

#define digitOnTime 0
#define dimTime 20
#define oneSec 500

#define btnPin 2
#define btn1 3
#define btn2 4

short currentMode = 0;

#define defaultMode 0
#define bright0Mode 1
#define bright1Mode 2
#define bright2Mode 3
#define lastMode 1
#define idleTimeout 30

const int opLed =  7;      // the number of the LED pin
const int errLed =  8;      // the number of the STOPLED pin

const int timer = 1000;           // The higher the number, the slower the timing.

int opLedState = LOW;
int colons = 0;

long previousMillis = 0;
uint64_t unixtime = 0;
volatile long periodCount = 0;
volatile long nowCount = 0;



volatile long starttime = 94702;
int seconds = 50;
int minutes = 59;
int hours = 0;
int hrs1 = 0;
int hrs2 = 0;
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
long dstOffset = 0;
DateTime now;



/* EEPROM serialization stuff... really want to move this to a library */
#include "serialization.h"
#include <EEPROM.h>


template <class T> int EEPROM_writeAnything(int ee, const T& value)
{
    const byte* p = (const byte*)(const void*)&value;
    int i;
    for (i = 0; i < sizeof(value); i++)
	  EEPROM.write(ee++, *p++);
    return i;
}

template <class T> int EEPROM_readAnything(int ee, T& value)
{
    byte* p = (byte*)(void*)&value;
    int i;
    for (i = 0; i < sizeof(value); i++)
	  *p++ = EEPROM.read(ee++);
    return i;
}
/* end EEPROM serialization stuff */




struct config_t
{
  short bright[3];
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
} config;


/* we always wait a bit between updates of the display */
unsigned long delaytime=1000;


//We always have to include the library
#include "LedControl.h"

/*
 Now we need a LedControl to work with.
 ***** These pin numbers will probably not work with your hardware *****
 pin 12 is connected to the DataIn 
 pin 11 is connected to the CLK 
 pin 10 is connected to LOAD 
 We have only a single MAX72XX.
 */
//LedControl ledbar=LedControl(13,12,11,1);
LedControl lc=LedControl(13,12,11,3);





void dec_bin(int number) {
 int x, y;
 x = y = 0;

 for(y = 7; y >= 0; y--) {
  x = number / (1 << y);
  number = number - x * (1 << y);
  Serial.print(x);
 }

 Serial.println("\n");

}



//begin RTC stuff
//#include "Wire.h"
//#include "RTClib.h"

//RTC_DS1307 RTC;

//#define DS3232_I2C_ADDRESS 0x68


void rtcSetup() {
    Wire.begin();
    RTC.begin();
    // use RTC_setter_prog once instead of doing it in here where its easy to run again accidentally
    //RTC.adjust(DateTime("Aug 17 2010", "20:33:00"));
}


void rtcGrab () {
    now = RTC.now(); // get time from the RTC chip
    rtcString.begin();
    
    unixtime = now.unixtime();
    now = unixtime + dstOffset;
    unixtime = now.unixtime(); // get unixtime back again so that it matches offsetted "now".
    
    second = now.second();
    minute = now.minute();
    hour = now.hour();
    dayOfWeek = now.dayOfWeek();
    dayOfMonth = now.day();
    month = now.month();
    year = now.year();

    // hours digiting
    if ( hour < 10 ) {
      hrs1 = 16 ;
    } else {
      hrs1 = round(hour/10);
    }  
    hrs2 = (hour % 10);
  
    // minutes digiting
    if ( minute < 10 ) {
      mins1 = 0;
    } else {
      mins1 = round(minute/10);
    }  
    mins2 = (minute % 10);
    
    // seconds digiting
    if ( second < 10 ) {
      secs1 = 0;
    } else {
      secs1 = round(second/10);
    }  
    secs2 = (second % 10);
    
}













void setup() {
  Serial.begin(57600);
  pinMode(btnPin, INPUT);
  pinMode(btn1, INPUT);
  pinMode(btn2, INPUT);
  digitalWrite(btn1, HIGH);
  digitalWrite(btn2, HIGH);
  
  //attachInterrupt(0, upCount, RISING);
  pinMode(opLed, OUTPUT);
  pinMode(errLed, OUTPUT);

  EEPROM_readAnything(0, config);

  Serial.println("config read from EEPROM:");
  Serial << "config.bright[0] = " << config.bright[0] << endl;
  Serial << "config.bright[1] = " << config.bright[1] << endl;
  Serial << "config.bright[2] = " << config.bright[2] << endl;
  
  digitalWrite(errLed, HIGH);

  for(int i = 0; i < 3; i++) {  
    if (config.bright[i] < 0) {
      // start up blank... very dim mode handled later by loop
      lc.shutdown(i, true);
    } else {
      // The MAX72XX is in power-saving mode on startup,
      // we have to do a wakeup call
      lc.shutdown(i,false);
      // Set the brightness to a medium values
      lc.setIntensity(i,config.bright[i]);
    }
  }
  // and clear the display
  lc.setRow(0,0, B11111111);
  lc.setRow(0,1, B11111111);
  lc.setRow(0,2, B11111111);
  lc.setRow(0,3, B11111111);  
  lc.setRow(0,4, B11111111);
  lc.setRow(0,5, B11111111);
  lc.setRow(0,6, B11111111);
  delay(200);
  lc.clearDisplay(0);
  lc.clearDisplay(1);
  lc.clearDisplay(2);

  rtcSetup(); 

}

void upCount() {
  periodCount++; 
  

}







#define DATEMODE 1
int tinyDispMode = 1;
int lastsecs = 0;

void updateDisplay() {
  byte shorty;
  if (tinyDispMode == DATEMODE ) {
    lc.setDigit(1,0,((month/10) % 10),false);
    lc.setDigit(1,1,(month % 10),false);
    lc.setChar(1,2,' ',true);
    lc.setDigit(1,3,((dayOfMonth/10) % 10),false);
    lc.setDigit(1,4,(dayOfMonth % 10),false);
    
  } else {
    
    lc.setDigit(1,0,((periodCount / 10000) % 10),false);
    lc.setDigit(1,1,((periodCount / 1000) % 10),false);
    lc.setDigit(1,2,((periodCount / 100) % 10),false);
    lc.setDigit(1,3,((periodCount / 10) % 10),false);
    lc.setDigit(1,4,(periodCount % 10),false);
  }
  
  lc.setDigit(2,0,hrs1,false);
  lc.setDigit(2,1,hrs2,false);
  lc.setDigit(2,2,mins1,false);
  lc.setDigit(2,3,mins2,false);
  lc.setDigit(2,4,secs1,false);  
  lc.setDigit(2,5,secs2,false);
  lc.setRow(0,5,B10101010);
  lc.setRow(0,6,B10101010);
  
  lc.setRow(0,4, byte(unixtime >> 32));
  lc.setRow(0,3, byte(unixtime >> 24));
  lc.setRow(0,2, byte(unixtime >> 16));  
  lc.setRow(0,1, byte(unixtime >> 8));
  lc.setRow(0,0, byte(unixtime));
  
  // update this so the next updateDisplayLazy will do what we expect
  lastsecs = second;

}


void updateDisplayLazy() {
  //FIXME - replace with interrupt driven update
  if ((second > lastsecs) || (second == 0 && lastsecs == 59)) {
    digitalWrite(opLed, HIGH);
    lastsecs = second;
    updateDisplay();
    digitalWrite(opLed, LOW);
  }
}

#define brightOffLevel -5

void adjustBright(int disp) {
  delay(100);
  trashBool = true;
  int i = 0;
  previousMillis=millis();
  int tempbright = config.bright[disp];
  int d=0;

  while(trashBool && (((millis() - previousMillis)/1000) < idleTimeout)) {
    i = knob.checkRotaryEncoder();
    if (i != 0) {
      previousMillis=millis(); //reset our timeout
      i += tempbright;
      if ( i > 15 ) i=15;
      if ( i < brightOffLevel ) i = brightOffLevel;
      tempbright = i;
      if ( i > -1) {
        Serial << "adjust disp" << disp << " to:" << i << endl;
        lc.shutdown(disp,false);
        //lc.setIntensity(disp,tempbright);
        lc.setIntensity(0,tempbright);
        lc.setIntensity(1,tempbright);
        lc.setIntensity(2,tempbright);
      } else {
        d=tempbright*tempbright;
        Serial << "disp in very dim mode, " << disp
          << " to:" << tempbright << ", delayms=" << d << endl;
      }
    }

    if (! digitalRead(btn2)) {
      delay(50); //debounce
      if (! digitalRead(btn2)) {
        //ok, its really down, exit
        trashBool=false;
        currentMode=defaultMode;
        Serial.println("exiting adjustBright due to btn2");
        //delay(200);
        updateDisplay();
        lc.setIntensity(disp,config.bright[disp]);
        return;
      }
    }

    if (! digitalRead(btn1)) {
      delay(50); //debounce
      if (! digitalRead(btn1)) {
        //ok, its really down, exit
        trashBool=false;
        currentMode++;
        Serial.println("exiting adjustBright due to btn1");
        delay(200);
        //config.bright[disp]=tempbright;
        config.bright[0]=tempbright;
        config.bright[1]=tempbright;
        config.bright[2]=tempbright;
        
        commit_config();
        updateDisplay();
        return;
      }
    }
    
    // special case if in very dim modes
    if ( tempbright < 0 ) {
      //lc.setIntensity(disp, 0);
      lc.setIntensity(0, 0);
      lc.setIntensity(1, 0);
      lc.setIntensity(2, 0);
      if ( tempbright == brightOffLevel ) {
        Serial << "disp down to Off level, disp=" << disp
          << " to: OFF" << endl;
        //lc.shutdown(disp, true);
        lc.shutdown(0, true);
        lc.shutdown(1, true);
        lc.shutdown(2, true);
      } else {
        //Serial << "disp in very dim mode, " << disp
        //  << " to:" << tempbright << ", delayms=" << d << endl;

        lc.shutdown(0, true);
        lc.shutdown(1, true);
        lc.shutdown(2, true);
        delay(d);
        lc.shutdown(0,false);
        lc.shutdown(1,false);
        lc.shutdown(2,false);
        delay(1);
        lc.shutdown(0, true);
        lc.shutdown(1, true);
        lc.shutdown(2, true);
        delay(d);
        lc.shutdown(0,false);
        lc.shutdown(1,false);
        lc.shutdown(2,false);
        delay(1);
        lc.shutdown(0, true);
        lc.shutdown(1, true);
        lc.shutdown(2, true); 
        delay(d);
        lc.shutdown(0,false);
        lc.shutdown(1,false);
        lc.shutdown(2,false);

      }
    }
  }
  
  //if we get here, that means we timed out
  currentMode=defaultMode;
  
}




void loop() { 
  digitalWrite(errLed, HIGH);
  if (currentMode > lastMode) currentMode = defaultMode; //reset on overflow

  if (currentMode != 0 ) Serial << "mode=" << currentMode << endl;
  switch (currentMode) {
    case bright0Mode:
      adjustBright(0);
      updateDisplay();      
      break;
    case bright1Mode:
      adjustBright(1);
      updateDisplay();
      break;
    case bright2Mode:
      adjustBright(2);
      updateDisplay();
      break;
    default:
      updateDisplayLazy();
      break;
  }

  if (! digitalRead(btn1)) {
    delay(20); //debounce
    if (! digitalRead(btn1)) {
      currentMode++;
    }
    if (currentMode > lastMode) currentMode = defaultMode; //reset on overflow
  }

  if (! digitalRead(btn2)) {
    delay(500); //debounce
    if (! digitalRead(btn2)) {
      
      if (dstOffset > 0) { 
        dstOffset = 0;
        Serial.println("dstOffset now 0");
      } else {
        dstOffset = 3600;
        Serial.println("dstOffset now 1 hour");
      }
    }
  }
 
  
  periodCount += knob.checkRotaryEncoder();
  digitalWrite(errLed, LOW); 
  rtcGrab();

}




void commit_config()
{

  Serial.println("saving!");
  EEPROM_writeAnything(0, config);

}






