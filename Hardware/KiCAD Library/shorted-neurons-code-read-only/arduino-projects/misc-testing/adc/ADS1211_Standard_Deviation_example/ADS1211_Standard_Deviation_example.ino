/*
This sketch demonstrates the use of the ADS1213 library by first initializing
it with the neccesary parameters, then reading a specified number of samples,
and then calculating the mean value (average) and standard deviation.
  The mean gives a reasonable estimate of the noise-free value. The standard
deviation gives an indication of the spread of the samples (see note below).
  This sketch can be used to assess the accuracy of the ADC in certain conditions
and with certain settings. Note that doubling the gain will usually double the
standard deviation as it is twice as sensitive. Many factors influence the
accuracy, the most obvious ones being: the layout of the board, the filters
used (use filters as per the datasheet for best results) and the noise in the
power supply. PC power supplies can be quite noisy, if you want to compare
the operational accuracy of your ADC, always find a way to measure it with its
final board layout and power supply. Only then you can get accurate results.
  Note: Assuming a bell-shaped distribution of the results, within one standard
deviation from the mean, 68% of all results lie. 95% of all results lie
within 2 standard deviations.

Calculating the mean and standard deviation can also be used for data filters.
A bunch of samples can be discarded when the standard deviation is too large.
An even better improvement would be, for example, to discard the lowest and
highest values, to discard noise.
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


#include <ADS1213.h>







void initPWM() {

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






void setup() { 
  //CPU_PRESCALE(CPU_125kHz);  // power supply still ramping up voltage
  //delay(3);              // actual delay 128 ms when F_OSC is 16000000
  //CPU_PRESCALE(CPU_16MHz);

  Serial.begin(9600);
 

  
  Serial.println("start with setup");
  delay(2000);
  
  initPWM(); // set up a timer4 clock to give clock to our ADC
  
  //ADC_ext.CMRwrite(1,B001,1,16,300);
  // channel 3, mode 001 (self-calibration), gain, TMR, Decimation Ratio
  Serial.println("Done with setup");
}

const int NoOfSamples = 20; // Warning: if set too high, DeviationSqSum may overflow!
// This will happen sooner when the real standard deviation is higher.
unsigned long Values[NoOfSamples];

boolean led = false;
boolean first = true;

void loop() {

  if (first) {
    Serial.println("first time go... constructing adc object");    
    ADS1213 ADC_ext(1.0,true,1,2,5,4);
    // clock speed MHz, true=offset binary (false=two's complement (then the output can be negative)), SCLK pin, IO pin, DRDY pin, CS pin (0 if not in use)

    Serial.println("object done, now configuring....");
    ADC_ext.CMRwrite(1,B001,1,16,300);
    // channel 1, mode 001 (self-calibration), gain, TMR, Decimation Ratio

    first = false;
    Serial.println("DONE with first time go");
    while(true) {
      // Set a time marker to later on calculate the approximate samples per second:
      delay(50);
      led = !led;
      digitalWrite(11, led);
      
      unsigned long SPSbegin = micros();
      // First read the specified number of samples:
      for (int i=0; i<NoOfSamples; i++) {
        //Serial.println("about to read");
        Values[i] = ADC_ext.read(B000,3);
        //Values[i] = i;
      }
      // Then calculate and print the samples per second to compare the speed of different settings:
      unsigned int SPS = 1000000*NoOfSamples/(micros() - SPSbegin);
      Serial.print("SPS: "); Serial.println(SPS,DEC);
    
      // Calculate and print mean:
      unsigned long ValuesAccum = 0;
      for (int i=0; i<NoOfSamples; i++) {
        ValuesAccum += Values[i];
      }
      unsigned long Mean = 0;
      Mean = ValuesAccum/NoOfSamples;
      Serial.print("Mean: "); Serial.println(Mean,DEC);
      
      // Calculate standard deviation:
      unsigned long DeviationSqSum = 0;
      for (int i=0; i<NoOfSamples; i++) {
        DeviationSqSum += sq(Values[i] - Mean);
      }
      //Serial.print("Std deviation sum of all squares: "); Serial.println(DeviationSqSum); // For debugging if you don't trust the std. dev. values
      unsigned long StdDeviation = sqrt(DeviationSqSum/(NoOfSamples));
      Serial.print("Std deviation: "); Serial.println(StdDeviation);
        led = !led;
      digitalWrite(11, led);
      delay(1000); // Wait a second to avoid overflowing the serial monitor with data
    }
  }
  
  
}
