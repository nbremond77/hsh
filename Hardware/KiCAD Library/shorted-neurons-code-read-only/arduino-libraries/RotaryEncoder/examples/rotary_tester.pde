#include "RotaryEncoder.h"

RotaryEncoder knob(6,10,9);

int periodCount = 0;

void setup() {
  Serial.begin(57600);
}


void loop() {
  Serial.print("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\brotary:");
        periodCount += knob.checkRotaryEncoder();
        //knob.checkRotaryEncoder();
  Serial.print(periodCount);
  Serial.print("         ");
}
