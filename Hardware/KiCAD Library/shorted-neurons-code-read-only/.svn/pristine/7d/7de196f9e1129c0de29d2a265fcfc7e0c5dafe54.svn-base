//#include <stdio.h>

#define digitOnTime 0
#define dimTime 20
#define oneSec 1000

const int btnPin = 2;
const int btnLed = 3;

int dim = 0;

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
int one = 10;
int two = 10;
int three = 10;
int four = 10;
int five = 10;
char ascii[6];


void blankDig(int d) {
  for (int s = firstSegPin; s <= lastSegPin; s++) { 
    digitalWrite(s, LOW);
  }
}


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


void setup() {
  //Serial.begin(115200);
  
  pinMode(btnPin, INPUT);
  //attachInterrupt(0, upCount, RISING);
  pinMode(btnLed, OUTPUT);

 
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

//void upCount() {
//  starttime++; 
//}

void loop() {

  if (millis() - previousMillis > oneSec) {
    // save the last we updated tenths
    previousMillis = millis();
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
    
    if (digitalRead(btnPin))  {
      // toggle dimmer flag
      if (dim ==1) {
          dim = 0;
      } else {
        dim = 1;
      }
    }
  } 


  // hours digiting
  if ( hours < 10 ) {
    hrs1 = 255;
  } else {
    hrs1 = round(hours/10);
  }  
  hrs2 = (hours % 10);

  // minutes digiting
  if ( minutes < 10 ) {
    mins1 = 0;
  } else {
    mins1 = round(minutes/10);
  }  
  mins2 = (minutes % 10);
  
  // seconds
  if ( seconds % 2 == 0 ) {
    sec = 10;
  } else {
    sec = round(seconds/10);
     switch (sec) {
        case 0:
          sec = 241;
          break;
        case 1:
          sec = 242;
          break;
        case 2:
          sec = 243;
          break;
        case 3:
          sec = 244;
          break;
        case 4:
          sec = 245;
          break;
        case 5:
          sec = 246;
          break;
        default:
          sec = 247;
          break;
     }

    
  }  
  
  
  intToMapToOutput(dig1, hrs1);
  intToMapToOutput(dig2, hrs2);
  intToMapToOutput(dig3, sec);
  intToMapToOutput(dig4, mins1);
  intToMapToOutput(dig5, mins2);

  if (dim) delay(dimTime) ;

}
