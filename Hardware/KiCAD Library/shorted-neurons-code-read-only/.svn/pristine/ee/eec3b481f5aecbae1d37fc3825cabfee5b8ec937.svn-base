//USE SPI TO CONTROL THE MAX7221 LED DRIVER
//THIS CODE EXAMPLES IMPLEMENTS A SIMPLE 4-DIGIT COUNTER

#define DATAOUT 11//MOSI
#define DATAIN 12//MISO - not used, but part of builtin SPI
#define SPICLOCK 13//sck
#define SLAVESELECT 4//ss

byte digit=1;
byte counterNumber1=0;
byte counterNumber10 = 0;
byte counterNumber100 = 0;
byte counterNumber1000 = 0;

///////////////////////////////////////////////////////////////////
//spi transfer function (from ATmega168 datasheet)
char spi_transfer(volatile char data)
{
  SPDR = data; // Start the transmission
  while (!(SPSR & (1<<SPIF))) // Wait the end of the transmission
  {
  };
  return SPDR; // return the received byte
}

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
byte write_7seg(int digAddress, int displayValue) //dig pot data transfer function
{
  digitalWrite(SLAVESELECT,LOW); //digital pot chip select is active low
  //2 byte data transfer to digital pot
  spi_transfer(digAddress);
  spi_transfer(displayValue);
  digitalWrite(SLAVESELECT,HIGH); //release chip, signal end transfer
}

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
void setup()
{
  byte i;
  byte clr;
  pinMode(DATAOUT, OUTPUT);
  pinMode(DATAIN, INPUT);
  pinMode(SPICLOCK,OUTPUT);
  pinMode(SLAVESELECT,OUTPUT);
  digitalWrite(SLAVESELECT,HIGH); //disable device

  ///////////////////////////////////////////////////////////////////
  // SPCR = 01010000
  //interrupt disabled,spi enabled,msb 1st,master,clk low when idle,
  //sample on leading edge of clk,system clock/4 (fastest)
  SPCR = (1<<SPE)|(1<<MSTR);
  clr=SPSR;
  clr=SPDR;
  delay(100);
  ///////////////////////////////////////////////////////////////////

  //clear 7221 and format to receive data
  write_7seg(0x0C,1);
  write_7seg(0x09,0xFF);
  write_7seg(0x0A,0x0F);
  write_7seg(0x0B,0x04);
}

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
void loop()
{
  do{
    write_7seg(1, counterNumber1000);
    counterNumber1000++;
    do{
      write_7seg(2, counterNumber100);
      counterNumber100++;
      do{
        write_7seg(3, counterNumber10);
        counterNumber10++;
        do{
          write_7seg(4, counterNumber1);
          delay (100);
          counterNumber1++;
        }
        while (counterNumber1<10);
        counterNumber1 = 0;
      }
      while (counterNumber10<10);
      counterNumber10 = 0;
    }
    while (counterNumber100<10);
    counterNumber100 = 0;
  }
  while (counterNumber1000<10);
  counterNumber1000 = 0;
}

