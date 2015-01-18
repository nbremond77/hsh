boolean foo=1;  //wtf why cant this compiler deal with a #define being first statement?

//Pin connected to ST_CP of 74HC595
#define latchPin 8
//Pin connected to SH_CP of 74HC595
#define clockPin 7
////Pin connected to DS of 74HC595
#define dataPin 9

byte shifterState = 0;


void setupShifter() {
  shifterState = 0;
  //set pins to output so you can control the shift register
  pinMode(latchPin, OUTPUT);
  pinMode(clockPin, OUTPUT);
  pinMode(dataPin, OUTPUT);
  for (int i=20; i<28; i++) {
        digitalWriteShifted(i, LOW);
  }
  delay(100);
  //Serial.println("shifter setup done");
}




int i;


void digitalWriteShifted(uint8_t pin, uint8_t pinstate) {
  /* 
  Serial.print("changing pin  ");
  Serial.print(pin, DEC);
  Serial.print(" to state ");
  Serial.println(pinstate, HEX);
  */ 
    
  if ( pin < 20 ) {
    digitalWrite(pin, pinstate);
  } else {
    // Q0 on shift register = fake pin 20,
    // so subtract 20 to get register bit position
    pin = pin - 20;
    
    if (pinstate) { //HIGH
      shifterState |= (1 << pin);
    } else { //LOW
      shifterState &= ~(1 << pin);
    }
    //shiftIt(shifterState);

    // replace shiftIt with direct port manipulation to get timings.
    // assumptions:  
    //     clock is D7 (PORTD bit 7)
    //     latch is D8 (PORTB bit 0)
    //      data is D9 (PORTB bit 1)    
    
    //digitalWrite(latchPin, LOW); //instead...
    PORTB &= ~(1 << 0);
    
    //shiftOut(dataPin, clockPin, MSBFIRST, x);  
    
        for (i = 0; i < 8; i++)  {
                //if (bitOrder == LSBFIRST)
                //    digitalWrite(dataPin, !!(val & (1 << i)));
                //else
                //    digitalWrite(dataPin, !!(shifterState & (1 << (7 - i))));

                // assume always MSBFIRST for speed sake)
                if (!!(shifterState & (1 << (7 - i))))
                   PORTB |= (1 << 1);
                else
                   PORTB &= ~(1 << 1);


                //digitalWrite(clockPin, HIGH);
                PORTD |= (1 << 7);

                delayMicroseconds(1);
                //digitalWrite(clockPin, LOW);
                PORTD &= ~(1 << 7);

        }

    //digitalWrite(latchPin, HIGH);
    PORTB |= (1 << 0);

  } 
}






void setup() {
  Serial.begin(57600);
  setupShifter();
}


void loop() {
  /**********************/
    // ~77us, 50% duty cycle
    digitalWriteShifted(20,HIGH);
    digitalWriteShifted(20,LOW); 
 /* */
  
  /*
    // ~9us, 47% duty cycle
    digitalWriteShifted(13,HIGH);
    digitalWriteShifted(13,LOW); 
  */
  
  /**********************
    // ~7.8us, 46% duty cycle
    digitalWrite(13, HIGH);
    digitalWrite(13, LOW);
  */
  
  /**********************
    //812ns total, 8% duty cycle
    PORTB = B00100000;
    // ~62ns spent high
    // then...
    PORTB = B00000000;
    // ~750ns spent low reexecuting loop()
  */
  
  /**********************
    //250ns total, 25% duty cycle
    while(1) {
      
      PORTB = B00100000;
      // ~62ns spent high
      
      //then
      PORTB = B00000000;
      //~188ns spent low, evaluating the while()
    }
   */
}

