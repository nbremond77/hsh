/* FreqCount - Example with serial output
 * http://www.pjrc.com/teensy/td_libs_FreqCount.html
 *
 * This example code is in the public domain.
 */
#include <WProgram.h>
#include <FreqCount.h>
#include <Wire.h>

// Set the TMP Address and Resolution here
int tmpAddress = B1001000;
int ResolutionBits = 12;

#define rhSensorPower 4 // pin D7 in arduinospeak

void setup() {
  Serial.begin(57600);
  Wire.begin();        // join i2c bus (address optional for master)
  SetResolution();
  pinMode(rhSensorPower, OUTPUT);
  
}




// Display TMP100 readout to serial
// Fork Robotics 2012
//





float getTemperature(){
  Wire.requestFrom(tmpAddress,2);
  byte MSB = Wire.receive();
  byte LSB = Wire.receive();

  int TemperatureSum = ((MSB << 8) | LSB) >> 4;

  float celsius = TemperatureSum*0.0625;
  float fahrenheit = (1.8 * celsius) + 32;

  Serial.print(" temp=");
  Serial.print(celsius);
  Serial.print("C, ");
  Serial.print(fahrenheit);
  Serial.print("F");
}

void SetResolution(){
  if (ResolutionBits < 9 || ResolutionBits > 12) exit;
  Wire.beginTransmission(tmpAddress);
  Wire.send(B00000001); //addresses the configuration register
  Wire.send((ResolutionBits-9) << 5); //writes the resolution bits
  Wire.endTransmission();

  Wire.beginTransmission(tmpAddress); //resets to reading the temperature
  Wire.send((byte)0x00);
  Wire.endTransmission();
}







int ops=0;
void loop() {


  digitalWrite(rhSensorPower, HIGH);  

  FreqCount.begin(1000);
  delay(2500);
  if (FreqCount.available()) {
    unsigned long count = FreqCount.read();
    ops++;
    Serial.print("ops=");
    Serial.print(ops);

    getTemperature();
    //Serial.print(", frequency= ");
    //Serial.print(count);
    
    //Serial.print("Hz, RH = ");
    Serial.print(", RH = ");
    Serial.print( ( (float) (7658-count)*364)/4096.0);
    Serial.println("%");

  }
  FreqCount.end();
  digitalWrite(rhSensorPower, LOW);
  delay(10000);
  //delay(500);
}

