#include <OneWire.h>
#include <DS2450.h>

DeviceAddress HVAC = { 0x20, 0x6F, 0xCD, 0x13, 0x0, 0x0, 0x0, 0x76 };
int vrange = 0;        // 0 = 2.56v, 1 = 5.12v
int rez = 8;           // rez = 0-f bits where 0 = 16
bool parasite = 1;     // parasite power?
float vdiv = 0.9;      // voltage divider circuit value?


OneWire oneWire(4);
ds2450 my2450(&oneWire, HVAC, vrange, rez, parasite, vdiv);

void setup(void) {
  Serial.begin(9600);
  my2450.begin();
}

void loop(void) {
  my2450.measure();
  Serial.print("chA = ");
  Serial.println((int)my2450.voltChA());
}
