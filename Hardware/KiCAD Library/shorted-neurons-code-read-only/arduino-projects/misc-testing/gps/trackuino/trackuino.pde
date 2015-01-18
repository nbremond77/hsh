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

// Trackuino custom libs
#include "aprs.h"
#include "ax25.h"
#include "config.h"
#include "debug.h"
#include "gps.h"
#include "modem.h"
#include "radio.h"
#include "radio_hx1.h"
#include "radio_mx146.h"
#include "sensors.h"

// Arduino/AVR libs
#include <Wire.h>
#include <WProgram.h>
#include <avr/power.h>
#include <avr/sleep.h>

Gps gps;
unsigned long next_tx_millis;

void disable_bod_and_sleep()
{
  /* This will turn off brown-out detection while
   * sleeping. Unfortunately this won't work in IDLE mode.
   * Relevant info about BOD disabling: datasheet p.44
   *
   * Procedure to disable the BOD:
   *
   * 1. BODSE and BODS must be set to 1
   * 2. Turn BODSE to 0
   * 3. BODS will automatically turn 0 after 4 cycles
   *
   * The catch is that we *must* go to sleep between 2
   * and 3, ie. just before BODS turns 0.
   */
  unsigned char mcucr;

  cli();
  mcucr = MCUCR | (_BV(BODS) | _BV(BODSE));
  MCUCR = mcucr;
  MCUCR = mcucr & (~_BV(BODSE));
  sei();
  sleep_mode();    // Go to sleep
}

void power_save()
{
  /* Enter power saving mode. SLEEP_MODE_IDLE is the least saving
   * mode, but it's the only one that will keep the UART running.
   * In addition, we need timer0 to keep track of time and timer2
   * to keep pwm output at its rest voltage.
   */

  set_sleep_mode(SLEEP_MODE_IDLE);
  sleep_enable();
  power_adc_disable();
  power_spi_disable();
  power_twi_disable();
  if (! modem_busy()) {  // Don't let timer 1 sleep if we're txing.
    power_timer1_disable();
  }

  sleep_mode();    // Go to sleep
  
  sleep_disable();  // Resume after wake up
  power_all_enable();
}


void setup()
{
  Serial.begin(9600);
  modem_setup();
  sensors_setup();
  next_tx_millis = millis() + APRS_DELAY;
}

void loop()
{
  int c;
  bool valid_gps_data;

  if (millis() >= next_tx_millis) {
    aprs_send(gps);
    next_tx_millis = millis() + APRS_PERIOD;
  }
  
  if (Serial.available()) {
    c = Serial.read();
    valid_gps_data = gps.encode(c);
  } else {
    power_save();
  }
}

