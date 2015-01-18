#include <OneWire.h>
#include <DS2438.h>

OneWire oneWire(7);

DeviceAddress hum1_addy = { 0x26, 0xC3, 0xD8, 0x0B, 0x01, 0x00, 0x00, 0xF8 };

ds2438 hum1(&oneWire, hum1_addy);



void setup(void)
{
  Serial.begin(9600);
  
  printAddress(hum1_addy);
  Serial.println();
  Serial.print("Initial config: ");
  Serial.println(hum1.readSetup(), BIN);
  hum1.writeSetup(0x00);
  Serial.print("New config: ");
  Serial.println(hum1.readSetup(), BIN);
  
  delay(1000);
}

void loop(void)
{
  printAddress(hum1_addy);
  Serial.print(" ");
  Serial.print(hum1.readTempF());
  Serial.print("F ");
  Serial.print(hum1.readVolt());
  Serial.print("v ");
  Serial.print(hum1.readHum());
  Serial.println("% RH");
  
  
  Serial.println();
}

// function to print a device address
void printAddress(DeviceAddress deviceAddress)
{
  for (uint8_t i = 0; i < 8; i++)
  {
    if (deviceAddress[i] < 16) Serial.print("0");
    Serial.print(deviceAddress[i], HEX);
    Serial.print(".");
  }
}
