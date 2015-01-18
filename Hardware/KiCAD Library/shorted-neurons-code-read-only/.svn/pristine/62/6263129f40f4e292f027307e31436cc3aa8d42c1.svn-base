const int ledPinB = 9; // Analog output pin that the Blue is attached to
const int ledPinG = 10; // Analog output pin that the Green is attached to
const int ledPinR = 11; // Analog output pin that the Red is attached to

byte FadeCount=0;
byte PauseCount=0;
byte FadeLength=10;

byte rgb_colors[3]; 
byte hue = 0;
byte saturation;
byte brightness=255;
int GB_Brightness;
int UL_brightness;

byte Mode=0;
byte ThisColorIndex=1;
byte ColorSetIndex=0;

//const byte DefaultR[] = { 0,   254, 0,   0,   0,   255, 255, 255, 255, 255, 255, 254, 254, 0,   0,   0,   254, 254, 255 , 255, 255, 0,   0,   255, 40, 0,   254, 0   };      //reserve 255 in arrays as end of relevant values in custom arrays
//const byte DefaultG[] = { 254, 254, 0,   0,   254, 255, 255, 255, 255, 255, 255, 0,   254, 254, 254, 0,   0,   0,   255 , 255, 255, 0,   0,   255, 40, 254, 254, 0   };
//const byte DefaultB[] = { 0,   254, 254, 0,   0,   255, 255, 255, 255, 255, 255, 0,   0,   0,   254, 254, 254, 0,   255 , 255, 255, 254, 254, 255, 40, 0,   254, 254 };
const byte DefaultR[] = { 254, 254, 254,   0,   0,   0, 254, 254, 254,   255 , 255, 255, 0,   0,   255, 40, 0,   254, 0   };      //reserve 255 in arrays as end of relevant values in custom arrays
const byte DefaultG[] = { 254,   0, 254, 254, 254,   0,   0,   0, 254,  255 , 255, 255, 0,   0,   255, 40, 254, 254, 0   };
const byte DefaultB[] = { 254,   0,   0,   0, 254, 254, 254,   0, 254,  255 , 255, 255, 254, 254, 255, 40, 0,   254, 254 };

boolean Mode4Pause = 0;
boolean CustomProg = 0;


///////////////////////part of getRGB function///////////////////////
const byte dim_curve[] = {
  0,   1,   1,   2,   2,   2,   2,   2,   2,   3,   3,   3,   3,   3,   3,   3,
  3,   3,   3,   3,   3,   3,   3,   4,   4,   4,   4,   4,   4,   4,   4,   4,
  4,   4,   4,   5,   5,   5,   5,   5,   5,   5,   5,   5,   5,   6,   6,   6,
  6,   6,   6,   6,   6,   7,   7,   7,   7,   7,   7,   7,   8,   8,   8,   8,
  8,   8,   9,   9,   9,   9,   9,   9,   10,  10,  10,  10,  10,  11,  11,  11,
  11,  11,  12,  12,  12,  12,  12,  13,  13,  13,  13,  14,  14,  14,  14,  15,
  15,  15,  16,  16,  16,  16,  17,  17,  17,  18,  18,  18,  19,  19,  19,  20,
  20,  20,  21,  21,  22,  22,  22,  23,  23,  24,  24,  25,  25,  25,  26,  26,
  27,  27,  28,  28,  29,  29,  30,  30,  31,  32,  32,  33,  33,  34,  35,  35,
  36,  36,  37,  38,  38,  39,  40,  40,  41,  42,  43,  43,  44,  45,  46,  47,
  48,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  60,  61,  62,
  63,  64,  65,  66,  68,  69,  70,  71,  73,  74,  75,  76,  78,  79,  81,  82,
  83,  85,  86,  88,  90,  91,  93,  94,  96,  98,  99,  101, 103, 105, 107, 109,
  110, 112, 114, 116, 118, 121, 123, 125, 127, 129, 132, 134, 136, 139, 141, 144,
  146, 149, 151, 154, 157, 159, 162, 165, 168, 171, 174, 177, 180, 183, 186, 190,
  193, 196, 200, 203, 207, 211, 214, 218, 222, 226, 230, 234, 238, 242, 248, 255,
};

///////////////////////part of getRGB function///////////////////////


void setup() {
  // setup from http://forum.arduino.cc/index.php/topic,134754.0.html
  // For Attiny85
  // Author: Nick Gammon
  // Date: 29 November 2012
  pinMode (ledPinB, OUTPUT);  // pin 5  // OC0A
  pinMode (ledPinG, OUTPUT);  // pin 6  // OC0B
  pinMode (ledPinR, OUTPUT);  // pin 3  // OC1B
/*
  // Timer 0, A side
   TCCR0A = _BV (WGM00) | _BV (WGM01) | _BV (COM0A1); // fast PWM, clear OC0A on compare
   TCCR0B = _BV (CS00);           // fast PWM, top at 0xFF, no prescaler
   OCR0A = 6;                   // duty cycle (50%)
   
   // Timer 0, B side
   TCCR0A |= _BV (COM0B1);        // clear OC0B on compare
   OCR0B = 6;                    // duty cycle (25%)
   
   // Timer 1
   TCCR1 = _BV (CS10);           // no prescaler
   GTCCR = _BV (COM1B1) | _BV (PWM1B);  //  clear OC1B on compare
   OCR1B = 3;                   // duty cycle (25%)
   OCR1C = 127;                  // frequency
*/
}  // setup from http://forum.arduino.cc/index.php/topic,134754.0.html


void loop() {
  FadeCount++;
  if (FadeCount == 0) {
    ThisColorIndex++;
    FadeCount = 1;
    if (DefaultR[ThisColorIndex] == 255) {
      //ThisColorIndex = 1+10*ColorSetIndex;
      ThisColorIndex = 1;
    }
  }
  updateLEDs(DefaultR[ThisColorIndex-1], DefaultG[ThisColorIndex-1], DefaultB[ThisColorIndex-1], DefaultR[ThisColorIndex], DefaultG[ThisColorIndex], DefaultB[ThisColorIndex], FadeCount, FadeLength);
}

void updateLEDs(byte Red, byte Green, byte Blue, byte ToRed, byte ToGreen, byte ToBlue, byte UL_ThisStep, byte UL_DelayMS) {
//  UL_brightness = getBrightness();
  UL_brightness = 255;                    //BRYAN adjust this is too bright
  if (UL_ThisStep == 0) {
    Red = map(Red, 0, 255, 0, UL_brightness);
    Green = map(Green, 0, 255, 0, UL_brightness);
    Blue = map(Blue, 0, 255, 0, UL_brightness);
  }  
  else {
    Red = map(UL_ThisStep, 0, 255, Red, ToRed);
    Green = map(UL_ThisStep, 0, 255, Green, ToGreen);
    Blue = map(UL_ThisStep, 0, 255, Blue, ToBlue);
  
    Red = map(Red, 0, 255, 0, UL_brightness);
    Green = map(Green, 0, 255, 0, UL_brightness);
    Blue = map(Blue, 0, 255, 0, UL_brightness);
  }
  
/* inverts output (properly)
  Red = map(Red, 0, 255, 255, 0);
  Green = map(Green, 0, 255, 255, 0);
  Blue = map(Blue, 0, 255, 255, 0);
*/
  analogWrite(ledPinR, Red);            // red value in index 0 of rgb_colors array
  analogWrite(ledPinG, Green);            // green value in index 1 of rgb_colors array
  analogWrite(ledPinB, Blue);            // blue value in index 2 of rgb_colors array
  delay(UL_DelayMS);
}



/////////////////////////getRGB function from http://www.kasperkamperman.com/blog/arduino/arduino-programming-hsb-to-rgb //////////////////////////////////////
void getRGB(byte hue, byte sat, byte val, byte colors[3]) { 
  /* convert hue, saturation and brightness ( HSB/HSV ) to RGB
   The dim_curve is used only on brightness/value and on saturation (inverted).
   This looks the most natural.      
   */
  //  val = dim_curve[val];
  sat = 255-dim_curve[255-sat];

  byte r;
  byte g;
  byte b;
  byte base;

  if (sat == 0) { // Acromatic color (gray). Hue doesn't mind.
    colors[0]=val;
    colors[1]=val;
    colors[2]=val;  
  } 
  else  { 

    base = ((255 - sat) * val)>>8;

    switch(hue/60) {
    case 0:
      r = val;
      g = (((val-base)*hue)/60)+base;
      b = base;
      break;

    case 1:
      r = (((val-base)*(60-(hue%60)))/60)+base;
      g = val;
      b = base;
      break;

    case 2:
      r = base;
      g = val;
      b = (((val-base)*(hue%60))/60)+base;
      break;

    case 3:
      r = base;
      g = (((val-base)*(60-(hue%60)))/60)+base;
      b = val;
      break;

    case 4:
      r = (((val-base)*(hue%60))/60)+base;
      g = base;
      b = val;
      break;

    case 5:
      r = val;
      g = base;
      b = (((val-base)*(60-(hue%60)))/60)+base;
      break;
    }

    updateLEDs(r, g, b, 0, 0, 0, 0, 20);
    colors[0]=r;
    colors[1]=g;
    colors[2]=b; 
  }   
}
