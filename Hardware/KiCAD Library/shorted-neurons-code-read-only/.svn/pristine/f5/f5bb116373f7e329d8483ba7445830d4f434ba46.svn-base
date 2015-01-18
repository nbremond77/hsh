// rf69_server.pde
// -*- mode: C++ -*-
// Example sketch showing how to create a simple messageing server
// with the RF69 class. RF69 class does not provide for addressing or reliability.
// It is designed to work with the other example rf69_client

#include <SPI.h>
#include <RF69.h>

// Singleton instance of the radio
RF69 rf69;

void setup() 
{
  Serial.begin(57600);
  if (!rf69.init())
    Serial.println("RF69 init failed");
    else Serial.println("RF69 server demo");
  // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
}

void loop()
{
  while (1)
  {
    rf69.waitAvailable();
    
    // Should be a message for us now   
    uint8_t buf[RF69_MAX_MESSAGE_LEN];
    uint8_t len = sizeof(buf);
    if (rf69.recv(buf, &len))
    {
      Serial.print("got request: ");
      Serial.println((char*)buf);
      
      // Send a reply
      uint8_t data[] = "And hello back to you";
      rf69.send(data, sizeof(data));
      rf69.waitPacketSent();
      Serial.println("Sent a reply");
    }
    else
    {
      Serial.println("recv failed");
    }
    Serial.print(".");
  }
}

