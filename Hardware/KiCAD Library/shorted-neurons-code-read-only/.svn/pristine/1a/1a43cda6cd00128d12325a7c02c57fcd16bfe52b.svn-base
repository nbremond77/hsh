#include <OneWire.h>
#include <DS2423.h>

DeviceAddress counter = { 0x1D, 0xE4, 0x7E, 0x01, 0x0, 0x0, 0x0, 0x76 };
//1D E4 7E 1 0 0 0 76

OneWire ow(8);
ds2423 myCounter(&ow, counter);


void setup(void)
{
  Serial.begin(57600);
}

void loop(void)
{ 
  Serial.println();
  Serial.print("Counter A: ");
  Serial.println(myCounter.readCounter(1));
  Serial.print("Counter B: ");
  Serial.println(myCounter.readCounter(2));
  
  
  delay(100);
}
