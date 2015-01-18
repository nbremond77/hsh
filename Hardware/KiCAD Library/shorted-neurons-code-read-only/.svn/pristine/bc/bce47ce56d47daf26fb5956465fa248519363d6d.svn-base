#include <stdio.h>

//int digitOnTime = 1; // single digit time on in ms
//int digitOnTime = 256; // single digit time on in ms

#define digitOnTime 0
#define dimTime 20
#define oneSec 500

const int btnPin = 2;
const int btnLed = 3;
const int zeroLed = 19;


int dim = 0;

const int blankSegDelay = 70;
const int timer = 1000;           // The higher the number, the slower the timing.

const int firstSegPin = 6;
const int lastSegPin = 13;

const int firstDigPin = 14;
const int lastDigPin = 18;


// pin mappings to std seg numbers
const int segA = 12;
const int segB = 6;
const int segC = 11;
const int segD = 10;
const int segE = 8;
const int segF = 13;
const int segG = 7;
const int segPt = 9;
const int dig1 = 14;
const int dig2 = 15;
const int dig3 = 16;
const int dig4 = 17;
const int dig5 = 18;

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
int mapErr[] = { 6, segPt, segA, segF, segG, segE, segD }; 
int mapBlank[] = { 0, 0 }; 

long previousMillis = 0;
volatile long starttime = 94702;
int one = 10;
int two = 10;
int three = 10;
int four = 10;
int five = 10;
char ascii[6];


/*
void toggleSeg(int s) {
      // turn the pin on:
      digitalWrite(s, HIGH);   
      while(! digitalRead(btnPin));   

      digitalWrite(s, LOW);       
      delay(timer);
  
}
*/

/*
void blinkSeg(int s) {
 
      // turn the pin on:
      digitalWrite(s, HIGH);   
      delay(timer/3);
      digitalWrite(s, LOW);       
      delay(timer);
  
}
*/

void blankDig(int d) {
  //Serial.print("    blankDig turning off digit: ");
  //Serial.println(d);
  for (int s = firstSegPin; s <= lastSegPin; s++) { 
    digitalWrite(s, LOW);
  }
}

/*
void unDoNum(int digit, int *map) {
  Serial.print("    unDoNum trying to nicely get rid of a number, elements=");
  Serial.println(map[0]);
  
  for (int n = 1; n <= map[0]; n++) {
      if (map[n] != 0) {
      digitalWrite(map[n], LOW);
      Serial.print("      unDoNum(");
      Serial.print(n);
      Serial.print(") turned OFF segment ");
      Serial.println(map[n]);
      delay(blankSegDelay);
    }
  }
}
*/

void doNum(int digit, int *map) {
  blankDig(digit);
  //Serial.print("    doNum trying to display a map, elements=");
  //Serial.println(map[0]);
  //Serial.print("    doNum displaying map on digit position ");
  //Serial.println(digit);

  
  // send cathode low allow current flow through the digit
// FIXME need define or IF here for "handwriting" mode, then:
//   digitalWrite(digit, LOW);
  
  for (int n = 1; n <= map[0]; n++) {
    if (map[n] != 0) {
      digitalWrite(map[n], HIGH);
      // uncomment delay for operation demo
      // delay(digitOnTime/2);
    }
  }
  // send cathode low allow current flow through the digit
  digitalWrite(digit, LOW);
   
  // wait for human eyes
  delay(digitOnTime);
  
  // turn the cathode back HIGH to blank the digit
  digitalWrite(digit, HIGH);
  //unDoNum(digit, map);
}

void intToMapToOutput(int digitPin, int n) {

    //Serial.print("   intToMapToOutput got ");  
    //Serial.print(digitPin);
    //Serial.print(",");
    //Serial.println(n);
    //    int a = atoi(n);
    //    Serial.print(", int");
    //    Serial.println(a);

    // FIXME - this case table is in ascii... dumb!
    switch (n) {
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
        case 10:
          doNum(digitPin, mapPt);
          break;
        default:
          doNum(digitPin, mapErr);
          break;          
   
    } // end of switch
}


void setup() {
  //Serial.begin(115200);
//  pinMode(btnPin, INPUT);
  attachInterrupt(0, upCount, RISING);
  pinMode(btnLed, OUTPUT);
  pinMode(zeroLed, OUTPUT);

  digitalWrite(zeroLed, LOW);
  
  // initialize each pin as an output:
  for (int thisPin = 6; thisPin < 19; thisPin++)  {
    pinMode(thisPin, OUTPUT);      
  }

  // start with all digit cathodes high (start blank)
  for (int thisPin = 14; thisPin < 19; thisPin++) { 
    // turn the pin on:
    digitalWrite(thisPin, HIGH);   
  }
}

void upCount() {
  starttime++; 
}

void loop() {

  if (millis() - previousMillis > oneSec) {
    // save the last we updated tenths
    previousMillis = millis();

    if (starttime > 99999) starttime = 00000;
    
    ltoa(starttime,ascii,10);
//    Serial.print("starttime is ");
//    Serial.println(starttime);
/*  Serial.print(" which has digits ");  
    Serial.print(ascii[0]);
    Serial.print(" ");  
    Serial.print(ascii[1]);
    Serial.print(" ");  
    Serial.print(ascii[2]);
    Serial.print(" ");  
    Serial.print(ascii[3]);
    Serial.print(" ");  
    Serial.print(ascii[4]);
    Serial.println();
*/

/*
    if (digitalRead(btnPin))  {
      // toggle dimmer flag
      if (dim ==1) {
          dim = 0;
      } else {
        dim = 1;
      }
    }
*/

/* uncomment for button accelleration demo

    if (digitOnTime > 2 && digitalRead(btnPin)) { 
      digitOnTime = digitOnTime /2;
      digitalWrite(btnLed, HIGH);
      delay(300);
      digitalWrite(btnLed, LOW);
      if (digitOnTime <= 2 ) {
        digitOnTime = 0;
        digitalWrite(btnLed, HIGH);
      }
    }
    
*/

  } 

    // Serial.println(" now outputting those digits");
    int x = ascii[0];
    intToMapToOutput(dig1, x);
    x = ascii[1];
    intToMapToOutput(dig2, x);
    x = ascii[2];
    intToMapToOutput(dig3, x);
    x = ascii[3];
    intToMapToOutput(dig4, x);
    x = ascii[4];
    intToMapToOutput(dig5, x);

    if (dim) delay(dimTime) ;

}
