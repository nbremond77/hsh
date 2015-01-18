#include "foobar.h"
#include <EEPROM.h>


template <class T> int EEPROM_writeAnything(int ee, const T& value)
{
    const byte* p = (const byte*)(const void*)&value;
    int i;
    for (i = 0; i < sizeof(value); i++)
	  EEPROM.write(ee++, *p++);
    return i;
}

template <class T> int EEPROM_readAnything(int ee, T& value)
{
    byte* p = (byte*)(void*)&value;
    int i;
    for (i = 0; i < sizeof(value); i++)
	  *p++ = EEPROM.read(ee++);
    return i;
}


/* Once your sketch has these two functions defined, you can now save and load whole arrays or structures of variables in a single call. You provide the first EEPROM address to be written, and the functions return how many bytes were transferred.
*/ 

struct config_t
{
    long alarm;
    int mode;
} configuration;

void setup()
{
    Serial.begin(57600);
    pinMode(3, INPUT)  ;
    digitalWrite(3, HIGH);
    EEPROM_readAnything(0, configuration);
    
    // ...
}
void loop()
{
    Serial.println(configuration.mode, DEC);
    Serial.println(configuration.alarm, DEC);
    
    // let the user adjust their alarm settings
    // let the user adjust their mode settings
    // ...
    delay(5);
    configuration.mode++;
    configuration.alarm--;
    
    // if they push the "Save" button, save their configuration
    if (digitalRead(3) == LOW) {
      Serial.println("saving!");
        EEPROM_writeAnything(0, configuration);
        delay(5000);
    }
}

