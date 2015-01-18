#ifndef RotaryEncoder_h
#define RotaryEncoder_h

#include "Arduino.h"


class RotaryEncoder
{
  public:
    //static uint8_t begin(void);
    //RotaryEncoder(uint8_t h1pin, uint8_t h2pin, uint8_t h3pin);
    RotaryEncoder(uint8_t h1pin, uint8_t h2pin, uint8_t h3pin, boolean twitchy=false);
    int checkRotaryEncoder();

  private:
    uint8_t _h1pin;
    uint8_t _h2pin;
    uint8_t _h3pin;
    boolean _twitchy;
    int _lastRotary;
    int _nowRotary;
    int _lastf;

};

#endif
