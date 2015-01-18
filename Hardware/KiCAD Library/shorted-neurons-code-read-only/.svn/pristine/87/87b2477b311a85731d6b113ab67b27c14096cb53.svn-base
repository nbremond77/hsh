#define LAUNCHER_UNITTYPE_RACK r
#define HARDCODED_UNITTYPE r
byte unitType = 'r';
#define DEBUG_VIA_SERIAL 1
//#define LAUNCHER_UNITTYPE_CONTROLLER 1
//#define HARDCODED_UNITTYPE C
//byte unitType = 'C';

#ifdef LAUNCHER_UNITTYPE_RACK
#define NODEID        1    //unique for each node on same network
#define NETWORKID     100  //the same on all nodes that talk to each other
#define RACKID        1
#define CONTROLLERID  2
#define CONTROLLER_RADIO_ADDRESS 0x02 //21
#endif

#ifdef LAUNCHER_UNITTYPE_CONTROLLER
#define NODEID        2    //unique for each node on same network
#define NETWORKID     100  //the same on all nodes that talk to each other
#define RACKID        1
#define CONTROLLERID  2
#define CONTROLLER_RADIO_ADDRESS 0x02 //21
#endif


//#define RADIO_TYPE_RFM12B 1
//#define RADIO_TYPE_RFM22B 1
#define RADIO_TYPE_RFM69HW 1

#define NUM_CHANNELS 4

#define SERIAL_BAUD_RATE 115200

#define DATAOUT 11  //MOSI
#define DATAIN 12   //MISO - not used, but part of builtin SPI
#define SPICLOCK 13 //sck

#include <SPI.h>
#define ADCSelectPin 17

#include <Mcp23s17.h>


#include <Streaming.h>
#include <PString.h>

// Flash has to come after Streaming because of conflicting definition of endl
#include <Flash.h>

#ifdef RADIO_TYPE_RFM12B
#include <JeeLib.h>
volatile uint8_t * recvdPacket;
#endif

#ifdef RADIO_TYPE_RFM22B
#include <JeeLib.h>
volatile uint8_t * recvdPacket;
#endif

#ifdef RADIO_TYPE_RFM69HW
#include <JeeLib.h>
#include <RFM69.h>
//Match frequency to the hardware version of the radio (uncomment one):
#define FREQUENCY   RF69_433MHZ
//#define FREQUENCY   RF69_868MHZ
//#define FREQUENCY     RF69_915MHZ
#define ENCRYPTKEY    "sampleEncryptKey" //exactly the same 16 characters/bytes on all nodes!
#define IS_RFM69HW    //uncomment only for RFM69HW! Leave out if you have RFM69W!
#define ACK_TIME      30 // max # of ms to wait for an ack

RFM69 radio;

volatile uint8_t * recvdPacket;
#endif




#define MCP23S17_SLAVE_SELECT_PIN 3 //arduino   <->   SPI Slave Select           -> CS  (Pin 11 on MCP23S17 DIP)
// SINGLE DEVICE
// Instantiate a single Mcp23s17 object
//MCP23S17 Mcp23s17 = MCP23S17( MCP23S17_SLAVE_SELECT_PIN );
MCP23S17 Mcp23s17 = MCP23S17(MCP23S17_SLAVE_SELECT_PIN, 0x7);
MCP23S17 Mcp23s17b = MCP23S17(MCP23S17_SLAVE_SELECT_PIN,0x0);


#define safetySw 16
#define armOrSafeLED 8
#define buzzerPin 9
//#define buzzerPin 5
#define txrxPin 5
#define gpioReset 4
#define fireSw 7
#define hvArmPin 6

MilliTimer sendTimer;
char start_msg[] = "BLINK";
byte needToSend, remote_pin, set_state;
int last_state = HIGH;
int low_count = 10;


#define ARM_LED_ON LOW
#define SAFE_LED_ON HIGH
#define SAFETY_KEY_INSERTED LOW
#define FIRE_SWITCH_DEPRESSED LOW

//status codes
#define STATE_SAFE 0x71    // 'q'
#define STATE_ARMED 0x41   // 'A'
#define STATE_FIRING 0x21  // '!'
#define STATE_BRICKED 0x78 // 'x'

byte state = STATE_SAFE;

boolean statesChanged = false;
boolean updatingSelections = false;





int availableMemory() {
  int size = 2048;
  byte *buf;
  while ((buf = (byte *) malloc(--size)) == NULL);
  free(buf);
  return size;
} 


//  BEGIN adc smoothing stuff //////////////////////
// Define the number of samples to keep track of.  The higher the number,
// the more the readings will be smoothed, but the slower the output will
// respond to the input.  Using a constant rather than a normal variable lets
// use this value to determine the size of the readings array.
const int numReadings = 20;

uint16_t readings[numReadings];      // the readings from the analog input
int index = 0;                  // the index of the current reading
uint16_t total = 0;                  // the running total
uint16_t average = 0;                // the average
// end adc smoothing stuff

uint16_t pinstateB = 0x0000;
uint16_t oldPinstateB = 0x0000;
uint16_t trash = 0x0000;

uint8_t channelsRaw[NUM_CHANNELS];
uint8_t currentChan = 0;
uint16_t counter = 0x0001;

long ops=0;

uint8_t armState = 0x00;
uint8_t oldArmState = 0x00;
uint8_t continuityState = 0x00;
uint16_t displayAstate = 0x0000;
uint16_t displayBstate = 0x0000;
char armedRack = 'N';
boolean shortedToggler = false;



uint8_t selectedState = 0x00;
uint8_t firingState = 0x00;




// ///////////////////////////////////////
// mcp3208 ADC stuff
#define AREFmv 3000
#define DEF12bits 4096
#define DEF10bits 1024
#define DEF12vR1 1000
#define DEF12vR2 5100
#define DEFmaxV 18300

// MAX6030 precision 3.000V reference
#define AREFvolts 3.000
#define AREFscaler 6.1  // divider ratio... 5.1k / 1k
//#define AREFmult 3735 // 3735 ~= 1000 * 3000 / 1024 * 5.1;
#define AREFmult 4468 // 4468 ~= 1000 * 3000 / 1024 * 6.1;
#define AREFdiv 1000 // divide afterwards to get back to an INT
#define batteryThresholdMilliVolts 3550


uint8_t i = 0;

void updateContinuity()
{
#ifdef LAUNCHER_UNITTYPE_CONTROLLER

  //Serial.println(F("This is a controller... not much point reading ADC when we dont have one"));
  1;
#endif

#ifdef LAUNCHER_UNITTYPE_RACK

  for (i = 0; i < NUM_CHANNELS; ++i) {
    channelsRaw[i] = (uint8_t) (readADC(i) / 16); // we need only 8 bits of resolution, but cannot just chop off the top bits
#ifdef DEBUG_VIA_SERIAL
    Serial.print("channel ");
    Serial.print(i,DEC);
    Serial.print(" raw=");
    Serial.print(readADC(i),DEC);
    Serial.print(", div16=");
    Serial.println(channelsRaw[i],DEC);
#endif    
  }

  /*
  // subtract the last reading:
   total= total - readings[index];         
   // read from the sensor:  
   readings[index] = readADC(0);
   // add the reading to the total:
   total= total + readings[index];       
   // advance to the next position in the array:  
   index = index + 1;                    
   
   // if we're at the end of the array...
   if (index >= numReadings)              
   // ...wrap around to the beginning: 
   index = 0;                           
   
   // calculate the average:
   average = total / numReadings;         
   */

  /*
  long mv = long(crap3) * AREFmult;
   mv = mv / AREFdiv;
   
   //float volts = float(crap3) * AREFvolts * AREFscaler / DEF12bits;
   
   Serial.print(" mv=");
   Serial.print(mv);
   //Serial.print(" V=");
   //Serial.print(volts,4);
   Serial.print(" mapped=");
   Serial.println(map(crap3,0,DEF12bits,0,DEFmaxV));
   */


#endif

}

byte commandMSB = 0x00;
byte msb = 0x00;
byte lsb = 0x00;

uint16_t readADC(int channel)
{

  uint16_t output;
  //Channel must be from 0 to 7
  //Shift bits to match datasheet for MCP3208
  commandMSB = B00000110;
  uint16_t commandBytes = (uint16_t) (commandMSB<<8|channel<<6);

  //Select ADC
  noInterrupts();
  digitalWrite(ADCSelectPin, LOW);
  //send start bit and bit to specify single or differential mode (single mode chosen here)
  SPI.transfer((commandBytes>>8) & 0xff);

  msb = SPI.transfer((byte)commandBytes & 0xff) & B00001111;
  lsb = SPI.transfer(0x00);
  //msb=0xBE;
  //lsb=0xEF;
  digitalWrite(ADCSelectPin,HIGH);
  interrupts();
  // cast before shiting the byte
  return(((uint16_t) msb) <<8 | lsb);

}

// end mcp3208 adc stuff
/////////////////////////////////////////



// byte reverser
// Reverses the order of bits in a byte.
// I.e. MSB is swapped with LSB, etc.
unsigned char reverse_bit_order( unsigned char x )
{
  x = ((x >> 1) & 0x55) | ((x << 1) & 0xaa);
  x = ((x >> 2) & 0x33) | ((x << 2) & 0xcc);
  x = ((x >> 4) & 0x0f) | ((x << 4) & 0xf0);
  return x;   
} 
// end byte reverser




// ______________________________________________________________________________
void mapStatesToDisplay() {

#ifdef LAUNCHER_UNITTYPE_CONTROLLER
  // prototype switch and LED wiring is a little counter-intuitive to the programmer 
  // so we use this function to remap when needed
  // controller display looks like this, with IO and bit num indicated. 

  //        RED=GAB.7  |  R-G=GAB.4,GAB.5  |    YELLOW=GBA.2    |  WHITE=GBA.0
  //           1       |        2          |          3         |       4
  //      GREEN=GAB.3  |    BLUE=GAB.1     |  R-G=GBA.6,GBA.7   |  RGB=GBA.5,GBA.1,GBA.4
  //        sw1=GBB.0  |     sw2=GBB.1     |       sw3=GBB.2    |    sw4=GBB.3

  // where Mcp.port() returns two bytes:
  //  portB    portA
  // 00000000 00000000
  // 76543210 76543210

  // lets start with empty...
  
  armState = 0x00;
  displayAstate = 0x0000;
  displayBstate = 0x0000;


  // switch 1 is B.bit4, shift it over to 
  armState = armState | ((pinstateB & B00000001) << 7);
  armState = armState | ((pinstateB & B00000010) << 5);
  armState = armState | ((pinstateB & B00000100) << 3);
  armState = armState | ((pinstateB & B00001000) << 1);

#ifdef DEBUG_VIA_SERIAL
  Serial.print("armState1 is now: rack=");
  Serial.print(armedRack);
  Serial.print(", "); 
  Serial.println(armState, BIN);

  Serial.print("oldArmState1 is now: rack=");
  Serial.print(armedRack);
  Serial.print(", "); 
  Serial.println(oldArmState, BIN);
#endif  
  
  if ((armState != oldArmState) && (armState != 0x00)){
  
    uint8_t newArmState = (armState ^ oldArmState);  // i used XOR productively for the first time!
    oldArmState = newArmState;  
    armState = newArmState;  

    //Serial.print("armState2 is now: rack=");
    //Serial.print(armedRack);
    //Serial.print(", "); 
    //Serial.println(armState, BIN);
    
  } else {
    armState = oldArmState;
  }
 


  // this is the rack select A/B switch
  armedRack = 'N';
  //Serial.println("Inside mapStatesToDisplay for CONTROLLER");

  if ( ((pinstateB & B01000000) & ((pinstateB & B10000000) >> 1)) ) {
    Serial.println("ERROR!!! we should never be able to see both A and B armed at same time!");
    armState=0x00;
    oldArmState=0x00;
    armedRack='E';
  } 
  else {
    if ((pinstateB & B01000000) != 0 ) {
      armedRack = 'A';
    } 
    else {
      if ((pinstateB & B10000000) != 0 ) { 
        armedRack = 'B';
      } 
      else {
        // nobody armed, switch is in middle
        armedRack='N';
      }
    }
  }

  //Serial.print("armState is now: rack=");
  //Serial.print(armedRack);
  //Serial.print(", "); 
  //Serial.println(armState, BIN);

  //armState = armState | ((pinstateB & B10000000) >> 7);  


  //Serial.print("armState3 is now: rack=");
  //Serial.print(armedRack);
  //Serial.print(", "); 
  //Serial.println(armState, BIN);

  // rack selector display business... rack A = display A port A bit 0
  displayAstate = displayAstate | ((pinstateB & B01000000) >> 6);

  // rack selector display business... rack B = display A port A bit 1
  displayAstate = displayAstate | ((pinstateB & B10000000) >> 6);  


  //armState chan 1 maps to display A port B bit 7
  displayAstate = displayAstate | ((armState & B10000000) << 8);

  //armState chan 2 maps to display A port B bit 5 (for red)
  displayAstate = displayAstate | ((armState & B01000000) << 6);

  //armState chan 3 maps to display B port A bit 2
  displayBstate = displayBstate | ((armState & B00100000) >> 3);
  //Serial.print("displayB.1 is now: ");
  //Serial.println(displayBstate,BIN);
  //armState chan 4 maps to display B port A bit 0
  displayBstate = displayBstate | ((armState & B00010000) >> 4);
  //Serial.print("displayB.2 is now: ");
  //Serial.println(displayBstate,BIN);


  // for testing controller side, for now reflect continuity leds = arm leds
  // _____________FIXME___________________FIXME__________FIXME
  //continuityState = armState;
  // _____________FIXME___________________FIXME__________FIXME

  //continuityState chan 1 maps to display A port B bit 3
  displayAstate = displayAstate | ((continuityState & B10000000) << 4);

  //continuityState chan 2 maps to display A port B bit 1
  displayAstate = displayAstate | ((continuityState & B01000000) << 3);

  //continuityState chan 3 maps to display B port A bit 7 for green
  // Fucking wierd... this one doesnt work, breaks the calling of transmit() @#&$*^@???
  //displayBstate = displayBstate | ((armState & B00100000) << 2);
  //continuityState chan 3 maps to display B port A bit 6 for red
  displayBstate = displayBstate | ((continuityState & B00100000) << 1);
  //Serial.print("displayB.3 is now: ");
  //Serial.println(displayBstate,BIN);

  //continuityState chan 4 maps to display B port A bit 1 for green
  displayBstate = displayBstate | ((continuityState & B00010000) >> 3);
  //Serial.print("displayB.4 is now: ");
  //Serial.println(displayBstate,BIN);

#endif

#ifdef LAUNCHER_UNITTYPE_RACK
  // prototype switch and LED wiring is a little counter-intuitive to the programmer 
  // so we use this function to remap when needed
  // controller display looks like this, with IO and bit num indicated. 


  // where Mcp.port() returns two bytes:
  //  portB    portA
  // 00000000 00000000
  // 76543210 76543210

  // lets start with empty...
  armState = 0x00;
  displayAstate = 0x0000;
  displayBstate = 0x0000;
  continuityState = 0x00;
  
  //Serial.print("this was selectedState: "); Serial.println(selectedState,BIN);
  
  for (uint8_t i = 0; i < NUM_CHANNELS; ++i) {
    //shorted
    /*Serial.print("displaymapping channel ");
    Serial.print(i,DEC);
    Serial.print(" raw=");
    Serial.println(channelsRaw[i],DEC);
    */

    if (channelsRaw[i] < 10) {
       if (shortedToggler) 
         channelsRaw[i] = 129;    
    }

    if (channelsRaw[i] < 128) {
      displayAstate = displayAstate | (B10000000 >> (i*2));

      continuityState = continuityState | (B10000000 >> i);
    }


    //Serial.print("this is bit number "); Serial.print(i,DEC);
    //Serial.print("which has select status: ");
    //Serial.println(((selectedState << i )& B10000000) >> 7);
    displayAstate = displayAstate | (((selectedState << i) & B10000000) >> ((i*2) + 1));


  }

  if (shortedToggler) {
    shortedToggler = false;
  } else {
    shortedToggler = true;
  }

  

  //Serial.print("FINAL displayAstate is now: ");
  displayAstate = displayAstate | (displayAstate << 8);
  //Serial.println(displayAstate, BIN);


#endif


}

// ______________________________________________________________________________
void updateDisplay() {

  /* interrupts must be disabled because currently if the radio recieves
   a packet, we interrupt and service it right away in a non-safe way 
   with respect to the SPI bus.  This could be fixed by the interrupt
   routine just setting a var which we check again often to see if we
   need to service the radio, but I am not sure what that would do WRT
   incoming packets.  
   */
  noInterrupts(); 
  Mcp23s17.port(displayAstate);
  if (unitType == 'C') {
    //Serial.println(F("this is a controller so updating partial display on gpioB"));
    Mcp23s17b.port(displayBstate);
  }
  interrupts();
  if( updatingSelections) {
    delay(30);
    updatingSelections = false;
  }
}






// ______________________________________________________________________________
void rackListen() {
#ifdef DEBUG_VIA_SERIAL
  Serial.println("rackListen: listening");
#endif
  byte j = 0;
  boolean waitingOnPacket = true;
  while ((j < 1000) && waitingOnPacket) {

    if (softTimeout()) waitingOnPacket = false;
#ifdef RADIO_TYPE_RFM12B    
    if (rf12_recvDone() && rf12_crc == 0) {
      waitingOnPacket = false;
      digitalWrite(txrxPin,LOW);
      Serial.println("got somethin");
      //recvdPacket = (volatile uint8_t *)rf12_data;
      recvdPacket = rf12_data;

      if (rf12_len != 8) {

#ifdef DEBUG_VIA_SERIAL
        Serial.println(F("Error: wrong byte count, payload is:"));
        for (byte i = 0; i < rf12_len; ++i)
          Serial.print((char)recvdPacket[i]);
        Serial.println();
#endif        
#endif

#ifdef RADIO_TYPE_RFM69HW    
    if (radio.receiveDone() && rf12_crc == 0) {
      waitingOnPacket = false;
      digitalWrite(txrxPin,LOW);
      Serial.println("got somethin");
      //recvdPacket = (volatile uint8_t *)rf12_data;
      recvdPacket = radio.DATA;

      if (radio.DATALEN != 8) {

#ifdef DEBUG_VIA_SERIAL
        Serial.println(F("Error: wrong byte count, payload is:"));
        for (byte i = 0; i < radio.DATALEN; ++i)
          Serial.print((char)recvdPacket[i]);
        Serial.println();
#endif

      if (radio.ACK_REQUESTED)
      {
        radio.sendACK();
        Serial.print(" - ACK sent");
        delay(10);
      }

#endif

        
      } else {
#ifdef DEBUG_VIA_SERIAL
        Serial.print("OK, received: ");
        Serial.print("rack=");
        Serial.print(recvdPacket[0]);
        Serial.print(", rackHex=");
        Serial.print(recvdPacket[1], HEX);
        Serial.print(", command=");
        Serial.print(recvdPacket[2]);
        Serial.print(", selected=");
        Serial.print(recvdPacket[3], BIN);
        Serial.print(", firing=");
        Serial.print(recvdPacket[4], BIN);
        Serial.print(", b=");
        Serial.print(recvdPacket[5]);
        Serial.print(", t=");
        Serial.print(recvdPacket[6]);    
        Serial.print(", s=");
        Serial.print(recvdPacket[7]);    
        Serial.println();
#endif
        selectedState = recvdPacket[3];          
        //Serial.print("this was selectedState right before figuring out what came over: "); Serial.println(selectedState,BIN);          
        byte cmd = recvdPacket[2];
        //selectedState = 0x00;
        firingState = 0x00;

        if (state != STATE_BRICKED && cmd == STATE_SAFE) {
          //Serial.println("controller wants us to go SAFE___________________________");
          stopFire();
          state = STATE_SAFE;
          
                  
        }
        
        if (state == STATE_SAFE && cmd == STATE_ARMED) {
          //Serial.println(F("CONTROLLER TURNED US TO ARMED!!!!!"));
          state = STATE_ARMED;
          selectedState = recvdPacket[3];
                  
        }

        if (state == STATE_FIRING && cmd == STATE_ARMED) {
          //Serial.println(F("whoa, slow down! stop firing and go to ARMED"));
          state = STATE_ARMED;
          stopFire();
          selectedState = recvdPacket[3];                  
        }


        if (state != STATE_SAFE && cmd == STATE_SAFE) {
          //Serial.println(F("controller wants us to go SAFE___________________________"));
          stopFire();
          state = STATE_SAFE;
                  
        }
  
        if (state == STATE_ARMED && cmd == STATE_FIRING) {
          //Serial.println(F("!!!!!!!!!!!!!!!!! controller wants us to FIRE!!!!!!!!!!!!!!!!"));
          state = STATE_FIRING;
          firingState = recvdPacket[4];
        }
  
        if (cmd == STATE_FIRING || cmd == STATE_ARMED || cmd == STATE_SAFE) {
          resetTimeout();
        }
      }
      digitalWrite(txrxPin,HIGH);
      needToSend = true;
      delay(10);
      //Serial.print("this was selectedState right before rackTransmit: "); Serial.println(selectedState,BIN);
      rackTransmit();
    }
  }
}






// ______________________________________________________________________________
void controllerListen() {
#ifdef DEBUG_VIA_SERIAL
  Serial.println("controllerListen(): listening");
#endif

  boolean waitingOnPacket = true;
  while (waitingOnPacket) {
    //Serial.print("listening2");    
    if (softTimeout()) { waitingOnPacket = false; }
#ifdef RADIO_TYPE_RFM12B    
    //Serial.println(" listening3");    
    if (rf12_recvDone() && rf12_crc == 0) {
      digitalWrite(txrxPin,LOW);
      waitingOnPacket = false;
      recvdPacket = rf12_data;

      Serial.println("got somethin");
      if (rf12_len != 8) {
#ifdef DEBUG_VIA_SERIAL
        Serial.println(F("Error: wrong byte count, payload is:"));
          for (byte i = 0; i < rf12_len; ++i)
            Serial.print(recvdPacket[i]);
          Serial.println();
#endif
#endif

#ifdef RADIO_TYPE_RFM69HW
    if (radio.receiveDone()) {
      waitingOnPacket = false;
      digitalWrite(txrxPin,LOW);
      Serial.println("got somethin");
      //recvdPacket = (volatile uint8_t *)rf12_data;
      recvdPacket = radio.DATA;

      if (radio.ACK_REQUESTED)
      {
        radio.sendACK();
        Serial.print(" - ACK sent");
        //delay(10);
      }

      if (radio.DATALEN != 8) {

#ifdef DEBUG_VIA_SERIAL
        Serial.println(F("Error: wrong byte count, payload is:"));
        for (byte i = 0; i < radio.DATALEN; ++i)
          Serial.print((char)recvdPacket[i]);
        Serial.println();
#endif
#endif



      } else {
#ifdef DEBUG_VIA_SERIAL
        Serial.print("OK, received: ");
#endif
  //      for (byte i = 0; i < rf12_len; ++i)
    //      Serial.print(recvdPacket[i]);
      //  Serial.println();
          //Serial.print(header);
  //    for (byte i = 0; i < 8; ++i)
  //      Serial.print(payload[i],HEX);
  
  /*  char payload[] = {
        'M','e', state, continuityState, selectedState,  firingState, 'V', 'I'};
  */
#ifdef DEBUG_VIA_SERIAL  
        Serial.print("rack=");
        Serial.print(recvdPacket[0]);
        Serial.print(", rackHex=");
        Serial.print(recvdPacket[1], HEX);
        Serial.print(", state=");
        Serial.print(recvdPacket[2]);
        Serial.print(", continuityState=");
        Serial.print(recvdPacket[3], BIN);
        Serial.print(", selected=");
        Serial.print(recvdPacket[4], BIN);
        Serial.print(", firing=");
        Serial.print(recvdPacket[5], BIN);
        //selectedState=recvdPacket[4];
        Serial.print(", t=");
        Serial.print(recvdPacket[6]);    
        Serial.print(", s=");
        Serial.print(recvdPacket[7]);    
        Serial.println();
#endif
        continuityState=recvdPacket[3];
        selectedState=recvdPacket[4];
        
        byte cmd = recvdPacket[2];  
      }
      digitalWrite(txrxPin,HIGH);
    }
  }
}








// ______________________________________________________________________________
void rackTransmit() {
  //if (sendTimer.poll(700))
  //    needToSend = 1;

  boolean waitingOnPacket = true;

  //Serial.println("Preparing to rackTransmit()");
  while(needToSend && (! checkTimeout())) {
    rf12_recvDone();

    //Serial.println("really going to rackTransmit()");
#ifdef RADIO_TYPE_RFM12B
    if (needToSend && rf12_canSend()) {
#endif

#ifdef RADIO_TYPE_RFM69HW
    if (needToSend ) {
#endif

        //Serial.println("REALLY really going to rackTransmit()");
        needToSend = 0;
      //sendLed(1);
  
    /*    Status response protocol packet to send from pad to Controller:
          Rack ID - 1 Byte
          Rack UUID - 1 Byte
          Command last seen - 1 Byte
          Channel state
              -Continuity - 1 Byte
              -Selected - 1 Byte
              -Firing - 1 Byte
          Stats
              -Voltage - 1 Byte
              -Current - 1 Byte
          Total: 8 bytes
          
  
    */
    
      uint8_t firing = 0;
      if ( state == STATE_FIRING ) 
        firing = armState;
  
      char payload[] = {
        'M','e', state, continuityState, selectedState,  firingState, 'V', 'I'};
  
  
#ifdef DEBUG_VIA_SERIAL
      Serial.print(F("Rack is sending the following STATUS: "));
      Serial.print("rack=");
      Serial.print(payload[0]);
      Serial.print(", rackHex=");
      Serial.print(payload[1], HEX);
      Serial.print(", command=");
      Serial.print(payload[2]);
      Serial.print(", selected=");
      //Serial.print(payload[3],BIN);
      Serial.print(armState, BIN);
      Serial.print(", firing=");
      Serial.print(firing, BIN);
      Serial.print(", b=");
      Serial.print(payload[5]);
      Serial.print(", t=");
      Serial.print(payload[6]);    
      Serial.print(", s=");
      Serial.print(payload[7]);    
      Serial.println();
#endif

#ifdef RADIO_TYPE_RFM12B
    byte header = 0 | RF12_HDR_DST | RACKID;
    rf12_sendStart(header, payload, sizeof payload);
#endif

#ifdef RADIO_TYPE_RFM69HW
    radio.sendWithRetry(RACKID, payload, sizeof payload);
#endif


           
    }
  }
}

// ______________________________________________________________________________
#ifdef LAUNCHER_UNITTYPE_CONTROLLER
void controllerTransmit() {
  if (sendTimer.poll(700))
      needToSend = 1;
  Serial.println("in controllerTransmit()");
#ifdef RADIO_TYPE_RFM12B
  if (needToSend && rf12_canSend()) {
#endif

#ifdef RADIO_TYPE_RFM69HW
  if (needToSend ) {
#endif

    Serial.println("Preparing to send");
    needToSend = 0;

    //sendLed(1);

  /*    Control protocol packet to send To pad:
        Rack number - 1 Byte
        Rack UUID - 1 Byte
        Command - 1 Byte
            -Initialize
            -Status
            -Arm
            -Fire
            -Safe
        Command params (2 bytes below depending on command in previous byte)
            -Initialize - 2 bytes ACK
            -Status - 2 Bytes @ 0
                 -No params
            -Arm - 1 Byte selected + 1 Byte always 0x00
                 -Channels selected
            -Fire - 1 Byte selected + 1 Byte trigger
                 -Channels selected
                 -Channels to trigger
            -Safe - 2 Bytes always 0xFF
                 -No params
        Padding - 3 bytes
        Total:8 bytes
  */
  
    uint8_t firing = 0;
    if ( state == STATE_FIRING ) 
      firing = armState;

    char payload[] = {
      armedRack,armedRack, state, armState, firing, 'b', 't', 's'};


#ifdef DEBUG_VIA_SERIAL
    Serial.print("Sending: ");
    Serial.print("rack=");
    Serial.print(payload[0]);
    Serial.print(", rackHex=");
    Serial.print(payload[1], HEX);
    Serial.print(", command=");
    Serial.print(payload[2]);
    Serial.print(", selected=");
    //Serial.print(payload[3],BIN);
    Serial.print(armState, BIN);
    Serial.print(", firing=");
    Serial.print(firing, BIN);
    Serial.print(", b=");
    Serial.print(payload[5]);
    Serial.print(", t=");
    Serial.print(payload[6]);    
    Serial.print(", s=");
    Serial.print(payload[7]);    
    Serial.println();
#endif

#ifdef RADIO_TYPE_RFM12B
    byte header = 0 | RF12_HDR_DST | RACKID;
    rf12_sendStart(header, payload, sizeof payload);
#endif

#ifdef RADIO_TYPE_RFM69HW
    radio.sendWithRetry(RACKID, payload, sizeof payload);
#endif


  }
  //resetTimeout();
  resetSoftTimeout();
  delay(1);
  controllerListen();  
}
#endif



#ifdef LAUNCHER_UNITTYPE_RACK
// ______________________________________________________________________________
void safeRackUnit() {

  digitalWrite(hvArmPin, LOW);

  for (i = 0; i < NUM_CHANNELS; ++i) {
    channelsRaw[i] = 255;
  }

  selectedState = 0x00;
  armState = 0x00;
  oldArmState = 0x00;
  //analogWrite(buzzerPin, 0); 
  digitalWrite(armOrSafeLED, SAFE_LED_ON);
  stopFire();
  Mcp23s17b.port(0x0000);
  Serial.println("system is now safe");

}
#endif



#define BUZZER_ARMED 100
#define BUZZER_FIRING 200

void armSystem() {
  digitalWrite(armOrSafeLED, ARM_LED_ON);
  //analogWrite(buzzerPin, BUZZER_ARMED); 
  digitalWrite(hvArmPin, HIGH);
  //Serial.println("system is ARMED");

}



void fireFireFire() {
  //analogWrite(buzzerPin, BUZZER_FIRING); 
#ifdef DEBUG_VIA_SERIAL
  Serial.println("system is FIRING");
  Serial.print(F("                              displayB before fire was:"));
  Serial.println(displayBstate, BIN);
#endif
  displayBstate = displayBstate | ((uint16_t) (reverse_bit_order(firingState)));
  displayBstate = displayBstate | ((uint16_t) (reverse_bit_order(firingState) << 8));

#ifdef DEBUG_VIA_SERIAL  
  Serial.print(F("                              displayB ReADY to FIRE:"));
  Serial.println(displayBstate, BIN);
#endif

  noInterrupts();
  Mcp23s17b.port(displayBstate);
  //Mcp23s17b.port(0xFFFF);
  interrupts();
}

void stopFire() {
  Serial.println("system is stopping fire.  we hope.");
  displayBstate = displayBstate &  0x00FF;
  displayBstate = 0x0000;
  noInterrupts();
  Mcp23s17b.port(displayBstate);
  interrupts();

}






long timeoutAtMillis = 0;
long softTimeoutAtMillis = 0;
static const long timeoutPeriod = 600;
long timeoutsTripped = 0;

void resetTimeout() {
  timeoutAtMillis = (millis() + timeoutPeriod);
}

void resetSoftTimeout() {
  if (unitType == 'C')
    softTimeoutAtMillis = (millis() + timeoutPeriod/2);

  if (unitType == 'r')
    softTimeoutAtMillis = (millis() + timeoutPeriod*2);
  
}

boolean checkTimeout() {
  if ( timeoutAtMillis > millis() ) {
#ifdef DEBUG_VIA_SERIAL    
    Serial.println("no timeout");
#endif    
    return(false);
  } 
  else {
    timeoutsTripped++;
    Serial.print("TIMEOUT!!!!!!! timeoutsTripped=");
    Serial.println(timeoutsTripped);
    state = STATE_SAFE;
#ifdef LAUNCHER_UNITTYPE_RACK    
    safeRackUnit();    
#endif    
    statesChanged = true;
    delay(50);
    return(true);
  }
}


boolean softTimeout() {
  if ( softTimeoutAtMillis > millis() ) {
    return(false);
  } else {
    statesChanged = true;
    return(true);
  }
}


#ifdef LAUNCHER_UNITTYPE_CONTROLLER
void checkSafetyKey() {
  if (digitalRead(safetySw) == SAFETY_KEY_INSERTED) {
    // read it again
    delay(5);
    if (digitalRead(safetySw) == SAFETY_KEY_INSERTED) {
      if (state == STATE_FIRING) {
        // this is okay, continue allowing fire
        //Serial.println(F("safety key still in, allowing fire to continue"));
        1;
      } else {
        state = STATE_ARMED;
         resetTimeout();
      }
      
      statesChanged = true;
      resetTimeout();
    } else {
      state = STATE_SAFE;
      statesChanged = true;
    }

  } else {
    state = STATE_SAFE;
    statesChanged = true;
  }

}
#endif


#ifdef LAUNCHER_UNITTYPE_CONTROLLER
void safeController() {
  digitalWrite(hvArmPin, LOW);
  //analogWrite(buzzerPin, 0); 
  digitalWrite(armOrSafeLED, SAFE_LED_ON);
  pinstateB = 0x00;
  continuityState=0x00;
  selectedState = 0x00;
  armState = 0x00;
  oldArmState = 0x00;
  Serial.println("system is now safe");
  delay(10);
}
#endif

#ifdef LAUNCHER_UNITTYPE_CONTROLLER
void askRackStatus() {

}
#endif



void armController() {
  digitalWrite(armOrSafeLED, ARM_LED_ON);
  //analogWrite(buzzerPin, BUZZER_ARMED); 
  digitalWrite(hvArmPin, HIGH);
#ifdef DEBUG_VIA_SERIAL  
  Serial.println("controller is ARMED");
#endif
}




#ifdef LAUNCHER_UNITTYPE_CONTROLLER
void updateChannelSelections() {
  //Serial.print(F("inside updateChannelSelections() : "));
  noInterrupts();
  //Serial.println(Mcp23s17b.port(), BIN);
  pinstateB = Mcp23s17b.port() >> 8;
  interrupts();
  //Serial.println(pinstateB, BIN);
  if (pinstateB != oldPinstateB ) {
    delay(20);
    noInterrupts();
    pinstateB = Mcp23s17b.port() >> 8;
    interrupts();
    if (pinstateB != oldPinstateB ) {
      Serial.print("inputs changed to: ");
      //uint8_t rev = reverse_bit_order(pinstateB);
      //Serial.println(rev, BIN);
      Serial.println(pinstateB, BIN);
      oldPinstateB = pinstateB;
      //mapStatesToDisplay();
      statesChanged = true;
      updatingSelections = true;
    }
  }
}
#endif


#ifdef LAUNCHER_UNITTYPE_CONTROLLER
void checkFireSwitch() {
  if (digitalRead(fireSw) == FIRE_SWITCH_DEPRESSED) {
    //wait and check again
    delay(10);
    if (digitalRead(fireSw) == FIRE_SWITCH_DEPRESSED) {
      if (state == STATE_ARMED) {
        state = STATE_FIRING;
      } else {
        if (state == STATE_FIRING) {
          state = STATE_FIRING;
        } else {
          state = STATE_BRICKED; //we should never get here if we were not armed to begin with
        }
      }
      statesChanged = true;
      //analogWrite(buzzerPin, BUZZER_FIRING); 
      Serial.println("controller is FIRING");
    } else {
      //state = STATE_ARMED;
      statesChanged = true;
      Serial.println(F("checkFireSwitch inside loop indicates FIRE no longer depressed"));
    }
  } else {
    if (state == STATE_FIRING) {
      // fire button no longer depressed
      state = STATE_ARMED;
      statesChanged = true;
      Serial.println(F("checkFireSwitch changed state to ARMED"));
    }
  }
}
#endif

#ifdef LAUNCHER_UNITTYPE_CONTROLLER
void assembleRackStatusPacket() {
  
}
#endif


#ifdef LAUNCHER_UNITTYPE_CONTROLLER
void assembleControlPacket() {
  /*    Control protocol packet to send To pad:
        Rack number - 1 Byte
        Rack UUID - 1 Byte
        Command - 1 Byte
            -Initialize
            -Status
            -Arm
            -Fire
            -Safe
        Command params (2 bytes below depending on command in previous byte)
            -Initialize - 2 bytes ACK
            -Status - 2 Bytes @ 0
                 -No params
            -Arm - 1 Byte selected + 1 Byte always 0x00
                 -Channels selected
            -Fire - 1 Byte selected + 1 Byte trigger
                 -Channels selected
                 -Channels to trigger
            -Safe - 2 Bytes always 0xFF
                 -No params
        Padding - 3 bytes
        Total:8 bytes
  */
  //char payload[] = {
  //    armedRack,armedRack,'L', 'I', 'N', 'K', RACKID, remote_pin, set_state        };
  if ( 2 == 4 );
}
#endif



// ______________________________________________________________________________
#ifdef LAUNCHER_UNITTYPE_RACK
void rackLoop() {

  if (state != STATE_BRICKED) {
    resetSoftTimeout();
    rackListen(); // listening may change our state!
  }

  switch(state) {
  case STATE_SAFE:
    Serial.print(F("rackLoop STATE_SAFE: going safe..."));
    safeRackUnit();
    //___________________________________________FIXME
    statesChanged = true;
    break;

  case STATE_ARMED:
    Serial.print(F("0rackLoop STATE_ARMED: going ARMED..."));
    if (checkTimeout()) break;
    armSystem();
    updateContinuity();
    //___________________________________________FIXME
    statesChanged = true;
    break;

  case STATE_FIRING:
    Serial.println(F("rackLoop STATE_FIRING: unit is FIRING!!!!!"));
    if (checkTimeout()) break;
    updateContinuity();
    fireFireFire();
    break;

  case STATE_BRICKED:
    Serial.println(F("rackLoop STATE_BRICKED: unit has had a fatal error and has bricked itself as a precaution!"));
    safeRackUnit();

  default:
    state = STATE_SAFE;
  }

}
#endif

// ______________________________________________________________________________
#ifdef LAUNCHER_UNITTYPE_CONTROLLER
void controllerLoop() {

  /*if (state != STATE_BRICKED) {
    resetSoftTimeout();
    controllerListen(); // listening may change our state!
  }
  */

  checkSafetyKey();

  switch(state) {
  case STATE_SAFE:
    //Serial.print(F("controllerLoop STATE_SAFE: going safe..."));
    safeController();
    askRackStatus();
    break;

  case STATE_ARMED:
    //Serial.print(F("controllerLoop STATE_ARMED: going ARMED..."));
    if (checkTimeout()) break;
    armController();
    updateChannelSelections();
    //askRackStatus();
    checkFireSwitch();
    //___________________________________________FIXME
    statesChanged = true;
    break;

  case STATE_FIRING:
    //Serial.println(F("controllerLoop STATE_FIRING: unit is FIRING!!!!!"));
    if (checkTimeout()) break;
    checkFireSwitch();
    askRackStatus();
    break;

  case STATE_BRICKED:
    Serial.println(F("controllerLoop STATE_BRICKED: unit has had a fatal error and has bricked itself as a precaution!"));
    safeController();

  default:
    state = STATE_SAFE;
  }

  needToSend = 1;
  if (needToSend)
    controllerTransmit();

}
#endif

// ______________________________________________________________________________
void setup () {
  delay(100); // give time for bootloader interrupt?  having flashing problems
  SPI.begin();
  //SPI.setClockDivider(SPI_CLOCK_DIV8);  // 2MHz SPI clock if 16MHz system
  //SPI.setClockDivider(SPI_CLOCK_DIV4);  // 2MHz SPI clock if 8MHz system    
  SPI.setClockDivider(SPI_CLOCK_DIV16);  // 2MHz SPI clock if 8MHz system    
  
  Serial.begin(SERIAL_BAUD_RATE);
  // initialize all the readings to 0: 
  for (int thisReading = 0; thisReading < numReadings; thisReading++)
    readings[thisReading] = 0;     

  Serial.println(F("combinedLauncher 20130203"));
  Serial.print(F("resetting GPIO and the radio... "));    
  pinMode(gpioReset, OUTPUT);
  digitalWrite(gpioReset, LOW);
  delay(100);
  digitalWrite(gpioReset, HIGH);  // effectively enable the mcp23s17, dont do earlier as we dont want its spurious/random outputs turned on
  // Set all pins to be outputs (by default they are all inputs)
  Mcp23s17.port(0x0000);
  Mcp23s17.pinModeAll(OUTPUT);


  Serial.println("done.");

  if (unitType == 'C') Serial.println(F("firmware built for CONTROLLER"));
  if (unitType == 'r') Serial.println(F("firmware built for RACK UNIT"));

#ifdef RADIO_TYPE_RFM12B
  rf12_initialize(NODEID, RF12_433MHZ, NETWORKID);
  //rf12_config(RF12_DATA_RATE_4);
#endif

#ifdef RADIO_TYPE_RFM69HW
  radio.initialize(FREQUENCY,NODEID,NETWORKID);
  radio.setHighPower(); //uncomment only for RFM69HW!
  radio.encrypt(ENCRYPTKEY);
#endif

  pinMode(ADCSelectPin,OUTPUT);
  digitalWrite(ADCSelectPin,HIGH);

  
  analogReference(EXTERNAL);
  pinMode(A4, INPUT);
  digitalWrite(A4, LOW);
  pinMode(A2, INPUT);
  digitalWrite(A2, LOW);

  pinMode(safetySw,INPUT);
  digitalWrite(safetySw, HIGH);
  pinMode(buzzerPin,OUTPUT);
  pinMode(txrxPin,OUTPUT);
  pinMode(armOrSafeLED,OUTPUT);
  digitalWrite(armOrSafeLED, ARM_LED_ON);

  counter=0x0001;
  for (uint8_t j = 0; j <16; ++j) {
    Serial.println(j,DEC);

    Mcp23s17.port(counter);  
    counter<<=1;
    delay(100);
    digitalWrite(armOrSafeLED, counter);

  }
  Mcp23s17.port(0xFFFF);    
  delay(100);
  Mcp23s17.port(0x0000);    

  // Write to individual pins
  //Mcp23s17.digitalWrite(8,LOW);
  //Mcp23s17.digitalWrite(12,HIGH);

  // Read all pins at once, 16-bit value
  uint16_t pinstate = Mcp23s17.port();

  // Set pin 14 (GPIO B6) to be an input
  //Mcp23s17.pinMode(14,INPUT);




  pinMode(hvArmPin, OUTPUT);
  digitalWrite(hvArmPin, LOW);

#ifdef LAUNCHER_UNITTYPE_RACK
  Mcp23s17b.port(0x0000);
  Mcp23s17b.pinModeAll(OUTPUT);

#endif

#ifdef LAUNCHER_UNITTYPE_CONTROLLER

  Serial.println(F("setting up gpioB for controller"));
  Mcp23s17b.pinModeAll(OUTPUT);
  Mcp23s17b.port(0x00FF); 
  Mcp23s17b.pinModeAll(INPUT);
  Mcp23s17b.pinMode(0xFF00);
  Mcp23s17b.setAllInputPolarity(0xFFFF);
  Mcp23s17b.setPullups(0xFFFF);  

  // Read all pins at once, 16-bit value
  pinstateB = Mcp23s17b.port();
  oldPinstateB = Mcp23s17b.port();
  
#endif



  Serial.print("chkMem free= ");
  Serial.print(availableMemory());
  Serial.print(", memory used=");
  Serial.println(2048-availableMemory());
  state = STATE_SAFE;
  
  delay(1000);

  resetTimeout();

}




void loop () {

  statesChanged = false;
  ops++;

#ifdef LAUNCHER_UNITTYPE_RACK
    rackLoop();
#endif

#ifdef LAUNCHER_UNITTYPE_CONTROLLER
    controllerLoop();    
#endif

  if (statesChanged) {
    mapStatesToDisplay();
    updateDisplay();
  }

}



