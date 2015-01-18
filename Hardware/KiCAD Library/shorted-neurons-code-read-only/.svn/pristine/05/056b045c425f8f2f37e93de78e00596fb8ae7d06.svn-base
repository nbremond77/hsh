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
/*
    Part of this code is based off of Paul East's _1wireweatherstation.pde
    http://www.paulandkate.f2s.com/wordpress/wp-content/uploads/2009/01/_1wireweatherstation.pde
    I have tried to contact him to figure out what license he will be using
    but did not hear back. Paul, if you read this please contact me ;)
*/


#include "DS2450.h"

extern "C" {
  #include "WConstants.h"
}

ds2450::ds2450(OneWire* _oneWire, uint8_t* deviceAddress, int8_t vrange, int8_t rez, bool parasite, float vdiv)
{
  _wire = _oneWire;
  _deviceAddress = deviceAddress;
  _vrange = vrange;
  _rez = rez;
  _parasite = parasite;
  _vdiv = vdiv;
}

void ds2450::begin()
{
  if(!_parasite) {                // Not needed if using parasite power
    _wire->reset();
    _wire->write(SKIPROM, 0);      // skip ROM, no parasite power on at the end
    _wire->write(WRITEMEM, 0);     // Write memory
    _wire->write(0x1c, 0);         // write to 001c
    _wire->write(0x00, 0);         // Vcc operation
    _wire->write(0x40, 0);         // "
    _wire->read();                 // Read back 16 bit CRC
    _wire->read();                 // "
    _wire->read();                 // Read back verification bits
  }
  
  _wire->reset();
  _wire->select(_deviceAddress);   // skip ROM, no parasite power on at the end
  _wire->write(WRITEMEM,0);        // Write memory
  _wire->write(0x08,0);            // write start at 0008 (Channel A Control/Status)
  _wire->write(0x00,0);            // "


  _wire->write(_rez,0);            // 0008 (Channel A Control/Status) - _rez bits
  _wire->read();                   // Read back 16 bit CRC
  _wire->read();                   // "
  _wire->read();                   // check readback byte
   
  _wire->write(_vrange, 0);        // 0009 (Channel A Control/Status) - VDC range
  _wire->read();                   // Read back 16 bit CRC
  _wire->read();                   // "
  _wire->read();                   // check readback byte

  _wire->write(_rez, 0);           // 000A (Channel B Control/Status) - _rez bits
  _wire->read();                   // Read back 16 bit CRC
  _wire->read();                   // "
  _wire->read();                   // check readback byte
  
  _wire->write(_vrange, 0);        // 000B (Channel B Control/Status) - VDC range
  _wire->read();                   // Read back 16 bit CRC
  _wire->read();                   // "
  _wire->read();                   // check readback byte

  _wire->write(_rez, 0);           // 000C (Channel C Control/Status) - _rez bits
  _wire->read();                   // Read back 16 bit CRC
  _wire->read();                   // "
  _wire->read();                   // check readback byte
  
  _wire->write(_vrange, 0);        // 000D (Channel C Control/Status) - VDC range
  _wire->read();                   // Read back 16 bit CRC
  _wire->read();                   // "
  _wire->read();                   // check readback byte
  
  _wire->write(_rez, 0);           // 000E (Channel D Control/Status) - _rez bits
  _wire->read();                   // Read back 16 bit CRC
  _wire->read();                   // "
  _wire->read();                   // check readback byte
  
  _wire->write(_vrange, 0);        // 000F (Channel D Control/Status) - VDC range
  _wire->read();                   // Read back 16 bit CRC
  _wire->read();                   // "
  _wire->read();                   // check readback byte
}


void ds2450::measure()
{
  int8_t _HighByte, _LowByte;

  _wire->reset();
  _wire->select(_deviceAddress);       // select ds2450
  _wire->write(CONVERT, 0);            // start convert
  _wire->write(ALLCHANNELS, 0);        // all channels
  _wire->write(PRESETZERO, _parasite); // preset to all zeros, parasite?

  _wire->read();                       // Read back 16 bit CRC
  _wire->read();                       // "
  
  if (_parasite) delay(10);           // delay for convert pull-up if parasite

  while(1) {                          // check that conversion is complete
    if(_wire->read() == 0xff)
      break;
  }
  delay(1);
  _wire->reset();
  _wire->select(_deviceAddress);     // select ds2450
  _wire->write(READMEM, 0);          // read memory
  _wire->write(0x00, 0);             // start at channel A
  _wire->write(0x00, 0);             // locations 0000 and 0001

  //Channel A
  _LowByte = _wire->read();          // Get the low byte (0 if 8 bit resolution)
  _HighByte = _wire->read();         // Get the high byte
  _ChA = (((int16_t)_HighByte <<8) | _LowByte);

  //Channel B
  _LowByte = _wire->read();          // Get the low byte (0 if 8 bit resolution)
  _HighByte = _wire->read();         // Get the high byte 
  _ChB = (((int16_t)_HighByte <<8) | _LowByte);

  //Channel C
  _LowByte = _wire->read();          // Get the low byte (0 if 8 bit resolution)
  _HighByte = _wire->read();         // Get the high byte
  _ChC = (((int16_t)_HighByte <<8) | _LowByte);

  //Channel D
  _LowByte = _wire->read();          // Get the low byte (0 if 8 bit resolution)
  _HighByte = _wire->read();         // Get the high byte 
  _ChD = (((int16_t)_HighByte <<8) | _LowByte);
}

float ds2450::_calculateVoltage(int _val)
{
  /*
  //if voltage range = 2.56v
  if(_vrange == 0){
    return _val / _vdiv * 0.000039;
  }
  // if voltage range = 5.12v
  else if (_vrange == 1) {
    return _val / _vdiv * 0.000078;
  }
  */
    return _val;
}

float ds2450::voltChA(void)
{
  return _calculateVoltage(_ChA);
}

float ds2450::voltChB(void)
{
  return _calculateVoltage(_ChB);
}

float ds2450::voltChC(void)
{
  return _calculateVoltage(_ChC);
}

float ds2450::voltChD(void)
{
  return _calculateVoltage(_ChD);
}
