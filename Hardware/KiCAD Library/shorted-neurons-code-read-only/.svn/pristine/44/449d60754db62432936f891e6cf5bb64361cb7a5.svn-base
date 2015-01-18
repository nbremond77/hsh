// rf22_reliable_datagram_server.pde
// -*- mode: C++ -*-
// Example sketch showing how to create a simple addressed, reliable messaging server
// with the RF22Datagram class.
// It is designed to work with the other example rf22_reliable_datagram_client

#include <RF22ReliableDatagram.h>
#include <RF22.h>
#include <SPI.h>

#define CLIENT_ADDRESS 1
#define SERVER_ADDRESS 0
#define actLed 9
uint32_t l = 0;
uint32_t i = 0;
uint32_t r = 0;
uint32_t f = 0;
uint32_t s = 0;

// Singleton instance of the radio
RF22ReliableDatagram rf22(SERVER_ADDRESS);

void setup() 
{
  
  Serial.begin(57600);
  Serial.println("init1");
  if (!rf22.init())
    Serial.println("RF22 init failed");
  // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
  rf22.setTxPower(RF22_TXPOW_2DBM);
  
  Serial.print("init2 - max msg length is: ");
  Serial.println(RF22_MAX_MESSAGE_LEN);
  pinMode(actLed, OUTPUT);

  
}

uint8_t data[] = "And a reliable hello back to you";
// Dont put this on the stack:
uint8_t buf[RF22_MAX_MESSAGE_LEN];
void loop()
{
  while(1) {
    l++;
    //Serial.print(l);
    // Wait for a message addressed to us from the client
    uint8_t len = sizeof(buf);
    uint8_t from;
    pinMode(actLed, INPUT);
    digitalWrite(actLed, LOW);
    if (rf22.recvfromAck(buf, &len, &from))
    {
      r++;
      pinMode(actLed, OUTPUT);
      digitalWrite(actLed, HIGH);
      //delay(10);

      Serial.print(" >> packet from id: 0x");
      Serial.print(from, HEX);
      Serial.print(" recvOk= ");
      Serial.print(r);
      Serial.print(" msg= ");
      Serial.println((char*)buf);

      uint8_t data2[RF22_MAX_MESSAGE_LEN] = " < server heard you say: ";
      int j = sizeof(data2) -1;
      j=25;
      data2[25] = '\0';
      for ( int i=0; i<sizeof(buf) && i < RF22_MAX_MESSAGE_LEN; i++) {
        if (buf[i] >20 && buf[i] <128 ) {
          data2[j] = buf[i];
          j++; 
        }
      }
      data2[j++] = '!';
      data2[j] = '\0';
      // Send a reply back to the originator client
      Serial.print("   sending reply... ");
      if (!rf22.sendtoWait(data2, sizeof(data2), from)) {
        Serial.print("sendtoWait failed, total f=");
        pinMode(actLed, INPUT);
        f++;
        Serial.println(f);
      } else {

        digitalWrite(actLed, LOW);
        s++;
        Serial.print(" OK! reply was acknowledged, goodness=");
        Serial.println(s);
        
      }

      /* Serial.println(sizeof(data2));
      Serial.print("loop6, reply was:");
      Serial.print((char*)data2);
      Serial.println("___EOL");
      */
    }
  }
}

