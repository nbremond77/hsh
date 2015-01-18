#include <OneWire.h>
#include <DS2433.h>

//typedef uint8_t DeviceAddress[8];
DeviceAddress MEM1 = { 0x23, 0xB0, 0x6B, 0xD2, 0x0, 0x0, 0x0, 0xC8 };

OneWire ow(4);
ds2433 my2433(&ow, MEM1);


//4kB = 512kb -- we only have 2kB sram!
//1 page = 256b (32B), 16 pages
byte memAll[512]; // 512B < hw limit
//byte memAll[32];
byte memPage[32]; // 32B

void setup(void)
{
  Serial.begin(9600);
}

void loop(void)
{ 
  memPage[0] = 0xde;
  memPage[1] = 0xad;
  memPage[2] = 0xbe;
  memPage[3] = 0xef;
  memPage[4] = 0xfe;
  memPage[5] = 0xed;

  Serial.println("\nwriting:");
  Serial.print(memPage[0], HEX);
  Serial.print(memPage[1], HEX);
  Serial.print(memPage[2], HEX);
  Serial.print(memPage[3], HEX);
  Serial.print(memPage[4], HEX);
  Serial.print(memPage[5], HEX);
  if(my2433.writeMem(memPage, 6, 0x00, 0x00)) {
    Serial.println("\nreading");
    my2433.readMem(memAll, 0x00, 0x00);
    Serial.print(memAll[0], HEX);
    Serial.print(memAll[1], HEX);
    Serial.print(memAll[2], HEX);
    Serial.print(memAll[3], HEX);
    Serial.print(memAll[4], HEX);
    Serial.print(memAll[5], HEX);
  }
  else 
    Serial.println("write failed");
  
  Serial.println();
  delay(500);
  
}
