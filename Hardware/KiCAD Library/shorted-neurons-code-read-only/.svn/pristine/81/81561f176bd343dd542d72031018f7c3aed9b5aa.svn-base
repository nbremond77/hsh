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

#include "DS2433.h"

extern "C" {
  #include "WConstants.h"
}

ds2433::ds2433(OneWire* _oneWire, uint8_t* deviceAddress)
{
  _wire = _oneWire;
  _deviceAddress = deviceAddress;
}


bool ds2433::writeMem(uint8_t* _memPage, int _pageSize, uint8_t _TA1, uint8_t _TA2)
{
  uint8_t myES; //store ES for auth
  
  _wire->reset();
  _wire->select(_deviceAddress);
  _wire->write(WRITESCRATCHPAD,0);
  _wire->write(_TA1, 0); //begin address
  _wire->write(_TA2, 0); //begin address
  //write _memPage to scratchpad  
  for (int i = 0; i < _pageSize; i++) {
    _wire->write(_memPage[i], 0);
  }
  
  //read and check data in scratchpad
  _wire->reset();
  _wire->select(_deviceAddress);
  _wire->write(READSCRATCHPAD,0);
  if (_wire->read() != _TA1) { //check TA1, return if bad
    return 0;
  }
  if (_wire->read() != _TA2) { //check TA2, return if bad
    return 0;
  }
  myES = _wire->read(); // ES Register
  //check data written
  for (int i = 0; i < _pageSize; i++) {
    if (_wire->read() != _memPage[i]) { //return if bad
      return 0;
    }
  }

  //issue copy with auth data
  _wire->reset();
  _wire->select(_deviceAddress);
  _wire->write(COPYSCRATCHPAD, 0);
  _wire->write(_TA1, 0);
  _wire->write(_TA2, 0);
  _wire->write(myES, 1); //pull-up!
  delay(10); //5ms min strong pullup delay
  
  _wire->reset(); //just in case...
  return 1;
}


void ds2433::readMem(uint8_t* _memAll, uint8_t _TA1, uint8_t _TA2)
{
  uint8_t tmpReader;
  bool readFF = 0;
  
  _wire->reset();
  _wire->select(_deviceAddress);
  _wire->write(READMEMORY, 0);
  _wire->write(_TA1, 0);
  _wire->write(_TA2, 0);
  for (int memPtr = 0; memPtr < 512; memPtr++) {
    tmpReader = _wire->read();
    if (tmpReader == 0xff & !readFF)
      readFF = 1;
    else if (tmpReader == 0xff & readFF)
      // 0xff read twice, hopefully EoF as we break here :)
      break;
      
    _memAll[memPtr] = tmpReader;
  }


}
