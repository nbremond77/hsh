#include <OneWire.h>
#include <DS2409.h>

DeviceAddress sw1 = { 0x1f, 0x70, 0x66, 0x05, 0x00, 0x00, 0x00, 0x2d };
DeviceAddress sw2 = { 0x1f, 0x9d, 0x67, 0x05, 0x00, 0x00, 0x00, 0x83 };
DeviceAddress sw3 = { 0x1f, 0x4b, 0x67, 0x05, 0x00, 0x00, 0x00, 0xf5 };
DeviceAddress deviceAddress;

OneWire ow(4);
ds2409 mySwitch(&ow, sw1, sw2, sw3);

void setup(void) {
  Serial.begin(9600);
}

void loop(void)
{
  walkSw(&mySwitch);
}

void printAddress(uint8_t* deviceAddress)
{
  for (uint8_t i = 0; i < 8; i++) {
    if (deviceAddress[i] < 16) Serial.print("0");
    Serial.print(deviceAddress[i], HEX);
    Serial.print(".");
  }
}

void walkSw(ds2409* owSwitch)
{
  for (int i=0; i<6; i++) {
    owSwitch->port(i);
    Serial.print("Port ");
    Serial.println(i);
    while(ow.search(deviceAddress)) {
      Serial.print("->");
      printAddress(deviceAddress);
      Serial.println();
    }
    delay(250);
  }
  
  Serial.println();
  delay(250);
}
  
