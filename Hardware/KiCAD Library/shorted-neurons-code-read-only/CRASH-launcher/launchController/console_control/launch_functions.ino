#include "launch_functions.h"

boolean is_safe(void) {
  if (digitalRead(safety_pin) == HIGH)
    return true;
  else
    return false;
}

boolean check_fire(void) {
  if (digitalRead(fire_pin) == LOW)
    return true;
  else
    return false;
}

byte read_rack_switch(void) {
  //read analog voltage on rack_select pin
  //return rackID associated with voltage

  //need to allow some room for variation in resistor values
  //minimum 10% variance, probably 15% for typical 5% resistors?
  
  //use #defines to allow implementation of functions to handle
  //different selection methods, such as a rotary encoder?
  return 1;
}

void read_select_sws(byte *state) {
  *state = 0;

  for (i = 0; i < sizeof(chan_select); i++) {
    if (digitalRead(chan_select[i]) == LOW)
      bitWrite(*state, chan_select[i], 1);
  }
}

void set_select_leds(byte *state) {
  for (i = 0; i < sizeof(chan_select); i++) {
    if (bitRead(*state, chan_select[i]))
      digitalWrite(cont_leds[i], HIGH);
    else
      digitalWrite(cont_leds[i], LOW);
  }
}

boolean arm(void) {
  return true;
}

boolean disarm(void) {
  return true;
}

void launch(byte rack, byte *state) {
  remote_node = 0x1;
  byte state_mask;
  byte tx_interval = 10;
  byte blink_interval = 30;
  long last_tx = 0;
  long last_blink = 0;
  long curr_millis = 0;
  
  byte header = 0 | RF12_HDR_DST | remote_node;
  //byte payload[8];
  
  read_select_sws(&state_mask);

//  for (i = 0; i < sizeof(chan_select) - 1; i++) {
//    if (bitRead(*state, chan_select[i])) {}
//  }

  byte payload[] = {rack, 0, cmd_fire, *state, state_mask, 0, 0, 0};
  
  while (check_fire() && !is_safe()) {
    curr_millis = millis();
    if (curr_millis - last_tx > tx_interval) {
      if (rf12_recvDone() && rf12_crc == 0) { }
      if (rf12_canSend())
        rf12_sendStart(header, payload, sizeof payload);
      last_tx = millis();
    }
    
    if (curr_millis - last_blink > blink_interval) {
      if (curr_millis - last_blink > blink_interval * 2) {
        set_select_leds(&zero);
        last_blink = millis();
      } else {
        set_select_leds(state);
      }
    }
  }
  payload[3] = 1;
  payload[4] = 1;
  for (i = 0; i < 10; i++) {
    if (rf12_recvDone() && rf12_crc == 0) { }
    if (rf12_canSend())
      rf12_sendStart(header, payload, sizeof payload);
    delay(3);
  }
}
