/*
 * Reads data from a serial GPS connected to pins (rxPin, txPin)
 * and dumps it on the hardware port (pins [0, 1]).
 *
 * Use it to verify the electrical connection of the GPS, modify
 * it at your convenience, etc.
 */

#include <SoftwareSerial.h>

#define rxPin 7
#define txPin 8
#define ledPin 13

// set up a new serial port
SoftwareSerial mySerial =  SoftwareSerial(rxPin, txPin);
byte pinState = 0;

void setup()  {
  // define pin modes for tx, rx, led pins:
  pinMode(rxPin, INPUT);
  pinMode(txPin, OUTPUT);
  pinMode(ledPin, OUTPUT);
  // set the data rate for the SoftwareSerial port
  mySerial.begin(9600);
  Serial.begin(115200);
}

void loop() {
  char someChar;
  // listen for new serial coming in:
  if (Serial.available() > 0) {
    someChar = Serial.read();
    mySerial.print(someChar);
  }
  someChar = mySerial.read();
  // print out the character:
  Serial.print(someChar);
  // toggle an LED just so you see the thing's alive.  
  // this LED will go on with every OTHER character received:
  toggle(13);

}

void toggle(int pinNum) {
  // set the LED pin using the pinState variable:
  digitalWrite(pinNum, pinState); 
  // if pinState = 0, set it to 1, and vice versa:
  pinState = !pinState;
}


