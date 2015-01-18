// rf22_reliable_datagram_client.pde
// -*- mode: C++ -*-
// Example sketch showing how to create a simple addressed, reliable messaging client
// with the RF22ReliableDatagram class.
// It is designed to work with the other example rf22_reliable_datagram_server

#include <RF22ReliableDatagram.h>
#include <RF22.h>
#include <SPI.h>

#define CLIENT_ADDRESS 1
#define SERVER_ADDRESS 0
#define actLed 9
#define rssiLed 3

// Singleton instance of the radio
RF22ReliableDatagram rf22(CLIENT_ADDRESS);

#include <OneWire.h>
#include <DallasTemperature.h>
#include <stdlib.h>


// Data for 1wire is plugged into Arduino port...
#define ONE_WIRE_BUS 8

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);





uint8_t data[RF22_MAX_MESSAGE_LEN] = "          0123456789abcdef0123456789";
//char data[] = "                Hello reliable World!";
char crap[] = "                                ";
// Dont put this on the stack:
uint8_t buf[RF22_MAX_MESSAGE_LEN];
uint32_t l = 0;
uint32_t i = 0;
uint32_t s = 0;
uint32_t f = 0;
uint32_t n = 0;


void setup() 
{
  Serial.begin(57600);
  if (!rf22.init())
    Serial.println("RF22 init failed");
  // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
  rf22.setRetries(10);
  pinMode(actLed, OUTPUT);
  pinMode(rssiLed, OUTPUT);
  sensors.begin();
  
  for (i=0; i<=RF22_MAX_MESSAGE_LEN; i++) {
    data[i] = '\0';
  }

}




void loop()
{
  l++;
  Serial.print(l);

  // call sensors.requestTemperatures() to issue a global temperature 
  // request to all devices on the bus
  Serial.print(" ... 1wire:");
  sensors.requestTemperatures(); // Send the command to get temperatures
  Serial.print("done, ");
  Serial.print(" Temperature for the device 1 (index 0) is: ");
  Serial.println(sensors.getTempFByIndex(0));  

  // this stdlib stuff is expensive for flash and ram...
  float foo = sensors.getTempFByIndex(0);
  //dtostrf(foo, 5, 2, crap);  
   // crap has in it "78.34"
   // like "c=99999, t=78.34F"
   //where 78.34 is in foo 
   //and 99999 is in l
   //snprintf (crap, 20, "c=%d, t=%#+6.2f", l, foo);
   int foo2 = foo+0;
   
   sprintf (crap, "c=%d", l);
   sprintf(&crap[strlen(crap)], ", t=%d", foo2);

  // convert the char[] to uint8_t cause rf22 lib needs that for datagrams  
  for (i=0; i<strlen(crap); i++) {
    data[i] = crap[i];
  }
 
  data[i+1] = '\0';


  Serial.print("payload will be:");
  Serial.println((char*)crap);
  Serial.println();
  
  pinMode(actLed,OUTPUT);
  digitalWrite(actLed, HIGH);
  Serial.print("  Sending to rf22_datagram_server, ");

  
  // Send a message to rf22_server
  if (!rf22.sendtoWait(data, strlen(crap), SERVER_ADDRESS)) {
    f++;
    Serial.print(" sendtoWait failed, failure ");
    Serial.println(f, DEC);
    pinMode(actLed, INPUT);
    analogWrite(rssiLed, 0);
  } 
  else {
    // Now wait for a reply from the server
    pinMode(actLed, INPUT);
    delay(10);
    pinMode(actLed, OUTPUT);
    digitalWrite(actLed, HIGH);
    delay(10);
    pinMode(actLed, INPUT);
    delay(10);
    pinMode(actLed, OUTPUT);
    digitalWrite(actLed, HIGH);
    Serial.print(" OK! ackRSSI was: ");
    Serial.print(rf22.lastRssi(), DEC); // of the ACK
    Serial.println("/255");
    analogWrite(rssiLed, rf22.lastRssi());
    uint8_t len = sizeof(buf);
    uint8_t from;   
    if (rf22.recvfromAckTimeout(buf, &len, 2000, &from)) {
      digitalWrite(actLed, LOW);
      s++;
      Serial.print("    also got reply success: ");
      //Serial.print(from, HEX);
      Serial.print(s, DEC);
      Serial.print(" : ");
      Serial.println((char*)buf);
    }
    else
    {
      pinMode(actLed, INPUT);
      n++;
      Serial.print("    No reply, is rf22_reliable_datagram_server running?");
      Serial.println(n, DEC);
    }
  }
}


