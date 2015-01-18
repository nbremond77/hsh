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


#include "DS2409.h"

extern "C" {
  #include "WConstants.h"
}

ds2409::ds2409(OneWire* _oneWire, uint8_t* sw1, uint8_t* sw2, uint8_t* sw3)
{
  _wire = _oneWire;
  _sw1 = sw1;
  _sw2 = sw2;
  _sw3 = sw3;
}

void ds2409::init(uint8_t* sw1, uint8_t* sw2, uint8_t* sw3)
{
  _sw1 = sw1;
  _sw2 = sw2;
  _sw3 = sw3;
}


//ports are: 0 = sw1-main, 1 = sw1-aux, 2 = sw2-main, etc
void ds2409::port(int port)
{
  switch(port) {
    case 0: // port sw1-main
      swCmd(_sw2, 0); // sw2 off
      swCmd(_sw3, 0); // sw3 off
      swCmd(_sw1, 2); // sw1 smart-on main
      break;

    case 1: // port sw1-aux
      swCmd(_sw2, 0); // sw2 off
      swCmd(_sw3, 0); // sw3 off
      swCmd(_sw1, 3); // sw1 smart-on aux
      break;

    case 2: // port sw2-main
      swCmd(_sw1, 0); // sw1 off
      swCmd(_sw3, 0); // sw3 off
      swCmd(_sw2, 2); // sw2 smart-on main
      break;
    
    case 3: // port sw2-aux
      swCmd(_sw1, 0); // sw1 off
      swCmd(_sw3, 0); // sw3 off
      swCmd(_sw2, 3); // sw2 smart-on aux
      break;

    case 4: // port sw3-main
      swCmd(_sw1, 0); // sw1 off
      swCmd(_sw2, 0); // sw2 off
      swCmd(_sw3, 2); // sw3 smart-on main
      break;
    
    case 5: // port sw3-aux
      swCmd(_sw1, 0); // sw1 off
      swCmd(_sw2, 0); // sw2 off
      swCmd(_sw3, 3); // sw3 smart-on aux
      break;
  }
}

void ds2409::swCmd(uint8_t* deviceAddress, int cmd)
{
  _wire->reset();
  _wire->select(deviceAddress);

  switch(cmd) {
    case 0: // All lines off
      _wire->write(ALLOFF, 0);
      _wire->read();             // Confirmation byte
      break;

    case 1: // Direct-On Main
      _wire->write(DIRECTMAIN, 0);
      _wire->read();            // Confirmation byte
      break;

    case 2: // Smart-On Main
      _wire->write(SMARTMAIN, 0);
      _wire->write(0xff, 0);   // reset stimulus
      _wire->read();           // 00h or 01h if devices present, ffh if none
      _wire->read();           // Confirmation byte
      break;

    case 3: // Smart-On Aux
      _wire->write(SMARTAUX, 0);
      _wire->write(0xff, 0);   // reset stimulus
      _wire->read();           // 00h or 01h if devices present, ffh if none
      _wire->read();           // Confirmation byte
      break;

    case 4: //Discharge Lines
      _wire->write(DISCHARGE, 0);
      _wire->read();           // Confirmation byte;
      break;
  }
}
