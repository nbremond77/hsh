//begin RTC stuff
#include "Wire.h"
#define DS3232_I2C_ADDRESS 0x68

// Convert normal decimal numbers to binary coded decimal
byte decToBcd(byte val) {
  return ( (val/10*16) + (val%10) );
}

// Convert binary coded decimal to normal decimal numbers
byte bcdToDec(byte val) {
  return ( (val/16*10) + (val%16) );
}

// Stops the DS3232, but it has the side effect of setting seconds to 0
// Probably only want to use this for testing
/*void stopDS3232()
{
  Wire.beginTransmission(DS3232_I2C_ADDRESS);
  Wire.send(0);
  Wire.send(0x80);
  Wire.endTransmission();
}*/

// 1) Sets the date and time on the DS3232
// 2) Starts the clock
// 3) Sets hour mode to 24 hour clock
// Assumes you're passing in valid numbers
void setDateDS3232(byte second,        // 0-59
                   byte minute,        // 0-59
                   byte hour,          // 1-23
                   byte dayOfWeek,     // 1-7
                   byte dayOfMonth,    // 1-28/29/30/31
                   byte month,         // 1-12
                   byte year)          // 0-99
{
   Wire.beginTransmission(DS3232_I2C_ADDRESS);
   Wire.send(0);
   Wire.send(decToBcd(second));    // 0 to bit 7 starts the clock
   Wire.send(decToBcd(minute));
   Wire.send(decToBcd(hour));      // If you want 12 hour am/pm you need to set
                                   // bit 6 (also need to change readDateDS3232)
   Wire.send(decToBcd(dayOfWeek));
   Wire.send(decToBcd(dayOfMonth));
   Wire.send(decToBcd(month));
   Wire.send(decToBcd(year));
   Wire.endTransmission();

}

// Gets the date and time from the DS3232
void getDateDS3232(byte *second,
          byte *minute,
          byte *hour,
          byte *dayOfWeek,
          byte *dayOfMonth,
          byte *month,
          byte *year)

{
  // Reset the register pointer
  Wire.beginTransmission(DS3232_I2C_ADDRESS);
  Wire.send(0);
  Wire.endTransmission();

  Wire.requestFrom(DS3232_I2C_ADDRESS, 7);

  // A few of these need masks because certain bits are control bits
  *second     = bcdToDec(Wire.receive() & 0x7f);
  *minute     = bcdToDec(Wire.receive());
  *hour       = bcdToDec(Wire.receive() & 0x3f);  // Need to change this if 12 hour am/pm
  *dayOfWeek  = bcdToDec(Wire.receive());
  *dayOfMonth = bcdToDec(Wire.receive());
  *month      = bcdToDec(Wire.receive());
  *year       = bcdToDec(Wire.receive());


}

//end RTC stuff




void rtcSetup() {
  
  byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
  
  Wire.begin();
  
  //DS3232 RTC setup bits.
  // Change these values to what you want to set your clock to.
  // You probably only want to set your clock once and then remove
  // the setDateDS3232 call.
  second = 30;
  minute = 30;
  hour = 16;
  dayOfWeek = 2;
  dayOfMonth = 24;
  month = 5;
  year = 10;
  //setDateDS3232(second, minute, hour, dayOfWeek, dayOfMonth, month, year);
  
}



long now = 0;
int errs = 0;
byte previousSecond = 0;

void rtcGrab() {
  
    getDateDS3232(&second, &minute, &hour, &dayOfWeek, &dayOfMonth, &month, &year);

    if (hour > 23 || minute > 59 || second > 59 || month > 12 || dayOfMonth > 31 || year >> 99 || dayOfWeek > 7) {
      errs++; 
      Serial.print("error #");
      Serial.print(errs, DEC);
      Serial.print(", data= ");
      Serial.print(hour, DEC);
      Serial.print(":");
      Serial.print(minute, DEC);
      Serial.print(":");
      Serial.print(second, DEC);
      Serial.print("  ");
      Serial.print(month, DEC);
      Serial.print("/");
      Serial.print(dayOfMonth, DEC);
      Serial.print("/");
      Serial.print(year, DEC);
      Serial.print("  Day_of_week:");
      Serial.println(dayOfWeek, DEC);
    
    } else {
#ifdef RTCDEBUG
      Serial.print(", data= ");
      Serial.print(hour, DEC);
      Serial.print(":");
      Serial.print(minute, DEC);
      Serial.print(":");
      Serial.print(second, DEC);
      Serial.print("  ");
      Serial.print(month, DEC);
      Serial.print("/");
      Serial.print(dayOfMonth, DEC);
      Serial.print("/");
      Serial.print(year, DEC);
      Serial.print("  Day_of_week:");
      Serial.println(dayOfWeek, DEC);
#endif
 
    }

  dmesg(22400);
  dmesg(22400+hour);

  // hours digiting

  homeHour=hour + homeOffset;
  if (homeHour > 23) homeHour = homeHour - 24;
  if (homeHour < 0) homeHour = homeHour + 24;


  awayHour=hour + awayOffset;

  if (awayHour > 23) awayHour = awayHour - 24;
  if (awayHour < 0) awayHour = awayHour + 24;

  if ( hoursTwelve ) {
	homeHour = homeHour % 12;
	awayHour = awayHour % 12;
	if (homeHour == 0 ) homeHour = 12;
	if (awayHour == 0 ) awayHour = 12;
  } else {
	homeHour = homeHour % 24;
	awayHour = awayHour % 24;
  }

  if (( homeHour < 10 ) && (!leadingZeroes)) {
    hrs3 = 10; //10 in the array is really a blank
  } else {
    hrs3 = round(homeHour/10);
  }  
  hrs4 = (homeHour % 10);


  if (( awayHour < 10) && (!leadingZeroes)) {
    hrs1 = 10; //10 in the array is really a blank
  } else {
    hrs1 = round(awayHour/10);
  }  
  hrs2 = (awayHour % 10);

  // minutes digiting
  if ( minute < 10 ) {
    mins1 = 0;
  } else {
    mins1 = round(minute/10);
  }  
  mins2 = (minute % 10);
  
  // seconds digiting
  if ( second < 10 ) {
    secs1 = 0;
  } else {
    secs1 = round(second/10);
  }  
  secs2 = (second % 10);

//  LEDs.setDigit(0,0,hrs1,false);

	if ( secs2 % 2) {
		colon1 = B00000001;
		colon2 = B00000000;
	} else {
		colon1 = B00000000;
		colon2 = B00000001;
	}

	
    digits[0] = digMap[hrs1];
    digits[1] = (digMap[hrs2] | colon1);
    digits[2] = digMap[mins1];
    digits[3] = digMap[mins2];
    digits[4] = digMap[hrs3];
    digits[5] = (digMap[hrs4] | colon2);
    digits[6] = digMap[mins1];
    digits[7] = digMap[mins2];

    if (second != previousSecond && (second % colorInterval == 0)) {
		setPrettyColors();
		setRear(random(0,7));
		previousSecond = second;
	}

//  } else {
//    Serial.println("interval not passed"); 
//  }

}



void checkAlarms() {
    dmesg(83000);
    Wire.beginTransmission(DS3232_I2C_ADDRESS);
    Wire.send(0x0F);
    Wire.endTransmission();

    Wire.requestFrom(DS3232_I2C_ADDRESS, 1);
  
    byte reg0E = Wire.receive();
    dmesg(83250);
    Serial.print("status register bits are:");
    Serial.println(reg0E, BIN);
    
    
    byte on = B00001001;
    byte off = B00000000;
  
    if ( reg0E == on ) {
      Serial.println("alarm flag was ON");
      dmesg(83801);
      Serial.print("status register bits are:");
    } else {
      if ( reg0E == off ) {
        Serial.println("no alarm");
        dmesg(83802);
      } else {
        Serial.print("EEEEEEEK, was neither!  panic: ");
        Serial.println(reg0E, BIN);
        dmesg(83809);
      }
    }
    dmesg(83999);
  
}



void setAlarms() {
  dmesg(84000);
  Wire.beginTransmission(DS3232_I2C_ADDRESS);
  Wire.send(0x00);
  Wire.endTransmission();

  Wire.requestFrom(DS3232_I2C_ADDRESS, 20);

  for (int r = 0; r < 20; r++) { 
    byte reg0E = Wire.receive();
    Serial.print(r, HEX);
    Serial.print(" hex, register bits are:");
    Serial.println(reg0E, BIN);
  }

/*  Wire.requestFrom(DS3232_I2C_ADDRESS, 2);
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

  byte setTo = B00000000;

  // set alarm 1 to go off every second (1 in MSB of its first four registers)
  setTo = B10000000;
  Wire.beginTransmission(DS3232_I2C_ADDRESS);
  Wire.send(0x07);
  Wire.send(setTo);
  Wire.send(setTo);
  Wire.send(setTo);
  Wire.send(setTo);
  Wire.endTransmission();

  // set alarm 1 enabled
  Wire.beginTransmission(DS3232_I2C_ADDRESS);
  Wire.send(0x0E);
  setTo = B00011101; // Alarms interrupt enable, 
  Wire.send(setTo);
  Wire.endTransmission();
  
  
//  while(true) {
    Wire.beginTransmission(DS3232_I2C_ADDRESS);
    Wire.send(0x0F);
    Wire.endTransmission();

    Wire.requestFrom(DS3232_I2C_ADDRESS, 1);

  
    byte reg0F = Wire.receive();
    Serial.print("status register bits are:");
    Serial.println(reg0F, BIN);
    
    
    byte on = B00000001;
    byte off = B00000000;
    setTo = B00000000;
  
    if ( reg0F == on ) {
      Serial.println("alarm flag was ON");
    } else {
      if ( reg0F == off ) {
        Serial.println("no alarm");
      } else {
        Serial.print("EEEEEEEK, was neither!  panic: ");
        Serial.println(reg0F, BIN);
      }
    }
  
    Serial.println("setting Alarm flag off");
    setTo = off;
  
    Serial.print("0x0Fh bits being set is:");
    Serial.println(setTo, BIN);
    
    Wire.beginTransmission(DS3232_I2C_ADDRESS);

    Wire.send(0x0F);
    Wire.send(setTo);
    Wire.endTransmission();

    Serial.println("setting Alarm flag ON");
    setTo = on;
  
    Serial.print("0x0Fh bits being set is:");
    Serial.println(setTo, BIN);
    
    Wire.beginTransmission(DS3232_I2C_ADDRESS);

    Wire.send(0x0F);
    Wire.send(setTo);
    Wire.endTransmission();
// }
 
  
}






void clockInterrupt() {
  rtcInterrupt = true;
  digitalWrite(13, HIGH);
}

void serviceClock() {
  detachInterrupt(0);
  dmesg(85000);


  dmesg(85100);
  Wire.beginTransmission(DS3232_I2C_ADDRESS);
  //dmesg(85101);
  Wire.send(0x00);
  //dmesg(85102);
  Wire.endTransmission();
  //dmesg(85103);

#ifdef RTCDEBUG
  dmesg(85200);
  Wire.requestFrom(DS3232_I2C_ADDRESS, 20);
  dmesg(85201);

  for (int r = 0; r < 20; r++) { 
    dmesg(85210+r);
    byte reg0E = Wire.receive();
    Serial.print(r, HEX);
    Serial.print(" hex, register bits are:");
    Serial.println(reg0E, BIN);
  }

/*  Wire.requestFrom(DS3232_I2C_ADDRESS, 2);
  byte reg0E = Wire.receive();
  Serial.print("0x0Eh bits requested is:");
  Serial.println(reg0E, BIN);
  byte reg0F = Wire.receive();
  Serial.print("0x0Fh bits requested is:");
  Serial.println(reg0F, BIN);
  */
#endif
  
  //byte on = B11001000;
  //byte off = B11000000;
  //byte setTo = B00000000;

  byte setTo = B00000000;

  // set alarm 1 to go off every second (1 in MSB of its first four registers)
  dmesg(85300);
  setTo = B10000000;
  Wire.beginTransmission(DS3232_I2C_ADDRESS);
  //dmesg(85301);
  Wire.send(0x07);
  //dmesg(85302);
  Wire.send(setTo);
  //dmesg(85303);
  Wire.send(setTo);
  //dmesg(85304);
  Wire.send(setTo);
  //dmesg(85305);
  Wire.send(setTo);
  //dmesg(85306);
  Wire.endTransmission();
  //dmesg(85307);

  dmesg(85310);
  // set alarm 1 enabled
  setTo = B00011101;
  Wire.beginTransmission(DS3232_I2C_ADDRESS);
  Wire.send(0x0E);
  Wire.send(setTo);
  Wire.endTransmission();
  
  
  dmesg(85400);
  Wire.beginTransmission(DS3232_I2C_ADDRESS);
  Wire.send(0x0F);
  Wire.endTransmission();

  Wire.requestFrom(DS3232_I2C_ADDRESS, 1);

  
  dmesg(85500);
  byte reg0E = Wire.receive();
  Serial.print("status register bits are:");
  Serial.println(reg0E, BIN);
  
  
  byte on = B00001001;
  byte off = B00001000;
  setTo = B00000000;

  dmesg(85600);
  if ( reg0E == on ) {
    Serial.println("alarm register 0E flag was ON, setting to off");
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

  setTo = off;

  dmesg(85700);
  Serial.print("0x0Fh bits being set is:");
  Serial.println(setTo, BIN);
  
  Wire.beginTransmission(DS3232_I2C_ADDRESS);

  Wire.send(0x0F);
  Wire.send(setTo);
  Wire.endTransmission();
 
  dmesg(85999);
  digitalWrite(13, LOW);
  rtcInterrupt = false;
  attachInterrupt(0, clockInterrupt, FALLING);
}

