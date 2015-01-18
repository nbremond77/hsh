// Date and time functions using a DS1307 RTC connected via I2C and Wire lib

#include <Wire.h>
#include "RTClib.h"
//#include <WString.h>                // include the String library

#define maxLength 30

String inString = String(maxLength);       // allocate a new String
String timeString = String(maxLength);// allocate a new String
char hasToBeCharStar[maxLength];

boolean needConfirm = true;

RTC_DS1307 RTC;

void setup () {
    Serial.begin(57600);
    Wire.begin();
    RTC.begin();

  //if (! RTC.isrunning()) {
  Serial.println("RTC time setter");
  Serial.println("please input a time as HH:MM:SS for a little");
  Serial.println("  while in the future.  for example:");
  Serial.println("13:43:30");
  Serial.println();
  inString = "";
  while ( inString.length() < 8 ) {
    // See if there's incoming serial data:
    if (Serial.available() > 0) {
      getIncomingChars();
      // print the string
      //Serial.print("cool, got ");
      //Serial.println(inString);
    }
  }
  timeString = inString;
  if (inString.substring(2,3) == ":") {
    //Serial.print("cool, got ");
    //Serial.println(inString);
    Serial.println();  
    Serial.print("please type \"YES\" to set the time to value above.  format has NOT been validated.");
    Serial.println(timeString);

    inString = "";
    while (needConfirm) {
      // See if there's incoming serial data:
      if (Serial.available() > 0) {
        getIncomingChars();
        // print the string
      }
      if (inString.substring(0) == "YES") {
        Serial.println("Thank you, confirmed.");
        needConfirm = false;
      }
    }
  
    timeString.toCharArray(hasToBeCharStar, maxLength);
    // following line sets the RTC to the date & time this sketch was compiled
    //RTC.adjust(DateTime(__DATE__, timeString));
    RTC.adjust(DateTime(__DATE__, hasToBeCharStar));

  } else {
    Serial.print("string=");
    Serial.println(inString);
    Serial.println("string didnt contain a \":\" skipping setting the RTC");
  }
}




void getIncomingChars() {
  // read the incoming data as a char:
  char inChar = Serial.read();
  // if you're not at the end of the string, append
  // the incoming character:
  if (inString.length() < maxLength) {
    inString += inChar;
  } 
  else {
    // empty the string by setting it equal to the inoming char:
    inString = inChar;
  }
}

#define padding(number) if (number < 10 ) {Serial.print('0'); Serial.print(number,DEC); } else {Serial.print(number,DEC); } 


void printer () {
    DateTime now = RTC.now();

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
    Serial.print(" unixtime = ");  
    Serial.print(now.unixtime());
    Serial.println();
}

void loop () {
  printer();
  delay(100); 
}
