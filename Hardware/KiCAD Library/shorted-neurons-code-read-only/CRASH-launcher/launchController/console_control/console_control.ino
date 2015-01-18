//Launch controller - console

#include <JeeLib.h>
//#include <RF12.h>
//#include <Ports.h>

#include "launch_functions.h"

//hardware attributes
const unsigned int UART_SPD = 57600;
const unsigned int RF12_FREQ = RF12_433MHZ;
const byte RF12_NGRP = 212;
const byte RF12_RID = 21;

//io pin definitions
//array order here is meaningful, channels 1-4 in order
//size of chan_select array determines channel count
const byte chan_select[] = {6, 7};
const byte cont_leds[] = {18, 19};
const byte safety_pin = 3;
const byte fire_pin = 4;
const byte beep_init_pin = 9;
const byte link_led = 5;
const byte rack_select = A0;

//command codes
const byte cmd_init = 0x01;
const byte cmd_status = 0x10;
const byte cmd_arm = 0x20;
const byte cmd_fire = 0x30;
const byte cmd_fault = 0x70;
const byte cmd_safe = 0xFF;

//param codes
const word arg_init_start = 0x1010;
const word arg_init_ack = 0x1020;
const word arg_status = 0x0000;
const word arg_safe = 0xFFFF;

//status codes
const byte status_safe = 0xFF;
const byte status_console_armed = 0x20;
const byte status_both_armed = 0x21;
const byte status_firing = 0x30;

byte zero = 0;

MilliTimer sendTimer;

//controller status vars
boolean ok2fire = false;
byte status = status_safe;
//byte chan_state[sizeof(chan_select)];
byte chan_state;

int i = 0;

//legacy vars
char start_msg[] = "BLINK";
byte needToSend, remote_node, remote_pin, set_state;
int last_state = HIGH;
int low_count = 10;


void setup () {
    //setup serial port
    Serial.begin(UART_SPD);
    Serial.println(UART_SPD);
    Serial.println("Send and Receive");

    //setup RFM12 comms
    rf12_initialize(2, RF12_FREQ, RF12_NGRP);
    
    //init arrays
//    for (i = 0; i < sizeof(chan_select) - 1; i++) {
//      chan_state[i] = 0;
//    }

    //initialize channel select pins
    for (i = 0; i < sizeof(chan_select); i++) {
      pinMode(chan_select[i], INPUT);
      digitalWrite(chan_select[i], HIGH);
    }
    
    //init safe, fire pins
    pinMode(safety_pin, INPUT);
    digitalWrite(safety_pin, HIGH);
    pinMode(fire_pin, INPUT);
    digitalWrite(fire_pin, HIGH);
    
    //set beep/init pin as init pin initially
    pinMode(beep_init_pin, INPUT);
    digitalWrite(beep_init_pin, HIGH);

    //init continuity indicator pins
    for (i = 0; i < sizeof(cont_leds); i++) {
      pinMode(cont_leds[i], OUTPUT);
      digitalWrite(cont_leds[i], LOW);
    }
    
    //init other outputs
    pinMode(link_led, OUTPUT);
    digitalWrite(link_led, LOW);
    
    //ensure safe mode
    status = status_safe;
    while (!is_safe()) {
    }
    
    //run self diags
    //check_battery()

    //find any currently initialized rack units
    //enum_racks()
}

void loop () {
  byte rackID = 0;
  
  if (is_safe() && status != status_safe) {
    status = status_safe;
    set_select_leds(&zero);
    digitalWrite(link_led, LOW);                                                                                                                                                                                                                                                                                                                                  
    //  safe all 3x
  }
  
  //if (no initialzed racks || init pressed)
  //  init(selected rack)
  //else
  //  if time to broadcast UUID/RID
  //    broadcast rack info
  //  if time for status check
  //    for (each rack)
  //      check status(rackID)
      if (!is_safe()) {
        status = status_console_armed;
        Serial.println("not safe");
        if (check_fire()) {
          while (check_fire() && !is_safe()) {
  //      wait for fire button release
          }
        }
        while (!is_safe()) {
          rackID = read_rack_switch();
          read_select_sws(&chan_state);
          set_select_leds(&chan_state);
          digitalWrite(link_led, HIGH);
  //      transmit armed to rackID
  //      loop until status = status_both_armed || 50ms elapsed
  //        if response
  //          if (!validate ack)
  //            error()
  //          status = status_both_armed
  //          response failed = 0
  //          update display (solid = good cont, blink = bad cont + selected, off = no cont + not selected)
  //      end loop
  //      if status != status_both_armed
  //        if (response failed++ > threshold)
  //          error()
  //      else if same rack and channels still selected
            while (check_fire()) {
              Serial.println("          firing");
              if (chan_state) {
                status = status_firing;
                launch(rackID, &chan_state);
              }
            }
  //      else -- (rack and/or channels changed)
  //        disarm current rack
  //        status = status_console_armed
  //    end while
          }
        }
  
/*  char *remote_pin_hex;
  
    if (Serial.available() >= 3) {
        //Serial.println("Got serial input");
        //rf12_config();
        remote_node = Serial.read();
        remote_pin = Serial.read();
        set_state = Serial.read();
        remote_node = remote_node - '0';
        remote_pin = remote_pin - '0';
        needToSend = 1;
    } else if (digitalRead(4) == LOW) {
        remote_node = 0x1;
        low_count = 10;

        if (digitalRead(7) == LOW)
          remote_pin = 0x7;
        else if (digitalRead(8) == LOW)
          remote_pin = 0x8;
        else {
          remote_pin = 0;
          needToSend = 0;
        }

        if (remote_pin) {
          set_state = 'H';
          last_state = LOW;
          needToSend = 1;
        }
    } else if (last_state == LOW) {
        delay(10);
        remote_node = 0x1;

        if (digitalRead(7) == LOW)
          remote_pin = 0x7;
        else
          remote_pin = 0x8;

        set_state = 'l';
        if (--low_count > 0)
          needToSend = 1;
        else {
          last_state = HIGH;
          needToSend = 0;
          low_count = 10;
        }
    }

    if (rf12_recvDone() && rf12_crc == 0) {
        //receiveLed(1);
        if (rf12_len != 8)
          Serial.println("Error: wrong byte count");
        else {
          Serial.print("OK ");
          for (byte i = 0; i < rf12_len; ++i)
              Serial.print(rf12_data[i]);
          Serial.println();
          if (rf12_data[5] == 2 && rf12_data[6] > 2 && rf12_data[6] <= 9) {
            switch (rf12_data[7]) {
              case 'H':
                digitalWrite(rf12_data[6], HIGH);
                break;
              case 'l':
                digitalWrite(rf12_data[6], LOW);
                break;
              default:
                Serial.println("Error: Incorrect status");
            }
          }
            
          //delay(100); // otherwise led blinking isn't visible
          //receiveLed(0);
        }
    }
    
    //if (sendTimer.poll(700))
    //    needToSend = 1;

    if (needToSend && rf12_canSend()) {
        //Serial.println("Preparing to send");
        needToSend = 0;
        
        //sendLed(1);

        byte header = 0 | RF12_HDR_DST | remote_node;
        char payload[] = {'B', 'L', 'I', 'N', 'K', remote_node, remote_pin, set_state};
        Serial.print("Sending: ");
        Serial.print(header);
        for (byte i = 0; i < 8; ++i)
            Serial.print(payload[i]);
        Serial.println();
        rf12_sendStart(header, payload, sizeof payload);

//        rf12_sendStart(0, payload, sizeof payload);
        //delay(100); // otherwise led blinking isn't visible
        //sendLed(0);
        //Serial.println("Sent");
        //Serial.print(last_state);
    } */
}
