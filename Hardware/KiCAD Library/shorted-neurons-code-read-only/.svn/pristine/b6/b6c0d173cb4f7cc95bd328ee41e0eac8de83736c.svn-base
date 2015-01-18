#include <PString.h>

#define PI 3.1415927
#define SECS 86400

double floaty = 3.141592777769;

// we need fundamental FILE definitions and printf declarations
//#include <stdio.h>

// create a FILE structure to reference our UART output function

//static FILE uartout = {0} ;

// create a output function
// This works because Serial.write, although of
// type virtual, already exists.
/*
static int uart_putchar (char c, FILE *stream)
{
    Serial.write(c) ;
    return 0 ;
}
*/


void setup()
{
  char buffer[40];
  char tmpbuff[40];
  Serial.begin(9600);
  delay(2000);
  
  // There are two main ways to use a PString.
  // First, the "quickie" way, simply renders a single value into a buffer
  PString(buffer, sizeof(buffer), PI); // print the value of PI into the buffer
  Serial.println(buffer); // do whatever you want with "buffer" here.

  // Other "quickie" examples:
  PString(buffer, sizeof(buffer), "Printing strings");
  Serial.println(buffer);
  PString(buffer, sizeof(buffer), SECS);
  Serial.println(buffer);
  PString(buffer, sizeof(buffer), floaty, DEC);
  Serial.println(buffer);
  PString(buffer, sizeof(buffer), SECS, HEX);
  Serial.println(buffer);
  
  // You can also created a (named) PString object and operate
  // on it exactly as you would with Serial or LiquidCrystal
  PString str(buffer, sizeof(buffer));
  str.print("The value of PI is ");
  str.print(PI);
  
  str.begin();
  
     // fill in the UART file descriptor with pointer to writer.
   //fdev_setup_stream (&uartout, uart_putchar, NULL, _FDEV_SETUP_WRITE);

   // The uart is the standard output device STDOUT.
   //stdout = &uartout ;
  

  dtostrf(floaty,8,6,buffer);
  
  //printf("this is printf: %.4f\n", floaty);
  
  //fprintf(&uartout, "fprintf %.4f sec\n", floaty );

  //str += " is mr value.\n";
  
  // At this point, buffer contains "The value of PI is 3.14.."
  // You can get to the data directly...
  Serial.print("next is dtostrf:");
  Serial.println(buffer);
  // ... or indirectly
  Serial.println(str);
  
  // There are a couple of useful member functions:
  Serial.print("The string's length is ");
  Serial.println(str.length());
  Serial.print("Its capacity is ");
  Serial.println(str.capacity());
  
  // You can reuse a PString with the begin() function
  str.begin();
  str.print("Hello, world!");
  Serial.println(str);
  
  // Or accomplish the same thing with the assignment operator:
  str = "Goodbye, cruel";
  
  // PStrings support the concatenation operator 
  
  dtostrf(floaty,10,6,tmpbuff);
  str += tmpbuff;
  str += "helloo\nthere!\n";
  Serial.println(str);
  
  // And you can also check for equivalance
  if (str == "Goodbye, cruel world!")
    Serial.println("Yes, alas, goodbye indeed");
}

void loop()
{}
