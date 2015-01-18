#ifndef DS2433_h
#define DS2433_h

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

#define DS2433MODEL 0x23

#define WRITESCRATCHPAD 0x0F
#define READSCRATCHPAD  0xAA
#define COPYSCRATCHPAD  0x55
#define READMEMORY      0xF0

typedef uint8_t DeviceAddress[8];

class ds2433
{
  public:
    ds2433(OneWire*, uint8_t*);
    bool writeMem(uint8_t*, int, uint8_t, uint8_t);
    void readMem(uint8_t*, uint8_t, uint8_t);

  private:
    OneWire* _wire;
    uint8_t* _deviceAddress;
};
#endif
