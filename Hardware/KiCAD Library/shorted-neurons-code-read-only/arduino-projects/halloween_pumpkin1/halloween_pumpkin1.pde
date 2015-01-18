/*
 Fading
 
 This example shows how to fade an LED using the analogWrite() function.
 
 The circuit:
 * LED attached from digital pin 9 to ground.
 
 Created 1 Nov 2008
 By David A. Mellis
 Modified 17 June 2009
 By Tom Igoe
 
 http://arduino.cc/en/Tutorial/Fading
 
 This example code is in the public domain.
 
 */


#define eyeR 0
#define eyeL 11
#define backlight 1

#define WAITTIME 1500

int eyes = 0;
int i = 0;
void setup()  { 
  //Serial.begin(57600);
  pinMode(eyeR, OUTPUT);
  //pinMode(eyeL, OUTPUT);
  pinMode(backlight, OUTPUT);  
} 

boolean t(int start, int now, int stoppp) {
  
  if (start == 0) {
    if ( now <= stoppp ) return(true);
  } else {
    if ( now >= stoppp ) return(true);
  }
  return(false);
  
}


void doBoth(int bStart, int bincr, int eyeStart, int eyeIncr) {

  int s;
  int eyes = eyeStart;
  if (bStart == 0) { s=250; } else { s = 0; }
    
  for(i = bStart; t(bStart, i, s); i +=bincr) { 
      // sets the value (range from 0 to 255):
      analogWrite(eyeR, eyes);         
      //analogWrite(eyeL, eyes);         
      analogWrite(backlight, i);         
      //Serial.print("bg=");
      //Serial.print(i);
      //Serial.print(", eyes=");
      //Serial.println(eyes);
      eyes += eyeIncr;
      // wait for 30 milliseconds to see the dimming effect    
      delay(30);                            
  } 
}

void doEyes(int eyeStart, int eyeIncr) {

    int s;
    if (eyeStart == 0) { s=250; } else { s = 0; }
    
  for(i = eyeStart; t(eyeStart, i, s); i +=eyeIncr) { 
      // sets the value (range from 0 to 255):
      analogWrite(eyeR, i);         
      //analogWrite(eyeL, i);         
      // wait for 30 milliseconds to see the dimming effect    
      delay(30);                            
  } 
}

void doBg(int bStart, int bincr) {

    int s;
    if (bStart == 0) { s=250; } else { s = 0; }
    
  for(i = bStart; t(bStart, i, s); i +=bincr) { 
      // sets the value (range from 0 to 255):
      analogWrite(backlight, i);         
      // wait for 30 milliseconds to see the dimming effect    
      delay(30);                            
  } 
}



void loop()  { 
  
  //Serial.println("11111111111");  
  doBoth(0, 5, 0, 5);
  doBoth(255, -5, 255, -5);
  delay(WAITTIME);  
  //Serial.println("2222222222222222222222");
  doEyes(0, 5);
  doEyes(255, -5);
  delay(WAITTIME);  
  //Serial.println("3333333333333");
  doBg(0, 5);
  doBg(255, -5);
  delay(WAITTIME);  
  //Serial.println("4444444444444444444444");
  doBoth(0, 5, 0, 5);
  doBg(255, -5);
  delay(WAITTIME);
  doEyes(255, -5);
  delay(WAITTIME);
  //Serial.println("55555555555");
  doBoth(0, 5, 255, -5);
  delay(WAITTIME);
  //Serial.println("6666666666666666666666");
  doBoth(0, 25, 0, 25);
  delay(WAITTIME * 5);
  doBoth(255, -25, 255, -25);
  delay(WAITTIME);
}


