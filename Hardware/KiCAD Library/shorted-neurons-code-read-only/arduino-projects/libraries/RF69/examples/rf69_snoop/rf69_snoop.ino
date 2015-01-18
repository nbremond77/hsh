// rf69_snoop.pde
// -*- mode: C++ -*-
// Example sketch that dumps the contents of all RF69 messages received

#include <SPI.h>
#include <RF69.h>

// Singleton instance of the radio
RF69 rf69;

void setup() 
{
  Serial.begin(9600);
  if (!rf69.init())
    Serial.println("RF69 init failed");
  // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
  rf69.setPromiscuous(true);
}

void loop()
{
    uint8_t buf[RF69_MAX_MESSAGE_LEN];
    uint8_t len = sizeof(buf);
    if (rf69.recv(buf, &len))
    {
      // Get and print the headers
      // They will remain valid until setModeRx()is enabled and another message starts
      uint8_t to    = rf69.headerTo();
      uint8_t from  = rf69.headerFrom();
      uint8_t id    = rf69.headerId();
      uint8_t flags = rf69.headerFlags();
      Serial.print("RF69 Message To: 0x");
      Serial.print(to, HEX);
      Serial.print(" From: 0x");
      Serial.print(from, HEX);
      Serial.print(" Id: 0x");
      Serial.print(id, DEC);
      Serial.print(" Flags: 0x");
      Serial.println(flags, HEX);

      // Print the data
      int i, j;
      for (i = 0; i < len; i += 16)
      {
        // Hex
        for (j = 0; j < 16 && i+j < len; j++)
        {
          if (buf[i+j] < 16)
            Serial.print("0"); // Sigh, Serial.print does not know how to pad hex
          Serial.print(buf[i+j], HEX);
          Serial.print(" ");
        }
        // Padding on last block
        while (j++ < 16)
          Serial.print("   ");
          
        Serial.print("   ");
        // ASCII
        for (j = 0; j < 16 && i+j < len; j++)
          Serial.print((isprint(buf[i+j]) ? buf[i+j] : '.'), HEX);
        Serial.println(""); 
      }   
      Serial.println(""); 
    }
}

