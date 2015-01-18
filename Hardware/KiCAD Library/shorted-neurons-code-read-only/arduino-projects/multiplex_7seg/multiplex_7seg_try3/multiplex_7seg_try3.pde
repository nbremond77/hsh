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

const int timer = 400;           // The higher the number, the slower the timing.

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

const int map0[] = { segA, segB, segC, segD, segE, segF };
const int map1[] = { segB, segC };
const int map2[] = { segA, segB, segG, segE, segD };
const int map3[] = { segA, segB, segG, segC, segD };
const int map4[] = { segF, segG, segB, segC };
const int map5[] = { segA, segF, segG, segC, segD };
const int map6[] = { segA, segF, segE, segD, segC, segG };
const int map7[] = { segA, segB, segC };
const int map8[] = { segB, segA, segF, segG, segC, segD, segE };
const int map9[] = { segA, segF, segG, segB, segC, segD };
const int mapPt[] = { segPt };
 


void setup() {
  // use a for loop to initialize each pin as an output:
  for (int thisPin = 6; thisPin < 19; thisPin++)  {
    pinMode(thisPin, OUTPUT);      
  }
  pinMode(btnPin, INPUT);
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
      delay(timer/4);
      digitalWrite(s, LOW);       
      delay(timer/4);
  
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

  for (int digPin = 14; digPin < 19; digPin++) { 
    digitalWrite(digPin, LOW);   

/*
    for (int segPin = 6; segPin < 14; segPin++) { 
      // turn the pin on:
      digitalWrite(segPin, LOW);   
      while(! digitalRead(btnPin));   

      digitalWrite(segPin, HIGH);       
      delay(timer);
    }
*/
   toggleSeg(segA);
   toggleSeg(segB);
   toggleSeg(segC);
   toggleSeg(segD);
   toggleSeg(segE);
   toggleSeg(segF);
   toggleSeg(segG);
   toggleSeg(segPt);   
   
    while(! digitalRead(btnPin)) blinkSeg(segPt);   
    digitalWrite(digPin, HIGH);
    delay(timer);
  }
}
//

  for (int thisPin = 6; thisPin < 19; thisPin++) { 

    //turn the pin off:
    digitalWrite(thisPin, LOW);    
    while(! digitalRead(btnPin));
    delay(timer);
    digitalWrite(thisPin, HIGH);    
  }
   
}
