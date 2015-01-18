
#define btnPin 13
#define BLUE 3
#define GREEN 4
#define RED 5
#define powerSw 7
#define focusSw 8
#define shutterSw 9
#define powerSwHoldTime 2000
#define warmupTime 5000
#define focusSwHoldTime 1200
#define shutterSwHoldTime 800
#define waitAfterExposure 10000
#define picPeriod 120000

void setup()
{
  Serial.begin(57600);
  pinMode(btnPin, INPUT);
  pinMode(RED, OUTPUT);
  pinMode(GREEN, OUTPUT);
  pinMode(BLUE, OUTPUT);
  pinMode(powerSw, OUTPUT);
  pinMode(focusSw, OUTPUT);
  pinMode(shutterSw, OUTPUT);
  digitalWrite(powerSw, LOW);
  digitalWrite(focusSw, HIGH);
  digitalWrite(shutterSw, HIGH);

}

void shoot() {
  Serial.println("shoot 001 - powering up the camera");
  digitalWrite(RED, HIGH);
  digitalWrite(powerSw, HIGH);
  delay(powerSwHoldTime);
  digitalWrite(RED, HIGH);
  digitalWrite(powerSw, LOW);
  Serial.println("shoot 002 - waiting for it to settle");
  delay(warmupTime);
  digitalWrite(RED, LOW);
  
  //focus
  Serial.println("shoot 003 - focusing");
  digitalWrite(BLUE, HIGH);
  digitalWrite(focusSw, LOW);
  delay(focusSwHoldTime);
  
  //shoot
  Serial.println("shoot 004 - SHOOT!");
  digitalWrite(GREEN, HIGH);
  digitalWrite(shutterSw, LOW);
  delay(shutterSwHoldTime);

  //wait for cam to write to SD card
  Serial.println("shoot 005 - waiting for cam to write the picture to SD card");
  digitalWrite(GREEN, LOW);
  digitalWrite(shutterSw, HIGH);
  digitalWrite(BLUE, LOW);
  digitalWrite(focusSw, HIGH);
  delay(waitAfterExposure);

  Serial.println("shoot 006 - powering camera off");
  digitalWrite(RED, HIGH);
  digitalWrite(powerSw, HIGH);
  delay(powerSwHoldTime);
  digitalWrite(RED, LOW);
  digitalWrite(powerSw, LOW);

  Serial.println("shoot 007 - done!  back to doing nothing...");

  
  
  
}


long previousMillis = 0;
long interval = picPeriod;

void loop()
{
  long m = millis();
  Serial.println(m);
  if (m - previousMillis > interval) {    
    //if (digitalRead(btnPin)) {
    previousMillis = m;         
    shoot();
    Serial.print(interval);
    Serial.println(" milliseconds until next cam shot");
    //}
  } else {
  
    // play with the LEDs
    delay(500);
    digitalWrite(RED, HIGH);
    delay(500);
    digitalWrite(GREEN, HIGH);
    delay(500);
    digitalWrite(BLUE, HIGH);
    delay(500);
    digitalWrite(RED, LOW);
    digitalWrite(GREEN, LOW);
    digitalWrite(BLUE, LOW);
    delay(500);
  }
}
