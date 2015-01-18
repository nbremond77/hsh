/*
  RotaryEncoder - abstraction for grey-code rotary encoders
 Copyright (c) 2011 Bryan Schmidt.  All rights reserved.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */


#include "Arduino.h"
#include "RotaryEncoder.h"
/*
RotaryEncoder::RotaryEncoder(uint8_t h1pin, uint8_t h2pin, uint8_t h3pin) {
	RotaryEncoder::RotaryEncoder(h1pin, h2pin, h3pin, false);
}
*/

RotaryEncoder::RotaryEncoder(uint8_t h1pin, uint8_t h2pin, uint8_t h3pin, boolean twitchy) {
  _h1pin = h1pin;
  _h2pin = h2pin;
  _h3pin = h3pin;
  _twitchy = twitchy;

  pinMode(_h1pin, INPUT); 
  pinMode(_h2pin, INPUT);
  pinMode(_h3pin, INPUT);

  digitalWrite(_h1pin, HIGH);
  digitalWrite(_h2pin, HIGH);
  digitalWrite(_h3pin, HIGH);

  _lastRotary = 0;
  _nowRotary = 0;
  _lastf = 0;

}


int RotaryEncoder::checkRotaryEncoder() {

  boolean h1 = (digitalRead(_h1pin));
  boolean h2 = (digitalRead(_h2pin));
  boolean h3 = (digitalRead(_h3pin));
  int r = 0;

  /* 
   so we have a rotary encoder^H^H^H^H^H^H^H^H^H^H cdrom-drive motor,
   with three Hall-effect sensors, which are hooked up to comparator
   gates.  What we wind up with is a truth table that can tell you
   whether we are moving or not, AND which direction, naturally 
   important for use as a human interface control.
   
   So each hall effect is boolean output of the comparator, and we put em
   all together into _nowRotary.  Apparently its little-endian :-)
   h1    0   0   0   0   1   1   1   1
   h2    0   0   1   1   0   0   1   1
   h3    0   1   0   1   0   1   0   1
   ---------------------------------------
   now    0   1   2   3   4   5   6   7
   
   
   #define h1pin 2
   #define h2pin 16
   #define h3pin 15
   001
   011
   010
   110
   100
   101
   
   */

  _nowRotary = ((h3 << 2) | (h2 << 1) | h1);

  int f = 0;

  if (_nowRotary == _lastRotary) {
    // dont bother solving the whole thing if we didnt move
    return(0);
  } 
  else {

    //Serial.print("according to cminus,   now = ");
    //Serial.println(_nowRotary);     
    if (_nowRotary > _lastRotary) f = 1;
    if (_nowRotary < _lastRotary) f = -1;

    if ( _twitchy ) {
      /* this switch() maps all unique states of the rotary.
       in most cases i find it twitchy and "too fast",
       sometimes bouncing around when magnet is in 
       just the right spot.
       
       See further down for the non-twitchy else-part
       */
      switch (_nowRotary) {
      case 0:
        f = 0;
        break;
      case 1:
        f = 1;
        break;
      case 5:
        f = 2;
        break;
      case 4:
        f = 3;
        break;
      case 6:
        f = 4;
        break;
      case 2:
        f = 5;
        break;
      case 3:
        f = 6;
        break;
      case 7:
        f = 7;
        break;
      }
      if (f > _lastf) r=1;
      if (f < _lastf) r=-1;
      if (f == _lastf) r=0;
      // two special cases, basically for overflow
      if (f == 0 && _lastf == 7) r=1;
      if (f == 7 && _lastf == 0) r=-1;

    } 
    else {
      /* NORMAL mode, not twitchy, we need two state changes to 
       actually be going in a direction 
       */
      switch (_nowRotary) {
        // cases are in the order in which they occur when 
        // rotating the thing.  used to map order into something 
        // that is actually in order.  need some fancy bit math 
        // i think to do better.
      case 1:
        f = 1;
        break;
      case 5:
        f = 1;
        break;
      case 4:
        f = 3;
        break;
      case 6:
        f = 3;
        break;
      case 2:
        f = 5;
        break;
      case 3:
        f = 5;
        break;
      } 

      if (f > _lastf) r=1;
      if (f < _lastf) r=-1;
      if (f == _lastf) r=0;
      // two special cases, basically for overflow
      if (f == 1 && _lastf == 5) r=1;
      if (f == 5 && _lastf == 1) r=-1;

    }

    _lastf = f;

    _lastRotary = _nowRotary;
    return(r);

  }  
}



