/*
  ADS1213.h - Library for communication with Texas Instruments ADS1213 Analog-to-Digital converter
  Created by Fons de Leeuw, April 19, 2011
  Released into the public domain.
*/

#ifndef ADS1213_h
#define ADS1213_h

#if defined(ARDUINO) && ARDUINO >= 100
#include "Arduino.h"
#else
#include "WProgram.h"
#endif

class ADS1213
{
  public:
    ADS1213(float clockspdMHz, boolean OffsetBin, byte SCLK, byte IO, byte DRDY, byte CS);

    void write(byte adr,byte count,byte val[]);
    void CMRwrite(byte channel,byte mode=0,byte gain=0,byte TMR=0,int DR=0);
    void channel(byte channel);

    unsigned long read(byte adr, byte count);
    unsigned long read(byte adr, byte count, boolean sync);
    long readSigned(byte count);

    void reset();
  private:
    int _tscaler;
    byte _SCLK;
    byte _IO;
    byte _DRDY;
    byte _CS;
    byte _SCLKdelay;
};

#endif