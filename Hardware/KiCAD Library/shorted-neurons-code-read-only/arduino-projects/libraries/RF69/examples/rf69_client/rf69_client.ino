// rf69_client.pde
// -*- mode: C++ -*-
// Example sketch showing how to create a simple messageing client
// with the RF69 class. RF69 class does not provide for addressing or reliability.
// It is designed to work with the other example rf69_server

#include <SPI.h>
#include <RF69.h>

// Singleton instance of the radio
RF69 rf69;

void setup() 
{
  Serial.begin(57600);
  if (!rf69.init())
    Serial.println("RF69 init failed");
  // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
}

void loop()
{
  while (1)
  {
    Serial.println("Sending to rf69_server");
    // Send a message to rf69_server
    uint8_t data[] = "Hello World!";
    rf69.send(data, sizeof(data));
   
    rf69.waitPacketSent();
    // Now wait for a reply
    uint8_t buf[RF69_MAX_MESSAGE_LEN];
    uint8_t len = sizeof(buf);

    if (rf69.waitAvailableTimeout(1000))
    { 
      // Should be a message for us now   
      if (rf69.recv(buf, &len))
      {
        Serial.print("got reply: ");
        Serial.println((char*)buf);
      }
      else
      {
        Serial.println("recv failed");
      }
    }
    else
    {
      Serial.println("No reply, is rf69_server running?");
    }
  }
}

