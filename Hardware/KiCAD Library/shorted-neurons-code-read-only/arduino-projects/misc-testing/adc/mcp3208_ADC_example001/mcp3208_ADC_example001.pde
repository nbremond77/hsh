// copied from forum at http://arduino.cc/forum/index.php/topic,53082.0.html near bottom of thread
// by jdubulator1

#include <SPI.h>

#define ADCSelectPin 17
#define HVenablePin 6

void setup()
{
  Serial.begin(57600);
  pinMode(ADCSelectPin,OUTPUT);
  digitalWrite(ADCSelectPin,HIGH);
  SPI.begin();
  SPI.setClockDivider(SPI_CLOCK_DIV8);
  analogReference(EXTERNAL);
  pinMode(A4, INPUT);
  digitalWrite(A4, LOW);
  pinMode(HVenablePin,OUTPUT);
  digitalWrite(HVenablePin,HIGH);  
  delay(1000);
  digitalWrite(HVenablePin,LOW);  
  delay(1000);
  digitalWrite(HVenablePin,HIGH);  
  delay(1000);
  digitalWrite(HVenablePin,LOW);  
  delay(1000);
  digitalWrite(HVenablePin,HIGH);  
  digitalWrite(HVenablePin,LOW);  
  
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
#define AREFmult 4468 // 4468 ~= 1000 * 3000 / 1024 * 6.1;
#define AREFdiv 1000 // divide afterwards to get back to an INT
#define batteryThresholdMilliVolts 3550

void loop()
{
  float time = micros();
  for(int i = 0;i<1000;i++)
  {
    readADC(0);
  }
  float time1 = micros();
  
  /* Serial.print((time1-time)/1000);
  Serial.print(" 0 = ");
  Serial.print(readADC(0),DEC);
  Serial.print("  1 = ");  
  Serial.print(readADC(1),DEC);
  Serial.print("  2 = ");
  Serial.print(readADC(2),DEC);
  Serial.print("  3 = ");
  Serial.print(readADC(3),DEC); */

  delay(5);
  uint16_t crap5 = readADC(1);
  delay(5);
  uint16_t crap3 = readADC(2);
  delay(5);
  uint16_t crap = analogRead(A4) ;
  delay(5);

  Serial.print("adc4=");
  Serial.print(crap3,DEC);
  uint16_t crap4 = crap3 >> 2;
  Serial.print(" shifted=");
  Serial.print(crap4);
  
  
  long mv = long(crap3) * AREFmult;
  mv = mv / AREFdiv;
  
  //float volts = float(crap3) * AREFvolts * AREFscaler / DEF12bits;
  
  Serial.print(" mv=");
  Serial.print(mv);
  //Serial.print(" V=");
  //Serial.print(volts,4);
  Serial.print(" mapped=");
  Serial.println(map(crap3,0,DEF12bits,0,DEFmaxV));


//
  Serial.print("adc5=");
  Serial.print(crap5,DEC);
  uint16_t crap6 = crap5 >> 2;
  Serial.print(" shifted=");
  Serial.print(crap6);
    
  mv = long(crap5) * AREFmult;
  mv = mv / AREFdiv;
  
  //volts = float(crap5) * AREFvolts * AREFscaler / DEF12bits;
  Serial.print(" mv=");
  Serial.print(mv);
  //Serial.print(" V=");
  //Serial.print(volts,4);
  Serial.print(" mapped=");
  Serial.println(map(crap5,0,DEF12bits,0,DEFmaxV));


//  
  uint16_t crap2 = crap << 2;
  Serial.print("  A4=");
  Serial.print(crap);
  Serial.print(" shifted=");
  Serial.print(crap2);
  
  mv = long(crap2) * AREFmult;
  mv = mv / AREFdiv;
  
  //volts = float(crap2) * AREFvolts * AREFscaler / DEF12bits;
  
  Serial.print(" mv=");
  Serial.print(mv);
  //Serial.print(" V=");
  //Serial.print(volts,4);
  Serial.print(" mapped=");
  Serial.println(map(crap2,0,DEF12bits,0,DEFmaxV));


 
//  mv = double(((crap * AREFmv) / DEF10bits) / (DEF12vR1 / (DEF12vR2+DEF12vR1)));

  /* Serial.print("  5 = ");
  Serial.print(readADC(5),DEC);
  Serial.print("  6 = ");
  Serial.print(readADC(6),DEC);
  Serial.print("  7 = ");
  Serial.print(readADC(7),DEC);
  delay(20);
  Serial.print("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");
  */
  Serial.println();
  delay(2000);
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
