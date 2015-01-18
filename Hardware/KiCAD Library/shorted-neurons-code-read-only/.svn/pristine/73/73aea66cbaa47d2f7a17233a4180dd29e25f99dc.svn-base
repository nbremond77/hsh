#include <stdio.h>

//int digitOnTime = 1; // single digit time on in ms
//int digitOnTime = 256; // single digit time on in ms

#define digitOnTime 0
#define dimTime 20
#define oneSec 500

const int btnPin = 14;
const int opLed = 4;      // the number of the LED pin
const int errLed =  3;      // the number of the STOPLED pin


const int timer = 1000;           // The higher the number, the slower the timing.

int opLedState = LOW;
int colons = 0;

long previousMillis = 0;
//+volatile long periodCount = 0;
int periodCount=12345;
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
int delaytime=200;


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
LedControl lc=LedControl(7,8,9,1);








void setup() {
  Serial.begin(57600);
  pinMode(btnPin, INPUT);
  digitalWrite(btnPin, HIGH);
  //attachInterrupt(0, upCount, RISING);
  pinMode(opLed, OUTPUT);
  pinMode(errLed, OUTPUT);

  digitalWrite(errLed, HIGH);
  // The MAX72XX is in power-saving mode on startup,
  // we have to do a wakeup call

  lc.shutdown(0,false);
  // Set the brightness to a medium values
  lc.setIntensity(0,8);
  // and clear the display
  lc.clearDisplay(0);



  //rtcSetup();  
  updateDisplay();
}






void updateDisplay() {
  //  lc.clearDisplay(0);
  // delay(delaytime*20);

  //lc.setDigit(0,0,((periodCount / 100000) % 10),false);
  lc.setDigit(0,0,((periodCount / 10000) % 10),false);
  lc.setDigit(0,1,((periodCount / 1000) % 10),false);
  lc.setDigit(0,2,((periodCount / 100) % 10),false);
  lc.setDigit(0,3,((periodCount / 10) % 10),false);
  lc.setDigit(0,4,(periodCount % 10),false);
  



}









int lastsecs = 0;
byte shorty;

void loop() { 

  
  if (! digitalRead(btnPin))  {
    periodCount++;
/*    Serial.print(periodCount);
    Serial.print(" button pushes so far, and digit should be ");
    Serial.println((periodCount / 10) % 10);
    Serial.println(periodCount % 10);
    // toggle opLedState
*/

    if (opLedState == LOW) {
      opLedState = HIGH;
    } else {
      opLedState = LOW;
    }
   
    //dec_bin(periodCount);
  
    digitalWrite(opLed, opLedState);

    updateDisplay();
  }
  
  //rtcGrab();
  delay(200);
 
  


}
