// test how fast we can toggle an output pin on a MAX7312 GPIO chip

#include <Wire.h>

#define MAX7312_ADDR 0x20
byte shifterState = 0;

void digitalWriteGPIO(uint8_t pin, uint8_t pinstate) {
  /* 
  Serial.print("changing pin  ");
  Serial.print(pin, DEC);
  Serial.print(" to state ");
  Serial.println(pinstate, HEX);
  */ 
    
  if ( pin < 20 ) {
    digitalWrite(pin, pinstate);
  } else {
    // Q0 on shift register = fake pin 20,
    // so subtract 20 to get register bit position
    pin = pin - 20;
    
    if (pinstate) { //HIGH
      shifterState |= (1 << pin);
    } else { //LOW
      shifterState &= ~(1 << pin);
    }

    Wire.beginTransmission(MAX7312_ADDR);
    Wire.send(0x02);
    Wire.send(shifterState);
    Wire.endTransmission();

  }
}



void setup () {
  //Serial.begin(57600);

  Wire.begin();
  Wire.beginTransmission(MAX7312_ADDR);
  Wire.send(0x06);
  Wire.send(0x00); // set port1 (0-7) to all outputs
  //Wire.send(0xFF); // set port2 (8-15) to all inputs 
  Wire.endTransmission();
  
}

void loop () {
  
  // takes ~660us for a full cycle, 50% duty cycle
  digitalWriteGPIO(13,HIGH);
  digitalWriteGPIO(13,LOW); 

}


