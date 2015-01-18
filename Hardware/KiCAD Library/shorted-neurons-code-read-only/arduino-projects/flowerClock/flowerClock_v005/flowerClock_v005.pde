#include <stdio.h>
#include <PString.h>

//int digitOnTime = 1; // single digit time on in ms
//int digitOnTime = 256; // single digit time on in ms

#define digitOnTime 0
#define dimTime 20
#define oneSec 500

#define opLed 6
#define errLed 6
#define rLed 6
#define gLed 6
#define bLed 6
#define btn1 7
#define btn2 12

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
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001, //.
  B00000001 //.
};

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

int debugPower = 8;
int digitsPower = 15;
int shinerPower = 2;
int flowerPower = 15;
int rearPower = 0;

int opLedState = LOW;
int colons = 0;

long previousMillis = 0;
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




/* we always wait a bit between updates of the display */
const int delaytime=500;
















//LedControl stuff
#include "LedControl.h"

/*
 Now we need a LedControl to work with.
 ***** These pin numbers will probably not work with your hardware *****
 pin 10 is connected to the DataIn 
 pin  9 is connected to the CLK 
 pin  8 is connected to LOAD 
 We have only a single MAX72XX.
 */
 

LedControl LEDs=LedControl(8,9,10,3);
LedControl debug=LedControl(15,16,17,1);

void dec_bin(int number) {
 int x, y;
 x = y = 0;

 for (y = 7; y >= 0; y--) {
  x = number / (1 << y);
  number = number - x * (1 << y);
  Serial.print(x);
 }

 Serial.println("\n");

}




int lastRotary = 0;
int nowRotary = 0;
boolean h1last = 0;
int lastf = 0;

#define h1pin 3
#define h2pin 5
#define h3pin 4



int checkRotary() {
  
  boolean h1 = (digitalRead(h1pin));
  boolean h2 = (digitalRead(h2pin));
  boolean h3 = (digitalRead(h3pin));
  
  /* 
    so we have a rotary encoder^H^H^H^H^H^H^H^H^H^H cdrom-drive motor,
    with three Hall-effect sensors, which are hooked up to comparator
    gates.  What we wind up with is a truth table that can tell you
    whether we are moving or not, AND which direction, naturally 
    important for use as a human interface control.
    
    So each hall effect is boolean output of the comparator, and we put em
    all together into nowRotary.  Apparently its little-endian.
    h1    0   0   0   0   1   1   1   1
    h2    0   0   1   1   0   0   1   1
    h3    0   1   0   1   0   1   0   1
---------------------------------------
   now    0   1   2   3   4   5   6   7
   

with 
#define h1pin 2
#define h2pin 15
#define h3pin 16

001
101
100
110
010
011

#define h1pin 2
#define h2pin 16
#define h3pin 15
001
011
010
110
100
101

*/

  nowRotary = ((h3 << 2) | (h2 << 1) | h1);
//  Serial.print << "according to cminus, now = " << nowRotary << '\n';
//  Serial.print("according to cminus, now = ");
//  Serial.println(nowRotary);
  
//  nowRotary = (h3+(h2*2)+(h1*4));
//  Serial << "according to ball,   now = " << nowRotary << '\n';
//  Serial.print("according to ball,   now = ");
//  Serial.println(nowRotary);  
  int f = 0;
  
 if (nowRotary == lastRotary) {
   return(0);
 } else {
   
  //Serial.print("according to cminus,   now = ");
  //Serial.println(nowRotary);     
  if (nowRotary > lastRotary) f = 1;
  if (nowRotary < lastRotary) f = -1;
  lastRotary = nowRotary;
  
//  Serial.print("according to old way, f=");
//  Serial.println(f);
/* this doesnt work and i dont understand it
  f = 0;
  if (h1 != h1last) {       // clock pin has changed value... now we can do stuff
    h3 = h1^h2^h3;              // work out direction using an XOR
    if ( h3 ) {
      f=-1;            // non-zero is Anti-clockwise
    } else {
      f=1;            // zero is therefore anti-clockwise
    }
    h1last = h1;            // store current clock state for next pass
  } else {
    f = 0;
  }

  Serial.print ("Jog:: count:");
  Serial.println(f);
*/


/* works! but too fast:  
  switch (nowRotary) {
    case 0:
      f = 0;
      break;
    case 1:
      f = 1;
      break;
    case 5:
      f = 2;
      break;
    case 4:
      f = 3;
      break;
    case 6:
      f = 4;
      break;
    case 2:
      f = 5;
      break;
    case 3:
      f = 6;
      break;
    case 7:
      f = 7;
      break;
  } 
  */
  switch (nowRotary) {
    // cases are in the order in which they occur when rotating the thing.  used to map order into something that is actually in order.  need some fancy bit math i think to do better.
    case 1:
      f = 1;
      break;
    case 5:
      f = 1;
      break;
    case 4:
      f = 3;
      break;
    case 6:
      f = 3;
      break;
    case 2:
      f = 5;
      break;
    case 3:
      f = 5;
      break;
  } 

  int r = 0;
  if (f > lastf) r=1;
  if (f < lastf) r=-1;
  if (f == lastf) r=0;
  // two special cases, basically for overflow
  if (f == 1 && lastf == 5) r=1;
  if (f == 5 && lastf == 1) r=-1;
  lastf = f;
  
  if (r == 1 ) { digitalWrite(gLed, HIGH); digitalWrite(bLed, LOW); }
  if (r == -1 ) { digitalWrite(gLed, LOW); digitalWrite(bLed, HIGH); }
  Serial.println(r);
  lastRotary = nowRotary;
  
  return(r);
  
 }  
}






//begin RTC stuff
#include "Wire.h"
#define DS3232_I2C_ADDRESS 0x68

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

// Stops the DS3232, but it has the side effect of setting seconds to 0
// Probably only want to use this for testing
/*void stopDS3232()
{
  Wire.beginTransmission(DS3232_I2C_ADDRESS);
  Wire.send(0);
  Wire.send(0x80);
  Wire.endTransmission();
}*/

// 1) Sets the date and time on the DS3232
// 2) Starts the clock
// 3) Sets hour mode to 24 hour clock
// Assumes you're passing in valid numbers
void setDateDS3232(byte second,        // 0-59
                   byte minute,        // 0-59
                   byte hour,          // 1-23
                   byte dayOfWeek,     // 1-7
                   byte dayOfMonth,    // 1-28/29/30/31
                   byte month,         // 1-12
                   byte year)          // 0-99
{
   Wire.beginTransmission(DS3232_I2C_ADDRESS);
   Wire.send(0);
   Wire.send(decToBcd(second));    // 0 to bit 7 starts the clock
   Wire.send(decToBcd(minute));
   Wire.send(decToBcd(hour));      // If you want 12 hour am/pm you need to set
                                   // bit 6 (also need to change readDateDS3232)
   Wire.send(decToBcd(dayOfWeek));
   Wire.send(decToBcd(dayOfMonth));
   Wire.send(decToBcd(month));
   Wire.send(decToBcd(year));
   Wire.endTransmission();

}

// Gets the date and time from the DS3232
void getDateDS3232(byte *second,
          byte *minute,
          byte *hour,
          byte *dayOfWeek,
          byte *dayOfMonth,
          byte *month,
          byte *year)

{
  // Reset the register pointer
  Wire.beginTransmission(DS3232_I2C_ADDRESS);
  Wire.send(0);
  Wire.endTransmission();

  Wire.requestFrom(DS3232_I2C_ADDRESS, 7);

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










void rtcSetup() {
  
  byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
  
  Wire.begin();
  
  //DS3232 RTC setup bits.
  // Change these values to what you want to set your clock to.
  // You probably only want to set your clock once and then remove
  // the setDateDS3232 call.
  second = 30;
  minute = 30;
  hour = 16;
  dayOfWeek = 2;
  dayOfMonth = 24;
  month = 5;
  year = 10;
  //setDateDS3232(second, minute, hour, dayOfWeek, dayOfMonth, month, year);
  
}


byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;

long now = 0;
int errs = 0;

void rtcGrab() {
  
//  now = millis();  
//  if (now - previousMillis > oneSec) {
    // save the last we updated tenths
//    previousMillis = now;
    seconds++;

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

  
    getDateDS3232(&second, &minute, &hour, &dayOfWeek, &dayOfMonth, &month, &year);

    if (hour > 23 || minute > 59 || second > 59 || month > 12 || dayOfMonth > 31 || year >> 99 || dayOfWeek > 7) {
      errs++; 
      Serial.print("error #");
      Serial.print(errs, DEC);
      Serial.print(", data= ");
      Serial.print(hour, DEC);
      Serial.print(":");
      Serial.print(minute, DEC);
      Serial.print(":");
      Serial.print(second, DEC);
      Serial.print("  ");
      Serial.print(month, DEC);
      Serial.print("/");
      Serial.print(dayOfMonth, DEC);
      Serial.print("/");
      Serial.print(year, DEC);
      Serial.print("  Day_of_week:");
      Serial.println(dayOfWeek, DEC);
    
    } else {
      Serial.print(", data= ");
      Serial.print(hour, DEC);
      Serial.print(":");
      Serial.print(minute, DEC);
      Serial.print(":");
      Serial.print(second, DEC);
      Serial.print("  ");
      Serial.print(month, DEC);
      Serial.print("/");
      Serial.print(dayOfMonth, DEC);
      Serial.print("/");
      Serial.print(year, DEC);
      Serial.print("  Day_of_week:");
      Serial.println(dayOfWeek, DEC);
 
    }



  // hours digiting
  if ( hour < 10 ) {
    hrs1 = 255;
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

//  LEDs.setDigit(0,0,hrs1,false);

    LEDs.setColumn(1,0,digMap[hrs1]);
    LEDs.setColumn(1,1,digMap[hrs2]);
    LEDs.setColumn(1,2,digMap[mins1]);
    LEDs.setColumn(1,3,digMap[mins2]);
    LEDs.setColumn(1,4,digMap[secs1]);
    LEDs.setColumn(1,5,digMap[secs2]);
//    LEDs.setColumn(1,6,digMap[i+2]);
//    LEDs.setColumn(1,7,digMap[i+3]);

  
//  } else {
//    Serial.println("interval not passed"); 
//  }

}


int mapChar (char *c) {
	int foo = c[0];
	return(foo-97);
}






void setup() {
  Serial.begin(57600);

  // The MAX72XX is in power-saving mode on startup,
  // we have to do a wakeup call
  debug.shutdown(0,false);
  LEDs.shutdown(0,false);
  LEDs.shutdown(1,false);
  LEDs.shutdown(2,false);
  debug.clearDisplay(0);
  LEDs.clearDisplay(0);
  LEDs.clearDisplay(1);
  LEDs.clearDisplay(2);
  
  // Set the brightness to a medium values
  debug.setIntensity(0,debugPower);
  LEDs.setIntensity(0,flowerPower);
  LEDs.setIntensity(1,digitsPower);
  LEDs.setIntensity(2,rearPower);

  pinMode(h1pin, INPUT);
  pinMode(h2pin, INPUT);
  pinMode(h3pin, INPUT);
  pinMode(btn1, INPUT); digitalWrite(btn1, HIGH);
  pinMode(btn2, INPUT); digitalWrite(btn2, HIGH);

  rtcSetup(); 
  rtcGrab(); 

  
  //attachInterrupt(0, upCount, RISING);
  pinMode(opLed, OUTPUT);
  pinMode(errLed, OUTPUT);
  pinMode(rLed, OUTPUT);
  pinMode(gLed, OUTPUT);
  pinMode(bLed, OUTPUT);
  
  digitalWrite(rLed, HIGH);


  LEDs.setColumn(1,0,charMap[mapChar("h")]);
  LEDs.setColumn(1,1,charMap[mapChar("e")]);
  LEDs.setColumn(1,2,charMap[mapChar("l")]);
  LEDs.setColumn(1,3,charMap[mapChar("l")]);
  LEDs.setColumn(1,4,charMap[mapChar("o")]);
  delay(10000);

}

void upCount() {
  periodCount++; 
}

/* 
 This function will light up every Led on the matrix.
 The led will blink along with the row-number.
 row number 4 (index==3) will blink 4 times etc.
 */
void single() {
  for(int row=0;row<8;row++) {
    Serial.print(row);
    for(int col=1;col<4;col++) {
      delay(delaytime);
      Serial.print(col);
      LEDs.setLed(1,row,col,true);
      delay(delaytime*3);
      LEDs.setLed(1,row,col,false);
/*      for(int i=0;i<col;i++) {
        rgb.setLed(0,row,col,false);
        Serial.print(i);
        delay(delaytime);
        rgb.setLed(0,row,col,true);
        delay(delaytime);
        }
*/
    }
    Serial.println();
    //rgb.clearDisplay(0);
  }
}

void rows() {
  for(int row=0;row<8;row++) {
    delay(delaytime);
    LEDs.setRow(1,row,B01110000);
    delay(delaytime);
    LEDs.setRow(1,row,(byte)0);
/*    for(int i=0;i<row;i++) {
      delay(delaytime);
      rgb.setRow(0,row,B01110000);
      delay(delaytime);
      rgb.setRow(0,row,(byte)0);
    }
*/
  }
  LEDs.clearDisplay(1);
}

/*
  This function lights up a some Leds in a column.
 The pattern will be repeated on every column.
 The pattern will blink along with the column-number.
 column number 4 (index==3) will blink 4 times etc.
 */
void columns() {

  if ( (periodCount % 10) == 0 ) {
    for(int col=0;col<7;col++) {
  //    delay(delaytime);
      LEDs.setColumn(0,col,random(255));
      LEDs.setColumn(2,col,random(127,255));
      LEDs.shutdown(0, !digitalRead(btn1));
      LEDs.shutdown(2, !digitalRead(btn2));
      
  //    delay(delaytime);
  //    rgb.setColumn(0,1,B10100100);
  //    rgb.setColumn(0,2,B10010010);
  //    rgb.setColumn(0,3,B10001001);
  //    delay(delaytime*10);
  
  //    rgb.setColumn(0,col,(byte)0);
  /*    for(int i=0;i<col;i++) {
        delay(delaytime);
        rgb.setColumn(0,col,B11111111);
        delay(delaytime);
        rgb.setColumn(0,col,B00000000);
      }
  */
    }
  //  rgb.clearDisplay(0);
  }
}



/*
 This method will display the characters for the
 word "Arduino" one after the other on digit 0. 
 */
void writeArduinoOn7Segment() {
  LEDs.setChar(0,0,'a',false);
  delay(delaytime);
  LEDs.setRow(0,0,0x05);
  delay(delaytime);
  LEDs.setChar(0,0,'d',false);
  delay(delaytime);
  LEDs.setRow(0,0,0x1c);
  delay(delaytime);
  LEDs.setRow(0,0,B00010000);
  delay(delaytime);
  LEDs.setRow(0,0,0x15);
  delay(delaytime);
  LEDs.setRow(0,0,0x1D);
  delay(delaytime);
  LEDs.clearDisplay(0);
  delay(delaytime);
} 

/*
  This method will scroll all the hexa-decimal
 numbers and letters on the display. You will need at least
 four 7-Segment digits. otherwise it won't really look that good.
 */
void scrollDigits() {
  /*
    Serial.println("two");
    LEDs.setColumn(0,1,B01100000);
    LEDs.setColumn(0,2,B11011010);
    LEDs.setColumn(0,3,B11110010);
    LEDs.setColumn(0,4,B01100110);

    delay(delaytime);

    Serial.println("three");
    LEDs.setColumn(0,1,B01100110);
    LEDs.setColumn(0,2,B11110010);
    LEDs.setColumn(0,3,B11011010);
    LEDs.setColumn(0,4,B01100000);

    delay(delaytime);
    */
  for(int i=0;i<10;i++) {
    LEDs.setColumn(1,0,digMap[i]);
    LEDs.setColumn(1,1,digMap[i+1]);
    LEDs.setColumn(1,2,digMap[i+2]);
    LEDs.setColumn(1,3,digMap[i+3]);
    LEDs.setColumn(1,4,digMap[i+4]);
    LEDs.setColumn(1,5,digMap[i+5]);
    LEDs.setColumn(1,6,digMap[i+6]);
    LEDs.setColumn(1,7,digMap[i+7]);
    debug.setDigit(0,0,i,false);
    debug.setDigit(0,1,i+1,false);
    debug.setDigit(0,2,i+2,false);
    debug.setDigit(0,3,i+3,false);
    debug.setDigit(0,4,i+4,false);
    delay(delaytime);
  }

  LEDs.clearDisplay(1);
  //delay(delaytime);
}




/*
  This method will scroll all the hexa-decimal
 numbers and letters on the display. You will need at least
 four 7-Segment digits. otherwise it won't really look that good.
 */
void scrollChars() {
  for(int i=0;i<27;i++) {
    LEDs.setColumn(1,0,charMap[i]);
    LEDs.setColumn(1,1,charMap[i+1]);
    LEDs.setColumn(1,2,charMap[i+2]);
    LEDs.setColumn(1,3,charMap[i+3]);
    LEDs.setColumn(1,4,charMap[i+4]);
    LEDs.setColumn(1,5,charMap[i+5]);
    LEDs.setColumn(1,6,charMap[i+6]);
    LEDs.setColumn(1,7,charMap[i+7]);
	wmesg(i);
  }

  LEDs.clearDisplay(1);
  //delay(delaytime);
}

void wmesg(int v) {
	// same as dmesg, but with wait delay
	dmesg(v);
	delay(delaytime);

}

void dmesg(int v) {
    uint8_t ones;
    uint8_t tens;
    uint8_t hundreds;
    uint8_t thousands;
    uint8_t tenthousands;
    boolean negative;	

/*    if(v < -999 || v > 999) 
       rtturn;
    if(v<0) {
        negative=true;
        v=v*-1;
    }
*/
    ones=v%10;
    v=v/10;
    tens=v%10;
    v=v/10;
    hundreds=v%10;			
    v=v/10;
    thousands=v%10;			
    v=v/10;
    tenthousands=v%10;			

    //Now print the number digit by digit
    debug.setDigit(0,0,(byte)tenthousands,false);
    debug.setDigit(0,1,(byte)thousands,false);
    debug.setDigit(0,2,(byte)hundreds,false);
    debug.setDigit(0,3,(byte)tens,false);
    debug.setDigit(0,4,(byte)ones,false);
}







void updateDisplay() {
  
/*  LEDs.setColumn(0,0,digMap[0]);
  LEDs.setColumn(0,1,digMap[1]);
  LEDs.setColumn(0,2,digMap[2]);
  LEDs.setColumn(0,3,digMap[3]);
  LEDs.setColumn(0,4,digMap[4]);
  LEDs.setColumn(0,5,digMap[5]);
  LEDs.setColumn(0,6,digMap[6]);
  LEDs.setColumn(0,7,digMap[7]);
    LEDs.setColumn(0,8,digMap[8]);
  delay(200);
*/
  LEDs.setColumn(1,0,digMap[((periodCount / 1000) % 10)]);
  LEDs.setColumn(1,1,digMap[((periodCount / 100) % 10)]);
  LEDs.setColumn(1,2,digMap[((periodCount / 10) % 10)]);
  LEDs.setColumn(1,3,digMap[(periodCount % 10)]);
  LEDs.setColumn(1,4,digMap[((periodCount / 1000) % 10)]);
  LEDs.setColumn(1,5,digMap[((periodCount / 100) % 10)]);
  LEDs.setColumn(1,6,digMap[((periodCount / 10) % 10)]);
  LEDs.setColumn(1,7,digMap[(periodCount % 10)]);



}










int lastsecs = 0;
byte shorty;

void loop() { 
//  Serial.println("1111 now rows....");
//  rows();

  columns();
//  Serial.println("3333 now singles....");
//  single();
  digitalWrite(rLed, HIGH);

/*  if ((second > lastsecs) || (second == 0 && lastsecs == 59)) {
    lastsecs = second;
    Serial.print("second = ");
    Serial.println(second);
    if ( colons == 0 ) {
      ledbar.setRow(0,5,B01010101);
      ledbar.setRow(0,6,B10101010);
      colons = 1;
    } else {
      ledbar.setRow(0,6,B01010101);
      ledbar.setRow(0,5,B10101010);
      colons = 0;
    }
    shorty = ~(byte(second));
    ledbar.setRow(0,0, shorty);
    shorty = ~(byte(minute));
    ledbar.setRow(0,1, shorty);
    shorty = ~(byte(hour));
    ledbar.setRow(0,2, shorty);
  }
*/  

  
  periodCount += checkRotary();
  Serial.print("periodCount now ");
  Serial.println(periodCount);

  if (opLedState == LOW) {
    opLedState = HIGH;
  } else {
    opLedState = LOW;
  }
   
  digitalWrite(opLed, opLedState);
  digitalWrite(rLed, LOW);
  //updateDisplay();
  rtcGrab();  
  scrollDigits();
  scrollChars();

}
