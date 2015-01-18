// Date and time functions using a DS1307 RTC connected via I2C and Wire lib

#include <Wire.h>
#include "RTClib.h"
#include <WString.h>                // include the String library
#include <avr/pgmspace.h>
#include <WProgram.h>

#define DS1307_ADDRESS 0x68
#define MAX7312_ADDR 0x20



static uint8_t bcd2bin (uint8_t val) { return val - 6 * (val >> 4); }
static uint8_t bin2bcd (uint8_t val) { return val + 6 * (val / 10); }


void pooIsRunning(void) {
  Wire.beginTransmission(DS1307_ADDRESS);
  Wire.send(0x0F);
  Wire.endTransmission();

  Wire.requestFrom(DS1307_ADDRESS, 1);
  byte ss = Wire.receive();
  Serial.print("0x0Fh bits requested is:");
  Serial.println(ss, BIN);
  //return !(ss>>7);
}


void toggle32kHz() {
  Wire.beginTransmission(DS1307_ADDRESS);
  Wire.send(0x0F);
  Wire.endTransmission();

  Wire.requestFrom(DS1307_ADDRESS, 1);
  byte ss = Wire.receive();
  Serial.print("0x0Fh bits requested is:");
  Serial.println(ss, BIN);

  byte on = B11001000;
  byte off = B11000000;
  byte setTo = B00000000;
  
  if ( ss == on ) {
    Serial.println("current was ON, setting to off");
    setTo = off;
  } else {
    if ( ss == off ) {
      Serial.println("current was off, setting to ON");
      setTo = on;
    } else {
      Serial.println("EEEEEEEK, was neither!  panic:");
      while(1){}
    }
  }

  Serial.print("0x0Fh bits being set is:");
  Serial.println(setTo, BIN);
  

  Wire.beginTransmission(DS1307_ADDRESS);
  Wire.send(0x0F);
  Wire.send(setTo);
  Wire.endTransmission();

  
}

void getGPIOconf() {
  Wire.beginTransmission(MAX7312_ADDR);
  Wire.send(0x00);
  Wire.endTransmission();

  Wire.requestFrom(MAX7312_ADDR, 1);

  byte ss = Wire.receive();
  Serial.print("0x00h bits on GPIO are set to:");
  Serial.println(ss, BIN);
  //return !(ss>>7);
}


int foostate = 1;
void toggleGPIO(uint8_t pin) {
  Wire.beginTransmission(MAX7312_ADDR);
  Wire.send(0x06);
  Wire.send(0x00); // set port1 (0-7) to all outputs
  //Wire.send(0xFF); // set port2 (8-15) to all inputs 
  Wire.endTransmission();

  Wire.beginTransmission(MAX7312_ADDR);
  Wire.send(0x02);

  if (foostate == 1 ) {
    Wire.send(B01110001);
    foostate = 0;
  } else {
    Wire.send(B11001010);
    foostate = 1;  
  }


  Wire.endTransmission();

  
}


/*
void RTC_DS1307::adjust(const DateTime& dt) {
    Wire.beginTransmission(DS1307_ADDRESS);
    Wire.send(0);
    Wire.send(bin2bcd(dt.second()));
    Wire.send(bin2bcd(dt.minute()));
    Wire.send(bin2bcd(dt.hour()));
    Wire.send(bin2bcd(0));
    Wire.send(bin2bcd(dt.day()));
    Wire.send(bin2bcd(dt.month()));
    Wire.send(bin2bcd(dt.year() - 2000));
    Wire.send(0);
    Wire.endTransmission();
}

void pRTC_DS1307::now() {
  Wire.beginTransmission(DS1307_ADDRESS);
  Wire.send(0);
  Wire.endTransmission();
  
  Wire.requestFrom(DS1307_ADDRESS, 7);
  uint8_t ss = bcd2bin(Wire.receive() & 0x7F);
  uint8_t mm = bcd2bin(Wire.receive());
  uint8_t hh = bcd2bin(Wire.receive());
  Wire.receive();
  uint8_t d = bcd2bin(Wire.receive());
  uint8_t m = bcd2bin(Wire.receive());
  uint16_t y = bcd2bin(Wire.receive()) + 2000;
  
  return DateTime (y, m, d, hh, mm, ss);
}


*/











































#define maxLength 30

String inString = String(maxLength);       // allocate a new String
String timeString = String(maxLength);       // allocate a new String
boolean needConfirm = true;

RTC_DS1307 RTC;

void setup () {
    Serial.begin(57600);
    Wire.begin();
    RTC.begin();
  Serial.print("current time: ");
  //if (! RTC.isrunning()) {
  printer();  
/*
  pooIsRunning();
  Serial.print("current time2: ");  
  printer();
  Serial.println("RTC time setter");
  Serial.println("please input a time as HH:MM:SS for a little");
  Serial.println("  while in the future.  for example:");
  Serial.println("13:43:30");
  Serial.println();
  
  while ( inString.length() < 8 ) {
    // See if there's incoming serial data:
    if (Serial.available() > 0) {
      getIncomingChars();
      // print the string
      //Serial.print("cool, got ");
      //Serial.println(inString);
    }
  }
  toggle32kHz();
  
  timeString = inString;
  if (inString.contains(":")) {
    Serial.print("cool, got ");
    Serial.println(inString);
  
    Serial.print("please type \"YES\" to set the time to value above.  format has NOT been validated.");
    Serial.println(timeString);

    inString = "";
    while (needConfirm) {
      // See if there's incoming serial data:
      if (Serial.available() > 0) {
        getIncomingChars();
        // print the string
      }
      if (inString.contains("YES")) {
        Serial.println("Thank you, confirmed.");
        needConfirm = false;
      }
    }
  
    // following line sets the RTC to the date & time this sketch was compiled
    RTC.adjust(DateTime(__DATE__, timeString));

  } else {
    Serial.print("string=");
    Serial.println(inString);
    Serial.println("string didnt contain a \":\" skipping setting the RTC");
  }
*/

}




void getIncomingChars() {
  // read the incoming data as a char:
  char inChar = Serial.read();
  // if you're not at the end of the string, append
  // the incoming character:
  if (inString.length() < maxLength) {
    inString.append(inChar);
  } 
  else {
    // empty the string by setting it equal to the inoming char:
    inString = inChar;
  }
}

#define padding(number) if (number < 10 ) {Serial.print('0'); Serial.print(number,DEC); } else {Serial.print(number,DEC); } 


void printer () {
    DateTime now = RTC.now();
/*    
    Serial.print(now.year(), DEC);
    Serial.print('/');
    Serial.print(now.month(), DEC);
    Serial.print('/');
    Serial.print(now.day(), DEC);
    Serial.print(' ');
    Serial.print(now.hour(), DEC);
    Serial.print(':');
    Serial.print(now.minute(), DEC);
    Serial.print(':');
    Serial.print(now.second(), DEC);
    Serial.println();
*/

    padding(now.year());
    Serial.print('/');
    padding(now.month());
    Serial.print('/');
    padding(now.day());
    Serial.print(' ');
    padding(now.hour());
    Serial.print(':');
    padding(now.minute());
    Serial.print(':');
    padding(now.second());
    Serial.println();

    Serial.print(" since midnight 1/1/1970 = ");
    Serial.print(now.unixtime());
    Serial.print("s = ");
    Serial.print(now.unixtime() / 86400L);
    Serial.println("d");
/*    
    // calculate a date which is 7 days and 30 seconds into the future
    DateTime future (now.unixtime() + 7 * 86400L + 30);
    
    Serial.print(" now + 7d + 30s: ");
    Serial.print(future.year(), DEC);
    Serial.print('/');
    Serial.print(future.month(), DEC);
    Serial.print('/');
    Serial.print(future.day(), DEC);
    Serial.print(' ');
    Serial.print(future.hour(), DEC);
    Serial.print(':');
    Serial.print(future.minute(), DEC);
    Serial.print(':');
    Serial.print(future.second(), DEC);
    Serial.println();
    Serial.println();
*/

}

void loop () {
  
  printer();
  toggle32kHz();
  toggleGPIO(1);
  getGPIOconf();
  
  delay(2000); 
}
