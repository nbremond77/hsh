//#include <stdio.h>
#define debug false
#define digitOnTime 2
#define dimTime 20
#define oneSec 300

const int btnPin = 2;
const int btnLed = 3;

int dim = 0;

const int firstSegPin = 6;
const int lastSegPin = 13;
int segPins[] = { 2,3,4,5,9,14,15};
int digPins[] = { 6,7,8};

const int firstDigPin = 6;
const int lastDigPin = 8;


// pin mappings to std seg numbers
const int segA = 2;
const int segB = 3;
const int segC = 4;
const int segD = 5;
const int segE = 9;
const int segF = A0;
const int segG = A1;
const int segPt = A2;
const int dig0 = 6;
const int dig1 = 7;
const int dig2 = 8;
short digits[] = { 11, 11, 11 };
//const int dig4 = 17;
//const int dig5 = 4;

/*
int map0[] = { 6, segA, segF, segE, segD, segC, segB };
int map1[] = { 2, segB, segC };
int map2[] = { 5, segA, segB, segG, segE, segD };
int map3[] = { 5, segA, segB, segG, segC, segD };
int map4[] = { 4, segF, segG, segB, segC };
int map5[] = { 5, segA, segF, segG, segC, segD };
int map6[] = { 6, segA, segF, segE, segD, segC, segG };
int map7[] = { 3, segA, segB, segC };
int map8[] = { 7, segB, segA, segF, segG, segC, segD, segE };
int map9[] = { 6, segA, segF, segG, segB, segC, segD };
int mapPt[] = { 1, segPt };
int mapDash[] = { 1, segG };
int mapDashPt[] = { 2, segG, segPt };
int mapErr[] = { 6, segPt, segA, segF, segG, segE, segD }; 
int mapBlank[] = { 0, 0 }; 
int mapSegA[] = { 1, segA };
int mapSegB[] = { 1, segB };
int mapSegC[] = { 1, segC };
int mapSegD[] = { 1, segD };
int mapSegE[] = { 1, segE };
int mapSegF[] = { 1, segF };
int mapSegG[] = { 1, segG };

*/

boolean map0[] = { 1,1,1,1,1,1,0 };
boolean map1[] = { 0,1,1,0,0,0,0 };
boolean map2[] = { 1,1,0,1,1,0,1 };
boolean map3[] = { 1,1,1,1,0,0,1 };
boolean map4[] = { 0,1,1,0,0,1,1 };
boolean map5[] = { 1,0,1,1,0,1,1 };
boolean map6[] = { 1,0,1,1,1,1,1 };
boolean map7[] = { 1,1,1,0,0,0,0 };
boolean map8[] = { 1,1,1,1,1,1,1 };
boolean map9[] = { 1,1,1,1,0,1,1 };
boolean mapPt[] = { 1, segPt };
boolean mapDash[] = { 0,0,0,0,0,0,1 };
boolean mapDashPt[] = { 0,0,0,0,0,0,1 };
boolean mapErr[] = { 1,0,0,1,1,1,1 }; 
boolean mapBlank[] = { 0,0,0,0,0,0,0 }; 
boolean mapSegA[] = { 1,0,0,0,0,0,0 };
boolean mapSegB[] = { 0,1,0,0,0,0,0 };
boolean mapSegC[] = { 0,0,1,0,0,0,0 };
boolean mapSegD[] = { 0,0,0,1,0,0,0 };
boolean mapSegE[] = { 0,0,0,0,1,0,0 };
boolean mapSegF[] = { 0,0,0,0,0,1,0 };
boolean mapSegG[] = { 0,0,0,0,0,0,1 };
boolean mapUpperE[] = { 1,0,0,1,1,1,1 }; 
boolean mapLowerR[] = { 0,0,0,0,1,0,1 }; 
boolean mapLowerO[] = { 0,0,1,1,1,0,1 }; 
boolean mapUpperL[] = { 0,0,0,1,1,1,0 }; 


long previousMillis = 0;
volatile long starttime = 94702;
int seconds = 50;
int minutes = 59;
int hours = 0;
int hrs1 = 0;
int hrs2 = 0;
int mins1 = 0;
int mins2 = 0;
int sec = 0;
int secs1 = 0;
int secs2 = 0;
int one = 10;
int two = 10;
int three = 10;
int four = 10;
int five = 10;
char ascii[6];

boolean errLast = false;

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


// battery related bits
long batteryMilliVolts = 0;
#define battSensePin A3      // *analog* battery woltage sense pin
//#define AREFSource EXTERNAL
#define AREFSource DEFAULT
//#define AREFmult 14 // 14 ~= 3311 / 1024 * 4.33;
#define AREFmv 3.300
#define AREFscaler 5.604
//#define AREFscaler 3.1521 // (1/(1006000 / (1006000 + 2165000)))
//#define AREFmult 465 // 465 ~= 100 * 1100 / 1024 * 4.33;
//#define AREFmult 1269 // 1269 ~= 100 * 3000 / 1024 * 4.33;
//                               100 * V / 1024 * (1/R2 / R2 + R1)
#define AREFmult 3630 // 3630 ~= 100 * 3300 / 1024 * (1/(98000 / (98000 + 1006000)))
//#define AREFmult 3301 // 3301 ~= 100 * 3300 / 1024 * (1/(1006000 / (1006000 + 9300000)))
//#define AREFmult 1016 // 1016 ~= 100 * 3300 / 1024 * (1/(1006000 / (1006000 + 2165000)))

//220k / 1000k WORKS!!!  1806 100 260 80
#define AREFmult 1806 // 1806 ~= 100 * 3300 / 1024 * (1/(218500 / (218500 + 1006000)))
#define AREFdiv 100 // divide afterwards to get back to an INT
#define SAMPLEDROP 280 //diode drop in the middle of intended sample range
#define DROPFACTOR 80 // linear approximation of increase in drop over the voltage range
#define batteryThresholdMilliVolts 3550

#define BUFFSIZE 200
char buffer[BUFFSIZE];
PString str(buffer, sizeof(buffer));


// voltmeter stuff
void volts() { 
  unsigned int bvRaw=analogRead(battSensePin);
  delay(2);
  bvRaw=analogRead(battSensePin);  // twice since first from ADC after wakeup is often noisy per datasheet
  if (debug) Serial << "bvRaw=" << bvRaw << endl;
  /* voltage in mV = raw reading * reference voltage / range * divider ratio */
  
  batteryMilliVolts = long(bvRaw) * AREFmult;
  if (debug) Serial << ", battertMv=" << batteryMilliVolts;
  batteryMilliVolts = batteryMilliVolts / AREFdiv;
  // now adjust for diode drop
  int diodeDrop = SAMPLEDROP + (batteryMilliVolts / DROPFACTOR);
  if (debug) Serial << ", diodeDrop=" << diodeDrop;

  batteryMilliVolts += diodeDrop;
  if (batteryMilliVolts < 300) batteryMilliVolts = 0;
  
  if (debug) Serial << ", battertMv=" << batteryMilliVolts;
  //Serial << ", batteryV=" << (batteryMilliVolts/1000) << "." << ((batteryMilliVolts % 1000) /10) << endl; 

  if (batteryMilliVolts < 16500) {
    digits[0] = batteryMilliVolts/10000;
    digits[1] = (batteryMilliVolts % 10000) / 1000;
    digits[2] = (batteryMilliVolts % 1000) / 100;
    if (digits[0] == 0) digits[0] = ' ';
  } else {
    if ( errLast ) {
      digits[0] = ' ';
      digits[1] = 'o';
      digits[2] = 'L';
    } else {
      digits[0] = 'E';
      digits[1] = 'r';
      digits[2] = 'r';
    }
    errLast = !errLast;
    
  }
  
  
  
  //if (debug)   
    Serial << ", batteryV=" << char(digits[0])
         << digits[1]
         << "." 
         << digits[2]
         << endl;
         //<< (batteryMilliVolts % 10) << endl; 

/*
  float floatyV = bvRaw;
  floatyV = floatyV * AREFmv * AREFscaler / 1024;
  // now adjust for diode drop
  floatyV = floatyV + (SAMPLEDROP/1000) + (floatyV / DROPFACTOR/1000);
  str.begin();
  str << ", inaccurate:batteryVfloaty=";
  str.print(floatyV,1);
  //str << "BUT...";
  //str << (floatyV,2) ;
  //str << "   doesnt work.";
  str << endl;
  Serial.print(str);
*/

}





void blankDig(int d) {
  for (int s = 0; s <= 7; s++) { 
    digitalWrite(segPins[s], HIGH);
  }
}


void doNum(int digit, boolean *map) {
  //blankDig(digit);
  //Serial.print("    doNum trying to display a map, elements=");
  //Serial.println(map[0]);
  //Serial.print("    doNum displaying map on digit position ");
  //Serial.println(digit);

  
  // send ANODE high to allow current flow through the digit
// FIXME need define or IF here for "handwriting" mode, then:
  //digitalWrite(digit, HIGH);
  
  for (int n = 0; n < 7; n++) {
    //if (map[n] != 0) {
      digitalWrite(segPins[n], !map[n]);
      // uncomment delay for operation demo
      //delay(digitOnTime);
    //}
  }
  // send cathode low allow current flow through the digit
  digitalWrite(digit, HIGH);
   
  // wait for human eyes
  delay(digitOnTime);
  
  // turn the cathode back HIGH to blank the digit
  digitalWrite(digit, LOW);
}

void intToMapToOutput(int digitPin, int n) {

    // FIXME - this case table is in ascii... dumb!
    switch (n) {
        case 0:
          doNum(digitPin, map0);
          break;
        case 1:
          doNum(digitPin, map1);
          break;
        case 2:
          doNum(digitPin, map2);
          break;
        case 3:
          doNum(digitPin, map3);
          break;
        case 4:
          doNum(digitPin, map4);
          break;
        case 5:
          doNum(digitPin, map5);
          break;
        case 6:
          doNum(digitPin, map6);
          break;
        case 7:
          doNum(digitPin, map7);
          break;
        case 8:
          doNum(digitPin, map8);
          break;
        case 9:
          doNum(digitPin, map9);
          break;
        case 10:
          doNum(digitPin, mapPt);
          break;
        case 11:
          doNum(digitPin, mapDash);
          break;
        case 12:
          doNum(digitPin, mapDashPt);
          break;
        case 32:
          doNum(digitPin, mapBlank);
          break;
        case 48:
          doNum(digitPin, map0);
          break;
        case 49:
          doNum(digitPin, map1);
          break;
        case 50:
          doNum(digitPin, map2);
          break;
        case 51:
          doNum(digitPin, map3);
          break;
        case 52:
          doNum(digitPin, map4);
          break;
        case 53:
          doNum(digitPin, map5);
          break;
        case 54:
          doNum(digitPin, map6);
          break;
        case 55:
          doNum(digitPin, map7);
          break;
        case 56:
          doNum(digitPin, map8);
          break;
        case 57:
          doNum(digitPin, map9);
          break;
        case 69: // E
          doNum(digitPin, mapUpperE);
          break;
        case 76:
          doNum(digitPin, mapUpperL);
          break;
        case 111:
          doNum(digitPin, mapLowerO);
          break;
        case 114: // r
          doNum(digitPin, mapLowerR);          
          break;


        case 255:
          doNum(digitPin, mapBlank);
          break;
        case 241:
          doNum(digitPin, mapSegA);
          break;
        case 242:
          doNum(digitPin, mapSegB);
          break;
        case 243:
          doNum(digitPin, mapSegC);
          break;
        case 244:
          doNum(digitPin, mapSegD);
          break;
        case 245:
          doNum(digitPin, mapSegE);
          break;
        case 246:
          doNum(digitPin, mapSegF);
          break;
        case 247:
          doNum(digitPin, mapSegG);
          break;
        default:
          doNum(digitPin, mapErr);
          break;          
   
    } // end of switch
}



//begin RTC stuff
#include "Wire.h"
#define DS1307_I2C_ADDRESS 0x68

// Convert normal decimal numbers to binary coded decimal
byte decToBcd(byte val)
{
  return ( (val/10*16) + (val%10) );
}

// Convert binary coded decimal to normal decimal numbers
byte bcdToDec(byte val)
{
  return ( (val/16*10) + (val%16) );
}

// Stops the DS1307, but it has the side effect of setting seconds to 0
// Probably only want to use this for testing
/*void stopDs1307()
{
  Wire.beginTransmission(DS1307_I2C_ADDRESS);
  Wire.send(0);
  Wire.send(0x80);
  Wire.endTransmission();
}*/

// 1) Sets the date and time on the ds1307
// 2) Starts the clock
// 3) Sets hour mode to 24 hour clock
// Assumes you're passing in valid numbers
void setDateDs1307(byte second,        // 0-59
                   byte minute,        // 0-59
                   byte hour,          // 1-23
                   byte dayOfWeek,     // 1-7
                   byte dayOfMonth,    // 1-28/29/30/31
                   byte month,         // 1-12
                   byte year)          // 0-99
{
   Wire.beginTransmission(DS1307_I2C_ADDRESS);
   Wire.send(0);
   Wire.send(decToBcd(second));    // 0 to bit 7 starts the clock
   Wire.send(decToBcd(minute));
   Wire.send(decToBcd(hour));      // If you want 12 hour am/pm you need to set
                                   // bit 6 (also need to change readDateDs1307)
   Wire.send(decToBcd(dayOfWeek));
   Wire.send(decToBcd(dayOfMonth));
   Wire.send(decToBcd(month));
   Wire.send(decToBcd(year));
   Wire.endTransmission();
}

// Gets the date and time from the ds1307
void getDateDs1307(byte *second,
          byte *minute,
          byte *hour,
          byte *dayOfWeek,
          byte *dayOfMonth,
          byte *month,
          byte *year)

{

  // Reset the register pointer
  Wire.beginTransmission(DS1307_I2C_ADDRESS);
  Wire.send(0);
  Wire.endTransmission();

  Wire.requestFrom(DS1307_I2C_ADDRESS, 7);

  // A few of these need masks because certain bits are control bits
  *second     = bcdToDec(Wire.receive() & 0x7f);
  *minute     = bcdToDec(Wire.receive());
  *hour       = bcdToDec(Wire.receive() & 0x3f);  // Need to change this if 12 hour am/pm
  *dayOfWeek  = bcdToDec(Wire.receive());
  *dayOfMonth = bcdToDec(Wire.receive());
  *month      = bcdToDec(Wire.receive());
  *year       = bcdToDec(Wire.receive());

}

//end RTC stuff










void setup() {
  Serial.begin(115200);
  
  pinMode(btnPin, INPUT);
  //attachInterrupt(0, upCount, RISING);
  pinMode(btnLed, OUTPUT);

 
  // initialize each pin as an output:
  for (int t = 0; t <= 7; t++)  {
    pinMode(segPins[t], OUTPUT);      
  }
  for (int t = 0; t <= 2; t++)  {
    pinMode(digPins[t], OUTPUT);
    digitalWrite(digPins[t], LOW);  //start anodes LOW (blank digits)
  }

  
  byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
  
  Wire.begin();
  
  //ds1307 RTC setup bits.
  // Change these values to what you want to set your clock to.
  // You probably only want to set your clock once and then remove
  // the setDateDs1307 call.
  second = 30;
  minute = 23;
  hour = 23;
  dayOfWeek = 7;
  dayOfMonth = 27;
  month = 2;
  year = 10;
  //setDateDs1307(second, minute, hour, dayOfWeek, dayOfMonth, month, year);
  
  pinMode(battSensePin, INPUT);
  analogReference(AREFSource);  
  
}

//void upCount() {
//  starttime++; 
//}
byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;

long now = 0;
int errs = 0;

void loop() {
  
  now = millis();  
  if (now - previousMillis > oneSec) {
    // save the last we updated tenths
    previousMillis = now;
    seconds++;
    
    volts();

    if (seconds >= 60) {
      seconds = 0;
      minutes++;
      if (minutes >= 60) {
        minutes = 0;
        hours++;
        if (hours >= 24) {
          hours = 0;
        }
      }
    }
    
/*    if (digitalRead(btnPin))  {
      // toggle dimmer flag
      if (dim ==1) {
          dim = 0;
      } else {
        dim = 1;
      }
    }
*/
  }
  //now = now/1000;

  //intToMapToOutput(dig1, ((now % 1000) /100));
  //Serial.println(((now % 1000) /100));
  //intToMapToOutput(dig2, ((now % 100) /10));
  //Serial.println(((now % 100) /10));
  //intToMapToOutput(dig3, (now % 10));
  //Serial.println((now % 10));

  intToMapToOutput(dig0, digits[0]);
  intToMapToOutput(dig1, digits[1]);
  intToMapToOutput(dig2, digits[2]);



}



