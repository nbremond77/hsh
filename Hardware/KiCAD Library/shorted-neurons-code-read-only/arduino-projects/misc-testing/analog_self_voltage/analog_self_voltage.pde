#include "AF_SDLog.h"
#include "util.h"
#include <avr/pgmspace.h>
#include <avr/sleep.h>
#include <Streaming.h>
#include <PString.h>
// 20292 = baseline
// 20432 = added chkmem, resulted in:
// chkMem free= 411, memory used=1637  
// (note that chkMem showed as little as 190 before simply cutting strings down, but before Flash lib)
//
// Flash has to come after Streaming because of conflicting definition of endl
#include <Flash.h>


// battery related bits
long batteryMilliVolts = 0;
#define battSensePin A3      // *analog* battery woltage sense pin
#define AREFSource EXTERNAL
//#define AREFmult 14 // 14 ~= 3311 / 1024 * 4.33;
#define AREFmv 3.000 // 465 ~= 100 * 1100 / 1024 * 4.33;
#define AREFscaler 4.33
#define AREFmult 1268 // 465 ~= 100 * 1100 / 1024 * 4.33;
#define AREFdiv 100 // divide afterwards to get back to an INT
#define batteryThresholdMilliVolts 3550

#define BUFFSIZE 200
char buffer[BUFFSIZE];
PString str(buffer, sizeof(buffer));

void setup() {                
  Serial.begin(57600); 
  pinMode(battSensePin, INPUT);
  analogReference(AREFSource);  
}
 
 
void volts() { 
  unsigned int bvRaw=analogRead(battSensePin);
  delay(2);
  bvRaw=analogRead(battSensePin);  // twice since first from ADC after wakeup is often noisy per datasheet
  Serial << "bvRaw=" << bvRaw << endl;
  /* voltage in mV = raw reading * reference voltage / range * divider ratio */
  
  batteryMilliVolts = long(bvRaw) * AREFmult;
  Serial << ", battertMv=" << batteryMilliVolts;
  batteryMilliVolts = batteryMilliVolts / AREFdiv;

  Serial << ", battertMv=" << batteryMilliVolts;
  //Serial << ", batteryV=" << (batteryMilliVolts/1000) << "." << ((batteryMilliVolts % 1000) /10) << endl; 
  Serial << ", batteryV=" << (batteryMilliVolts/1000) << "." 
         << ((batteryMilliVolts % 1000) / 100) 
         << ((batteryMilliVolts % 100) / 10) 
         << (batteryMilliVolts % 10) << endl; 

  float floatyV = bvRaw;
  floatyV = floatyV * AREFmv * AREFscaler / 1024;
  str.begin();
  str << ", batteryVfloaty=";
  str.print(floatyV,2);
  str << "BUT...";
  str << (floatyV,2) ;
  str << "   doesnt work.";
  str << endl;
  Serial.print(str);
  
}

boolean t = true;
boolean f = false;

void loop() {
  volts();
  delay(900);
  
}
