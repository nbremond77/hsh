//**************************************************************//
//  Name    : shiftOutCode, Hello World                                
//  Author  : Carlyn Maw,Tom Igoe, David A. Mellis 
//  Date    : 25 Oct, 2006    
//  Modified: 23 Mar 2010                                 
//  Version : 2.0                                             
//  Notes   : Code for using a 74HC595 Shift Register           //
//          : to count from 0 to 255                           
//****************************************************************

#include <LiquidCrystal_shifted.h>

void setup() {
  Serial.begin(57600);
  setupShifter();
}






void loop() {
  // count from 0 to 255 and display the number 
  // on the LEDs
/*
  for (int numberToDisplay = 0; numberToDisplay < 256; numberToDisplay++) {
    // take the latchPin low so 
    // the LEDs don't change while you're sending in bits:
    digitalWrite(latchPin, LOW);
    // shift out the bits:
    shiftOut(dataPin, clockPin, MSBFIRST, numberToDisplay);  

    //take the latch pin high so the LEDs will light up:
    digitalWrite(latchPin, HIGH);
    // pause before next value:
    delay(500);
  }
*/
byte regState = B11111111;

/*
  regState &= ~(1 << 0);
  Serial.print("this should be 11111110\n               ");
  Serial.println(regState, BIN);
  shiftIt(regState);
  Serial.println("waiting 5s");
  delay(5000);
  
  regState |= (1 << 0);
  Serial.print("this should be 11111111\n               ");
  Serial.println(regState, BIN);
  shiftIt(regState);
  Serial.println("waiting 5s");
  delay(5000);

  regState &= ~(1 << 2);
  Serial.print("this should be 11111011\n               ");
  Serial.println(regState, BIN);
  shiftIt(regState);
  Serial.println("waiting 5s");
  delay(5000);
  
  regState |= (1 << 2);
  Serial.print("this should be 11111111\n               ");
  Serial.println(regState, BIN);
  shiftIt(regState);
  Serial.println("waiting 5s");
  delay(5000);  
*/


  
  digitalWriteShifted(21, HIGH);
  digitalWriteShifted(23, HIGH);
  digitalWriteShifted(20, HIGH);
  digitalWriteShifted(21, LOW);
  digitalWriteShifted(13, LOW);
  digitalWriteShifted(20, LOW);
  digitalWriteShifted(27, HIGH);
  digitalWriteShifted(25, HIGH);
  digitalWriteShifted(25, LOW);
  digitalWriteShifted(23, LOW);
  digitalWriteShifted(27, LOW);

}


/*
void digitalWriteShifted(uint8_t pin, boolean pinstate) {
  Serial.print("changing pin  ");
  Serial.print(pin, DEC);
  Serial.print(" to state ");
  Serial.println(pinstate, HEX);
  
  if ( pin < 20 ) {
    digitalWrite(pin, pinstate);
  } else {
    // Q0 on shift register = fake pin 20
    pin = pin - 20;
    
    if (pinstate) { //HIGH
      shifterState |= (1 << pin);
    } else { //LOW
      shifterState &= ~(1 << pin);
    }
    shiftIt(shifterState);
  } 
  
  Serial.println("             waiting 3s");
  Serial.println();
  delay(3000);  
}

*/



/* 
    y = (x >> n) & 1;    // n=0..15.  stores nth bit of x in y.  y becomes 0 or 1.

    x &= ~(1 << n);      // forces nth bit of x to be 0.  all other bits left alone.

    x &= (1<<(n+1))-1;   // leaves alone the lowest n bits of x; all higher bits set to 0.

    x |= (1 << n);       // forces nth bit of x to be 1.  all other bits left alone.

    x ^= (1 << n);       // toggles nth bit of x.  all other bits left alone.

    x = ~x;              // toggles ALL the bits in x.

*/
