/*
 * MotorKnob
 *
 * A stepper motor follows the turns of a potentiometer
 * (or other sensor) on analog input 0.
 *
 * http://www.arduino.cc/en/Reference/Stepper
 */

#include <Stepper.h>

// change this to the number of steps on your motor
#define STEPS 20

// create an instance of the stepper class, specifying
// the number of steps of the motor and the pins it's
// attached to
Stepper stepper(STEPS, 7, 8, 9, 10);

// the previous reading from the analog input
int previous = 0;

#define BLUE 3
#define GREEN 4
#define RED 6


void setup()
{
  // set the speed of the motor to 30 RPMs
  stepper.setSpeed(1500);
  Serial.begin(57600);
  pinMode(RED, OUTPUT);
  pinMode(GREEN, OUTPUT);
  pinMode(BLUE, OUTPUT);
  pinMode(5, INPUT);
}

void loop()
{
  // get the sensor value
  int val = (analogRead(0) - 512) /8;
  delay(10);
  Serial.println(val);
  // move a number of steps equal to the change in the
  // sensor reading
  if ( val == previous ) {
    digitalWrite(RED, HIGH);
    digitalWrite(GREEN, LOW);
    digitalWrite(BLUE, LOW);
  } else {
      if ( val > previous ) {
        digitalWrite(RED, LOW);
        digitalWrite(GREEN, HIGH);
        digitalWrite(BLUE, LOW);
      } else {
          if ( val < previous ) {
            digitalWrite(RED, LOW);
            digitalWrite(GREEN, LOW);
            digitalWrite(BLUE, HIGH);
          }
      }  
  }
  stepper.step(val - previous);
  
  // remember the previous value of the sensor
  previous = val;
//  delay(20);
}
