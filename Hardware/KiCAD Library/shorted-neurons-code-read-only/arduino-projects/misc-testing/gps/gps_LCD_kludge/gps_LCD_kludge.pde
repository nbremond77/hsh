/* trackuino copyright (C) 2010  EA5HAV Javi
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// Trackuino custom libs
#include "debug.h"
#include "gps.h"
#include <SoftwareSerial.h>

// Arduino/AVR libs
#include <Wire.h>
#include <WProgram.h>
#include <avr/power.h>
#include <avr/sleep.h>

Gps gps;
unsigned long next_tx_millis;

void disable_bod_and_sleep()
{
  /* This will turn off brown-out detection while
   * sleeping. Unfortunately this won't work in IDLE mode.
   * Relevant info about BOD disabling: datasheet p.44
   *
   * Procedure to disable the BOD:
   *
   * 1. BODSE and BODS must be set to 1
   * 2. Turn BODSE to 0
   * 3. BODS will automatically turn 0 after 4 cycles
   *
   * The catch is that we *must* go to sleep between 2
   * and 3, ie. just before BODS turns 0.
   */
  unsigned char mcucr;

  cli();
  mcucr = MCUCR | (_BV(BODS) | _BV(BODSE));
  MCUCR = mcucr;
  MCUCR = mcucr & (~_BV(BODSE));
  sei();
  sleep_mode();    // Go to sleep
}

void power_save()
{
  /* Enter power saving mode. SLEEP_MODE_IDLE is the least saving
   * mode, but it's the only one that will keep the UART running.
   * In addition, we need timer0 to keep track of time and timer2
   * to keep pwm output at its rest voltage.
   */

  set_sleep_mode(SLEEP_MODE_IDLE);
  sleep_enable();
  power_adc_disable();
//bts  power_spi_disable();
//bts  power_twi_disable();
  //if (! modem_busy()) {  // Don't let timer 1 sleep if we're txing.
  //  power_timer1_disable();
  //}

  sleep_mode();    // Go to sleep
  
  sleep_disable();  // Resume after wake up
  power_all_enable();
}

#include <SoftwareSerial.h>

#define rxPin 7  
#define txPin 8
#define ledPin 13
#define fixLED 6

// set up a new serial port
SoftwareSerial mySerial =  SoftwareSerial(rxPin, txPin);
byte pinState = 0;

// include the library code:
#include <LiquidCrystal.h>

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);


void setup()  {
  // define pin modes for tx, rx, led pins:
  pinMode(rxPin, INPUT);
  pinMode(txPin, OUTPUT);
  pinMode(ledPin, OUTPUT);
  pinMode(fixLED, OUTPUT);
  digitalWrite(fixLED, HIGH);
  // set the data rate for the SoftwareSerial port
  mySerial.begin(9600);
  // set up the LCD's number of columns and rows: 
  lcd.begin(16, 2);
  lcd.print("GPS kludge v0.1");
  //delay(2000);
  digitalWrite(fixLED, LOW);
  Serial.begin(115200);
  //next_tx_millis = millis() + 30000;
  
}



void toggle(int pinNum) {
  // set the LED pin using the pinState variable:
  digitalWrite(pinNum, pinState); 
  // if pinState = 0, set it to 1, and vice versa:
  pinState = !pinState;
}


void printGPS() {
  
  Serial.write("/");					// Report w/ timestamp, no APRS messaging. $ = NMEA raw data
Serial.write(gps.get_time());		// 170915h = 17h:09m:15s zulu (not allowed in Status Reports)
Serial.write(gps.get_lat());		// Lat: 38deg and 22.20 min (.20 are NOT seconds, but 1/100th of minutes)
Serial.write("/");					// Symbol table
Serial.write(gps.get_lon());		// Lon: 000deg and 25.80 min
Serial.write("O");					// Symbol: O=balloon, -=QTH
Serial.write(gps.get_course());
Serial.write("/");
Serial.write(gps.get_speed());		// Course and speed (degrees/knots)
Serial.write("/A=");
Serial.write(gps.get_altitude());	// Altitude (feet). Goes anywhere in the comment area
Serial.println("");
  lcd.clear();
  lcd.setCursor(0, 0);
  if (gps.get_fix()) {
    lcd.print(gps.get_lat());
    digitalWrite(fixLED, HIGH);
    lcd.print(" a");
    lcd.print(gps.get_altitude());

  } else {
    lcd.print("wait for fix ");
    lcd.print(millis()/1000);
    digitalWrite(fixLED, LOW);
  }

  lcd.setCursor(0, 1);
  lcd.print(gps.get_lon());
  lcd.print("v=");
  lcd.print(gps.get_speed());		// speed (knots)

  
  

}


void loop()
{
  char c;
  bool valid_gps_data;

  if (millis() >= next_tx_millis) {
    //aprs_send(gps);
    printGPS();
    next_tx_millis = millis() + 1000;
    toggle(ledPin);
  }
  
  //if (Serial.available()) {
    
    //c = mySerial.read();
    //Serial.print(c);
    //valid_gps_data = gps.encode(c);

  //} else {
  //  power_save();
  //  delay(100);
  //}
  
  //sleep(100);
  
  int i;
  unsigned char buffer[256];

  valid_gps_data = 0;
  while (! valid_gps_data) {
	for (i = 0; i < 256; i++) {
		buffer[i] = mySerial.read();
                Serial.print(buffer[i]);
	}
	for (i = 0; i < 256; i++) {
		if (gps.encode(buffer[i])) {
			valid_gps_data = 1;
                        digitalWrite(fixLED, HIGH);
                        //delay(10);
			break;
		}
	}
  }
  
  Serial.println("loop done");
}


void loop2() {
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
  toggle(ledPin);

}

