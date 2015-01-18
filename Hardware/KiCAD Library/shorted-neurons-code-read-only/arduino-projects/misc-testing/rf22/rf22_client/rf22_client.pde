// rf22_client.pde
// -*- mode: C++ -*-
// Example sketch showing how to create a simple messageing client
// with the RF22 class. RF22 class does not provide for addressing or reliability.
// It is designed to work with the other example rf22_server

#include <SPI.h>
#include <RF22.h>
#include "pitches.h"
#define buzzerPin 9
// Singleton instance of the radio
RF22 rf22;

void setup() 
{

  Serial.begin(57600);
  Serial.println("clientattempting RF22 init...");
  if (!rf22.init())

    Serial.println("clientRF22 init failed");
    // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
    //rf22.setTxPower(RF22_TXPOW_2DBM);
  Serial.println("clientoutput power now 8DBM.");    
}

uint32_t i = 0;
uint32_t r = 0;
void loop()
{
  while (1)
  {
    Serial.println("Sending to rf22_server");
    
    tone(buzzerPin, NOTE_C4, 20);
    // Send a message to rf22_server
    uint8_t data[] = "Hello World!";
    rf22.send(data, sizeof(data));
    Serial.print("client1");

    Serial.print("client2");    
    rf22.waitPacketSent(500);
        Serial.print("client3");
    // Now wait for a reply
    //uint8_t buf[RF22_MAX_MESSAGE_LEN];
    uint8_t buf[32];
    uint8_t len = sizeof(buf);
        i++;
        Serial.print("client "); Serial.println(i);
    if (rf22.waitAvailableTimeout(500))
    { 
        Serial.print("client4");
      // Should be a message for us now   
      if (rf22.recv(buf, &len))
      {
        Serial.print("clientgot reply: ");
        i++;
        Serial.print(i);
        Serial.println((char*)buf);
        tone(buzzerPin, NOTE_F5, 20);
      }
      else
      {
        Serial.println("clientrecv failed");
        tone(buzzerPin, NOTE_FS3, 20);
      }
    }
    else
    {
      Serial.println("clientNo reply, is rf22_server running?");
    }
  }
}

