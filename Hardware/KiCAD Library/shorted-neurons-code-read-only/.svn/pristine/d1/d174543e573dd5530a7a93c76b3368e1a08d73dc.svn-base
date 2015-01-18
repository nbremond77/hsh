/*
  ADS1213.h - Library for communication with Texas Instruments ADS1213 Analog-to-Digital converter
  Created by Fons de Leeuw, April 19, 2011
  Released into the public domain.
*/

#if defined(ARDUINO) && ARDUINO >= 100
#include "Arduino.h"
#else
#include "WProgram.h"
#endif

#include "ADS1213.h"

ADS1213::ADS1213(float clockspdMHz, boolean OffsetBin, byte SCLK, byte IO, byte DRDY, byte CS)
{
  _tscaler = (clockspdMHz)*10;
  _SCLKdelay = 5*10/_tscaler+1;
  
  if (SCLK<8 || SCLK>13 || IO<8 || IO>13 || DRDY<2 || DRDY>7) return;
  _SCLK = SCLK - 8;
  _IO = IO - 8;
  _DRDY = DRDY;
  _CS = CS;
  
  pinMode(SCLK, OUTPUT);
  if (CS != 0 && CS>=2 && CS<=13) pinMode(CS, OUTPUT);
  
  reset();
  byte CommandBytes[] = {B01000000,B00000000}; // Default except for self-calibration

  if (OffsetBin) {
    CommandBytes[0] |= 1<<5; // Sets offset binary if true
  }
  write(B0100,2,CommandBytes);
}


void ADS1213::write(byte adr,byte count,byte val[])
{
  byte insr_byte = ((count-1)<<5) | adr;

  while (!(PIND & _BV(_DRDY)));  // wait for ready to go high
  while (PIND & _BV(_DRDY));     // wait for ready to go low
  
  if (_CS) digitalWrite(_CS,LOW);
  
  // clock out instruction byte
  DDRB |= _BV(_IO); 
  delayMicroseconds(11*10/_tscaler+1); //t38// 11 x Xin
  for (byte mask = 0x80; mask; mask >>= 1) {
    if (mask & insr_byte) PORTB |= _BV(_IO); else PORTB &= ~_BV(_IO);
    PORTB |= _BV(_SCLK);
    delayMicroseconds(_SCLKdelay); //t10// 5 x Xin
    PORTB &= ~_BV(_SCLK);
    delayMicroseconds(_SCLKdelay); //t11// 5 x Xin
  }
  
  delayMicroseconds(13*10/_tscaler+1); //t19// 13 x Xin (t11 adds up)
  // clock out bits, MSB first
  for (byte i = 0; i < count; i++) { 
    for (byte mask = 0x80; mask; mask >>= 1) {
      if (mask & val[i]) PORTB |= _BV(_IO); else PORTB &= ~_BV(_IO);
      PORTB |= _BV(_SCLK);
      delayMicroseconds(_SCLKdelay); //t10// 5 x Xin
      PORTB &= ~_BV(_SCLK);
      delayMicroseconds(_SCLKdelay); //t11// 5 x Xin
    }
  }
  DDRB &= ~_BV(_IO);
  if (_CS) digitalWrite(_CS,HIGH);
}

void ADS1213::CMRwrite(byte channel,byte mode,byte gain,byte TMR,int DR)
{
  byte Byte[3];
  
  int _gain;
  switch (gain) {
    case 2: _gain = B001; break;
    case 4: _gain = B010; break;
    case 8: _gain = B011; break;
    case 16: _gain= B100; break;
    default: _gain = 0;
  }
  Byte[0] = mode<<5 | _gain<<2 | channel-1;
  
  byte _TMR;
  switch (TMR) {
    case 2: _TMR = B001; break;
    case 4: _TMR = B010; break;
    case 8: _TMR = B011; break;
    case 16: _TMR= B100; break;
    default: _TMR = 0;
  }
  Byte[1] = _TMR<<5 | DR>>8;
  Byte[2] = DR;
  write(B0101,3,Byte);
}

void ADS1213::channel(byte channel)
{
  byte WriteByte[] = {0};
  WriteByte[0] |= channel-1;
  write(B0101,1,WriteByte);
}


long ADS1213::readSigned(byte count)
{
  long ReadValue = read(B0000,count,true);
  switch (count) {
    case 3: if (ReadValue & 1L<<23) ReadValue |= 0xFF800000;; break;
    case 2: if (ReadValue & 1L<<15) ReadValue |= 0xFFFF8000;; break;
    case 1: if (ReadValue & 1L<<7) ReadValue |= 0xFFFFFF80;; break;
  }
  return ReadValue;
}

unsigned long ADS1213::read(byte adr, byte count)
{
  return read(adr,count,true);
}

unsigned long ADS1213::read(byte adr, byte count, boolean sync)
{
  unsigned long Value;
  byte insr_byte = B10000000 | ((count-1)<<5) | adr;
  
  if (sync) {
    while (!(PIND & _BV(_DRDY)));  // wait for ready to go high
    while (PIND & _BV(_DRDY));     // wait for ready to go low
  }
  if (_CS) digitalWrite(_CS,LOW);

  // clock out instruction byte
  DDRB |= _BV(_IO); 
  delayMicroseconds(6); //t38// 11 x Xin 
  for (byte mask = 0x80; mask; mask >>= 1) {
    if (mask & insr_byte) PORTB |= _BV(_IO); else PORTB &= ~_BV(_IO);
    PORTB |= _BV(_SCLK);
    delayMicroseconds(_SCLKdelay); //t10// 5 x Xin
    PORTB &= ~_BV(_SCLK);
    delayMicroseconds(_SCLKdelay); //t11// 5 x Xin
  }
  
  DDRB &= ~_BV(_IO);
  PORTB &= ~_BV(_IO);
  
  delayMicroseconds(13*10/_tscaler-_SCLKdelay); //t19// 13 x Xin (t11 adds up)
  Value = 0;
  for (byte j = 0; j < (8*count); j++) {
    PORTB |= _BV(_SCLK);
    delayMicroseconds(_SCLKdelay); //t10// 5 x Xin
    Value <<= 1;
    if (PINB & _BV(_IO)) Value |= 1;
    PORTB &= ~_BV(_SCLK);
    delayMicroseconds(_SCLKdelay); //t11// 5 x Xin
  }
  if (_CS) digitalWrite(_CS,HIGH);
  return Value;
}


void ADS1213::reset()
{
  PORTB |= _BV(_SCLK);
  delayMicroseconds(1024*10/_tscaler+1);  //t3// 1024 x Xin
  PORTB &= ~_BV(_SCLK);
  delayMicroseconds(10*10/_tscaler+1);//t2// 10 x Xin
  PORTB |= _BV(_SCLK);
  delayMicroseconds(512*10/_tscaler+1);  //t1// 512 x Xin
  PORTB &= ~_BV(_SCLK);
  delayMicroseconds(10*10/_tscaler+1);//t2//
  PORTB |= _BV(_SCLK);
  delayMicroseconds(1024*10/_tscaler+1); //t3// 1024 x Xin
  PORTB &= ~_BV(_SCLK);
  delayMicroseconds(10*10/_tscaler+1);//t2//
  PORTB |= _BV(_SCLK);
  delayMicroseconds(2048*10/_tscaler+1); //t4// 2048 x Xin
  PORTB &= ~_BV(_SCLK);
}