
// MCP23S17 SPI 16-bit IO expander
// http://ww1.microchip.com/downloads/en/DeviceDoc/21952b.pdf

// For the cmd, AAA is the 3-bit MCP23S17 device hardware address.
// Useful for letting up to 8 chips sharing same SPI Chip select
// #define MCP23S17_READ  B0100AAA1 
// #define MCP23S17_WRITE B0100AAA0 

// The default SPI Control Register - SPCR = B01010000;
// interrupt disabled,spi enabled,msb 1st,master,clk low when idle,
// sample on leading edge of clk,system clock/4 rate (fastest).
// Enable the digital pins 11-13 for SPI (the MOSI,MISO,SPICLK)
#include <SPI.h>
#include "Mcp23s17.h"

//---------- constructor ----------------------------------------------------

MCP23S17::MCP23S17(uint8_t slave_select_pin)
{
  SPI.begin();
  //Serial.println("MCP23S17 default constructor 001");
  setup_ss(slave_select_pin);
  //Serial.println("MCP23S17 default constructor 002");
  setup_device(0x00);
  //Serial.println("MCP23S17 default constructor 003");
}

MCP23S17::MCP23S17(uint8_t slave_select_pin, byte aaa_hw_addr)
{
  SPI.begin();
  // Set the aaa hardware address for this chip by tying the 
  // MCP23S17's pins (A0, A1, and A2) to either 5v or GND.
  setup_ss(slave_select_pin);

  // We enable HAEN on all connected devices before we can address them individually
  setup_device(0x00);
  write_addr(IOCON, read_addr(IOCON)|HAEN);

  // Remember the hardware address for this chip
  setup_device(aaa_hw_addr);
}

//------------------ protected -----------------------------------------------

uint16_t MCP23S17::byte2uint16(byte high_byte, byte low_byte)
{
  return (uint16_t)high_byte<<8 | (uint16_t)low_byte;
}

byte MCP23S17::uint16_high_byte(uint16_t uint16)
{
  return (byte)(uint16>>8);
}

byte MCP23S17::uint16_low_byte(uint16_t uint16)
{
  return (byte)(uint16 & 0x00FF);
}

void MCP23S17::setup_ss(uint8_t slave_select_pin)
{
  // Set slave select (Chip Select) pin for SPI Bus, and start high (disabled)
  ::pinMode(slave_select_pin,OUTPUT);
  ::digitalWrite(slave_select_pin,HIGH);
  this->slave_select_pin = slave_select_pin;
}

void MCP23S17::setup_device(uint8_t aaa_hw_addr)
{
  //Serial.println("MCP23S17::setup_device 001");
  this->aaa_hw_addr = aaa_hw_addr;
  //Serial.println("MCP23S17::setup_device 002");
  this->read_cmd  = B01000000 | aaa_hw_addr<<1 | 1<<0; // MCP23S17_READ  = B0100AAA1 
  //Serial.println("MCP23S17::setup_device 003");
  this->write_cmd = B01000000 | aaa_hw_addr<<1 | 0<<0; // MCP23S17_WRITE = B0100AAA0
  //Serial.println("MCP23S17::setup_device 004");
  // write_addr(IOCON, read_addr(IOCON)|SEQOP); // no need to enable SEQOP if BANK=0
}

uint16_t MCP23S17::read_addr(byte addr)
{
  byte low_byte;
  byte high_byte;
  ::digitalWrite(slave_select_pin, LOW);
  SPI.transfer(read_cmd);
  SPI.transfer(addr);
  low_byte  = SPI.transfer(0x0/*dummy data for read*/);
  high_byte = SPI.transfer(0x0/*dummy data for read*/);
  ::digitalWrite(slave_select_pin, HIGH);
  return byte2uint16(high_byte,low_byte);
}

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
 
#define HORKON PORTB &= ~(1 << 0);
void MCP23S17::write_addr(byte addr, uint16_t data)
{
  //Serial.println("MCP23S17::write_addr 001");
  ::digitalWrite(slave_select_pin, LOW);
  //HORKON
  //PORTB &= ~(1 << 0);
  //delay(10);
  //Serial.println("MCP23S17::write_addr 002");
  SPI.transfer(write_cmd);
  //Serial.println("MCP23S17::write_addr 003");
  SPI.transfer(addr);
  //Serial.println("MCP23S17::write_addr 004");
  SPI.transfer(uint16_low_byte(data));
  //Serial.println("MCP23S17::write_addr 005");
  SPI.transfer(uint16_high_byte(data));
  //Serial.println("MCP23S17::write_addr 006");
  //PORTB |= (1 << 0);
  ::digitalWrite(slave_select_pin, HIGH);
  //Serial.println("MCP23S17::write_addr 007");
}

//---------- public ----------------------------------------------------

void MCP23S17::pinModeAll(bool mode)
{
  uint16_t input_pins;
  if(mode == INPUT)
    input_pins = 0xFFFF;
  else
    input_pins = 0x0000;

  write_addr(IODIR, input_pins);
}

void MCP23S17::pinMode(uint16_t value)
{
  write_addr(IODIR, value);
}


/* 
void MCP23S17::setPullups(bool mode)
{
  uint16_t input_pins;
  if(mode == INPUT)
    input_pins = 0xFFFF;
  else
    input_pins = 0x0000;

  write_addr(GPPU, input_pins);
}
*/

void MCP23S17::port(uint16_t value)
{
  write_addr(GPIO,value);
}


void MCP23S17::setPullups(uint16_t value)
{
  write_addr(GPPU,value);
}

void MCP23S17::setAllInputPolarity(uint16_t value)
{
  write_addr(IOPOL,value);
}


uint16_t MCP23S17::port()
{
  return read_addr(GPIO);
}

void MCP23S17::pinMode(uint8_t pin, bool mode)
{
  if(mode == INPUT)
    write_addr(IODIR, read_addr(IODIR) | 1<<pin );
  else
    write_addr(IODIR, read_addr(IODIR) & ~(1<<pin) );
}


void MCP23S17::setPullup(uint8_t pin, bool mode)
{
  if(mode == INPUT)
    write_addr(GPPU, read_addr(GPPU) | 1<<pin );
  else
    write_addr(GPPU, read_addr(GPPU) & ~(1<<pin) );
}

void MCP23S17::digitalWrite(uint8_t pin, bool value)
{
  if(value)
    write_addr(GPIO, read_addr(GPIO) | 1<<pin );  
  else
    write_addr(GPIO, read_addr(GPIO) & ~(1<<pin) );  
}

int MCP23S17::digitalRead(uint8_t pin)
{
  (int)(read_addr(GPIO) & 1<<pin);
}



