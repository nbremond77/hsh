/* derived from Adafruit  GPSLogger_v2.1  */

#include <Streaming.h>
#include <PString.h>
// Flash has to come after Streaming because of conflicting definition of endl
#include <Flash.h>

#define actLed 2


#define BUFFSIZE 80
char buffer[BUFFSIZE];
char buffer2[40];
uint8_t bufferidx = 0;
uint8_t fix = 0; // current fix data
uint8_t i;



/**********************************
   DS18S20 Temperature chip i/o */
   

#include <OneWire.h>
OneWire ds(15);  // on pin 8
int qsensors, HighByte, LowByte, TReading, SignBit, Tc_100, Whole, Fract, Tf_100, fWhole, fFract;
int dispSign = 0x0B;
byte smac[8];
float floaty = -32.86;


float getDS18B20_Celsius() {
  floaty = floaty + 0.01;
  byte i;
  byte present = 0;
  byte data[12];
  byte addr[8];
  
  if ( !ds.search(addr)) {
    Serial.print(F("No more sensors\n"));
    ds.reset_search();
    delay(250);
    qsensors=0;
    //return(-273.15);
    ds.search(addr); // do it again to get a usable sensor 
  } else {
    qsensors++;
  }
  
  
  
  Serial.print("R=");
  for( i = 0; i < 8; i++) {
    Serial.print(addr[i], HEX);
    Serial.print(" ");
    smac[i] = addr[i];
  }

  if ( OneWire::crc8( addr, 7) != addr[7]) {
      Serial.print(F("sensor returned invalid CRC!\n"));
      return(-273.16);
  }
  
  if (( addr[0] != 0x28) && ( addr[0] != 0x10)) {
      Serial.print(F("device is not a DS18x20 family device.\n"));
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
  // ds18b20 :
  //TReading = (HighByte << 8) + LowByte;
  //SignBit = TReading & 0x8000;  // test most sig bit
  
  //ds18s20
  TReading = LowByte >> 1;
  SignBit = HighByte & 0x80;
  boolean HalfBit = LowByte & 0x01;
  int Count_Remain = data[6];
  int Count_PerC = data[7];  
  
  // test most sig bit
  if (SignBit) // negative
  {
    TReading = (TReading ^ 0xffff) + 1; // 2's comp
  }

  //clearly i do not understand at which point the INT turns into a FLOAT
  //floaty = (float(TReading - 0.25)) + float(float(16 - float(Count_Remain))/ 16);
  floaty = ((float(TReading - 0.25)) + (16 - float(Count_Remain))/ 16);
  //Serial << "EARLY Floaty =                                     " << floaty << "  ";
  //Serial.println(Count_Remain, DEC);
  return(floaty);
  /*
  Serial << "TReading = " << TReading << endl;

  //ds18b20
  //Tc_100 = (6 * TReading) + TReading / 4;    // multiply by (100 * 0.0625) or 6.25
  
  //ds18s20
  Tc_100 = TReading;

  Serial << "Tc_100 = " << Tc_100 << endl;
  
  if (SignBit) { // negative
    floaty = 0 - float(Tc_100);
    dispSign = 0x0A;
    Tc_100 = 0 - Tc_100;
    if (HalfBit) {
      floaty = floaty - 0.5;
    }

  } else {
    floaty = float(Tc_100);
    dispSign = 0x0F;
    if (HalfBit) {
      floaty = floaty + 0.5;
    }
  }
  

  
  Serial << "floaty celsius reading is" << floaty << "." << endl;
  
  return(floaty);
  */
}


float getDS18B20_Fahrenheit() {
  floaty = (getDS18B20_Celsius() * 9/5) + 32;
  //Serial << "floaty fahrenheit reading is" << floaty << "." << endl;
  return(floaty);
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


// memory monitor crap

void chkMem() {
  Serial.print(F("chkMem free= "));
  Serial.print(availableMemory());
  Serial.print(F(", memory used="));
  Serial.println(2048-availableMemory());

}

int availableMemory() {
 int size = 2048;
 byte *buf;
 while ((buf = (byte *) malloc(--size)) == NULL);
 free(buf);
 return size;
} 

// end memory monitor crap



void setup()
{
  Serial.begin(57600);
  pinMode(actLed, OUTPUT);
  //pinMode(led2Pin, OUTPUT);
}


long iterations = 0;
long ts = millis();
PString str(buffer, sizeof(buffer));

int bv = 0;

void loop()
{
  //chkMem();
  str.begin();
  //Serial.println(Serial.available(), DEC);
  char c;
  uint8_t sum;
  //chkMem();
  // Serial.println(F("trying to read the sensor..."));
  //tempLoop();
  iterations++;
  ts = millis() / 1000;
  
  //float temp = getDS18B20_Celsius();
  //Serial << F("floaty celsius reading is ") << temp << F("C.") << endl;
  float temp = getDS18B20_Fahrenheit();
  Serial << F("floaty fahrenheit reading is ") << temp << F("F") << endl;
  /*
  Tf_100 = ((Tc_100 + (80 * (Tc_100 / 100)) + 3200));
  Serial.print("Tc_100 in main is ");
  Serial.println(Tc_100);

  Serial.print("Tf_100 is ");

  Serial.println(Tf_100);
  
  Serial.print(F("loop done "));
  Serial.println(iterations);
  */
}


/************************
    adafruit's idea of sleeping.  not sure i like it as much as other one above
    
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
*********** end adafruit sleeping **********/

/* EOF */
