// rf22_server.pde
// -*- mode: C++ -*-
// Example sketch showing how to create a simple messageing server
// with the RF22 class. RF22 class does not provide for addressing or reliability.
// It is designed to work with the other example rf22_client

#include <SPI.h>
#include <RF22.h>

// Singleton instance of the radio
RF22 rf22;

void setup() 
{
  Serial.begin(57600);
    Serial.println("attempting RF22 init...");
  if (!rf22.init())
    Serial.println("RF22 init failed");
  // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
  rf22.setTxPower(RF22_TXPOW_8DBM);
  Serial.println("output power now 8DBM.");    
}
uint32_t i = 0;
uint32_t s = 0;
void loop()
{
  while (1)
  {
             i++;
        Serial.print(i);
    rf22.waitAvailableTimeout(1000);
    Serial.print("    ");
    // Should be a message for us now   
    uint8_t buf[RF22_MAX_MESSAGE_LEN];
    uint8_t len = sizeof(buf);
    if (rf22.recv(buf, &len))
    {
      Serial.print("got request: ");
      Serial.print((char*)buf);
      
      // Send a reply
      uint8_t data[] = "And hello back to you";
      rf22.send(data, sizeof(data));
      rf22.waitPacketSent();
      Serial.print(" ...Sent a reply ");
      s++;
      Serial.print(i);
    }
    else
    {
      Serial.print("recv failed");
    }
    Serial.println(" .");
  }
}

