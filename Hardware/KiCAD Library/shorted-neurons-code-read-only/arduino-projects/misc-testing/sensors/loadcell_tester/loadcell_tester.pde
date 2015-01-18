/*
  LiquidCrystal Library - Hello World
 
 Demonstrates the use a 16x2 LCD display.  The LiquidCrystal
 library works with all LCD displays that are compatible with the 
 Hitachi HD44780 driver. There are many of them out there, and you
 can usually tell them by the 16-pin interface.
 
 This sketch prints "Hello World!" to the LCD
 and shows the time.
 
  The circuit:
 * LCD RS pin to digital pin 12
 * LCD Enable pin to digital pin 11
 * LCD D4 pin to digital pin 5
 * LCD D5 pin to digital pin 4
 * LCD D6 pin to digital pin 3
 * LCD D7 pin to digital pin 2
 * 10K resistor:
 * ends to +5V and ground
 * wiper to LCD VO pin (pin 3)
 
 Library originally added 18 Apr 2008
 by David A. Mellis
 library modified 5 Jul 2009
 by Limor Fried (http://www.ladyada.net)
 example added 9 Jul 2009
 by Tom Igoe
 modified 8 Feb 2010
 by Tom Igoe
 
 This example code is in the public domain.

 http://www.arduino.cc/en/Tutorial/LiquidCrystal
 */

// include the library code:
#include <LiquidCrystal.h>

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(7,6, 5, 4, 3, 2);




long ch1 = 0;
long mv = 0;
long psi = 0;
long grams = 0;


#define refMilliVolts=5000

long accumulator = 0;
#define CAL_LOOPS 20
#define CAL_LOOP_DELAY 100
int adcOffset = 0;

void setup() {
  // set up the LCD's number of columns and rows: 
  lcd.begin(16, 2);
  // Print a message to the LCD.
  lcd.print("wait calibration");
  short calLoops=CAL_LOOPS;
  while (calLoops > 0 ) {
      ch1 = analogRead(A1);
      accumulator+=ch1;
      lcd.setCursor(0,1);
      lcd.print("                ");
      lcd.setCursor(0,1);
      if (calLoops < 10 ) lcd.print(" ");
      lcd.print(calLoops);
      lcd.print(": ");
      lcd.print(ch1);
      lcd.print(",");
      lcd.print(accumulator);
      delay(CAL_LOOP_DELAY);
      calLoops--;
  }
  adcOffset=accumulator / CAL_LOOPS;
  lcd.clear();
  lcd.print("calibration done");
  lcd.setCursor(0,1);
  lcd.print("  offset = ");
  lcd.print(adcOffset);
  delay(CAL_LOOP_DELAY * CAL_LOOPS);
}

void loop() {
  // set the cursor to column 0, line 1
  // (note: line 1 is the second row, since counting begins with 0):
  lcd.setCursor(0,0);
  lcd.print("r=");
  ch1 = analogRead(A1);
  lcd.print(ch1);
  lcd.print("-");
  lcd.print(adcOffset);
  ch1 = ch1 - adcOffset;
  lcd.setCursor(8, 0);
  lcd.print(" mv=");
  
  mv = ch1 * 5000 / 1024;
  lcd.print(mv);
  
  lcd.setCursor(0, 1);
  grams = mv * 30821 / 1000;
  lcd.print(grams);
  lcd.print("g ");
  
  // for pressure transd5ucer, 3mv/V full scale at 2000 psi.  Gain is 504,
  // so 5V excitation = 15mV full scale * 504 = 7560mV full scale 
  //
  // FIXME!!!!!!!!!!! GAIN IS TOO HIGH FOR REAL TESTING! 
  //  mv = realmv * 504 gain
  // psi = mv / full scale amped voltage * full scale psi
  psi = mv * 2000 / 7560;
  lcd.setCursor(8, 1);
  lcd.print(psi);
  lcd.print("psi");


  
  delay(500);
  lcd.clear();
}

