// rf22_reliable_datagram_client.pde
// -*- mode: C++ -*-
// Example sketch showing how to create a simple addressed, reliable messaging client
// with the RHReliableDatagram class, using the RH_RF22 driver to control a RF22 radio.
// It is designed to work with the other example rf22_reliable_datagram_server
// Tested on Duemilanove, Uno with Sparkfun RFM22 wireless shield
// Tested on Flymaple with sparkfun RFM22 wireless shield
// Tested on ChiKit Uno32 with sparkfun RFM22 wireless shield

#include <RHReliableDatagram.h>
#include <RH_RF22.h>
#include <SPI.h>

#define CLIENT_ADDRESS 2
#define SERVER_ADDRESS 0

// Singleton instance of the radio driver
RH_RF22 driver(8,3);
//RH_RF22 driver;

// Class to manage message delivery and receipt, using the driver declared above
RHReliableDatagram manager(driver, CLIENT_ADDRESS);

void setup() 
{
  Serial.begin(57600);
    //shut off the rf12 SS pin 
    pinMode(10, OUTPUT);
    digitalWrite(10, HIGH);
  // toggle the rf22 reset
    pinMode(7, OUTPUT);
    digitalWrite(7, HIGH);
    delay(200);
    digitalWrite(7, LOW);
    delay(300);
//    pinMode(8, OUTPUT);
//    digitalWrite(8, HIGH);
//    delay(100);
//    digitalWrite(8, LOW);
//    delay(100);
    
  if (!manager.init()) {
    Serial.println("init failed");
  }  else {
    Serial.println("passed ...");
    // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
    // chg data rate: FSK,   Rb = 125kbs,  Fd = 125kHz
    driver.setModemConfig(RH_RF22::FSK_Rb125Fd125);
    // change center frequency to 436 MHz, double pullin range from 0.05 to 0.10
    driver.setFrequency(436.000, 0.10);
    // default after init is 8 dbm (set it anyhow) - see .h file for valid choices
    //driver.setTxPower(RH_RF22_TXPOW_8DBM);
    driver.setTxPower(RH_RF22_TXPOW_20DBM);
    // driver.setTxPower(RH_RF22_TXPOW_2DBM);
    // set retries to lower than 10 since this isn't critical data
    manager.setRetries(2); 
  }
  // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
}

uint8_t data[] = "Hello World!";
// for radio ...
char stringToSend[ RH_RF22_MAX_MESSAGE_LEN+1] = "\0"; // don't bother to chg this to uint8_t
uint8_t buf[ RH_RF22_MAX_MESSAGE_LEN+1];              // used for radio to rcv returned string
uint32_t loopCtr = 0;
uint32_t packets = 0;
uint32_t success = 0;
uint32_t failures = 0;
uint16_t rssiCtr = 0;
uint16_t rssiAvg = 0;
//uint8_t  rssi[NUMBER_OF_RSSI_TO_AVG] = {0};

uint16_t maxWait = 200;

void loop()
{
  Serial.println("Sending to rf22_reliable_datagram_server");
    
  // Send a message to manager_server
  if (manager.sendtoWait(data, sizeof(data), SERVER_ADDRESS))
  {
    
    // Now wait for a reply from the server
    uint8_t len = sizeof(buf);
    uint8_t from;   
    if (manager.recvfromAckTimeout(buf, &len, 2000, &from))
    {
      Serial.print("got reply from : 0x");
      Serial.print(from, HEX);
      Serial.print(": ");
      Serial.println((char*)buf);
    }
    else
    {
      Serial.println("No reply, is rf22_reliable_datagram_server running, or not programmed to reply?");
    }
  }
  else
    Serial.println("sendtoWait failed");
  delay(500);
}

