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

#include <ADS1213.h>

ADS1213 ADC_ext(2.0,true,13,11,2,5);
// clock speed MHz, true=offset binary (false=two's complement (then the output can be negative)), SCLK pin, IO pin, DRDY pin, CS pin (0 if not in use)

void setup() {
  Serial.begin(115200);
  ADC_ext.CMRwrite(3,B001,1,16,300);
  // channel 3, mode 001 (self-calibration), gain, TMR, Decimation Ratio
  Serial.println("Done with setup");
}

const int NoOfSamples = 60; // Warning: if set too high, DeviationSqSum may overflow!
// This will happen sooner when the real standard deviation is higher.
unsigned long Values[NoOfSamples];

void loop() {
  // Set a time marker to later on calculate the approximate samples per second:
  unsigned long SPSbegin = micros();
  // First read the specified number of samples:
  for (int i=0; i<NoOfSamples; i++) {
    Values[i] = ADC_ext.read(B000,3);
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
  delay(1000); // Wait a second to avoid overflowing the serial monitor with data
}
