#include "EEPROMserialization.h"
#include <EEPROM.h>


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

