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



void setup() {
  
  CPU_PRESCALE(CPU_125kHz);  // power supply still ramping up voltage
  delay(10);              // actual delay 128 ms when F_OSC is 16000000
  CPU_PRESCALE(CPU_16MHz);
  delay(10);
  Serial.begin(9600);

  // start the SPI library:
  SPI.begin();
  pinMode(1, OUTPUT);
  pinMode(2, OUTPUT);
  pinMode(3, INPUT);
  SPI.setClockDivider(SPI_CLOCK_DIV128);
  SPI.setBitOrder(MSBFIRST);
  SPI.setDataMode(SPI_MODE0);
  // initalize the  data ready and chip select pins:
  pinMode(dataReadyPin, INPUT);
  pinMode(chipSelectPin, OUTPUT);
  digitalWrite(chipSelectPin, HIGH); 
  //pinMode(10, OUTPUT);
  
  try3();
}

void try1() {  
  // initialize Timer4
  cli();               // disable global interrupts
  TCCR4A = B01000000;  // comparator output mode toggle OC4A on match, enable PWM on OCR4A
  TCCR4B = B00000010;  // deadtime = T-C4 div 4, prescale source = clock/16
  //TCCR4C = 0;        // n/a
  //TCCR4D |= B00000010; // Fast PWM on OCR4A
  //TCCR4E = 0;        // n/a
  
  OCR4A = B00000010;   //compare register to 16 = toggle every 16th cycle per TCCR4A
  TCNT4 = 0;           // reset counter to zero
  TIFR4 = 0;           // no ISR
  //TIMSK4 |= B01000000; // generate an interrrupt on OCIE4A?
  //TIMSK4 = _BV(OCIE4A); // not sure i get this... i dont want an ISR since i want hardware PWM
  DDRC |= B10000000;   // set PC7 to output
  
  // enable global interrupts:
  sei();
  
}


void try2() {  // sorta works, get 2.666MHz not-so-square-wave
  // initialize Timer4
  cli();               // disable global interrupts
  TCCR4A = B01000000;  // comparator output mode toggle OC4A on match, enable PWM on OCR4A
  TCCR4B = B00000001;  // deadtime = no division, prescale source = clock/1
  //TCCR4C = 0;        // n/a
  //TCCR4D |= B00000010; // Fast PWM on OCR4A
  //TCCR4E = 0;        // n/a
  
  OCR4A = B00000010;   //compare register to 16 = toggle every 16th cycle per TCCR4A
  OCR4C = B00000011;
  TCNT4 = 0;           // reset counter to zero
  TIFR4 = 0;           // no ISR
  //TIMSK4 |= B01000000; // generate an interrrupt on OCIE4A?
  //TIMSK4 = _BV(OCIE4A); // not sure i get this... i dont want an ISR since i want hardware PWM
  DDRC |= B10000000;   // set PC7 to output
  
  // enable global interrupts:
  sei();
  
}


void try3() {
  
/* explanation... look near bottom for conclusions

(10:06:09 PM) shorted_neuron: any AVR types awake in here?
(10:06:39 PM) Hyratel: kinda, whatcha need?
(10:06:52 PM) shorted_neuron: playing with timer4 on atmega32u4
(10:07:16 PM) shorted_neuron: let me hit pastebin...
(10:07:17 PM) Hyratel: beyond my knowledge though I'll need to learn it soon
(10:11:29 PM) shorted_neuron: http://pastebin.com/y0qFtL4m
(10:22:06 PM) lain: shorted_neuron: what's the issue?
(10:22:45 PM) shorted_neuron: cant seem to get a wave output on OC4A (PORTC 7)
(10:23:03 PM) shorted_neuron: i must be misunderstanding registers, have been looking at it too long
(10:29:10 PM) ***lain looks
(10:33:27 PM) shorted_neuron: hey lain ... i'll admit to being a MCU dummy... normally i work in boring C with libraries to make things go, so i dont get all of the register symbols for avr-gcc
(10:33:39 PM) shorted_neuron: is PWM even what I want to generate a quare wave?
(10:33:46 PM) shorted_neuron: square wave too
(10:34:39 PM) lain: yeah
(10:35:19 PM) lain: hm, WGM41..40 in TCCR4D, you have them set to 10 binary but your comment says Fast PWM
(10:35:30 PM) lain: for Fast PWM, Table 15-19 indicates you want 00 there
(10:37:52 PM) lain: although
(10:37:53 PM) lain: hm..
(10:38:19 PM) lain: ah right
(10:39:33 PM) shorted_neuron: oh... do i need to set OCR4C to give it a "TOP"?
(10:40:28 PM) shorted_neuron: ahha! yes that seems to be it-ish...
(10:40:55 PM) lain: hrm.
(10:41:42 PM) shorted_neuron: actually have a wave form now... , 4MHz... not sure i understand why its 4MHz... 
(10:41:53 PM) lain: how are you measuring it?
(10:43:57 PM) lain: oh I see now, yeah OCR4C is used as the TOP value indeed
(10:44:12 PM) shorted_neuron: not sure if you can see this as diff...
(10:44:14 PM) shorted_neuron: http://pastebin.com/diff.php?i=inNZrBXQ
(10:44:23 PM) shorted_neuron: measuring with oscilloscope
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
(11:04:19 PM) shorted_neuron: and it works
(11:04:21 PM) lain: yup
(11:04:51 PM) shorted_neuron: my goodness you got me a lot further in 30 minutes than i did in several sessions by myself.  thank you very much... time to document...

*/

// initialize Timer4
cli();               // disable global interrupts
TCCR4A = B01000010;  // comparator output mode toggle OC4A on match, enable PWM on OCR4A
//TCCR4C = 0;        // n/a
TCCR4D = B00000000;  // Fast PWM on OCR4A
//TCCR4E = 0;        // n/a

// for 16MHz system, set 1MHz output clock:
TCCR4B = B00000001;  // deadtime = no division, prescale source = clock/1
OCR4A = 7;  // count from zero, so this means we toggle every 8th cycle per TCCR4A
OCR4C = 15; // TOP counter overflow every 16th cycle

//..OR... for 16MHz system, set 1MHz output clock:
TCCR4B = B00000011;  // deadtime = no division, prescale source = clock/4
OCR4A = 1;  // count from zero, so this means we toggle every 8th cycle per TCCR4A
OCR4C = 1; // TOP counter overflow every 16th cycle

//..OR... for 16MHz system, set 500kHz output clock:
TCCR4B = B00000100;  // deadtime = no division, prescale source = clock/4
OCR4A = 1;  // count from zero, so this means we toggle every other cycle per TCCR4A
OCR4C = 1; // TOP counter overflow every other cycle


/* for 16MHz system, set 4MHz output clock (max i can get apparently) */
//TCCR4B = B00000001;  // deadtime = no division, prescale source = clock/1
//OCR4A = 1;  // count from zero, so this means we toggle every other cycle per TCCR4A
//OCR4C = 1; // TOP counter overflow every other cycle



TCNT4 = 0;           // reset counter to zero
TIFR4 = 0;           // no ISR
DDRC |= B10000000;   // set PC7 to output

// enable global interrupts:
sei();
  
}




boolean led = false;
void loop() {

  delay(50);
  led = !led;
  digitalWrite(11, led);
  
  SPI.transfer(B11100100);
  SPI.transfer(0x00);
  SPI.transfer(0x00);
  SPI.transfer(0x00);
  SPI.transfer(0x00);
    
}

