#include <stdio.h>
#include <Streaming.h>
#include <PString.h>


// Flash has to come after Streaming because of conflicting definition of endl
#include <Flash.h>




//int digitOnTime = 1; // single digit time on in ms
//int digitOnTime = 256; // single digit time on in ms

#define digitOnTime 0
#define dimTime 20
#define helloTime 500
#define oneSec 500
#define blank B00000000
#define homeOffset 0
#define awayOffset -7

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
int flowerPower = 10;
int rearPower = 15;

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


boolean hoursTwelve = true;


/* we always wait a bit between updates of the display */
const int delaytime=2000;
















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
  
  dmesg(43300);
  boolean h1 = (digitalRead(h1pin)); dmesg(43301);
  boolean h2 = (digitalRead(h2pin)); dmesg(43302);
  boolean h3 = (digitalRead(h3pin)); dmesg(43303);
  
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
   dmesg(43305);
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
  dmesg(43300+nowRotary);
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
  
  dmesg(43410+r);
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



long now = 0;
int errs = 0;
byte debugHour = -1;

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
//#ifdef RTCDEBUG
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
//#endif
 
    }

  dmesg(22400);
  if (debugHour > 23) debugHour = 0;
  int myhour=debugHour++;
  dmesg(22400+hour);

/*
	screwup:
	 	12mode
			12	9
			01	10
			02	11
			03	12
			04	1
			05	2
			06	3
			07	12
			08	1
			09	2
			10	3
			11	4
			12	5
			1	6
			2	7
			3	8
			4	9
			5	10
			6	11
			7	12
			8	1
			9	2
			10	3
			11	4
			12	9
*/
  // hours digiting

  homeHour=myhour + homeOffset;
  if (homeHour > 23) homeHour = homeHour - 24;
  if (homeHour < 0) homeHour = homeHour + 24;


  awayHour=myhour + awayOffset;

  if (awayHour > 23) awayHour = awayHour - 24;
  if (awayHour < 0) awayHour = awayHour + 24;

  if ( hoursTwelve ) {
	homeHour = homeHour % 12;
	awayHour = awayHour % 12;
	if (homeHour == 0 ) homeHour = 12;
	if (awayHour == 0 ) awayHour = 12;
  } else {
	homeHour = homeHour % 24;
	awayHour = awayHour % 24;
  }

  if (( homeHour < 10 ) && hoursTwelve) {
    hrs3 = 10; //10 in the array is really a blank
  } else {
    hrs3 = round(homeHour/10);
  }  
  hrs4 = (homeHour % 10);


  if (( awayHour < 10) && hoursTwelve) {
    hrs1 = 10; //10 in the array is really a blank
  } else {
    hrs1 = round(awayHour/10);
  }  
  hrs2 = (awayHour % 10);

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

	if ( secs2 % 2) {
		colon1 = B00000001;
		colon2 = B00000000;
	} else {
		colon1 = B00000000;
		colon2 = B00000001;
	}

	
    LEDs.setColumn(1,0,digMap[hrs1]);
    LEDs.setColumn(1,1,(digMap[hrs2] | colon1));
    LEDs.setColumn(1,2,digMap[mins1]);
    LEDs.setColumn(1,3,digMap[mins2]);
    LEDs.setColumn(1,4,digMap[hrs3]);
    LEDs.setColumn(1,5,(digMap[hrs4] | colon2));
    LEDs.setColumn(1,6,digMap[mins1]);
    LEDs.setColumn(1,7,digMap[mins2]);

  while(digitalRead(btn1)) {
	delay(100);
  }

  delay(1000);
  
//  } else {
//    Serial.println("interval not passed"); 
//  }

}


int mapChar (char *c) {
	int foo = c[0];
	byte b = charMap[foo-97];
	return(b);
}

int mapCharDpFirst (char *c) {
	int foo = c[0];
	byte b = charMap[foo-97];
	b = b >> 1;
	return(b);
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
    Serial << "row:" << row << ",";
    for(int col=0;col<8;col++) {
      delay(delaytime);
      Serial.print(col);
      LEDs.setLed(0,row,col,true);
      delay(delaytime*3);
      LEDs.setLed(0,row,col,false);
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
  dmesg(56000);
  for(int row=0;row<8;row++) {
	dmesg(56000+row);
	LEDs.setRow(0,row,(byte)255);
	delay(delaytime);
	LEDs.setRow(0,row,(byte)0);
  }
  LEDs.clearDisplay(0);
/* 

56000 = rear 0 
56001 = rear 1 
56002 = rear 2 
56003 = rear 3 
56004 = rear 4 
56005 = top 5 
56006 = top 6 
56200= flower and dig 0
56201= flower and dig 1
56202= flower and dig 2
56203= flower and dig 3
56204= flower and dig 4
56205= flower and dig 5
56206= flower and dig 6
56207= flower and dig 7


B00011100;

*/


  for(int row=0;row<8;row++) {
	dmesg(56200+row);
	LEDs.setRow(2,row,(byte)255);
	delay(delaytime);
	LEDs.setRow(2,row,(byte)0);
  }
  LEDs.clearDisplay(2);
  dmesg(56999);
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
      delay(delaytime);
  //    LEDs.setColumn(0,col,random(255));
  //    LEDs.setColumn(2,col,random(255));
      
  //    delay(delaytime);
  //    rgb.setColumn(0,1,B10100100);
  //    rgb.setColumn(0,2,B10010010);
  //    rgb.setColumn(0,3,B10001001);
  //    delay(delaytime*10);
  
	LEDs.setColumn(0,col,B11111111);
	dmesg(33000+col);
	delay(delaytime);
	LEDs.setColumn(0,col,B00000000);
      	LEDs.setColumn(2,col,B11111111);
	dmesg(33200+col);
	delay(delaytime);
	LEDs.setColumn(2,col,B00000000);
    }
  //  rgb.clearDisplay(0);
  }
}




/*
	33000 = nothing
	33200 = nothing
	33001 = nothing
	33002 = nothing
	33006 = nothing

	33003 = rear red shiners
	33004 = rear green
	33005 = rear blue

	33201 = front red shiners
	33202 = front grn shiners
	33203 = front blue shiners
	33204 = front flower red
	33205 = front flwoer green
	33206 = front flower blue
















*/

#define maxLength 30

void colors() {
  /*
	000 - off
	001 - blue
	010 - green
	011 - cyan
	100 - red
	101 - magenta
	110 - yellow
	111 - white

  */

	for(int i=0;i<8;i++) {
		// on back,
        	LEDs.setRow(rearLEDs,i,B11111111);
		dmesg(20100+i);
		while ( Serial.available() < 1) {
			// See if there's incoming serial data:
			if (Serial.available() > 0) {
				Serial.read();
			}
		}
		Serial.flush();
		LEDs.clearDisplay(rearLEDs);

	}
	
	for(int j=0;j<8;j++) {
		// front
        	LEDs.setRow(flowerLEDs,j,B11111111);
		dmesg(20300+j);
  		while ( Serial.available() < 1) {
			// See if there's incoming serial data:
			if (Serial.available() > 0) {
				Serial.read();
			}
		}
		Serial.flush();
		LEDs.clearDisplay(flowerLEDs);

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
	dmesg(i);
  }

  LEDs.clearDisplay(1);
  //delay(delaytime);
}

void wmesg(long v) {
	// same as dmesg, but with wait delay
	dmesg(v);
	delay(delaytime);

}

void dmesg(long v) {
    int ones;
    int tens;
    int hundreds;
    int thousands;
    int tenthousands;
    boolean negative;	

/*    if(v < -999 || v > 999) 
       rtturn;
    if(v<0) {
        negative=true;
        v=v*-1;
    }
*/
    //Serial << "dmesg: " << v << endl;

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


void setFlower(byte color) {
	dmesg(80100);
	Serial.print("setFlower now at ");
	Serial.print(color, BIN);
	for(i=0;i<8;i++) {
       		LEDs.setRow(flowerLEDs,i,color);
		dmesg(80110 + i);
	}
}


void setRear(byte color) {
	dmesg(81100);
	Serial.print(", setRear now at ");
	Serial.println(color, BIN);
	for(i=0;i<8;i++) {
       		LEDs.setRow(rearLEDs,i,color);
		dmesg(81110 + i);
	}

}




void setStartupColors() {

	for(i=0;i<8;i++) {
		for (j=2;j>0;j--) {
        		LEDs.setRow(j,i,0);
		}

	}
}



void setPrettyColors() {

	for(i=0;i<8;i++) {
		// on back,
        	LEDs.setRow(rearLEDs,i,B00011100);
		dmesg(21100+i);
/*		while ( Serial.available() < 1) {
			// See if there's incoming serial data:
			if (Serial.available() > 0) {
				Serial.read();
			}
		}
		Serial.flush();
		LEDs.clearDisplay(rearLEDs);
*/

	}
	dmesg(21190);
	
/*
	for(i=0;i<4;i++) {
		// front
        	LEDs.setRow(flowerLEDs,i,B00011110);
		dmesg(21200+i);
	}
	dmesg(21290);
	
	for(i=4;i<8;i++) {
		// front
        	LEDs.setRow(flowerLEDs,i,B00101110);
		dmesg(21300+i);
	}
	dmesg(21390);
*/
	dmesg(21400);
        	LEDs.setRow(flowerLEDs,0,B00010110);
        	LEDs.setRow(flowerLEDs,1,B00011110);
        	LEDs.setRow(flowerLEDs,2,B00010110);
        	LEDs.setRow(flowerLEDs,3,B00011110);
        	LEDs.setRow(flowerLEDs,4,B00100110);
        	LEDs.setRow(flowerLEDs,5,B00101110);
        	LEDs.setRow(flowerLEDs,6,B00101110);
        	LEDs.setRow(flowerLEDs,7,B00100010);


}


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

  pinMode(h1pin, INPUT);
  pinMode(h2pin, INPUT);
  pinMode(h3pin, INPUT);
  pinMode(btn1, INPUT); digitalWrite(btn1, HIGH);
  pinMode(btn2, INPUT); digitalWrite(btn2, HIGH);
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
  
  digitalWrite(rLed, HIGH);

  delay(waitForChips);

  debug.setRow(0,0,mapCharDpFirst("h"));
  debug.setRow(0,1,mapCharDpFirst("e"));
  debug.setRow(0,2,mapCharDpFirst("l"));
  debug.setRow(0,3,mapCharDpFirst("l"));
  debug.setRow(0,4,mapCharDpFirst("o"));
/*  debug.setRow(0,1,B01001111);
  debug.setRow(0,2,B00001110);
  debug.setRow(0,3,B00001110);
  debug.setRow(0,4,B00011101);
*/
  x = checkRotary();
  delay(helloTime);
  dmesg(7);
  //LEDs.clearDisplay(1);
  dmesg(8);
  setStartupColors();
  delay(waitForChips);
  debug.shutdown(0,false);
  LEDs.shutdown(0,false);
  LEDs.shutdown(1,false);
  LEDs.shutdown(2,false);
  dmesg(9);

}




void loop() { 
  dmesg(10000);

  x = checkRotary();
  if (x) {
		flowerState += x;
		Serial.println(flowerState, DEC);
		if (flowerState > 7 || flowerState < 0 ) {
			setPrettyColors();
			flowerState = 0;
		} else {
			flowerState = flowerState & B00000111;
			Serial.println(flowerState, DEC);
			shinerState = flowerState;
			rearState = flowerState;
			setFlower((shinerState << 4) | (flowerState << 1));
			setRear(rearState << 2);
		}
  }

  //updateDisplay();
  rtcGrab();  

}
