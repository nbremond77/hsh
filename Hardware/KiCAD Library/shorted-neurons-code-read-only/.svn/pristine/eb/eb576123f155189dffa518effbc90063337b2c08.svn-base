// copied from forum at http://arduino.cc/forum/index.php/topic,53082.0.html near bottom of thread
// by jdubulator1

#include <SPI.h>

#define ADCSelectPin 11
#define HVenablePin 11

void setup()
{
  Serial.begin(9600);
  pinMode(ADCSelectPin,OUTPUT);
  digitalWrite(ADCSelectPin,HIGH);
  SPI.begin();
  SPI.setClockDivider(SPI_CLOCK_DIV8);
  analogReference(EXTERNAL);
}

#define AREFmv 3000
#define DEF12bits 4096
#define DEF10bits 1024
#define DEF12vR1 1000
#define DEF12vR2 5100
#define DEFmaxV 18300

// MAX6030 precision 3.000V reference
#define AREFvolts 3.000
#define AREFscaler 6.1  // divider ratio... 5.1k / 1k
//#define AREFmult 3735 // 3735 ~= 1000 * 3000 / 1024 * 5.1;
//#define AREFmult 4468 // 4468 ~= 1000 * 3000 / 1024 * 6.1;
#define AREFmult 2929 // 2929 ~= 1000 * 3000 / 1024 * 1;
#define AREFdiv 1000 // divide afterwards to get back to an INT
#define batteryThresholdMilliVolts 3550

#define adcChan 6

//long samplePeriod = 100;
uint16_t samplePeriod = 1000;
long nextTime = micros()+samplePeriod;
long timeTmp = micros();
long mv = 0;
long i = 0;

void loop()
{
  //i++;
  //nextTime = micros();
  
  //Serial.print(nextTime,DEC);
  //Serial.print(" - ");

//  digitalWrite(HVenablePin,HIGH);
  while(micros() < nextTime)
  {
    //timeTmp = micros();
    0;
  }
  
  nextTime = micros() + samplePeriod;
  //digitalWrite(HVenablePin,LOW);  
  
//  uint16_t sample0 = readADC(adcChan);
  Serial.print(nextTime, DEC);
//  Serial.print(", ");
//  Serial.print(i, DEC);
//  Serial.print(",raw=");
//  Serial.println(sample0,DEC);
  Serial.println(readADC(adcChan),DEC);
//readADC(adcChan);
//  mv = long(sample0) * AREFmult / AREFdiv;
  //mv = mv / AREFdiv;
//  Serial.print(",mv=");
//  Serial.println(mv);

}

byte commandMSB = 0x00;
byte msb = 0x00;
byte lsb = 0x00;

uint16_t readADC(int channel)
{
  uint16_t output;
  //Channel must be from 0 to 7
  //Shift bits to match datasheet for MCP3208
  commandMSB = B00000110;
  uint16_t commandBytes = (uint16_t) (commandMSB<<8|channel<<6);
  
  //Select ADC
  digitalWrite(ADCSelectPin, LOW);
  //send start bit and bit to specify single or differential mode (single mode chosen here)
  SPI.transfer((commandBytes>>8) & 0xff);

  msb = SPI.transfer((byte)commandBytes & 0xff) & B00001111;
  lsb = SPI.transfer(0x00);
  
  digitalWrite(ADCSelectPin,HIGH);
  

  // cast before shiting the byte
  return(((uint16_t) msb) <<8 | lsb);
}
