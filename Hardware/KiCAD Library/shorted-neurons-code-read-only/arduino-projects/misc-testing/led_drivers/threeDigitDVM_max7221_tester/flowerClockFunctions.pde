

// memory monitor crap

void chkMem() {
  Serial.print(F("chkMem free= "));
  Serial.print(availableMemory());
  Serial.print(F(", memory used="));
  Serial.println(2048-availableMemory());

}

int availableMemory() {
 int size = 2048;
 byte *buf;
 while ((buf = (byte *) malloc(--size)) == NULL);
 free(buf);
 return size;
} 

// end memory monitor crap



void checkButtons() {
	dmesg(39000);
	if (!digitalRead(btn1)) {
		Serial.println(F("btn1 is depressed"));
		dmesg(39010);
	}
	if (!digitalRead(btn2)) {
		Serial.println(F("btn2 is depressed"));
		dmesg(39020);
	}

}







//LedControl stuff

void dec_bin(int number) {
 int x, y;
 x = y = 0;

 for (y = 7; y >= 0; y--) {
  x = number / (1 << y);
  number = number - x * (1 << y);
  Serial.print(x);
 }

 Serial.println("\n");

}







int checkRotary() {
  
  dmesg(43300);
  boolean h1 = (digitalRead(h1pin)); dmesg(43301);
  boolean h2 = (digitalRead(h2pin)); dmesg(43302);
  boolean h3 = (digitalRead(h3pin)); dmesg(43303);
  
  /* 
    so we have a rotary encoder^H^H^H^H^H^H^H^H^H^H cdrom-drive motor,
    with three Hall-effect sensors, which are hooked up to comparator
    gates.  What we wind up with is a truth table that can tell you
    whether we are moving or not, AND which direction, naturally 
    important for use as a human interface control.
    
    So each hall effect is boolean output of the comparator, and we put em
    all together into nowRotary.  Apparently its little-endian.
    h1    0   0   0   0   1   1   1   1
    h2    0   0   1   1   0   0   1   1
    h3    0   1   0   1   0   1   0   1
---------------------------------------
   now    0   1   2   3   4   5   6   7
   

with 
#define h1pin 2
#define h2pin 15
#define h3pin 16

001
101
100
110
010
011

#define h1pin 2
#define h2pin 16
#define h3pin 15
001
011
010
110
100
101

*/

  nowRotary = ((h3 << 2) | (h2 << 1) | h1);
//  Serial.print << "according to cminus, now = " << nowRotary << '\n';
//  Serial.print("according to cminus, now = ");
//  Serial.println(nowRotary);
  
//  nowRotary = (h3+(h2*2)+(h1*4));
//  Serial << "according to ball,   now = " << nowRotary << '\n';
//  Serial.print("according to ball,   now = ");
//  Serial.println(nowRotary);  
  int f = 0;
  
 if (nowRotary == lastRotary) {
   dmesg(43305);
   return(0);
 } else {
   
  //Serial.print("according to cminus,   now = ");
  //Serial.println(nowRotary);     
  if (nowRotary > lastRotary) f = 1;
  if (nowRotary < lastRotary) f = -1;
  lastRotary = nowRotary;
  
//  Serial.print("according to old way, f=");
//  Serial.println(f);
/* this doesnt work and i dont understand it
  f = 0;
  if (h1 != h1last) {       // clock pin has changed value... now we can do stuff
    h3 = h1^h2^h3;              // work out direction using an XOR
    if ( h3 ) {
      f=-1;            // non-zero is Anti-clockwise
    } else {
      f=1;            // zero is therefore anti-clockwise
    }
    h1last = h1;            // store current clock state for next pass
  } else {
    f = 0;
  }

  Serial.print ("Jog:: count:");
  Serial.println(f);
*/


/* works! but too fast:  
  switch (nowRotary) {
    case 0:
      f = 0;
      break;
    case 1:
      f = 1;
      break;
    case 5:
      f = 2;
      break;
    case 4:
      f = 3;
      break;
    case 6:
      f = 4;
      break;
    case 2:
      f = 5;
      break;
    case 3:
      f = 6;
      break;
    case 7:
      f = 7;
      break;
  } 
  */
  dmesg(43300+nowRotary);
  switch (nowRotary) {
    // cases are in the order in which they occur when rotating the thing.  used to map order into something that is actually in order.  need some fancy bit math i think to do better.
    case 1:
      f = 1;
      break;
    case 5:
      f = 1;
      break;
    case 4:
      f = 3;
      break;
    case 6:
      f = 3;
      break;
    case 2:
      f = 5;
      break;
    case 3:
      f = 5;
      break;
  } 

  int r = 0;
  if (f > lastf) r=1;
  if (f < lastf) r=-1;
  if (f == lastf) r=0;
  // two special cases, basically for overflow
  if (f == 1 && lastf == 5) r=1;
  if (f == 5 && lastf == 1) r=-1;
  lastf = f;
  
  dmesg(43410+r);
  lastRotary = nowRotary;
  
  return(r);
  
 }  
}







int mapChar (char *c) {
	int foo = c[0];
	byte b = charMap[foo-97];
	return(b);
}

int mapCharDpFirst (char *c) {
	int foo = c[0];
	byte b = charMap[foo-97];
	b = b >> 1;
	return(b);
}




/* 
 This function will light up every Led on the matrix.
 The led will blink along with the row-number.
 row number 4 (index==3) will blink 4 times etc.
 */
#define singleTime 10

void single() {
  short a=0;
  LEDs.clearDisplay(a);
  for(int row=0;row<8;row++) {
    //Serial << "chip:" << a << " row:" << row << ",";
    for(int col=0;col<8;col++) {
      //delay(singleTime);
      //Serial.print(col);
      LEDs.setLed(a,row,col,true);
      delay(singleTime*3);
      LEDs.setLed(a,row,col,false);
    }
  }

}

void rows() {
  dmesg(56000);
  for(int row=0;row<8;row++) {
	dmesg(56000+row);
	LEDs.setRow(0,row,(byte)255);
	delay(delaytime);
	LEDs.setRow(0,row,(byte)0);
  }
  LEDs.clearDisplay(0);
  dmesg(56999);
}

/*
  This function lights up a some Leds in a column.
 The pattern will be repeated on every column.
 The pattern will blink along with the column-number.
 column number 4 (index==3) will blink 4 times etc.
 */
void columns() {

  if ( (periodCount % 10) == 0 ) {
    for(int col=0;col<7;col++) {
      delay(delaytime);
  //    LEDs.setColumn(0,col,random(255));
  //    LEDs.setColumn(2,col,random(255));
      
  //    delay(delaytime);
  //    rgb.setColumn(0,1,B10100100);
  //    rgb.setColumn(0,2,B10010010);
  //    rgb.setColumn(0,3,B10001001);
  //    delay(delaytime*10);
  
	LEDs.setColumn(0,col,B11111111);
	dmesg(33000+col);
	delay(delaytime);
	LEDs.setColumn(0,col,B00000000);
      	LEDs.setColumn(2,col,B11111111);
	dmesg(33200+col);
	delay(delaytime);
	LEDs.setColumn(2,col,B00000000);
    }
  //  rgb.clearDisplay(0);
  }
}




/*
	33000 = nothing
	33200 = nothing
	33001 = nothing
	33002 = nothing
	33006 = nothing

	33003 = rear red shiners
	33004 = rear green
	33005 = rear blue

	33201 = front red shiners
	33202 = front grn shiners
	33203 = front blue shiners
	33204 = front flower red
	33205 = front flwoer green
	33206 = front flower blue
















*/


/*
 This method will display the characters for the
 word "Arduino" one after the other on digit 0. 
 */
void writeArduinoOn7Segment() {
  LEDs.setChar(0,0,'a',false);
  delay(delaytime);
  LEDs.setRow(0,0,0x05);
  delay(delaytime);
  LEDs.setChar(0,0,'d',false);
  delay(delaytime);
  LEDs.setRow(0,0,0x1c);
  delay(delaytime);
  LEDs.setRow(0,0,B00010000);
  delay(delaytime);
  LEDs.setRow(0,0,0x15);
  delay(delaytime);
  LEDs.setRow(0,0,0x1D);
  delay(delaytime);
  LEDs.clearDisplay(0);
  delay(delaytime);
} 

/*
  This method will scroll all the hexa-decimal
 numbers and letters on the display. You will need at least
 four 7-Segment digits. otherwise it won't really look that good.
 */
void scrollDigits() {
  /*
    Serial.println("two");
    LEDs.setColumn(0,1,B01100000);
    LEDs.setColumn(0,2,B11011010);
    LEDs.setColumn(0,3,B11110010);
    LEDs.setColumn(0,4,B01100110);

    delay(delaytime);

    Serial.println("three");
    LEDs.setColumn(0,1,B01100110);
    LEDs.setColumn(0,2,B11110010);
    LEDs.setColumn(0,3,B11011010);
    LEDs.setColumn(0,4,B01100000);

    delay(delaytime);
    */
  for(int i=0;i<10;i++) {
    LEDs.setColumn(0,0,digMap[i]);
    LEDs.setColumn(0,1,digMap[i+1]);
    LEDs.setColumn(0,2,digMap[i+2]);
    LEDs.setColumn(0,3,digMap[i+3]);
    delay(delaytime);
  }

  LEDs.clearDisplay(1);
  //delay(delaytime);
}



void wmesg(long v) {
	// same as dmesg, but with wait delay
	dmesg(v);
	delay(delaytime);

}

void dmesg(long v) {
    int ones;
    int tens;
    int hundreds;
    int thousands;
    int tenthousands;
    boolean negative;	

/*    if(v < -999 || v > 999) 
       rtturn;
    if(v<0) {
        negative=true;
        v=v*-1;
    }
*/
    Serial << "dmesg: " << v << endl;

    ones=v%10;
    v=v/10;
    tens=v%10;
    v=v/10;
    hundreds=v%10;			
    v=v/10;
    thousands=v%10;			
    v=v/10;
    tenthousands=v%10;			

    /*
    //Now print the number digit by digit
    debug.setDigit(0,0,(byte)tenthousands,false);
    debug.setDigit(0,1,(byte)thousands,false);
    debug.setDigit(0,2,(byte)hundreds,false);
    debug.setDigit(0,3,(byte)tens,false);
    debug.setDigit(0,4,(byte)ones,false);
    */
}







void updateDisplay() {
  
/*  LEDs.setColumn(0,0,digMap[0]);
  LEDs.setColumn(0,1,digMap[1]);
  LEDs.setColumn(0,2,digMap[2]);
  LEDs.setColumn(0,3,digMap[3]);
  LEDs.setColumn(0,4,digMap[4]);
  LEDs.setColumn(0,5,digMap[5]);
  LEDs.setColumn(0,6,digMap[6]);
  LEDs.setColumn(0,7,digMap[7]);
    LEDs.setColumn(0,8,digMap[8]);
  delay(200);
*/
  LEDs.setColumn(clockDigits,0,digMap[((periodCount / 1000) % 10)]);
  LEDs.setColumn(clockDigits,1,digMap[((periodCount / 100) % 10)]);
  LEDs.setColumn(clockDigits,2,digMap[((periodCount / 10) % 10)]);
  LEDs.setColumn(clockDigits,3,digMap[(periodCount % 10)]);

}


void updateLEDs() {
  if (dvmError) {
    LEDs.setColumn(clockDigits,0,digits[0]);
    LEDs.setColumn(clockDigits,1,digits[1]);
    LEDs.setColumn(clockDigits,2,digits[2]);
  } else {
    LEDs.setColumn(clockDigits,0,digMap[digits[0]]);
    LEDs.setColumn(clockDigits,1,(digMap[digits[1]] | decimalA));
    LEDs.setColumn(clockDigits,2,(digMap[digits[2]] | decimalB));
  }
}



void updateBrightness() {
  sensorValue = 0;
  sensorValue = analogRead(photoResistor);


  // need some hysterisis here...
  if ((sensorValue > lastSensorValue+20) || (sensorValue < lastSensorValue-20)) {
 
    brightness = map(sensorValue, 0, 1023, 0, 20);
    if(brightness > 15 ) brightness = 15;
    if(brightness < 0 ) brightness = 0;
    //brightness = brightness *2;
    //if(brightness > 15 ) brightness = 15;
    //if(brightness < 0 ) brightness = 0;
  
#ifdef BRIGHTNESS_DEBUG
    // print the results to the serial monitor:
    Serial.print("sensor = " );                       
    Serial.print(sensorValue);      
    Serial.print("\t output = ");      
    Serial.println(brightness);   
#endif
    
    if (brightness != lastBright) {
      if (brightness == 0 || sensorValue < lowLight) {
	if (!colorShutoff) {
          LEDs.setIntensity(clockDigits,0);
	}
      } else {
        LEDs.setIntensity(clockDigits,brightness);
      }
    }
    lastBright=brightness;
    lastSensorValue=sensorValue;
  }
}



void rotarySetup() {
  dmesg(2000);
  pinMode(h1pin, INPUT);
  pinMode(h2pin, INPUT);
  pinMode(h3pin, INPUT);
  pinMode(btn1, INPUT); digitalWrite(btn1, HIGH);
  pinMode(btn2, INPUT); digitalWrite(btn2, HIGH);
  dmesg(2999);
}
