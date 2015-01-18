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

#ifndef __GPS_H__
#define __GPS_H__

class Gps
{
public:
  Gps();
  bool encode(char c); // process one character received from GPS
  Gps &operator << (char c) {encode(c); return *this;}

  const char *get_time() { return _rmc_time; }
  const char *get_date() { return _date; }
  const char *get_lat() { return _lat; }
  const char *get_lon() { return _lon; }
  const char *get_course() { return _course; }
  const char *get_speed() { return _speed; }
  const char *get_altitude() { return _altitude; }
  
private:
  enum {_GPS_SENTENCE_GPGGA, _GPS_SENTENCE_GPRMC, _GPS_SENTENCE_OTHER};
    
  // properties
  char _rmc_time[8], _gga_time[8], _new_time[8];
  char _date[7], _new_date[7];
  char _lat[9], _new_lat[9];
  char _lon[10], _new_lon[10];
  char _course[4], _new_course[4];
  char _speed[4], _new_speed[4];
  char _altitude[7], _new_altitude[7];

  unsigned long _last_time_fix, _new_time_fix;
  unsigned long _last_position_fix, _new_position_fix;
  
  // parsing state variables
  unsigned char _parity;
  bool _is_checksum_term;
  char _term[15];
  unsigned char _sentence_type;
  unsigned char _term_number;
  unsigned char _term_offset;
  bool _gps_fixed;
  
  // internal utilities
  int from_hex(char a);
  unsigned long parse_decimal();
  bool term_complete();
  bool gps_isdigit(char c) { return c >= '0' && c <= '9'; }
  long gps_atol(const char *str);
  void left_pad(char *dst, const char *src, int dst_len);
  void left_pad(char *dst, long val, int dst_len);
  void truncate(char *dst, const char *src);
};


#endif
