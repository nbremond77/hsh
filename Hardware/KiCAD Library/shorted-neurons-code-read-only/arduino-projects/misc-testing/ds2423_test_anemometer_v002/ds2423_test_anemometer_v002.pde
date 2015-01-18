#include <OneWire.h>
#include <DS2423.h>

DeviceAddress counter = { 0x1D, 0xE4, 0x7E, 0x01, 0x0, 0x0, 0x0, 0x76 };
//1D E4 7E 1 0 0 0 76

OneWire ow(15);
ds2423 myCounter(&ow, counter);

/*
uint32_t a1 = 0;
uint32_t a2 = 0;
uint32_t b1 = 0;
uint32_t b2 = 0;
uint32_t diffA = 0;
uint32_t diffB = 0;
*/

signed int a1 = 0;
signed int a2 = 0;
signed int b1 = 0;
signed int b2 = 0;
int diffA = 0;
int diffB = 0;
int secondsPerSample = 1;
float cupRadius = 2.875; //radius of cup rotation in inches
float cupCirc = PI * (2 * cupRadius); //circumference in inches
float feetPerRev = cupCirc / 12;
#define mile 5280

void setup(void)
{
  Serial.begin(57600);
  Serial.print("\ncupRadius=");
  Serial.println(cupRadius, DEC);
  Serial.print("cupCirc=");
  Serial.println(cupCirc,DEC);
  Serial.print("feetPerRev=");
  Serial.println(feetPerRev,DEC);
  Serial.print("secondsPerSample=");
  Serial.println(secondsPerSample,DEC);
}



void loop(void)
{ 
  ow.reset();
  a1=(signed int)myCounter.readCounter(1);
  b1=(signed int)myCounter.readCounter(2);
  //delay(secondsPerSample * 1000);
  //delay(10);
  //a2=(signed int)myCounter.readCounter(1);
  //b2=(signed int)myCounter.readCounter(2);

  //diffA = abs (unsigned int)(a2-a1);
  //diffB = abs (unsigned int)(b2-b1);
  
  /* A and B each get one count per RPM, 
         therefore divide by two,
         multiply by 60 seconds in a minute,
         then divide by numer of seconds we sample
  */
  //float rpm = float((diffA + diffB) /2) * 60 / secondsPerSample;
  //float mph = rpm * feetPerRev * 60 / mile;
  //Serial.print("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");  
  Serial.print("a1=");
  Serial.print(a1,DEC);
  //Serial.print(",a2=");
  //Serial.print(a2,DEC);
  Serial.print(",b1=");
  Serial.print(b1,DEC);
  //Serial.print(",b2=");
  //Serial.print(b2,DEC);
  //Serial.print("  A=");
  //Serial.print(diffA);
  //Serial.print(", B=");
  //Serial.print(diffB);
  //Serial.print(", rpm=");
  //Serial.print(rpm);
  //Serial.print(", mph=");
  //Serial.print(mph);  
  Serial.println("             ");
  //delay(secondsPerSample * 1000);
  delay(100);
}
