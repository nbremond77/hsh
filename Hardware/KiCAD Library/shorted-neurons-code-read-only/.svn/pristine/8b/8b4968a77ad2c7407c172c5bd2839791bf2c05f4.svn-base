/* trackuino copyright (C) 2010  EA5HAV Javi
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

/* Big credit to Mikal Hart and: http://arduiniana.org/libraries/tinygps/,
 * from which most of the code has been taken.
 */

#include "gps.h"
#include <WProgram.h>
#include <string.h>

#define _GPRMC_TERM   "GPRMC"
#define _GPGGA_TERM   "GPGGA"

Gps::Gps()
:  _parity(0)
,  _is_checksum_term(false)
,  _sentence_type(_GPS_SENTENCE_OTHER)
,  _term_number(0)
,  _term_offset(0)
,  _gps_fixed(false)
{
  strcpy(_lat, "0000.00N");
  strcpy(_lon, "00000.00W");
  strcpy(_course, "000");
  strcpy(_speed, "000");
  strcpy(_altitude, "000000");
  strcpy(_date, "010180");
  strcpy(_rmc_time, "000000h");
  strcpy(_gga_time, "000000h");
  _term[0] = '\0';
}

//
// public methods
//

bool Gps::encode(char c)
{
  bool valid_sentence = false;

  switch(c)
  {
    case ',': // term terminators
      _parity ^= c;
    case '\r':
    case '\n':
    case '*':
      if (_term_offset < sizeof(_term))
      {
        _term[_term_offset] = 0;
        valid_sentence = term_complete();
      }
      ++_term_number;
      _term_offset = 0;
      _is_checksum_term = c == '*';
      return valid_sentence;
      
    case '$': // sentence begin
      _term_number = _term_offset = 0;
      _parity = 0;
      _sentence_type = _GPS_SENTENCE_OTHER;
      _is_checksum_term = false;
      _gps_fixed = false;
      return valid_sentence;
  }
  
  // ordinary characters
  if (_term_offset < sizeof(_term) - 1)
    _term[_term_offset++] = c;
  if (!_is_checksum_term)
    _parity ^= c;
  
  return valid_sentence;
}


//
// internal utilities
//
int Gps::from_hex(char a) 
{
  if (a >= 'A' && a <= 'F')
    return a - 'A' + 10;
  else if (a >= 'a' && a <= 'f')
    return a - 'a' + 10;
  else
    return a - '0';
}

void Gps::truncate(char *dst, const char *src)
{
  int i;
  for (i = 0; src[i] && src[i] != '.'; i++) {
    dst[i] = src[i];
  }
  dst[i] = '\0';  
}


// TODO: rewrite this so that it doesn't pad with a final 0 (like left_pad(..., long))
void Gps::left_pad(char *dst, const char *src, int dst_len)
{
  int src_len = strlen(src);
    
  if (dst_len < src_len) {
    // Overflow: fill up with nines
    while (dst_len) dst[--dst_len] = '9';
  } else {
    while (src_len) dst[--dst_len] = src[--src_len];
    while (dst_len) dst[--dst_len] = '0';
  }
}

void Gps::left_pad(char *dst, long val, int dst_len)
{
  while (dst_len--) {
    dst[dst_len] = (val % 10) + '0';
    val /= 10;
  }
}


unsigned long Gps::parse_decimal()
{
  char *p = _term;
  bool isneg = *p == '-';
  if (isneg) ++p;
  unsigned long ret = 100UL * gps_atol(p);
  while (gps_isdigit(*p)) ++p;
  if (*p == '.')
  {
    if (gps_isdigit(p[1]))
    {
      ret += 10 * (p[1] - '0');
      if (gps_isdigit(p[2]))
        ret += p[2] - '0';
    }
  }
  return isneg ? -ret : ret;
}

long Gps::gps_atol(const char *str)
{
  long ret = 0;
  while (gps_isdigit(*str))
    ret = 10 * ret + *str++ - '0';
  return ret;
}


// Processes a just-completed term
// Returns true if new sentence has just passed checksum test and is validated
bool Gps::term_complete()
{
  if (_is_checksum_term)
  {
    unsigned char checksum = 16 * from_hex(_term[0]) + from_hex(_term[1]);
    if (checksum == _parity)
    {
      if (_gps_fixed)
      {
        _last_time_fix = _new_time_fix;
        _last_position_fix = _new_position_fix;
        
        switch(_sentence_type)
        {
          case _GPS_SENTENCE_GPRMC:
            strcpy(_rmc_time, _new_time);
            strcpy(_date,     _new_date);
            strcpy(_lat,      _new_lat);
            strcpy(_lon,      _new_lon);
            strcpy(_speed,    _new_speed);
            strcpy(_course,   _new_course);
            break;
          case _GPS_SENTENCE_GPGGA:
            strcpy(_gga_time, _new_time);
            strcpy(_lat,      _new_lat);
            strcpy(_lon,      _new_lon);
            strcpy(_altitude, _new_altitude);
            break;
        }
        
        // Return a valid object only when we've got two rmc and gga
        // messages with the same timestamp
        if (! strcmp(_gga_time, _rmc_time))
          return true;
      }
    }
    return false;
  }
  
  // the first term determines the sentence type
  if (_term_number == 0)
  {
    if (!strcmp(_term, _GPRMC_TERM))
      _sentence_type = _GPS_SENTENCE_GPRMC;
    else if (!strcmp(_term, _GPGGA_TERM))
      _sentence_type = _GPS_SENTENCE_GPGGA;
    else
      _sentence_type = _GPS_SENTENCE_OTHER;
    return false;
  }
  
  if (_sentence_type != _GPS_SENTENCE_OTHER && _term[0])
    switch((_sentence_type == _GPS_SENTENCE_GPGGA ? 200 : 100) + _term_number)
  {
    case 101: // Time in both sentences
    case 201:
      strncpy(_new_time, _term, 6);
      _new_time[6] = 'h';
      _new_time[7] = '\0';
      _new_time_fix = millis();
      break;
    case 102: // GPRMC validity ('A'=fixed, 'V'=no fix yet)
      _gps_fixed = _term[0] == 'A';
      break;
    case 103: // Latitude
    case 202:
      strncpy(_new_lat, _term, 7);  // APRS format: 3020.12N (DD, MM.MM, Hemisphere)
      _new_lat[7] = '\0';
      _new_position_fix = millis();
      break;
    case 104: // N/S
    case 203:
      _new_lat[7] = _term[0];
      _new_lat[8] = '\0';
      break;
    case 105: // Longitude
    case 204:
      strncpy(_new_lon, _term, 8);  // APRS format: 00143.13W (DD, MM.MM, Hemisphere)
      _new_lon[8] = '\0';
      break;
    case 106: // E/W
    case 205:
      _new_lon[8] = _term[0];
      _new_lon[9] = '\0';
      break;
    case 107: // Speed (GPRMC)
      // TODO: This is highly dependant on the venus 634 flpx GPS, where course/speed
      // is already left-padded with zeros. 
      strncpy(_new_speed, _term, 3);
      _new_speed[3] = '\0';
      break;
    case 108: // Course (GPRMC)
      strncpy(_new_course, _term, 3);
      _new_course[3] = '\0';
      break;
    case 109: // Date (GPRMC)
      strncpy(_new_date, _term, 6);
      _new_date[6] = '\0';
      break;
    case 206: // Fix data (GPGGA)
      _gps_fixed = _term[0] > '0';
      break;
    case 209: // Altitude (GPGGA)
      long altitude = parse_decimal();  // altitude in cm
      // 10000 ft = 3048 m
      // x ft = altitude mt --> x = 100 * altitude (in cm) / 3048
      altitude = (altitude * 25) / 762;  // APRS needs feet
      left_pad(_new_altitude, altitude, 6);
      _new_altitude[6] = '\0';
      break;
  }
  
  return false;
}
