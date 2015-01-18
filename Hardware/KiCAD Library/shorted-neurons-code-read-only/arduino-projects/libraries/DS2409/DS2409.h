#ifndef DS2409_h
#define DS2409_h

/*
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Copyright 2010 Guilherme Barros
*/



#include <OneWire.h>

#define DS2409MODEL 0x1f
#define DIRECTMAIN  0xa5
#define SMARTMAIN   0xcc
#define SMARTAUX    0x33
#define ALLOFF      0x66
#define DISCHARGE   0x99

typedef uint8_t DeviceAddress[8];

class ds2409
{
  public:
    ds2409(OneWire*, uint8_t*, uint8_t*, uint8_t*);
    void init(uint8_t*, uint8_t*, uint8_t*);
    void swCmd(uint8_t*, int);
    void port(int);

  private:
    OneWire* _wire;
    uint8_t* _sw1;
    uint8_t* _sw2;
    uint8_t* _sw3;
};
#endif
