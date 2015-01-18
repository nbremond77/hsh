/*
  For Loop Iteration
 
 Demonstrates the use of a for() loop. 
 Lights multiple LEDs in sequence, then in reverse.
 
 The circuit:
 * LEDs from pins 2 through 7 to ground
 
 created 2006
 by David A. Mellis
 modified 5 Jul 2009
 by Tom Igoe 
 
 http://www.arduino.cc/en/Tutorial/ForLoop
 */

const int btnPin = 2;
const int btnLed = 3;

const int blankSegDelay = 70;
const int timer = 200;           // The higher the number, the slower the timing.

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

int map0[] = { segA, segF, segE, segD, segC, segB, 0, 0 };
int map1[] = { segB, segC, 0, 0, 0, 0, 0, 0 };
int map2[] = { segA, segB, segG, segE, segD, 0, 0, 0 };
int map3[] = { segA, segB, segG, segC, segD, 0, 0, 0 };
int map4[] = { segF, segG, segB, segC, 0, 0, 0, 0 };
int map5[] = { segA, segF, segG, segC, segD, 0, 0, 0 };
int map6[] = { segA, segF, segE, segD, segC, segG, 0, 0 };
int map7[] = { segA, segB, segC, 0, 0, 0, 0, 0 };
int map8[] = { segB, segA, segF, segG, segC, segD, segE, 0 };
int map9[] = { segA, segF, segG, segB, segC, segD, 0, 0 };
int mapPt[] = { segPt, 0, 0, 0, 0, 0, 0, 0 };
 


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
  Serial.print("blankDig turning off digit: ");
  Serial.println(d);
  for (int s = firstSegPin; s <= lastSegPin; s++) { 
    digitalWrite(s, LOW);
    delay(blankSegDelay/2);
  }
  delay(blankSegDelay*3);
}

void unDoNum(int digit, int *map) {
  Serial.print("unDoNum trying to nicely get rid of a number, elements=");
  Serial.println(sizeof(map));
  
  for (int n = 0; n <= 7; n++) {
    if (map[n] != 0) {
      digitalWrite(map[n], LOW);
      Serial.print("  unDoNum(");
      Serial.print(n);
      Serial.print(") turned OFF segment ");
      Serial.println(map[n]);
      delay(blankSegDelay);
    }
  }
}


void doNum(int digit, int *map) {
  blankDig(digit);
  Serial.print("doNum trying to display a map, elements=");
  Serial.println(sizeof(map));
  
  for (int n = 0; n <= 7; n++) {
    if (map[n] != 0) {
      digitalWrite(map[n], HIGH);
      Serial.print("  doNum(");
      Serial.print(n);
      Serial.print(") turned on segment ");
      Serial.println(map[n]);
      delay(blankSegDelay);
    }
  }
  Serial.println("doNum done, waiting for button push");
  while(! digitalRead(btnPin)) blinkSeg(btnLed);
//  digitalWrite(digit, LOW);
  unDoNum(digit, map);
}



void loop() {
  // start with all digit high
  for (int thisPin = 14; thisPin < 19; thisPin++) { 
    // turn the pin on:
    digitalWrite(thisPin, HIGH);   
//    delay(timer);                  
    // turn the pin off:
    //digitalWrite(thisPin, LOW);    
  }

  // pring cathodes low
 while(1) {

   while(! digitalRead(btnPin)) blinkSeg(btnLed);   

   
  for (int digPin = 14; digPin < 19; digPin++) { 
    Serial.print(digPin);
    Serial.println("<< working on digitPin");
    digitalWrite(digPin, LOW);   
    for (int num = 0; num <= 10; num++) {
      Serial.print("  ");
      Serial.print(num);
      Serial.println("<< number to display");
      switch (num) {
        case 0:
          doNum(digPin, map0);
          break;
        case 1:
          doNum(digPin, map1);
          break;
        case 2:
          doNum(digPin, map2);
          break;
        case 3:
          doNum(digPin, map3);
          break;
        case 4:
          doNum(digPin, map4);
          break;
        case 5:
          doNum(digPin, map5);
          break;
        case 6:
          doNum(digPin, map6);
          break;
        case 7:
          doNum(digPin, map7);
          break;
        case 8:
          doNum(digPin, map8);
          break;
        case 9:
          doNum(digPin, map9);
          break;
        case 10:
          doNum(digPin, mapPt);
          break;          
   
      } // end of switch
    }
    while(! digitalRead(btnPin)) blinkSeg(btnLed);   
    digitalWrite(digPin, HIGH);
    delay(timer);
  }
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
