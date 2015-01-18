#define ADCSelectPin 17
void setup() {
  SPI.begin();
  SPI.setClockDivider(SPI_CLOCK_DIV4);  // 2MHz SPI clock if 8MHz system    
  
  Serial.begin(SERIAL_BAUD_RATE);

  pinMode(ADCSelectPin,OUTPUT);
  digitalWrite(ADCSelectPin,HIGH);
  analogReference(EXTERNAL);
}



/************************************************
   MCP3208 ADC chip over SPI bus ... 
*/
byte commandMSB = 0x00;
byte msb = 0x00;
byte lsb = 0x00;

uint16_t readADC(int channel) {

  uint16_t output;
  //Channel must be from 0 to 7
  //Shift bits to match datasheet for MCP3208
  commandMSB = B00000110;
  uint16_t commandBytes = (uint16_t) (commandMSB<<8|channel<<6);

  //Select ADC
  noInterrupts();
  digitalWrite(ADCSelectPin, LOW);
  //send start bit and bit to specify single or differential mode (single mode chosen here)
  SPI.transfer((commandBytes>>8) & 0xff);

  msb = SPI.transfer((byte)commandBytes & 0xff) & B00001111;
  lsb = SPI.transfer(0x00);
  //msb=0xBE;
  //lsb=0xEF;
  digitalWrite(ADCSelectPin,HIGH);
  interrupts();
  // cast before shiting the byte
  return(((uint16_t) msb) <<8 | lsb);

}


void loop () {
}

