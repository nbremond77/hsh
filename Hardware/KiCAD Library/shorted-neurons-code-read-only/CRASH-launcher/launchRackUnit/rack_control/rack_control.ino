 //Launch controller - rack

#include <JeeLib.h>
//#include <RF12.h>
//#include <Ports.h>

//hardware attributes
const unsigned int UART_SPD = 57600;
const unsigned int RF12_FREQ = RF12_433MHZ;
const byte RF12_NGRP = 212;
const byte RF12_RID = 0; //default to broadcast

//io pin definitions
//array order here is meaningful, channels 1-4 in order
//size of coil_select array determines channel count
const byte coil_select[] = {6,7};
const byte cont_sense[] = {4,5};
const byte safety_coil = 6;
const byte beep_init_pin = 9;
const byte link_led = 3;

//ATmega 168/328 PORTD mapping for fire coils
//order MUST map 1 to 1 to order of coil_select array
/*const byte coil_portd_map[] = {B00010000,
                              B00100000,
                              B01000000,
                              B10000000};
*/
const byte coil_portd_map[] = {B01000000,
                               B10000000};


//must map to pins defined in coil_select array
const byte coil_portd_alloff = B00001111;

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

MilliTimer sendTimer;

//controller status vars
boolean ok2fire = false;
byte status = status_safe;

int i = 0;

//legacy vars
char start_msg[] = "BLINK";
byte needToSend, remote_node, remote_pin, set_state;
int last_state = HIGH;


void setup () {
    //setup serial port
    Serial.begin(UART_SPD);
    Serial.println(UART_SPD);
    Serial.println("Send and Receive");

    //setup RFM12 comms
    rf12_initialize(1, RF12_FREQ, RF12_NGRP);
    
    //initialize channel select pins
    for (i = 0; i < sizeof(coil_select); i++) {
      pinMode(coil_select[i], OUTPUT);
      digitalWrite(coil_select[i], LOW);
    }
    
    //init safety pin
    pinMode(safety_coil, OUTPUT);
    digitalWrite(safety_coil, LOW);
    
    //set beep/init pin as init pin initially
    pinMode(beep_init_pin, INPUT);
    digitalWrite(beep_init_pin, HIGH);
  
    //init other outputs
    pinMode(link_led, OUTPUT);
    digitalWrite(link_led, LOW);
    
    //ensure safe mode
    status = status_safe;
    if (!disarm()) {
      //error!
    }
    //while (!check_safety_key()) {
    //}
    
    //run self diags
    //check_battery()
    
    //find any currently initialized rack units
    //enum_racks()
}

void loop () {
  char *remote_pin_hex;
  
/*    if (Serial.available() >= 3) {
        //Serial.println("Got serial input");
        rf12_config();
        remote_node = Serial.read();
        remote_pin = Serial.read();
        set_state = Serial.read();
        remote_node = remote_node - '0';
        remote_pin = remote_pin - '0';
        needToSend = 1;
    } else if (digitalRead(4) == LOW) {
        remote_node = 0x21;

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
        remote_node = 0x21;

        if (digitalRead(7) == LOW)
          remote_pin = 0x7;
        else
          remote_pin = 0x8;

        set_state = 'l';
        last_state = HIGH;
        needToSend = 1;
    } */

    if (rf12_recvDone() && rf12_crc == 0) {
        //receiveLed(1);
        Serial.println("Got data");
        if (rf12_len != 8)
          Serial.println("Error: wrong byte count");
        else {
          Serial.print("OK ");
          for (byte i = 0; i < rf12_len; ++i)
              Serial.print(rf12_data[i]);
          Serial.println();
          if (rf12_data[0] == 1 && rf12_data[3] == rf12_data[4] && rf12_data[3]) {
/*            switch (rf12_data[7]) {
              case 'H':
                digitalWrite(rf12_data[6], HIGH);
                break;
              case 'l':
                digitalWrite(rf12_data[6], LOW);
                break;
              default:
                Serial.println("Error: Incorrect status");
            } */
            if (rf12_data[2] == cmd_arm && status == status_safe) {
              if (!arm()) {
                //error!
              }
            } else if (rf12_data[2] == cmd_fire && status == status_both_armed) {
              if (!engage(rf12_data[3], rf12_data[4])) {
                //error!
              }
            } else if (rf12_data[2] == cmd_fire) {
              PORTD = rf12_data[3];
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
    }
}
