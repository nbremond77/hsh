// Date and time functions using a DS1307 RTC connected via I2C and Wire lib

#include <Wire.h>
#include "RTClib.h"
//#include <WString.h>                // include the String library
#include <avr/pgmspace.h>
//#include <WProgram.h>

#define DS1307_ADDRESS 0x68

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

/*
bitmath:
Whenever you see the variable n, its value is assumed to be 0 through 15.

    y = (x >> n) & 1;    // n=0..15.  stores nth bit of x in y.  y becomes 0 or 1.

    x &= ~(1 << n);      // forces nth bit of x to be 0.  all other bits left alone.

    x &= (1<<(n+1))-1;   // leaves alone the lowest n bits of x; all higher bits set to 0.

    x |= (1 << n);       // forces nth bit of x to be 1.  all other bits left alone.

    x ^= (1 << n);       // toggles nth bit of x.  all other bits left alone.

    x = ~x;              // toggles ALL the bits in x.

*/

volatile boolean crapState = 1;

void serviceClock() {
	crapState = true;
}


void setAlarms() {
  Wire.beginTransmission(DS1307_ADDRESS);
  Wire.send(0x00);
  Wire.endTransmission();

  Wire.requestFrom(DS1307_ADDRESS, 20);

  for (int r = 0; r < 20; r++) { 
    byte reg0E = Wire.receive();
    Serial.print(r, HEX);
    Serial.print(" hex, register bits are:");
    Serial.println(reg0E, BIN);
  }

/*  Wire.requestFrom(DS1307_ADDRESS, 2);
  byte reg0E = Wire.receive();
  Serial.print("0x0Eh bits requested is:");
  Serial.println(reg0E, BIN);
  byte reg0F = Wire.receive();
  Serial.print("0x0Fh bits requested is:");
  Serial.println(reg0F, BIN);
  */
  
  //byte on = B11001000;
  //byte off = B11000000;
  //byte setTo = B00000000;
/*  
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
*/  

  byte setTo = B00000000;

  // set alarm 1 to go off every second (1 in MSB of its first four registers)
  setTo = B10000000;
  Wire.beginTransmission(DS1307_ADDRESS);
  Wire.send(0x07);
  Wire.send(setTo);
  Wire.send(setTo);
  Wire.send(setTo);
  Wire.send(setTo);
  Wire.endTransmission();

  // set alarm 1 enabled
  setTo = B00011101;
  Wire.beginTransmission(DS1307_ADDRESS);
  Wire.send(0x0E);
  Wire.send(setTo);
  Wire.endTransmission();
  
  
//  while(true) {
    Wire.beginTransmission(DS1307_ADDRESS);
    Wire.send(0x0F);
    Wire.endTransmission();

    Wire.requestFrom(DS1307_ADDRESS, 1);

  
    byte reg0E = Wire.receive();
    Serial.print("status register bits are:");
    Serial.println(reg0E, BIN);
    
    
    byte on = B00000001;
    byte off = B00000000;
    setTo = B00000000;
  
    if ( reg0E == on ) {
      Serial.println("alarm flag was ON, setting to off");
      setTo = off;
    } else {
      if ( reg0E == off ) {
        Serial.println("no alarm");
      } else {
        Serial.print("EEEEEEEK, was neither!  panic: ");
        Serial.println(reg0E, BIN);
        //while(1){}
        setTo = off;
      }
    }
  
    setTo = B00000000;
  
    Serial.print("0x0Fh bits being set is:");
    Serial.println(setTo, BIN);
    
    Wire.beginTransmission(DS1307_ADDRESS);
    Wire.send(0x0F);
    Wire.send(setTo);
    Wire.endTransmission();
    printer();
    delay(100);

 // }
// 
  
}







































#define maxLength 30

//String inString = String(maxLength);       // allocate a new String
//String timeString = String(maxLength);       // allocate a new String
boolean needConfirm = true;

RTC_DS1307 RTC;

void setup () {
    Serial.begin(57600);
    Wire.begin();
    RTC.begin();
  Serial.print("current time: ");
  //if (! RTC.isrunning()) {
  printer();  
  pooIsRunning();
  Serial.print("current time2: ");  
  printer();
/*  Serial.println("RTC time setter");
  Serial.println("please input a time as HH:MM:SS for a little");
  Serial.println("  while in the future.  for example:");
  Serial.println("13:43:30");
  Serial.println();
  
  while ( inString.length() < 1 ) {
    // See if there's incoming serial data:
    if (Serial.available() > 0) {
      getIncomingChars();
      // print the string
      //Serial.print("cool, got ");
      //Serial.println(inString);
    }
  }
  
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
  pinMode(2, INPUT);
  digitalWrite(2, HIGH);
  setAlarms();
  //attachInterrupt(0, serviceClock, LOW);
  serviceClock();
  //toggle32kHz();
}



/*
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
*/

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
    Serial.print(" ");

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

volatile boolean ledState = true;

void loop () {
  //printer();
  delay(300); 
  if(crapState) {
	detachInterrupt(0);
	Serial.println("in serviceClock!!!!!!!!!!!!");
	if (ledState) {
		ledState = false;
	} else {
		ledState = true;
	}
	digitalWrite(13, ledState);

	Serial.println("clearing the alarm");

	Wire.beginTransmission(DS1307_ADDRESS);
	Wire.send(0x0F);
    	Wire.send(B00000000);
	Wire.endTransmission();

	Serial.print("attaching interrupt and exiting serviceClock");
	Serial.println(".");
	crapState = false;
  	attachInterrupt(0, serviceClock, LOW);
  } else {
	Serial.println("nothign to do");
  }
}
