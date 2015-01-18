/*
 
 Circuit:

 DRDY: pin 5 (INT0)
 CS: pin 4
 MOSI: pin 11
 MISO: pin 12
 SCK: pin 13
 
 
 INSR   8 Bits  Instruction Register  
 DOR   24 Bits  Data Output Register
 CMR   32 Bits  Command Register
 OCR   24 Bits  Offset Calibration Register
 FCR   24 Bits  Full-Scale Calibration Register



SPI_CLOCK_DIV4

*/


#define CPU_PRESCALE(n) (CLKPR = 0x80, CLKPR = (n))
#define CPU_16MHz       0x00
#define CPU_8MHz        0x01
#define CPU_4MHz        0x02
#define CPU_2MHz        0x03
#define CPU_1MHz        0x04
#define CPU_500kHz      0x05
#define CPU_250kHz      0x06
#define CPU_125kHz      0x07
#define CPU_62kHz       0x08


#include <SPI.h>

//Sensor's memory register addresses:
const int PRESSURE = 0x1F;      //3 most significant bits of pressure
const int PRESSURE_LSB = 0x20;  //16 least significant bits of pressure
const int TEMPERATURE = 0x21;   //16 bit temperature reading
const byte READ = 0b11111100;     // SCP1000's read command
const byte WRITE = 0b00000010;   // SCP1000's write command

// pins used for the connection with the sensor
// the other you need are controlled by the SPI library):
const int dataReadyPin = 5;
const int chipSelectPin = 4;

#include <MsTimer2.h>

// Switch on LED on pin 13 each second


void flash() {
  static boolean output = HIGH;
  
  digitalWrite(10, output);
  output = !output;
}


/* _______________________________________________

#include <avr/io.h>
#include <avr/interrupt.h>
#include "usart.h"


EMPTY_INTERRUPT(TIMER4_OVF_vect);

volatile uint8_t flag;
volatile uint16_t adc;

ISR(bryanclock_vect)
{
    flag = 1;
}


int main(void)
{
    // Timer4 presc. 1:16536
    TCCR4B = (1<<CS43) | (1<<CS42) | (1<<CS41) | (1<<CS40);
    // Enable overflow interrupt at F_CPU/65536/1024 Hz
    TIMSK4 = (1<<TOIE4);

    // Set TOP to 0x3FF (= 1023)
    TC4H = 3;
    OCR4C = 0xFF;
   
    sei();

    while (1)
    {
        if (flag) {
            flag = 0;
            printf("ADC = %04u\r\n", adc);
        }
    }
} 



________________________________*/



/*
#define KPIN 10
ISR(TIMER4_OVF_vect)
{
    digitalWrite(KPIN, !digitalRead(KPIN));
}
*/

/*
void initPWM() {
  
    /* explanation... look near bottom for conclusions
    (10:44:44 PM) lain: so basically in Fast PWM mode it will count from 0 to OCR4C (TOP)
    (10:45:13 PM) lain: if you look at 15.8.2 in the datasheet, the diagram shows how Fast PWM works
    (10:46:18 PM) shorted_neuron: checking
    (10:46:38 PM) lain: basically, when the counter is above OCR4A (compare register) the pin should go low (or high, depending on which pin)
    (10:46:46 PM) wedtm is now known as wedtm|away
    (10:46:59 PM) lain: and then when it hits OCR4C (TOP), the counter should reset to 0 and return high (or low, depending again on which pin)
    (10:47:08 PM) shorted_neuron: im a dummy, i just want genSquareWave(Hz, pin) <chuckle>
    (10:47:33 PM) lain: so OCR4C is going to set your period, and OCR4A is going to set your duty cycle, basically
    (10:48:01 PM) shorted_neuron: so this is 16MHz clock system... so i get 4MHz regardless of TOP being  0001, 0010, or 0011
    (10:48:10 PM) shorted_neuron: oh..... okay let me digest that...
    (10:48:24 PM) lain: hmmm
    (10:48:27 PM) wedtm|away is now known as wedtm
    (10:49:35 PM) shorted_neuron: let me do new paste, i dont think that diff is actually diffing from the first version
    (10:50:22 PM) shorted_neuron: http://pastebin.com/H6TaZgrN 
    (10:50:52 PM) lain: let's see
    (10:51:38 PM) lain: Table 15-7 for Fast PWM mode and COM4A1..0 of 01 is Cleared on Compare Match. Set when TCNT4 = 0x000
    (10:51:41 PM) shorted_neuron: OCR4C set to 0000 or 0001 i understand... its going to hit either of those every other cycle
    (10:53:17 PM) lain: so the counter will start at 0 and count up to ocr4c, at which point it resets to 0
    (10:53:44 PM) lain: the pin is set low when the counter reaches ocr4a
    (10:53:58 PM) lain: and it is set high when the counter is reset to zero (when it matches ocr4c)
    (10:54:05 PM) Guest54931 is now known as intranick
    (10:55:33 PM) lain: so if you set ocr4c to 4 and ocr4a to 2, then it should be: 2 cycles high, 2 cycles low
    (10:55:57 PM) lain: and likewise if you set ocr4c = 10 and ocr4a = 2, it should be 2 cycles high, 8 cycles low
    (10:56:01 PM) lain: etc
    (10:56:05 PM) lain: unless I've messed it up :P
    (10:56:24 PM) shorted_neuron: you're probably right... checking
    (10:56:58 PM) lain: been a while since I've messed with these timers
    (10:58:35 PM) shorted_neuron: easier to understand with decimal for sure
    (10:59:07 PM) shorted_neuron: you are right... and seeting OCR4C to something greater than A is going to make for some VERY occasional edges
    (10:59:53 PM) lain: :)
    (11:00:07 PM) lain: yeah perhaps just a glitch when it resets or something
    (11:00:57 PM) lain: er oh misread, C > A, yeah, not glitches just normal operation
    (11:01:15 PM) lain: if A is C/2, it should be a 50% duty cycle square wave
    (11:02:55 PM) shorted_neuron: and i have to remember to count from zero, which i usually do not have a problem with...
    (11:03:03 PM) lain: hehe
    (11:03:47 PM) shorted_neuron: so 16Mhz sys clock, i want OCR4C = 15 (TOP is every 16 cycles)
    (11:04:04 PM) shorted_neuron: and for 50% of that i want 7 (match every 8 cycles)
    (11:04:12 PM) lain: sounds correct
    (11:04:16 PM) shorted_neuron: resulting in 1MHz output at 50% duty cycle

* /
  // initialize Timer4
  cli();               // disable global interrupts
  TCCR4A = B01000010;  // comparator output mode toggle OC4A on match, enable PWM on OCR4A
  //TCCR4C = 0;        // n/a
  TCCR4D = B00000000;  // Fast PWM on OCR4A
  //TCCR4E = 0;        // n/a
  
  // for 16MHz system, set 1MHz output clock:
  //TCCR4B = B00000001;  // deadtime = no division, prescale source = clock/1
  //OCR4A = 7;  // count from zero, so this means we toggle every 8th cycle per TCCR4A
  //OCR4C = 15; // TOP counter overflow every 16th cycle
  
  //..OR... for 16MHz system, set 1MHz output clock:
  TCCR4B = B00000011;  // deadtime = no division, prescale source = clock/4
  OCR4A = 1;  // count from zero, so this means we toggle every 8th cycle per TCCR4A
  OCR4C = 1; // TOP counter overflow every 16th cycle
  
  //..OR... for 16MHz system, set 500kHz output clock:
  //TCCR4B = B00000100;  // deadtime = no division, prescale source = clock/4
  //OCR4A = 1;  // count from zero, so this means we toggle every other cycle per TCCR4A
  //OCR4C = 1; // TOP counter overflow every other cycle
  
  
  // for 16MHz system, set 4MHz output clock (max i can get apparently) 
  TCCR4B = B00000001;  // deadtime = no division, prescale source = clock/1
  OCR4A = 1;  // count from zero, so this means we toggle every other cycle per TCCR4A
  OCR4C = 1; // TOP counter overflow every other cycle

  // for 16MHz system, set 2MHz output clock  
  TCCR4B = B00000010;  // deadtime = no division, prescale source = clock/2
  OCR4A = 1;  // count from zero, so this means we toggle every other cycle per TCCR4A
  OCR4C = 1; // TOP counter overflow every other cycle
  

  // for 16MHz system, set 2MHz output clock  
  TCCR4B = B00000001;  // deadtime = no division, prescale source = clock/2
  OCR4A = 1;  // count from zero, so this means we toggle every other cycle per TCCR4A
  OCR4C = 1; // TOP counter overflow every other cycle
    
  
  
  TCNT4 = 0;           // reset counter to zero
  TIFR4 = 0;           // no ISR
  DDRC |= B10000000;   // set PC7 to output
  
  // enable global interrupts:
  sei();
 
}

*/

void setup_ADS1211() {
  
      
  writeRegister(B00000100, B01010011);  
       // write to  command reg byte 3:
         // bias off
         // turn on REFout,
         // offset binary (0 = twos complement)
         // unipolar
         // MSByte first 
         // MSBits first
         // enable data send on SDOUT
         // do reset

  writeRegister(B00000101, B00100001);  
       // write to  command reg byte 2:
         // (000= normal mode) or (001 = self calibrate)
         // 000 = no gain by PGA
         // 01 = channel select chan 2



  writeRegister(B00000110, B00100000);  
       // write to  command reg byte 1:
         // 100 = turbo mode 16
         // output data rate fDATA = fXIN • TMR / (512 • (Decimation Ratio + 1))
         //     1000000 * 16 / (512 * (312+1))
         // first five bits of "22" are : 00000

  writeRegister(B00000111, B00100110);  
       // write to command reg byte 0
       // rest of "38" remaining 8 bits are: 00100110

  //writeRegister(B00000111, B00010101);  
       // write to command reg byte 0
       // rest of "22" remaining 8 bits are: 00010101


}


void setup() {
  
  CPU_PRESCALE(CPU_125kHz);  // power supply still ramping up voltage
  delay(2);              // actual delay 128 ms when F_OSC is 16000000
  CPU_PRESCALE(CPU_16MHz);
  delayMicroseconds(10);
  Serial.begin(9600);

  // start the SPI library:
  SPI.begin();
  pinMode(1, OUTPUT);
  pinMode(2, OUTPUT);
  pinMode(3, INPUT);
  pinMode(12,OUTPUT);
  

  //pinMode(11,OUTPUT);

  SPI.setClockDivider(SPI_CLOCK_DIV8); //DIV8 = 2MHz SPI clock works with ADC at 10MHz
  SPI.setBitOrder(MSBFIRST);
  // initalize the  data ready and chip select pins:
  pinMode(dataReadyPin, INPUT);
  pinMode(chipSelectPin, OUTPUT);
  digitalWrite(chipSelectPin, HIGH); 
  
  //initPWM(); // set up a timer4 clock to give clock to our ADC
  
  delay(100);
  SPI.setDataMode(SPI_MODE1); //seems to only work after being in mode zero and moving to mode 1
  setup_ADS1211();


  Serial.println("done with setup");
  delay(1000);
}

boolean led = false;

const int NoOfSamples = 10; // Warning: if set too high, DeviationSqSum may overflow!
// This will happen sooner when the real standard deviation is higher.
uint32_t Values[NoOfSamples];

void loop() {


//  Serial.print (", ");


/*  
  foo = readRegister(B10000010, 1);
  if (foo != 65535) {
     Serial.println (foo,DEC);
     
  }
*/
  //delay(100);
  
      unsigned long SPSbegin = micros();
      // First read the specified number of samples:
      for (int i=0; i<NoOfSamples; i++) {
        //Serial.println("about to read");
        //Values[i] = ADC_ext.read(B000,3);

        while (!(digitalRead(dataReadyPin)));  // wait for ready to go high
        while (digitalRead(dataReadyPin));  // wait for ready to go low
      
        uint8_t foo = 0;
      
        int32_t foo2 = 0;
        foo2 = readRegister(B10000000, 1);
        foo2 = foo2 << 8;
      
        foo2 = foo2 + readRegister(B10000001, 1);
        //foo2 = foo2 << 8;
        //foo2 = foo2 + readRegister(B10000010, 1);
        //foo2 = foo2 >> 7;
        //readRegister(B10000010, 1);

        Values[i] = foo2;
        //Serial.println (foo2,DEC);


      }
      // Then calculate and print the samples per second to compare the speed of different settings:
      unsigned int SPS = 1000000*NoOfSamples/(micros() - SPSbegin);
      Serial.print("SPS: "); Serial.print(SPS,DEC);
    
      // Calculate and print mean:
      unsigned long ValuesAccum = 0;
      for (int i=0; i<NoOfSamples; i++) {
        ValuesAccum += Values[i];
      }
      unsigned long Mean = 0;
      Mean = ValuesAccum/NoOfSamples;
      Serial.print(",   Mean: "); Serial.print(Mean,DEC);
      
      // Calculate standard deviation:
      unsigned long DeviationSqSum = 0;
      for (int i=0; i<NoOfSamples; i++) {
        DeviationSqSum += sq(Values[i] - Mean);
      }
      //Serial.print("Std deviation sum of all squares: "); Serial.println(DeviationSqSum); // For debugging if you don't trust the std. dev. values
      unsigned long StdDeviation = sqrt(DeviationSqSum/(NoOfSamples));
      Serial.print(", StDev: "); Serial.print(StdDeviation);

      // now lets take that reading and get to force...
      // full scale is 1.978mv/V * 5V excitation * gain of 276 = 2730mv full scale
      // 
      //     (((2746-728) * 5000) / 32768 ) * (100000 / (1.978 * 5000 * 246))  * 2.2 
      //float Kilos = ((((Mean - 500) * 5000) / 32768) * (100000 / (1.978 * 5000 * 234))) + (500 / Mean);
      //float Kilos = ((((((float)(Mean)) - 510) * 5000) / 32768) * (100000 / (1.978 * 5000 * 234))) + (510 / ((float)(Mean)));
      float Kilos = (((Mean * 5000) / 32768) * (100000 / (1.978 * 5000 * 234))) - 5;
      float Pounds = Kilos * 2.2;
      Serial.print(", Kilos: "); Serial.print(Kilos,4);
      Serial.print(", Pounds: "); Serial.println(Pounds,4);
      
      led = !led;
      digitalWrite(11, led);
      analogWrite(12, ((int) (Pounds)));
      delay(500); // Wait a second to avoid overflowing the serial monitor with data

  
    
}

//Read from or write to register from the SCP1000:
uint32_t readRegister(byte thisRegister, int bytesToRead ) {
  byte inByte = 0;           // incoming byte from the SPI
  uint32_t result = 0;   // result to return
  //Serial.print(thisRegister, BIN);
  //Serial.print("\t");
  // SCP1000 expects the register name in the upper 6 bits
  // of the byte. So shift the bits left by two bits:
  //thisRegister = thisRegister << 2;
  // now combine the address and the command into one byte
  //byte dataToSend = thisRegister & READ;
  byte dataToSend = thisRegister;
  //Serial.println(thisRegister, BIN);
  


  
  // take the chip select low to select the device:
  digitalWrite(chipSelectPin, LOW);
  // send the device the register you want to read:
  SPI.transfer(dataToSend);
  // send a value of 0 to read the first byte returned:
  result = SPI.transfer(B10000000);
  //Serial.print(inByte);
  //Serial.print(" = ");
  //Serial.println(result, BIN);

  // decrement the number of bytes left to read:
  bytesToRead--;
  // if you still have another byte to read:
  if (bytesToRead > 0) {
    // shift the first byte left, then get the second byte:
    result = result << 8;
    inByte = SPI.transfer(B10000000);
    // combine the byte you just got with the previous one:
    result = result | inByte;
    // decrement the number of bytes left to read:
    bytesToRead--;
  }
  // take the chip select high to de-select:
  digitalWrite(chipSelectPin, HIGH);
  // return the result:
  return(result);
}


//Sends a write command to SCP1000

void writeRegister(byte thisRegister, byte thisValue) {


  //byte dataToSend = thisRegister | WRITE;
  byte dataToSend = thisRegister;
  // take the chip select low to select the device:
  while (!(digitalRead(dataReadyPin)));  // wait for ready to go high
  while (digitalRead(dataReadyPin));  // wait for ready to go low

  digitalWrite(chipSelectPin, LOW);

  SPI.transfer(dataToSend); //Send register location
  SPI.transfer(thisValue);  //Send value to record into register

  // take the chip select high to de-select:
  digitalWrite(chipSelectPin, HIGH);
}

