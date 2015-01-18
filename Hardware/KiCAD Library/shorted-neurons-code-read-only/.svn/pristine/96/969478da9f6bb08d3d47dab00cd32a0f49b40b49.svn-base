#include <stdio.h>
#include <PString.h>

//int digitOnTime = 1; // single digit time on in ms
//int digitOnTime = 256; // single digit time on in ms

#define digitOnTime 0
#define dimTime 20
#define oneSec 500

#define btnPin 2
#define opLed 6
#define errLed 3
#define rLed 6
#define gLed 4
#define bLed 3

byte digMap[] = { 
  B11111100, 
  B01100000,
  B11011010,
  B11110010,
  B01100110,
  B10110110,
  B00111110,
  B11100000,
  B11111110,
  B11100110,
  B11111100, 
  B01100000,
  B11011010,
  B11110010,
  B01100110,
  B10110110,
  B00111110,
  B11100000,
  B11111110,
  B11100110, 
  B11111100, 
  B01100000,
  B11011010,
  B11110010,
  B01100110,
  B10110110,
  B00111110,
  B11100000,
  B11111110,
  B11100110
};

const int timer = 1000;           // The higher the number, the slower the timing.

int digitsPower = 10;
int clockLedsPower = 10;

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
const int delaytime=5;


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
 

LedControl lc=LedControl(13,12,11,1);
LedControl rgb=LedControl(9,8,7,1);

//LedControl rgb=LedControl(13,12,11,1);
//LedControl lc=LedControl(9,8,7,1);




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




int lastRotary = 0;
int nowRotary = 0;
boolean h1last = 0;
int lastf = 0;

#define h1pin 2
#define h2pin 15
#define h3pin 16



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
  lc.setIntensity(0,digitsPower);
  rgb.setIntensity(0,clockLedsPower);
  
  return(r);
  
 }  
}











void setup() {
  Serial.begin(57600);
  delay(2000);
  pinMode(btnPin, INPUT);
  pinMode(h1pin, INPUT);
  pinMode(h2pin, INPUT);
  pinMode(h3pin, INPUT);
  //attachInterrupt(0, upCount, RISING);
  pinMode(opLed, OUTPUT);
  pinMode(errLed, OUTPUT);
  pinMode(rLed, OUTPUT);
  pinMode(gLed, OUTPUT);
  pinMode(bLed, OUTPUT);
  
  digitalWrite(rLed, HIGH);

  // The MAX72XX is in power-saving mode on startup,
  // we have to do a wakeup call
  lc.shutdown(0,false);
  rgb.shutdown(0,false);
  // Set the brightness to a medium values
  lc.setIntensity(0,5);
  rgb.setIntensity(0,0);
  // and clear the display
  lc.clearDisplay(0);
  rgb.clearDisplay(0);



  //rtcSetup(); 
  // rtcGrab(); 
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
      rgb.setLed(0,row,col,true);
      delay(delaytime*3);
      rgb.setLed(0,row,col,false);
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
    rgb.setRow(0,row,B01110000);
    delay(delaytime);
    rgb.setRow(0,row,(byte)0);
/*    for(int i=0;i<row;i++) {
      delay(delaytime);
      rgb.setRow(0,row,B01110000);
      delay(delaytime);
      rgb.setRow(0,row,(byte)0);
    }
*/
  }
  rgb.clearDisplay(0);
}

/*
  This function lights up a some Leds in a column.
 The pattern will be repeated on every column.
 The pattern will blink along with the column-number.
 column number 4 (index==3) will blink 4 times etc.
 */
void columns() {

  for(int col=0;col<7;col++) {
//    delay(delaytime);
    rgb.setColumn(0,col,random(random(127),255));
    delay(delaytime);
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



/*
 This method will display the characters for the
 word "Arduino" one after the other on digit 0. 
 */
void writeArduinoOn7Segment() {
  lc.setChar(0,0,'a',false);
  delay(delaytime);
  lc.setRow(0,0,0x05);
  delay(delaytime);
  lc.setChar(0,0,'d',false);
  delay(delaytime);
  lc.setRow(0,0,0x1c);
  delay(delaytime);
  lc.setRow(0,0,B00010000);
  delay(delaytime);
  lc.setRow(0,0,0x15);
  delay(delaytime);
  lc.setRow(0,0,0x1D);
  delay(delaytime);
  lc.clearDisplay(0);
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
    lc.setColumn(0,1,B01100000);
    lc.setColumn(0,2,B11011010);
    lc.setColumn(0,3,B11110010);
    lc.setColumn(0,4,B01100110);

    delay(delaytime);

    Serial.println("three");
    lc.setColumn(0,1,B01100110);
    lc.setColumn(0,2,B11110010);
    lc.setColumn(0,3,B11011010);
    lc.setColumn(0,4,B01100000);

    delay(delaytime);
    */
  for(int i=0;i<10;i++) {
    lc.setColumn(0,1,digMap[i]);
    lc.setColumn(0,2,digMap[i+1]);
    lc.setColumn(0,3,digMap[i+2]);
    lc.setColumn(0,4,digMap[i+3]);
    delay(delaytime);
  }

  lc.clearDisplay(0);
  //delay(delaytime);
}






void updateDisplay() {
  lc.setColumn(0,0,digMap[0]);
  lc.setColumn(0,1,digMap[1]);
  lc.setColumn(0,2,digMap[2]);
  lc.setColumn(0,3,digMap[3]);
  lc.setColumn(0,4,digMap[4]);
  lc.setColumn(0,5,digMap[5]);
  lc.setColumn(0,6,digMap[6]);
  lc.setColumn(0,7,digMap[7]);
    lc.setColumn(0,8,digMap[8]);
  delay(500);
  lc.setColumn(0,0,digMap[((periodCount / 1000) % 10)]);
  lc.setColumn(0,1,digMap[((periodCount / 100) % 10)]);
  lc.setColumn(0,2,digMap[((periodCount / 10) % 10)]);
  lc.setColumn(0,3,digMap[(periodCount % 10)]);
  lc.setColumn(0,4,digMap[((periodCount / 1000) % 10)]);
  lc.setColumn(0,5,digMap[((periodCount / 100) % 10)]);
  lc.setColumn(0,6,digMap[((periodCount / 10) % 10)]);
  lc.setColumn(0,7,digMap[(periodCount % 10)]);
    lc.setColumn(0,8,B00100101);


}










int lastsecs = 0;
byte shorty;

void loop() { 
//  Serial.println("1111 now rows....");
//  rows();
  rgb.setColumn(0,1,B11111111);
  rgb.setColumn(0,2,B11111111);
  rgb.setColumn(0,3,B11111111);
  rgb.setColumn(0,4,B11111111);
  rgb.setColumn(0,5,B11111111);
  rgb.setColumn(0,6,B11111111);
   delay(delaytime*3);
  Serial.println("2222 now columns....");
  columns();
  columns();
  columns();
  columns();
  columns();
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
  periodCount++;  

  if (opLedState == LOW) {
    opLedState = HIGH;
  } else {
    opLedState = LOW;
  }
   
  digitalWrite(opLed, opLedState);
  digitalWrite(rLed, LOW);
  updateDisplay();

}
