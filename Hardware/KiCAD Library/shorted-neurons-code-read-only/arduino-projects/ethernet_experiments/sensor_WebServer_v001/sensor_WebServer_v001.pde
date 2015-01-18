/*
 * Web Server
 *
 * A simple web server that shows the value of the analog input pins.
 */

#include <Ethernet.h>

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 1, 220 };

Server server(80);

#include <OneWire.h>

/* DS18S20 Temperature chip i/o */

OneWire ds(8);  // on pin 10

int photoPin = 0;  //define a pin for Photo resistor
int ledPin=3;     //define a pin for LED


// clock crap
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

int qsensors = 0;

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

void rtcSetup() {
  
  byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
  
  Wire.begin();
  
  //DS3232 RTC setup bits.
  // Change these values to what you want to set your clock to.
  // You probably only want to set your clock once and then remove
  // the setDateDS3232 call.
  second = 20;
  minute = 12;
  hour = 0;
  dayOfWeek = 7;
  dayOfMonth = 15;
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

      Serial.print(year, DEC);
      Serial.print("/");
      Serial.print(month, DEC);
      Serial.print("/");
      Serial.print(dayOfMonth, DEC);
      Serial.print("  ");
      Serial.print(hour, DEC);
      Serial.print(":");
      Serial.print(minute, DEC);
      Serial.print(":");
      Serial.print(second, DEC);
      Serial.print("  ");

//      Serial.print("  Day_of_week:");
//      Serial.println(dayOfWeek, DEC);

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

/* only applies when we have a display :)
  lc.setDigit(0,0,hrs1,false);
  lc.setDigit(0,1,hrs2,false);
  lc.setDigit(0,2,mins1,false);
  lc.setDigit(0,3,mins2,false);
  lc.setDigit(0,4,secs1,false);  
  lc.setDigit(0,5,secs2,false);
*/

//  } else {
//    Serial.println("interval not passed"); 
//  }

}






//end RTC stuff



const int wiz811resetPin = 9;


void setup()
{
  pinMode( wiz811resetPin, OUTPUT );
  digitalWrite(wiz811resetPin, LOW);
  delay(50);
  digitalWrite(wiz811resetPin, HIGH);
  delay(200);
  Ethernet.begin(mac, ip);
  server.begin();
  Serial.begin(115200);
  pinMode( ledPin, OUTPUT );
  pinMode( 4, INPUT );
  pinMode( 5, INPUT );
  
  rtcSetup();
  
}


int HighByte, LowByte, TReading, SignBit, Tc_100, Whole, Fract, Tf_100, fWhole, fFract;

byte smac[8];

void tempLoop(void) {
  byte i;
  byte present = 0;
  byte data[12];
  byte addr[8];
  
  if ( !ds.search(addr)) {
//    Serial.print("No more addresses.\n");
    ds.reset_search();
    delay(250);
    qsensors=0;
    return;
  } else {
    qsensors++;
  }
  ds.search(addr);
  
  
  Serial.print("R=");
  for( i = 0; i < 8; i++) {
    Serial.print(addr[i], HEX);
    Serial.print(" ");
    smac[i] = addr[i];
  }

  if ( OneWire::crc8( addr, 7) != addr[7]) {
      Serial.print("CRC is not valid!\n");
      return;
  }
  
  if ( addr[0] != 0x28) {
      Serial.print("Device is not a DS18B20 family device.\n");
      return;
  }

  // The DallasTemperature library can do all this work for you!

  ds.reset();
  ds.select(addr);
  ds.write(0x44,1);         // start conversion, with parasite power on at the end
  
  delay(1000);     // maybe 750ms is enough, maybe not
  // we might do a ds.depower() here, but the reset will take care of it.
  
  present = ds.reset();
  ds.select(addr);    
  ds.write(0xBE);         // Read Scratchpad

  Serial.print("P=");
  Serial.print(present,HEX);
  Serial.print(" ");
  for ( i = 0; i < 9; i++) {           // we need 9 bytes
    data[i] = ds.read();
    Serial.print(data[i], HEX);
    Serial.print(" ");
  }
  Serial.print(" CRC=");
  Serial.print( OneWire::crc8( data, 8), HEX);
//  Serial.println();
  
  LowByte = data[0];
  HighByte = data[1];
  TReading = (HighByte << 8) + LowByte;
  SignBit = TReading & 0x8000;  // test most sig bit
  if (SignBit) // negative
  {
    TReading = (TReading ^ 0xffff) + 1; // 2's comp
  }
  Tc_100 = (6 * TReading) + TReading / 4;    // multiply by (100 * 0.0625) or 6.25

  Tf_100 = Tc_100 * 9/5 + 3200;
//  fWhole = (Tc_100/100) * 9/5 + 32;
  fWhole = Tf_100 / 100;
  fFract = Tf_100 % 100;
	


  Whole = Tc_100 / 100;  // separate off the whole and fractional portions
  Fract = Tc_100 % 100;

  
  

  if (SignBit) // If its negative
  {
     Serial.print("-");
  }
  Serial.print(Whole);
  Serial.print(".");
  if (Fract < 10)
  {
     Serial.print("0");
  }
  Serial.print(Fract);
  Serial.print("C, which is ");


  if (SignBit) // If its negative
  {
     Serial.print("-");
  }
  Serial.print(fWhole);
  Serial.print(".");
  if (fFract < 10)
  {
     Serial.print("0");
  }
  Serial.print(fFract);

  Serial.print("\n");


}









int photons=0;
int lamp=1024;

void lightLoop()
{
  photons=analogRead(photoPin);
  lamp = abs((photons - 1024)/4);
  analogWrite(ledPin, (lamp));  //send the value to the ledPin. Depending on value of resistor 
                                                //you have  to divide the value. for example, 
                                                //with a 10k resistor divide the value by 2, for 100k resistor divide by 4.
  delay(10); //short delay for faster response to light.
}







void loop()
{
  rtcGrab();
  Client client = server.available();
  if (client) {
    // an http request ends with a blank line
    boolean current_line_is_blank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        // if we've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so we can send a reply
        if (c == '\n' && current_line_is_blank) {
          // send a standard http response header
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println();
        
          
          client.print("Today is ");
          switch (dayOfWeek) {
            case 1:
              client.print("Sunday, ");
              break;
            case 2:
              client.print("Monday, ");
              break;
            case 3:
              client.print("Tuesday, ");
              break;
            case 4:
              client.print("Wednesday, ");
              break;
            case 5:
              client.print("Thursday, ");
              break;
            case 6:
              client.print("Friday, ");
              break;
            case 7:
              client.print("Saturday, ");
              break;
            default:
              client.print("EEEK!  MAYDAY!!!!");
              break;            
          }


          switch (month) {
            case 1:
              client.print("January ");
              break;
            case 2:
              client.print("February ");
              break;
            case 3:
              client.print("March ");
              break;
            case 4:
              client.print("April ");
              break;
            case 5:
              client.print("May ");
              break;
            case 6:
              client.print("June ");
              break;
            case 7:
              client.print("July ");
              break;
            case 8:
              client.print("August ");
              break;
            case 9:
              client.print("September ");
              break;
            case 10:
              client.print("October");
              break;
            case 11:
              client.print("November ");
              break;
            case 12:
              client.print("December ");
              break;
            default:
              client.print("month of the apocalypse? ");
              break;

          }

          client.print(" ");
          client.print(dayOfMonth, DEC);
          client.print(" 20");
          client.print(year, DEC);
          client.println(". <br/><br/>");
          
          client.print("The current time is: ");
          if (hour < 10) {
            client.print("0");
          }
          client.print(hour, DEC);
          client.print(":");
          if (minute < 10) {
            client.print("0");
          }          
          client.print(minute, DEC);
          client.print(":");
          if (second < 10) {
            client.print("0");
          }          
          client.print(second, DEC);
          client.println(" <font color=grey>(at least thats what Mr. ds1337c RTC said)</font><br/><br/>");

          
          // output the value of each analog input pin
          /*for (int i = 0; i < 6; i++) {
            client.print("analog input ");
            client.print(i);
            client.print(" is ");
            client.print(analogRead(i));
            client.println("<br />");
          }
          */
          
          if (digitalRead(4)) {
            client.println("The green light/switch is  <font color=green>ON</font><br/><br/>");
          } else {
            client.println("The green light/switch is OFF<br/><br/>");
          }


          if (digitalRead(5)) {
            client.println("The red light/switch is <font color=red>ON</font><br/><br/>");
          } else {
            client.println("The red light/switch is OFF<br/><br/>");
          }


          
          client.print("photon level is ");
          client.print(photons);
          client.print(" which seems <b>");

          if ( photons < 150 ) {
            client.print("dark... and lonely, and only the 35bit clock to talk to.");                
          } else {
            if ( photons < 500 ) {
               client.print("kinda dim... maybe just a monitor on");                
            } else {

              if ( photons < 800 ) {
                 client.print("comfortable");                
              } else {
                if (photons < 850 ) {
                    client.print("about normal room lighting");                
                } else {
                  if (photons < 950 ) {
                    client.print("on the bright side");
                  } else {
                    if (photons < 1000 ) {
                      client.print("very bright, must be working on something that needs lots of light");
                    } else {

                      client.print("STINKING BRIGHT IN HERE, who moved me into the sunshine!?!?!");
                    }
                  }
                }
              }
            }
          }
      
          client.println("</b><br/>As such, the lamp is set to the complimentary value ");
          client.println(lamp);
          
          
          
          // print out the last temp we got          
          client.print(" (out of 255)<br/><br/>temperature round here: ");
          if (SignBit) // If its negative
          {
            client.print("-");
          }
          client.print(Whole);
          client.print(".");
          if (Fract < 10)
          {
             client.print("0");
          }
          client.print(Fract);
          client.print("C, or <b>");


          if (SignBit) // If its negative
          {
             client.print("-");
          }
          client.print(fWhole);
          client.print(".");
          if (fFract < 10)
          {
             client.print("0");
          }
          client.print(fFract);
          client.print("F</b>ahrenheit.  <br/>&nbsp;<font color=grey>or thats what sensor at 1-wire addr (");
          
          for( int i = 0; i < 8; i++) {
            client.print(smac[i], HEX);
            client.print(":");
          }


          client.print(") seems to think</font><br/><br/>");




          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          
          break;
        }
        if (c == '\n') {
          // we're starting a new line
          current_line_is_blank = true;
        } else if (c != '\r') {
          // we've gotten a character on the current line
          current_line_is_blank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    client.stop();
  }
  tempLoop();
  lightLoop();
}
