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
//#define AREFSource EXTERNAL
#define AREFSource DEFAULT
//#define AREFmult 14 // 14 ~= 3311 / 1024 * 4.33;
#define AREFmv 3.300
#define AREFscaler 5.604
//#define AREFscaler 3.1521 // (1/(1006000 / (1006000 + 2165000)))
//#define AREFmult 465 // 465 ~= 100 * 1100 / 1024 * 4.33;
//#define AREFmult 1269 // 1269 ~= 100 * 3000 / 1024 * 4.33;
//                               100 * V / 1024 * (1/R2 / R2 + R1)
#define AREFmult 3630 // 3630 ~= 100 * 3300 / 1024 * (1/(98000 / (98000 + 1006000)))
//#define AREFmult 3301 // 3301 ~= 100 * 3300 / 1024 * (1/(1006000 / (1006000 + 9300000)))
//#define AREFmult 1016 // 1016 ~= 100 * 3300 / 1024 * (1/(1006000 / (1006000 + 2165000)))

//220k / 1000k WORKS!!!  1806 100 260 80
#define AREFmult 1806 // 1806 ~= 100 * 3300 / 1024 * (1/(218500 / (218500 + 1006000)))
#define AREFdiv 100 // divide afterwards to get back to an INT
#define SAMPLEDROP 260 //diode drop in the middle of intended sample range
#define DROPFACTOR 80 // linear approximation of increase in drop over the voltage range
#define batteryThresholdMilliVolts 3550

#define BUFFSIZE 200
char buffer[BUFFSIZE];
PString str(buffer, sizeof(buffer));

void setup() {                
  Serial.begin(115200); 
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
  // now adjust for diode drop
  int diodeDrop = SAMPLEDROP + (batteryMilliVolts / DROPFACTOR);
  Serial << ", diodeDrop=" << diodeDrop;

  batteryMilliVolts += diodeDrop;
  if (batteryMilliVolts < 300) batteryMilliVolts = 0;
  
  Serial << ", battertMv=" << batteryMilliVolts;
  //Serial << ", batteryV=" << (batteryMilliVolts/1000) << "." << ((batteryMilliVolts % 1000) /10) << endl; 
  Serial << ", batteryV=" << (batteryMilliVolts/1000) << "." 
         << ((batteryMilliVolts % 1000) / 100) 
         << ((batteryMilliVolts % 100) / 10) 
         << endl;
         //<< (batteryMilliVolts % 10) << endl; 

  float floatyV = bvRaw;
  floatyV = floatyV * AREFmv * AREFscaler / 1024;
  // now adjust for diode drop
  floatyV = floatyV + (SAMPLEDROP/1000) + (floatyV / DROPFACTOR/1000);
  str.begin();
  str << ", inaccurate:batteryVfloaty=";
  str.print(floatyV,1);
  //str << "BUT...";
  //str << (floatyV,2) ;
  //str << "   doesnt work.";
  str << endl;
  Serial.print(str);
  
}

boolean t = true;
boolean f = false;

void loop() {
  volts();
  delay(900);
  
}
