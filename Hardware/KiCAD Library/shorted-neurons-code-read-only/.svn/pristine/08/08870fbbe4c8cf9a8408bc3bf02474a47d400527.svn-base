//****************************************************************
/* FIXER FOR:  which should have allowed us to disable sleeper()
 * Watchdog Sleep Example 
 * Demonstrate the Watchdog and Sleep Functions
 */
//****************************************************************

#include <avr/wdt.h>

/*
    Note that for newer devices (ATmega88 and newer, effectively any
    AVR that has the option to also generate interrupts), the watchdog
    timer remains active even after a system reset (except a power-on
    condition), using the fastest prescaler value (approximately 15
    ms).  It is therefore required to turn off the watchdog early
    during program startup, the datasheet recommends a sequence like
    the following:
*/

#include <avr/wdt.h>

//uint8_t mcusr_mirror __attribute__ ((section (".noinit")));
int mcusr_mirror __attribute__ ((section (".noinit")));

int foo = 7;

void get_mcusr(void) \
  __attribute__((naked)) \
  __attribute__((section(".init3")));
void get_mcusr(void) {
  mcusr_mirror = MCUSR;
  MCUSR = 0;
  wdt_disable();
  foo=42;
}


void setup(){
  get_mcusr();
  Serial.begin(9600);
  Serial.println("wdt_disable() succeeded... i think! therefore you should see next line is 42:");
  Serial.println(foo);
  Serial.print("MCUSR started as: ");
  Serial.println(mcusr_mirror);

}

void loop() {
  
}


