/* Code starts here - call it GPSLogger_v2.1 :) */

// this is a generic logger that does checksum testing so the data written should be always good
// Assumes a sirf III chipset logger attached to pin 0 and 1

#include "AF_SDLog.h"
#include "util.h"
#include <avr/pgmspace.h>
#include <avr/sleep.h>
#include <Streaming.h>
#include <PString.h>





// power saving modes
#define SLEEPDELAY 0
#define TURNOFFGPS 0
#define LOG_RMC_FIXONLY 1

AF_SDLog card;
File f;

#define led1Pin 9
#define led2Pin 7
#define powerPin 2

#define BUFFSIZE 75
char buffer[BUFFSIZE];
uint8_t bufferidx = 0;
uint8_t fix = 0; // current fix data
uint8_t i;



/**********************************
   DS18S20 Temperature chip i/o */
#include <OneWire.h>
OneWire ds(8);  // on pin 8
int qsensors, HighByte, LowByte, TReading, SignBit, Tc_100, Whole, Fract, Tf_100, fWhole, fFract;

byte smac[8];
float floaty = -32.86;

float getDS18B20_Celsius() {
  floaty = floaty + 0.01;
  byte i;
  byte present = 0;
  byte data[12];
  byte addr[8];
  
  if ( !ds.search(addr)) {
    Serial.print("No more sensors found on 1-wire bus.\n");
    ds.reset_search();
    delay(250);
    qsensors=0;
    return(-273.15);
  } else {
    qsensors++;
  }
  ds.search(addr);
  
  
  //dbgSerial.print("R=");
  for( i = 0; i < 8; i++) {
    //dbgSerial.print(addr[i], HEX);
    //dbgSerial.print(" ");
    smac[i] = addr[i];
  }

  if ( OneWire::crc8( addr, 7) != addr[7]) {
      Serial.print("sensor returned invalid CRC!\n");
      return(-273.16);
  }
  
  if ( addr[0] != 0x28) {
      Serial.print("discovered device is not a DS18B20 family device.\n");
      return(-273.17);
  }

  // The DallasTemperature library can do all this work for you!

  ds.reset();
  ds.select(addr);
  ds.write(0x44,1);         // start conversion, with parasite power on at the end
  delay(800);     // maybe 750ms is enough, maybe not
  // we might do a ds.depower() here, but the reset will take care of it.
  
  present = ds.reset();
  ds.select(addr);    
  ds.write(0xBE);         // Read Scratchpad

  //dbgSerial.print("P=");
  //dbgSerial.print(present,HEX);
  //dbgSerial.print(" ");
  for ( i = 0; i < 9; i++) {           // we need 9 bytes
    data[i] = ds.read();
    //dbgSerial.print(data[i], HEX);
    //dbgSerial.print(" ");
  }
//dbg  Serial.print(" CRC=");
//dbg  Serial.print( OneWire::crc8( data, 8), HEX);
//dbg  Serial.println();
  
  LowByte = data[0];
  HighByte = data[1];
  TReading = (HighByte << 8) + LowByte;
  SignBit = TReading & 0x8000;  // test most sig bit
  if (SignBit) // negative
  {
    TReading = (TReading ^ 0xffff) + 1; // 2's comp
  }

  Tc_100 = (6 * TReading) + TReading / 4;    // multiply by (100 * 0.0625) or 6.25

    if (SignBit) { // negative
    floaty = 0 - (float(Tc_100) / 100);
  } else {
    floaty = float(Tc_100) / 100;
  }
  
  //Serial << "floaty celsius reading is" << floaty << "." << endl;
  
  return(floaty);
}
float getDS18B20_Fahrenheit() {
  floaty = (getDS18B20_Celsius() * 9/5) + 32;
  //dbgSerial << "floaty fahrenheit reading is" << floaty << "." << endl;
  return(floaty);
}

void tempLoop(void) {
  floaty = floaty + 0.01;
  byte i;
  byte present = 0;
  byte data[12];
  byte addr[8];
  
  if ( !ds.search(addr)) {
    Serial.print("No more addresses.\n");
    ds.reset_search();
    delay(250);
    qsensors=0;
    return;
  } else {
    qsensors++;
  }
  ds.search(addr);
  
  
  //Serial.print("R=");
  for( i = 0; i < 8; i++) {
    Serial.print(addr[i], HEX);
    Serial.print(" ");
    smac[i] = addr[i];
  }

  if ( OneWire::crc8( addr, 7) != addr[7]) {
      Serial.print("CRC is not valid!\n");
      return;
  }
  
  if ( addr[0] != 0x28) {
      Serial.print("Device is not a DS18B20 family device.\n");
      return;
  }

  // The DallasTemperature library can do all this work for you!

  ds.reset();
  ds.select(addr);
  ds.write(0x44,1);         // start conversion, with parasite power on at the end
  delay(800);     // maybe 750ms is enough, maybe not
  // we might do a ds.depower() here, but the reset will take care of it.
  
  present = ds.reset();
  ds.select(addr);    
  ds.write(0xBE);         // Read Scratchpad

  //Serial.print("P=");
  //Serial.print(present,HEX);
  //Serial.print(" ");
  for ( i = 0; i < 9; i++) {           // we need 9 bytes
    data[i] = ds.read();
    //Serial.print(data[i], HEX);
    //Serial.print(" ");
  }
//  Serial.print(" CRC=");
//  Serial.print( OneWire::crc8( data, 8), HEX);
//  Serial.println();
  
  LowByte = data[0];
  HighByte = data[1];
  TReading = (HighByte << 8) + LowByte;
  SignBit = TReading & 0x8000;  // test most sig bit
  if (SignBit) // negative
  {
    TReading = (TReading ^ 0xffff) + 1; // 2's comp
  }

  Tc_100 = (6 * TReading) + TReading / 4;    // multiply by (100 * 0.0625) or 6.25

  //Tf_100 = Tc_100 * 9/5 + 3200;
  if (SignBit) { // negative
    floaty = 0 - (float(Tc_100) / 100);
  } else {
    floaty = float(Tc_100) / 100;
  }
  
  Serial << "floaty celsius reading is" << floaty << "." << endl;
  
  
  if (SignBit) { // negative
    floaty = ((0 - (float(Tc_100) / 100)) * 9/5) + 32;
  } else {
    floaty = ((float(Tc_100) / 100) * 9/5) + 32;
  }  

  Serial << "floaty fahrenheit reading is" << floaty << "." << endl;
/*
//  fWhole = (Tc_100/100) * 9/5 + 32;
  fWhole = Tf_100 / 100;
  fFract = Tf_100 % 100;

  Whole = Tc_100 / 100;  // separate off the whole and fractional portions
  Fract = Tc_100 % 100;
  

  if (SignBit) // If its negative
  {
     Serial.print("-");
  }
  Serial.print(Whole);
  Serial.print(".");
  if (Fract < 10)
  {
     Serial.print("0");
  }
  Serial.print(Fract);
  Serial.print("C, which is ");


  if (SignBit) // If its negative
  {
     Serial.print("-");
  }
  Serial.print(fWhole);
  Serial.print(".");
  if (fFract < 10)
  {
     Serial.print("0");
  }
  Serial.print(fFract);
  Serial.print("\n");
*/
}

/* END DS18S20 stuff */

/***********************************
 Generic Functions
*/
   
// read a Hex value and return the decimal equivalent
uint8_t parseHex(char c) {
  if (c < '0')
    return 0;
  if (c <= '9')
    return c - '0';
  if (c < 'A')
    return 0;
  if (c <= 'F')
    return (c - 'A')+10;
}

// blink out an error code
void error(uint8_t errno) {
  while(1) {
    for (i=0; i<errno; i++) {
      digitalWrite(led1Pin, HIGH);
      digitalWrite(led2Pin, HIGH);
      delay(100);
      digitalWrite(led1Pin, LOW);
      digitalWrite(led2Pin, LOW);
      delay(100);
    }
    for (; i<10; i++) {
      delay(200);
    }
  }
}

const int battSensePin =  3;      // *analog* battery woltage sense pin

void setup()
{
  Serial.begin(9600);
  putstring_nl("\r\nGPSlogger");
  pinMode(led1Pin, OUTPUT);
  pinMode(led2Pin, OUTPUT);
  pinMode(powerPin, OUTPUT);
  pinMode(battSensePin, INPUT);
  analogReference(DEFAULT);  
  
  digitalWrite(powerPin, LOW);
  sdCardSetup();
}

void sdCardSetup() {
  if (!card.init_card()) {
    putstring_nl("Card init. failed!");
    error(1);
  }
  if (!card.open_partition()) {
    putstring_nl("No partition!");
    error(2);
  }
  if (!card.open_filesys()) {
    putstring_nl("Can't open filesys");
    int foo = card.open_filesys();
    Serial.println(foo);
    error(3);
  }
  if (!card.open_dir("/")) {
    putstring_nl("Can't open /");
    error(4);
  }

  strcpy(buffer, "GPSLOG00.TXT");
  for (buffer[6] = '0'; buffer[6] <= '9'; buffer[6]++) {
    for (buffer[7] = '0'; buffer[7] <= '9'; buffer[7]++) {
      putstring("\ntrying to open ");Serial.println(buffer);
      f = card.open_file(buffer);
      if (!f)
        break;
      card.close_file(f);
    }
    if (!f)
      break;
  }

  if(!card.create_file(buffer)) {
    putstring("couldnt create ");
    Serial.println(buffer);
    error(5);
  }
  f = card.open_file(buffer);
  if (!f) {
    putstring("error opening ");
    Serial.println(buffer);
    card.close_file(f);
    error(6);
  }
  putstring("writing to ");
  Serial.println(buffer);
  putstring_nl("ready!");

  delay(250);
  
}


long iterations = 0;
long ts = millis();
PString str(buffer, sizeof(buffer));

int bv = 0;

void loop()
{
  str.begin();
  //Serial.println(Serial.available(), DEC);
  char c;
  uint8_t sum;
  // Serial.println("trying to read the sensor...");
//  tempLoop();
  iterations++;
  ts = millis() / 1000;
  //float temp = getDS18B20_Celsius();
  //Serial << "floaty celsius reading is " << temp << "C." << endl;
  float temp = getDS18B20_Fahrenheit();
  //Serial << "floaty fahrenheit reading is " << temp << "F" << endl;

  bv=analogRead(battSensePin);

  if (temp < -273 ) {
    Serial.println("poop, something is wrong, its absolute zero!.  Turning the heater off and skipping everything else.");
    digitalWrite(led1Pin, LOW); 
    return;
  }
  
  if (temp <80 ) {
    str << "uptime=" << ts << " sec, batt=" << bv << ", " << temp << "F is under 80, turning the \"heater\" on\n"; 
    digitalWrite(led1Pin, HIGH); 
  } else {
    str << "uptime=" << ts << " sec, batt=" << bv << ", " << temp << "F is >=80, turning the \"heater\" OFF\n"; 
    digitalWrite(led1Pin, LOW); 
    
  }
  
  Serial.print(str);
  buffer[str.length()+1] = 0; // terminate it
  if(card.write_file(f, (uint8_t *) buffer, str.length()) != str.length()) {
     putstring_nl("can't write!");
     return;
  }
  int i = 0;
  int ledState = LOW;
  for (i = 0; i <= 58; i++) {
    if (ledState == LOW)
      ledState = HIGH;
    else
      ledState = LOW;

    digitalWrite(led1Pin, ledState); 
    delay(1000);
  }

/*  // read one 'line'
  if (Serial.available()) {
    c = Serial.read();
    Serial.print(c, BYTE);
    if (bufferidx == 0) {
      while (c != '$')
        c = Serial.read(); // wait till we get a $
    }
    buffer[bufferidx] = c;

    Serial.print(c, BYTE);
    if (c == 'Z') {
      putstring_nl("EOL");
      Serial.print(buffer);
      buffer[bufferidx+1] = 0; // terminate it

      // rad. lets log it!
      Serial.print(buffer);
      Serial.print('#', BYTE);
      digitalWrite(led2Pin, HIGH);      // sets the digital pin as output

      if(card.write_file(f, (uint8_t *) buffer, bufferidx) != bufferidx) {
         putstring_nl("can't write!");
    return;
      }

      digitalWrite(led2Pin, LOW);

      bufferidx = 0;

      // turn off GPS module?

//      sleep_sec(SLEEPDELAY);

      return;
    }
    bufferidx++;
    if (bufferidx == BUFFSIZE-1) {
       Serial.print('!', BYTE);
       bufferidx = 0;
    }
  } else {

  }
*/


}

void sleep_sec(uint8_t x) {
  while (x--) {
     // set the WDT to wake us up!
    WDTCSR |= (1 << WDCE) | (1 << WDE); // enable watchdog & enable changing it
    WDTCSR = (1<< WDE) | (1 <<WDP2) | (1 << WDP1);
    WDTCSR |= (1<< WDIE);
    set_sleep_mode(SLEEP_MODE_PWR_DOWN);
    sleep_enable();
    sleep_mode();
    sleep_disable();
  }
}

SIGNAL(WDT_vect) {
  WDTCSR |= (1 << WDCE) | (1 << WDE);
  WDTCSR = 0;
}

/* End code */
