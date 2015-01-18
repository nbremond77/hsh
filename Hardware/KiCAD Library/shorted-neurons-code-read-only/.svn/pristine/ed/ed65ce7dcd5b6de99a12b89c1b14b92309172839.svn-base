// rf22_reliable_datagram_client.pde
// -*- mode: C++ -*-
// Example sketch showing how to create a simple addressed, reliable messaging client
// with the RF22ReliableDatagram class.
// It is designed to work with the other example rf22_reliable_datagram_server

#include <RF22ReliableDatagram.h>
#include <RF22.h>
#include <SPI.h>

#define CLIENT_ADDRESS 1
#define SERVER_ADDRESS 2
#define buzzerPin 9

// Singleton instance of the radio
RF22ReliableDatagram rf22(CLIENT_ADDRESS);

void setup() 
{
  Serial.begin(57600);
  if (!rf22.init())
    Serial.println("RF22 init failed");
  // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
  rf22.setRetries(10);
  pinMode(buzzerPin, OUTPUT);
}

uint8_t data[] = "Hello World!";
// Dont put this on the stack:
uint8_t buf[RF22_MAX_MESSAGE_LEN];
uint32_t i = 0;
uint32_t s = 0;
uint32_t f = 0;
uint32_t n = 0;

#define BUZZERXMIT 150
#define BUZZERACKOK 80
#define BUZZERERR 250
#define gb 5

void loop()
{
  while (1)
  {
    i++;
    Serial.print(i);
    Serial.print("  Sending to rf22_datagram_server");
    pinMode(gb,OUTPUT);
    digitalWrite(gb, HIGH);
    analogWrite(buzzerPin, BUZZERXMIT);
    delay(100);
    analogWrite(buzzerPin, 0);
    //delay(100);
    
    // Send a message to rf22_server
    if (!rf22.sendtoWait(data, sizeof(data), SERVER_ADDRESS)) {
      f++;
      Serial.print(" sendtoWait failed, failure ");
      Serial.println(f, DEC);
      pinMode(gb, INPUT);
      analogWrite(buzzerPin, BUZZERERR);
      delay(500);
      analogWrite(buzzerPin, 0);      
      delay(1000);
    } else {
      // Now wait for a reply from the server
 //     Serial.println(rf22.lastRssi(), HEX); // of the ACK
      uint8_t len = sizeof(buf);
      uint8_t from;   
      if (rf22.recvfromAckTimeout(buf, &len, 2000, &from)) {
        digitalWrite(gb, LOW);
        s++;
        Serial.print(" got reply success: ");
        //Serial.print(from, HEX);
        Serial.print(s, DEC);
        Serial.print(" : ");
        Serial.println((char*)buf);
        analogWrite(buzzerPin, BUZZERACKOK);
        delay(100);
        analogWrite(buzzerPin, 0);
        delay(100);
        analogWrite(buzzerPin, BUZZERACKOK);
        delay(100);
        analogWrite(buzzerPin, 0);
        delay(100);

      }
      else
      {
        pinMode(gb, INPUT);
        n++;
        Serial.print(" No reply, is rf22_datagram_server running?");
        Serial.println(n, DEC);
        analogWrite(buzzerPin, BUZZERERR);
        delay(2000);
        analogWrite(buzzerPin, 0);
        delay(1000);
      }
    }
  }
}

