// This sketch demonstrates the use of the ADS1213 library by first initializing
// it with the neccesary parameters, then reading it every half second while cycling through the channels.

#include <ADS1213.h>

ADS1213 ADC_ext(2.0,false,13,11,2,0);
// clock speed MHz, true=offset binary (false=two's complement (can be negative)), SCLK pin, IO pin, DRDY pin, CS pin (0 if not in use)

void setup() {
  Serial.begin(115200);
  ADC_ext.CMRwrite(3,B001,1,1,255);
  // channel 3, mode 001 (self-calibration), gain 1, TMR 1, DR 255
  Serial.println("Done with setup");
}

void loop() {
  static byte Channel=1; // Static makes sure it doesn't get re-initialized every time
  Serial.print(Channel,DEC); Serial.print(" ch ");
  Serial.println(ADC_ext.readSigned(3),DEC); // Read and print the signed value
  Channel += 1;
  if (Channel>4) Channel = 1;
  ADC_ext.channel(Channel); // Set the current (incremented) channel by using the channel() function
  delay(500);
}
