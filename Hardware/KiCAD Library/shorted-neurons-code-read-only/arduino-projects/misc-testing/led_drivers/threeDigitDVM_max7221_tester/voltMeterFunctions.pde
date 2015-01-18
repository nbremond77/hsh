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
#define NUMBER_OF_SAMPLES 20
#define SAMPLE_WAIT 5

#define BUFFSIZE 200
char buffer[BUFFSIZE];
PString str(buffer, sizeof(buffer));

boolean errLast = false;

void voltMeterSetup() {                
  Serial.begin(115200); 
  pinMode(battSensePin, INPUT);
  analogReference(AREFSource);  
}
 
 
void volts() { 
  unsigned long bvRaw=analogRead(battSensePin);
  delay(2);
  bvRaw=0;
  for (short j=0; j < NUMBER_OF_SAMPLES; j++) {
    bvRaw+=analogRead(battSensePin);  // twice since first from ADC after wakeup is often noisy per datasheet
    delay(SAMPLE_WAIT);
  }
  
  bvRaw=(bvRaw/NUMBER_OF_SAMPLES);
    
  Serial << "bvRaw=" << bvRaw << endl;
  /* voltage in mV = raw reading * reference voltage / range * divider ratio */
  
  batteryMilliVolts = long(bvRaw) * AREFmult;
  Serial << ", battertMv=" << batteryMilliVolts;
  batteryMilliVolts = batteryMilliVolts / AREFdiv;
  // now adjust for diode drop
  int diodeDrop = SAMPLEDROP + (batteryMilliVolts / DROPFACTOR);
  Serial << ", diodeDrop=" << diodeDrop;

  batteryMilliVolts += diodeDrop;
  if (batteryMilliVolts < 380) batteryMilliVolts = 0;
  
  Serial << ", battertMv=" << batteryMilliVolts;
  //Serial << ", batteryV=" << (batteryMilliVolts/1000) << "." << ((batteryMilliVolts % 1000) /10) << endl; 
  Serial << ", batteryV=" << (batteryMilliVolts/1000) << "." 
         << ((batteryMilliVolts % 1000) / 100) 
         << ((batteryMilliVolts % 100) / 10) 
         << endl;
         //<< (batteryMilliVolts % 10) << endl; 

  if (batteryMilliVolts < 16500) {
    dvmError=false;
    if (batteryMilliVolts < 10000) {
      digits[0] = (batteryMilliVolts % 10000) / 1000;
      digits[1] = (batteryMilliVolts % 1000) / 100;
      digits[2] = (batteryMilliVolts % 100) / 10;
      decimalA=B00000001;
      decimalB=B00000000;    
      Serial << ", batteryV=" << char(digits[0])
           << "." 
           << digits[1]
           << digits[2]
           << endl;
  
    } else {
      digits[0] = batteryMilliVolts/10000;
      digits[1] = (batteryMilliVolts % 10000) / 1000;
      digits[2] = (batteryMilliVolts % 1000) / 100;
      decimalA=B00000000;
      decimalB=B00000001;    
      Serial << ", batteryV=" << char(digits[0])
           << digits[1]
           << "." 
           << digits[2]
           << endl;
    }

  } else { // acceptable range...
    dvmError=true;
    if ( errLast ) {
      digits[0] = CHAR_SPACE;
      digits[1] = CHAR_o;
      digits[2] = CHAR_L;
    } else {
      digits[0] = CHAR_E;
      digits[1] = CHAR_r;
      digits[2] = CHAR_r;
    }
    errLast = !errLast;
    
  }
  //Serial.print(str);
  
}



