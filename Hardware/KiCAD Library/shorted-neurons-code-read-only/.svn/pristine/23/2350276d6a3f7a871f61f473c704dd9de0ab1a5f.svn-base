#include <stdio.h>

//int digitOnTime = 1; // single digit time on in ms
//int digitOnTime = 256; // single digit time on in ms

#define digitOnTime 0
#define dimTime 20
#define oneSec 500
#define oneWireBusA 15

const int btnPin = 14;
const int opLed =  4;      // the number of the LED pin
const int errLed =  3;      // the number of the STOPLED pin


const int timer = 1000;           // The higher the number, the slower the timing.

int opLedState = LOW;
int colons = 0;

long previousMillis = 0;
volatile long periodCount = 0;
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
unsigned long delaytime=20;


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
//LedControl ledbar=LedControl(16,15,14,1);





void dec_bin(int number) {
 int x, y;
 x = y = 0;

 for(y = 7; y >= 0; y--) {
  x = number / (1 << y);
  number = number - x * (1 << y);
  Serial.print(x);
 }

 Serial.println("\n");

}








//begin RTC stuff
#include "Wire.h"
#define DS3232_I2C_ADDRESS 0x68

// Convert normal decimal numbers to binary coded decimal
byte decToBcd(byte val)
{
  return ( (val/10*16) + (val%10) );
}

// Convert binary coded decimal to normal decimal numbers
byte bcdToDec(byte val)
{
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


byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;

long now = 0;
int errs = 0;

void rtcGrab() {
  
//  now = millis();  
//  if (now - previousMillis > oneSec) {
    // save the last we updated tenths
//    previousMillis = now;
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
    
/*    if (digitalRead(btnPin))  {
      // toggle dimmer flag
      if (dim ==1) {
          dim = 0;
      } else {
        dim = 1;
      }
    }
*/

  
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
 
    }



  // hours digiting
  if ( hour < 10 ) {
    hrs1 = 255;
  } else {
    hrs1 = round(hour/10);
  }  
  hrs2 = (hour % 10);

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

  lc.setDigit(0,0,hrs1,false);
  lc.setDigit(0,1,hrs2,false);
  if ((secs2 % 2) == 0) {
    lc.setRow(0,2,B10000000);
  } else {
    lc.setRow(0,2,B00000000);
  }
  lc.setDigit(0,3,mins1,false);
  lc.setDigit(0,4,mins2,false);
//  lc.setDigit(0,4,secs1,false);  
//  lc.setDigit(0,4,secs2,false);
  
//  } else {
//    Serial.println("interval not passed"); 
//  }

}








/**********************************
   DS18S20 Temperature chip i/o */
   

#include <OneWire.h>
OneWire ds(oneWireBusA);  // on pin 15
int qsensors, HighByte, LowByte, TReading, SignBit, Tc_100, Whole, Fract, Tf_100, fWhole, fFract;
int dispSign = 0x0B;
byte smac[8];
float floaty = -32.86;


float getDS18B20_Celsius() {
  floaty = floaty + 0.01;
  byte i;
  byte present = 0;
  byte data[12];
  byte addr[8];
  
  if ( !ds.search(addr)) {
    Serial.print("No more sensors\n");
    ds.reset_search();
    delay(250);
    qsensors=0;
    //return(-273.15);
    ds.search(addr); // do it again to get a usable sensor 
  } else {
    qsensors++;
  }
  
  
  
  Serial.print("R=");
  for( i = 0; i < 8; i++) {
    Serial.print(addr[i], HEX);
    Serial.print(" ");
    smac[i] = addr[i];
  }

  if ( OneWire::crc8( addr, 7) != addr[7]) {
      Serial.print("sensor returned invalid CRC!\n");
      return(-273.16);
  }
  
  if ( addr[0] != 0x28) {
      Serial.print("device is not a DS18B20 family device.\n");
      return(-273.17);
  }

  // The DallasTemperature library can do all this work for you!

  ds.reset();
  ds.select(addr);
  ds.write(0x44,1);         // start conversion, with parasite power on at the end
  delay(800);     // maybe 750ms is enough, maybe not
  // we might do a ds.depower() here, but the reset will take care of it.
  
  present = ds.reset();
  ds.select(addr);    
  ds.write(0xBE);         // Read Scratchpad

  //dbgSerial.print("P=");
  //dbgSerial.print(present,HEX);
  //dbgSerial.print(" ");
  for ( i = 0; i < 9; i++) {           // we need 9 bytes
    data[i] = ds.read();
    //dbgSerial.print(data[i], HEX);
    //dbgSerial.print(" ");
  }
//dbg  Serial.print(" CRC=");
//dbg  Serial.print( OneWire::crc8( data, 8), HEX);
//dbg  Serial.println();
  
  LowByte = data[0];
  HighByte = data[1];
  TReading = (HighByte << 8) + LowByte;
  SignBit = TReading & 0x8000;  // test most sig bit
  if (SignBit) // negative
  {
    TReading = (TReading ^ 0xffff) + 1; // 2's comp
  }

  //Serial << "TReading = " << TReading << endl;

  Tc_100 = (6 * TReading) + TReading / 4;    // multiply by (100 * 0.0625) or 6.25

  //Serial << "Tc_100 = " << Tc_100 << endl;
  
  if (SignBit) { // negative
    floaty = 0 - (float(Tc_100) / 100);
    //dispSign = 0x0A;
    dispSign = B01000000;
    Tc_100 = 0 - Tc_100;
  } else {
    floaty = float(Tc_100) / 100;
    //dispSign = 0x0F;
    dispSign = B00000001;
  }
  
  //Serial << "floaty celsius reading is" << floaty << "." << endl;
  
  return(floaty);
}


float getDS18B20_Fahrenheit() {
  floaty = (getDS18B20_Celsius() * 9/5) + 32;
  //dbgSerial << "floaty fahrenheit reading is" << floaty << "." << endl;
  return(floaty);
}


/* END DS18S20 stuff */














void setup() {
  Serial.begin(57600);
  pinMode(oneWireBusA, INPUT);
  digitalWrite(oneWireBusA, HIGH); //turn on input pullup

  pinMode(btnPin, INPUT);
  digitalWrite(btnPin, HIGH); //turn on input pullup
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


  rtcSetup();  
}

void upCount() {
  periodCount++; 
  

}



/*
 This method will display the characters for the
 word "Arduino" one after the other on digit 0. 
 */
void writeArduinoOn7Segment() {
  lc.setChar(0,0,'a',false);
  delay(delaytime);
  lc.setRow(0,0,0x05);
  delay(delaytime);
  lc.setChar(0,0,'d',false);
  delay(delaytime);
  lc.setRow(0,0,0x1c);
  delay(delaytime);
  lc.setRow(0,0,B00010000);
  delay(delaytime);
  lc.setRow(0,0,0x15);
  delay(delaytime);
  lc.setRow(0,0,0x1D);
  delay(delaytime);
  lc.clearDisplay(0);
  delay(delaytime);
} 

/*
  This method will scroll all the hexa-decimal
 numbers and letters on the display. You will need at least
 four 7-Segment digits. otherwise it won't really look that good.
 */
void scrollDigits() {
  for(int i=0;i<16;i++) {
    lc.setDigit(0,5,i,false);
    lc.setDigit(0,4,i+1,false);
    lc.setDigit(0,3,i+2,false);    
    lc.setDigit(0,2,i+3,false);
    lc.setDigit(0,1,i+4,false);
    lc.setDigit(0,0,i+5,false);

    delay(delaytime);
  }
  lc.clearDisplay(0);
  delay(delaytime);
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
  digitalWrite(errLed, HIGH);
  //writeArduinoOn7Segment();
  //scrollDigits();


  if (! digitalRead(btnPin))  {
    digitalWrite(opLed, HIGH);
    //tempLoop();

  
    //float temp = getDS18B20_Celsius();
    //Serial << F("floaty celsius reading is ") << temp << F("C.") << endl;
    float temp = getDS18B20_Fahrenheit();
    //Serial << F("floaty fahrenheit reading is ") << temp << F("F") << endl;
    Tf_100 = ((Tc_100 + (80 * (Tc_100 / 100)) + 3200));
    Serial.print("Tc_100 in main is ");
    Serial.println(Tc_100);
  
    Serial.print("Tf_100 is ");
  
    Serial.println(Tf_100);
    
    if ( Tf_100 < 0 ) {
      dispSign = B00000100;
    } else {
      if ( Tf_100 >= 10000 ) {
        //dispSign = (Tf_100 / 10000 % 10);
        // above is correct number, but we need a "bitmap"... 
        // so cheat and pretend its always 1 for now
        dispSign = B00110000;
        if ( Tf_100 >= 20000 ) {
          //dispSign = (Tf_100 / 10000 % 10);
          // above is correct number, but we need a "bitmap"... 
          // so cheat and pretend its always 2 for now
          dispSign = B01101101;
        }
      } else {
//        dispSign = 0x0F;
        dispSign = B00000000;
      }
    }
    
    
  
    lc.clearDisplay(0);
    lc.setIntensity(0,15);
    //write_7seg(4,0x8F);
    lc.setRow(0,0,dispSign);
    lc.setDigit(0,1,abs(Tf_100 / 1000 % 10),false);
    lc.setDigit(0,2,abs(Tf_100 / 100 % 10),false);
    lc.setRow(0,3,B10000000);
    lc.setDigit(0,4,abs(Tf_100 /10 % 10),false);


    //updateDisplay();
    digitalWrite(opLed, LOW);
    delay(2000);
    lc.clearDisplay(0);
    lc.setIntensity(0,8);
  }
  
  rtcGrab();
  delay(200);
  digitalWrite(errLed, LOW);
  


}
