#include <Wire.h>
#include <Adafruit_MPL115A2.h>

Adafruit_MPL115A2 mpl115a2;

#define wdo 4
#define actled 13

void setup(void) 
{
  Serial.begin(57600);
  Serial.println("Hello!");
  
  Serial.println("Getting barometric pressure ...");
  mpl115a2.begin();
  
  pinMode(wdo, OUTPUT);
  pinMode(actled, OUTPUT);
  pinMode(12, INPUT);
  digitalWrite(12, HIGH); // pullup on
  digitalWrite(actled, HIGH);
  delay(500);
  digitalWrite(actled, LOW);
}

boolean flipstate = 0;
void flipWatchdog(void) {
  flipstate = !flipstate;
  digitalWrite(wdo,  flipstate);
}

void loop(void) 
{
  float pressureKPA = 0, temperatureC = 0;    

  mpl115a2.getPT(&pressureKPA,&temperatureC);
  Serial.print("Pressure (kPa): "); Serial.print(pressureKPA, 4); Serial.print(" kPa  ");
  Serial.print("Temp (*C): "); Serial.print(temperatureC, 1); Serial.println(" *C both measured together");
  
  pressureKPA = mpl115a2.getPressure();  
  //Serial.print("Pressure (kPa): "); Serial.print(pressureKPA, 4); Serial.println(" kPa");

  temperatureC = mpl115a2.getTemperature();  
  //Serial.print("Temp (*C): "); Serial.print(temperatureC, 1); Serial.println(" *C");
  
  while(digitalRead(12)){
    delay(500);
    flipWatchdog();
  }
 
  
}
