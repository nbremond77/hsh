
#define btnPin 13
#define fastPinSw 14
//#define BLUE 3
//#define GREEN 4
//#define RED 5
#define BLUE 9
#define GREEN 9
#define RED 9
#define powerSw 7
#define focusSw 6
#define shutterSw 5
#define powerSwHoldTime 2000
#define warmupTime 4000
#define focusSwHoldTime 1200
#define shutterSwHoldTime 2000
#define waitAfterExposure 3000
#define longPicPeriod 120000
#define shortPicPeriod 10000

int blinkTime = 100;
long previousMillis = 0;
long interval = 60000;
boolean powerOff = true;


void setup()
{
  Serial.begin(57600);
  pinMode(btnPin, INPUT);
  pinMode(fastPinSw, INPUT);
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

boolean leftOff = true;

void shoot() {
  if (leftOff) {
    Serial.println("shoot 001 - powering up the camera");
    digitalWrite(RED, HIGH);
    digitalWrite(powerSw, HIGH);
    delay(powerSwHoldTime);
    digitalWrite(RED, HIGH);
    digitalWrite(powerSw, LOW);
    Serial.println("shoot 002 - waiting for it to settle");
    delay(warmupTime);
    digitalWrite(RED, LOW);
  } else {
    Serial.println("shoot 001 - cam should already be on...");
  }
  
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

  if (powerOff) {
    Serial.println("shoot 006 - powering camera off");
    digitalWrite(RED, HIGH);
    digitalWrite(powerSw, HIGH);
    delay(powerSwHoldTime);
    digitalWrite(RED, LOW);
    digitalWrite(powerSw, LOW);
    leftOff = true;
  } else {
    Serial.println("shoot 006 - fast mode, NOT powering camera off");
    leftOff = false;
  }
  
  Serial.println("shoot 007 - done!  back to doing nothing...");

  
  
  
}





void chkBtn () {
  if (digitalRead(btnPin)) {
    digitalWrite(RED, LOW);
    digitalWrite(GREEN, LOW);
    digitalWrite(BLUE, LOW);
    powerOff=false;
    shoot();
  } else {
    delay(blinkTime);
  }
    
}



void loop() {
  long m = millis();
  
  if (digitalRead(fastPinSw)) {
    interval = shortPicPeriod;
    blinkTime = 100;
    powerOff = false;
  } else {
    interval = longPicPeriod;
    powerOff = true;
    blinkTime = 400;
  }
  
  Serial.println(m);
  if (m - previousMillis > interval) {    
    //if (digitalRead(btnPin)) {
    shoot();
    previousMillis = millis();         
    Serial.print(interval);
    Serial.println(" milliseconds until next cam shot");
    //}
  } else {
  
    // play with the LEDs
    chkBtn();
    digitalWrite(RED, HIGH);
    chkBtn();
    digitalWrite(GREEN, HIGH);
    chkBtn();
    digitalWrite(BLUE, HIGH);
    chkBtn();
    digitalWrite(RED, LOW);
    digitalWrite(GREEN, LOW);
    digitalWrite(BLUE, LOW);
    delay(blinkTime);
  }
}
