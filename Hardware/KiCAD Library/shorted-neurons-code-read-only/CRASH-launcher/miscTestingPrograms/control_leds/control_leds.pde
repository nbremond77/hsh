// Demo of a sketch which sends and receives packets
// 2010-05-17 <jcw@equi4.com> http://opensource.org/licenses/mit-license.php
// $Id: pingPong.pde 5655 2010-05-17 16:13:35Z jcw $

// with thanks to Peter G for creating a test sketch and pointing out the issue
// see http://news.jeelabs.org/2010/05/20/a-subtle-rf12-detail/

#include <RF12.h>
#include <Ports.h>
#define safetySw 3
#define buzzerPin 9
Port leds (1);
MilliTimer sendTimer;
char start_msg[] = "BLINK";
byte needToSend, remote_pin, set_state;
int last_state = HIGH;
int low_count = 10;

byte remote_node = 0x15;

static void sendLed (byte on) {
    leds.mode(OUTPUT);
    leds.digiWrite(on);
}

static void receiveLed (byte on) {
    leds.mode2(OUTPUT);
    leds.digiWrite2(!on); // inverse, because LED is tied to VCC
}

void setup () {
    Serial.begin(57600);
    Serial.println(57600);
    Serial.println("Send and Receive");
    rf12_initialize(2, RF12_433MHZ, 212);
    
    pinMode(4,INPUT);
    digitalWrite(4, HIGH);
    pinMode(6,INPUT);
    digitalWrite(6, HIGH);
    pinMode(7,INPUT);
    digitalWrite(7, HIGH);
    pinMode(8,INPUT);
    digitalWrite(8, HIGH);
    pinMode(safetySw,INPUT);
    digitalWrite(safetySw, HIGH);
        pinMode(buzzerPin,OUTPUT);
    pinMode(5,OUTPUT);
    pinMode(6,OUTPUT);
}

void loop () {
  char *remote_pin_hex;
  if (!digitalRead(safetySw)) {
    digitalWrite(5,HIGH);
    digitalWrite(6,LOW);
    analogWrite(buzzerPin,128);
  } else {
    digitalWrite(5,LOW);
    digitalWrite(6,HIGH);
    analogWrite(buzzerPin,0);
  }
    if (Serial.available() >= 3) {
        //Serial.println("Got serial input");
        rf12_config();
        remote_node = Serial.read();
        remote_pin = Serial.read();
        set_state = Serial.read();
        remote_node = remote_node - '0';
        remote_pin = remote_pin - '0';
        needToSend = 1;
    } else if (digitalRead(4) == LOW  && !digitalRead(safetySw)) {
        Serial.println("fire button depressed");
        low_count = 10;
        analogWrite(buzzerPin,240);
        if (digitalRead(7) == LOW)
          remote_pin = 0x7;
        else if (digitalRead(6) == LOW)
          remote_pin = 0x6;
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
        

        if (digitalRead(7) == LOW)
          remote_pin = 0x7;
        else
          remote_pin = 0x6;

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
        Serial.println("Preparing to send");
        needToSend = 0;
        
        //sendLed(1);

        byte header = 0 | RF12_HDR_DST | remote_node;
        char payload[] = {'B', 'L', 'I', 'N', 'K', remote_node, remote_pin, set_state};
        Serial.println(remote_node, DEC);
        Serial.println(remote_pin, DEC);
        Serial.print("Sending: ");
        //Serial.print(header);
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
