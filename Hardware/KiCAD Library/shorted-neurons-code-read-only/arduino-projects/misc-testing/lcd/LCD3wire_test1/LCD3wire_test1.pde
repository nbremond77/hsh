/* LCD display with 3 wires
 * ------------------------
 *
 * based on previous examples by Tomek. 
 * This program will use shiftout to send 
 * data to a shift register with strobe that 
 * will transfer the serial into parallel data
 *
 * the pin-out for LCD displays is standard and there is plenty
 * of documentation to be found on the internet.
 *
 * (cleft) 2007 Dojodave for K3 and SADI
 * http://www.arduino.cc
 *
 */

// pins to be used on Arduino
int led = 13;
int count = 0;
int Dout = 9;
int STR = 8;
int CLK = 7;

// the Qx in the order they are connected on the chip
// dumbass started at 1 instead of zero
int DI = 1;
int RW = 2;
int Enable = 3;
int DB[] = {
  7, 6, 5, 4};



void LcdInit() {
  delay(100);
  // initialize LCD after a short pause
  // needed by the LCD's controller

  /////////// 4 pin initialization
  LcdCommandWrite(0x03); // function set:
  // 4 pin initialization
  delay(64);
  LcdCommandWrite(0x03); // function set:
  // 4 pin initialization
  delay(50);
  LcdCommandWrite(0x03); // function set:
  // 4 pin initialization
  delay(50);
  LcdCommandWrite(0x02); // function set:
  // 4 pin initialization
  delay(50);
  LcdCommandWrite(0x2C); // function set:
  // 4-bit interface, 1 display lines, 5x7 font
  /////////// end of 4 pin initialization 

  delay(20);
  LcdCommandWrite(0x06); // entry mode set:
  // increment automatically, no display shift
  delay(20);
  LcdCommandWrite(0x0E); // display control:
  // turn display on, cursor on, no blinking
  delay(20);
  // clear display, set cursor position to zero
  LcdCommandWrite(0x01); 
  delay(100);

  LcdCommandWrite(0x80); // display control:
  delay(20);
}

void sendByteOut(int value) {
  shiftOut(Dout, CLK, LSBFIRST, value);
  digitalWrite(STR, LOW);
  delayMicroseconds(50);
  digitalWrite(STR,HIGH);
}

void LcdCommandWrite(int value) {
  int i = 0;
  int value1 = 0;
  int control = 0; // stores DI and RW
  digitalWrite(STR,LOW); // set the strobe LOW
  control = value >> 8; // get the control signals DI and RW
  control <<= 5; // shift the control signals to the left
  value1 = value;
  value1 >>= 4; //send the first 4 databits (from 8) 
  value1 |= control; // set the control values
  value1 &= 239; // set Enable LOW
  sendByteOut(value1);
  value1 |= 16; // Set Enable HIGH
  sendByteOut(value1);
  value1 &= 239; // set Enable LOW
  sendByteOut(value1);

  delay(1);

  value &= 15; // set HByte to zero 
  value |= control; // set the control values
  value &= 239; // set Enable LOW
  sendByteOut(value);
  value |= 16; // Set Enable HIGH
  sendByteOut(value);
  value &= 239; // set Enable LOW
  sendByteOut(value);
}

void LcdDataWrite(int value) {
  int i = 0;
  int value1 = 0;
  digitalWrite(STR,LOW); // set the strobe LOW
  value1 =value;
  value1 >>= 4; //send the first 4 databits (from 8) 
  value1 |= 64; // set DI HIGH
  value1 &= 223; // set RW LOW
  value1 &= 239; // set Enable LOW
  sendByteOut(value1);
  value1 |= 16; // Set Enable HIGH
  sendByteOut(value1);
  value1 &= 239; // set Enable LOW
  sendByteOut(value1);

  delay(1);

  value &= 15; // set HByte to zero 
  value |= 64; // set DI HIGH
  value &= 223; // set RW LOW
  value &= 239; // set Enable LOW
  sendByteOut(value);
  value |= 16; // Set Enable HIGH
  sendByteOut(value);
  value &= 239; // set Enable LOW
  sendByteOut(value);
}

// efficient way of multiplying numbers by themselves
int pow(int base, int expo) {
  int temp = 1;
  for (int c = 1; c <= expo; c++) {
    temp *= base;
  }
  return temp;
}

// checks out how many digits there are in a number
int estimateDigits(int nr) {
  int dec = 10;
  int temp = 1;
  int div = nr/dec;
  while (div > 0) {
    dec *= 10;
    div = nr/dec;
    temp++;
  }
  return temp;
}

// shows numbers on the display
void LcdNumberWrite(int nr) {
  int digits = estimateDigits(nr);
  LcdNumberWrite(nr, digits);
}

// this function help us to write numbers 
// with more than one digit
void LcdNumberWrite(int nr, int digits) {
  for (int i = digits-1; i >= 0; i--) {
    int dec = pow(10,i);
    int div = nr/dec;
    LcdDataWrite(div+48); 
    if (div > 0) {
      nr -= div*dec; 
    }
  }
}

void setup (void) {
  int i = 0;
  /* dumbass assumes in-order
  for (i=CLK; i <= STR; i++) {
    pinMode(i,OUTPUT);
  }
  */
  pinMode(CLK, OUTPUT);
  pinMode(STR, OUTPUT);
  pinMode(Dout, OUTPUT);
  LcdInit();
  LcdCommandWrite(0x0F); //  cursor blink
  delay(10);
}

void loop (void) {
  LcdCommandWrite(0x02); // set cursor position to zero
  delay(10);

  // Write the message
  //like this
  LcdDataWrite('L');
  LcdDataWrite('c');
  LcdDataWrite('d');

  //or like this
  int wrote[] = {
    'D', 'i', 's', 'p', 'l', 'a', 'y', ' '  };
  for ( count = 0; count<=7; count++) {
    LcdDataWrite(wrote[count]);
  } 

  LcdDataWrite('w');
  LcdDataWrite('i');
  LcdDataWrite('t');
  LcdDataWrite('h');
  LcdDataWrite(' ');

  // and Numbers over 9 easily like this
  LcdNumberWrite(3);
  LcdDataWrite(' ');

  LcdDataWrite('P');
  LcdDataWrite('i');
  LcdDataWrite('n');
  LcdDataWrite('s');

  delay(3000);
}
