#include <stdio.h>

const int digitOnTime = 2;

const int btnPin = 2;
const int btnLed = 3;

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


void setup() {
  Serial.begin(115200);
  pinMode(btnPin, INPUT);
  pinMode(btnLed, OUTPUT);
  
  // use a for loop to initialize each pin as an output:
  for (int thisPin = 6; thisPin < 19; thisPin++)  {
    pinMode(thisPin, OUTPUT);      
  }

}

void toggleSeg(int s) {
      // turn the pin on:
      digitalWrite(s, HIGH);   
      while(! digitalRead(btnPin));   

      digitalWrite(s, LOW);       
      delay(timer);
  
}

void blinkSeg(int s) {
 
      // turn the pin on:
      digitalWrite(s, HIGH);   
      delay(timer/3);
      digitalWrite(s, LOW);       
      delay(timer);
  
}

void blankDig(int d) {
  //Serial.print("    blankDig turning off digit: ");
  //Serial.println(d);
  for (int s = firstSegPin; s <= lastSegPin; s++) { 
    digitalWrite(s, LOW);
    //delay(blankSegDelay/2);
  }
  //delay(blankSegDelay*3);
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
  digitalWrite(digit, LOW);
  
  for (int n = 1; n <= map[0]; n++) {
    if (map[n] != 0) {
      digitalWrite(map[n], HIGH);
      //Serial.print("      doNum(");
      //Serial.print(n);
      //Serial.print(") turned on segment ");
      //Serial.println(map[n]);

    }
  }
  
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

long previousMillis = 0;
long interval = 1000;  
long starttime = 94702;
int one = 10;
int two = 10;
int three = 10;
int four = 10;
int five = 10;
char ascii[6];

void loop() {
  // start with all digit high
  for (int thisPin = 14; thisPin < 19; thisPin++) { 
    // turn the pin on:
    digitalWrite(thisPin, HIGH);   
    //    delay(timer);                  
    // turn the pin off:
    //digitalWrite(thisPin, LOW);    
  }


 while(1) {

   while(! digitalRead(btnPin)) blinkSeg(btnLed);   

/*   
  for (int digPin = 14; digPin < 19; digPin++) { 
    //Serial.print(digPin);
    //Serial.println("<< working on digitPin");
    
    for (int num = 0; num <= 10; num++) {
      Serial.print("  ");
      Serial.print(num);
      Serial.println(" << number to display");
      intToMapToOutput(digPin, num);
    }
    while(! digitalRead(btnPin)) blinkSeg(btnLed);   
    digitalWrite(digPin, HIGH);
    delay(timer);
  }
  
*/

  if (millis() - previousMillis > interval) {
    // save the last we updated tenths
    previousMillis = millis();
    starttime++;
    
    ltoa(starttime,ascii,10);
//    Serial.print("starttime is ");
    Serial.println(starttime);
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
  } 

//    Serial.println(" now outputting those digits");
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


 } // end of while
//

  for (int thisPin = 6; thisPin < 19; thisPin++) { 

    //turn the pin off:
    digitalWrite(thisPin, LOW);    
    while(! digitalRead(btnPin));
    delay(timer);
    digitalWrite(thisPin, HIGH);
  }
   
}
