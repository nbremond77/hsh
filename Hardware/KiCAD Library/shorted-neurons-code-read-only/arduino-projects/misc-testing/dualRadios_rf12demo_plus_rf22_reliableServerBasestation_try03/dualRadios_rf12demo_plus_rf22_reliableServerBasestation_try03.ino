// Configure some values in EEPROM for easy config of the RF12 later on.
// 2009-05-06 <jcw@equi4.com> http://opensource.org/licenses/mit-license.php
// $Id: RF12demo.pde 7686 2011-05-19 13:07:57Z jcw $

// this version adds flash memory support, 2009-11-19

#include <Ports.h>
#include <RF12.h>
#include <util/crc16.h>
#include <util/parity.h>
#include <avr/eeprom.h>
#include <avr/pgmspace.h>

#define DATAFLASH   0   // check for presence of DataFlash memory on JeeLink
#define FLASH_MBIT  16  // support for various dataflash sizes: 4/8/16 Mbit

#define LED_PIN     9   // activity LED

#define COLLECT 0x20 // collect mode, i.e. pass incoming without sending acks

//____begin rf22_____________


// changing entire scheme of this thing:
//   server changes:
//      a. server will use only the ack functions built into the library,
//         rather than ack receipt by sending entire string back to client
//      b. server will keep stats on packet traffic by client adrs #
//      c. server will print (to log page) it's own stats along with stats and
//         other info  reported by the client(s) 
//   client chenges:
//      a. client will at regular intervals offer to send stats/info to server,
//         soas to not tie up client with having to listen for server requests
//      b. client will respond to server's requests for stats or other info
//      c. client will keep stats on packets sent and acks rcv'd
//      d. client will track signal quality and report avg rssi when requested
// 
//    -- sbs, 5/12/14, updated 5/13/14
//
//
// use board: Arduino Duemilanove w/ ATmega/328

// #include <RF22ReliableDatagram.h>
// #include <RF22.h>
#include <RHReliableDatagram.h>
#include <RH_RF22.h>
#include <SPI.h>

#define SERIAL_BAUD_RATE 115200

// #define RH_RF22_MAX_MESSAGE_LEN 50   // defaults to 50
#define CLIENT_ADDRESS 7  // ignored, answers anyone
#define SERVER_ADDRESS 0
#define actLed 9

//#define DEBUG

uint32_t loopCtr =  0;
uint32_t received = 0;
uint32_t failures = 0;
uint32_t success =  0;


RH_RF22 driver(8,3);     // instance of the radio driver
// Class to manage message delivery and receipt, using the driver declared above
RHReliableDatagram rf22(driver, SERVER_ADDRESS);

//const char statRqstStr[] = "prt stats";
//bool prtStatsFlag = false;
char serverAdrs[8], clientAdrs[8];   // for printing address at beginning of line

void radioBustedSoThrowHissyFit() {
  // since we can't do anything useful ...
  pinMode(actLed, OUTPUT);
  while (1) {
    digitalWrite(actLed, LOW);
    delay(200);
    digitalWrite(actLed, HIGH);
    delay(200);
  }
}


void rf22setup() {
  //Serial.begin(SERIAL_BAUD_RATE);
  
      //shut off the rf12 SS pin 
    pinMode(10, OUTPUT);
    digitalWrite(10, HIGH);
  // toggle the rf22 reset
    pinMode(7, OUTPUT);
    digitalWrite(7, HIGH);
    delay(200);
    digitalWrite(7, LOW);
    delay(300);
  
  sprintf(serverAdrs, "%02X: ", SERVER_ADDRESS);
  Serial.println("\n");
  Serial.print(serverAdrs);
  Serial.println("<--- server adrs");
  Serial.print(serverAdrs);
  Serial.print(F("once upon a time, this part came from  "));
  
  Serial.print(F("basement_crashboard/distill_140512/rf22_server_140515_a/rf22_server_140515_a.ino"));
  Serial.print(serverAdrs);
  Serial.print(F("attempting rf22 init ... "));
  if (!rf22.init()) {
    Serial.println(" failed!");
    radioBustedSoThrowHissyFit();
  }
  else {
    Serial.println("passed ...");
    // Defaults after init are 434.0MHz, 0.05MHz AFC pull-in, modulation FSK_Rb2_4Fd36
    // chg data rate: FSK,   Rb = 125kbs,  Fd = 125kHz
    driver.setModemConfig(RH_RF22::FSK_Rb125Fd125);
    // change center frequency to 436 MHz, double pullin range from 0.05 to 0.10
    driver.setFrequency(436.000, 0.10);
    // default after init is 8 dbm - see .h file for valid choices
    //driver.setTxPower(RH_RF22_TXPOW_2DBM);
    //driver.setTxPower(RH_RF22_TXPOW_8DBM);
    driver.setTxPower(RH_RF22_TXPOW_20DBM);
    
    // set retries to lower than 10 since this isn't critical data
    rf22.setRetries(2); 
  }
  Serial.print(serverAdrs);
  Serial.print(F("max msg length is: "));
  Serial.println(RH_RF22_MAX_MESSAGE_LEN);
  pinMode(actLed, OUTPUT);
}

uint8_t buf[RH_RF22_MAX_MESSAGE_LEN];
void rf22serverloop() {
  loopCtr++;
  /*
  // if requst to print stats was received, print info now ...
  if (prtStatsFlag) {
    Serial.print(serverAdrs);
    Serial.print(F("stats: packets_rcvd = "));
    Serial.println(received);      
    Serial.print(serverAdrs);
    Serial.print(F("       ack_fails = "));
    Serial.println(failures);
    Serial.print(serverAdrs);
    Serial.print(F("       successes = "));
    Serial.println(success);
    prtStatsFlag = false;
  }
  */
  
  // Wait for a message addressed to us from the client
  uint8_t len = sizeof(buf);
  uint8_t from;
  pinMode(actLed, INPUT);
  digitalWrite(actLed, LOW);
  if (rf22.recvfromAck(buf, &len, &from)) {
    received++;
    pinMode(actLed, OUTPUT);
    digitalWrite(actLed, HIGH);
    sprintf(clientAdrs, "%02X: ", from);
    Serial.print(clientAdrs);
    #ifdef DEBUG
    Serial.print(" recvOk: ");
    Serial.print(received);
    Serial.print(" msg: ");
    Serial.println((char*)buf);
    #endif
    #ifndef DEBUG
    Serial.println((char*)buf);
    #endif
    }
    // done with buf, clear it ...
    // for ( int i=0; i<sizeof(buf) && i < RH_RF22_MAX_MESSAGE_LEN; i++) {
    for ( int i=0; i < RH_RF22_MAX_MESSAGE_LEN; i++)  buf[i] = 0;
  }
  
  
      /*
      // if message is request to print stats, set flag and do at beginning of loop ...
      prtStatsFlag = true;
      for (int i=0; i<9; i++) {
        if (buf[i] != statRqstStr[i])
          prtStatsFlag = false;   // negate flag if not print stat request
      }
      */
      
      // following stuff is the verbose acknowledgement that's to be cut ...
      /*
      // following line and a couple below changed to shorten msg overhead
      // uint8_t data2[RH_RF22_MAX_MESSAGE_LEN] = " < server heard you say: ";
      uint8_t data2[RH_RF22_MAX_MESSAGE_LEN] = "rcvd: ";
      int j = sizeof(data2) -1;   // ??
      j=6;   // adjusted length per change above
      data2[6] = '\0';
      for ( int i=0; i<sizeof(buf) && i < RH_RF22_MAX_MESSAGE_LEN; i++) {
        if (buf[i] >20 && buf[i] <128 ) {  // apparently copying only printable chars
          data2[j] = buf[i];
          j++; 
        }
      }
      // data2[j++] = '!';  // silly
      data2[j] = 0;
      // finish out clearing remainder of data2 string ...
      for ( int i=j; i < RH_RF22_MAX_MESSAGE_LEN; i++) {
        data2[j] = 0;
      }
      // done with buf, clear it ...
      for ( int i=0; i<sizeof(buf) && i < RH_RF22_MAX_MESSAGE_LEN; i++) {
        buf[i] = 0;
      }
      #ifdef DEBUG
      // Serial.print("   sending reply... ");
      Serial.print(F("sending reply: "));
      Serial.println((char*)&data2);
      #endif
      
      // repair following line to previous state ...
      // undo that ...
      if (!rf22.sendtoWait(data2, strlen((char*)&(data2)), from)) {
      // if (!rf22.sendtoWait(data2, sizeof(data2), from)) {
        // failed to rcv acknowledge ...
        failures++;
        #ifdef DEBUG
        Serial.print(F("strlen((char*)&(data2)) = "));
        Serial.println(strlen((char*)&(data2)));
        Serial.print("data2 = ");
        Serial.println((char*)&data2);
        Serial.print(F("sendtoWait failed, total failures="));
        Serial.println(failures);
        #endif
        #ifndef DEBUG
        Serial.println(" NO ack");
        #endif
        pinMode(actLed, INPUT);
      }
      else {
        digitalWrite(actLed, LOW);
        success++;
        #ifdef DEBUG
        Serial.print(F("reply acknowledged, successes="));
        Serial.println(success);
        #endif
        #ifndef DEBUG
        Serial.println(" ack");
        #endif
      }
    }
  }
  */




//___ end rf22 __________________



static unsigned long now () {
    // FIXME 49-day overflow
    return millis() / 1000;
}

static void activityLed (byte on) {
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, !on);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// RF12 configuration setup code

typedef struct {
    byte nodeId;
    byte group;
    char msg[RF12_EEPROM_SIZE-4];
    word crc;
} RF12Config;

static RF12Config config;

static char cmd;
static byte value, stack[RF12_MAXDATA], top, sendLen, dest, quiet;
static byte testbuf[RF12_MAXDATA];

static void addCh (char* msg, char c) {
    byte n = strlen(msg);
    msg[n] = c;
}

static void addInt (char* msg, word v) {
    if (v >= 10)
        addInt(msg, v / 10);
    addCh(msg, '0' + v % 10);
}

static void saveConfig () {
    // set up a nice config string to be shown on startup
    memset(config.msg, 0, sizeof config.msg);
    strcpy(config.msg, " ");
    
    byte id = config.nodeId & 0x1F;
    addCh(config.msg, '@' + id);
    strcat(config.msg, " i");
    addInt(config.msg, id);
    if (config.nodeId & COLLECT)
        addCh(config.msg, '*');
    
    strcat(config.msg, " g");
    addInt(config.msg, config.group);
    
    strcat(config.msg, " @ ");
    static word bands[4] = { 315, 433, 868, 915 };
    word band = config.nodeId >> 6;
    addInt(config.msg, bands[band]);
    strcat(config.msg, " MHz ");
    
    config.crc = ~0;
    for (byte i = 0; i < sizeof config - 2; ++i)
        config.crc = _crc16_update(config.crc, ((byte*) &config)[i]);

    // save to EEPROM
    for (byte i = 0; i < sizeof config; ++i) {
        byte b = ((byte*) &config)[i];
        eeprom_write_byte(RF12_EEPROM_ADDR + i, b);
    }
    
    if (!rf12_config())
        Serial.println("config save failed");
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// OOK transmit code

// Turn transmitter on or off, but also apply asymmetric correction and account
// for 25 us SPI overhead to end up with the proper on-the-air pulse widths.
// With thanks to JGJ Veken for his help in getting these values right.
static void ookPulse(int on, int off) {
    rf12_onOff(1);
    delayMicroseconds(on + 150);
    rf12_onOff(0);
    delayMicroseconds(off - 200);
}

static void fs20sendBits(word data, byte bits) {
    if (bits == 8) {
        ++bits;
        data = (data << 1) | parity_even_bit(data);
    }
    for (word mask = bit(bits-1); mask != 0; mask >>= 1) {
        int width = data & mask ? 600 : 400;
        ookPulse(width, width);
    }
}

static void fs20cmd(word house, byte addr, byte cmd) {
	byte sum = 6 + (house >> 8) + house + addr + cmd;
	for (byte i = 0; i < 3; ++i) {
		fs20sendBits(1, 13);
		fs20sendBits(house >> 8, 8);
		fs20sendBits(house, 8);
		fs20sendBits(addr, 8);
		fs20sendBits(cmd, 8);
		fs20sendBits(sum, 8);
		fs20sendBits(0, 1);
		delay(10);
	}
}

static void kakuSend(char addr, byte device, byte on) {
    int cmd = 0x600 | ((device - 1) << 4) | ((addr - 1) & 0xF);
    if (on)
        cmd |= 0x800;
    for (byte i = 0; i < 4; ++i) {
        for (byte bit = 0; bit < 12; ++bit) {
            ookPulse(375, 1125);
            int on = bitRead(cmd, bit) ? 1125 : 375;
            ookPulse(on, 1500 - on);
        }
		ookPulse(375, 375);
		delay(11); // approximate
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// DataFlash code

#if DATAFLASH

#define DF_ENABLE_PIN   8           // PB0

#if FLASH_MBIT == 4
// settings for 0.5 Mbyte flash in JLv2
#define DF_BLOCK_SIZE   16          // number of pages erased at same time
#define DF_LOG_BEGIN    32          // first 2 blocks reserved for future use
#define DF_LOG_LIMIT    0x0700      // last 64k is not used for logging
#define DF_MEM_TOTAL    0x0800      // 2048 pages, i.e. 0.5 Mbyte
#define DF_DEVICE_ID    0x1F44      // see AT25DF041A datasheet
#endif

#if FLASH_MBIT == 8
// settings for 1 Mbyte flash in JLv2
#define DF_BLOCK_SIZE   16          // number of pages erased at same time
#define DF_LOG_BEGIN    32          // first 2 blocks reserved for future use
#define DF_LOG_LIMIT    0x0F00      // last 64k is not used for logging
#define DF_MEM_TOTAL    0x1000      // 4096 pages, i.e. 1 Mbyte
#define DF_DEVICE_ID    0x1F45      // see AT26DF081A datasheet
#endif

#if FLASH_MBIT == 16
// settings for 2 Mbyte flash in JLv3
#define DF_BLOCK_SIZE   256         // number of pages erased at same time
#define DF_LOG_BEGIN    512         // first 2 blocks reserved for future use
#define DF_LOG_LIMIT    0x1F00      // last 64k is not used for logging
#define DF_MEM_TOTAL    0x2000      // 8192 pages, i.e. 2 Mbyte
#define DF_DEVICE_ID    0x2020      // see M25P16 datasheet
#endif

// structure of each page in the log buffer, size must be exactly 256 bytes
typedef struct {
    byte data [248];
    word seqnum;
    long timestamp;
    word crc;
} FlashPage;

// structure of consecutive entries in the data area of each FlashPage
typedef struct {
    byte length;
    byte offset;
    byte header;
    byte data[RF12_MAXDATA];
} FlashEntry;

static FlashPage dfBuf;     // for data not yet written to flash
static word dfLastPage;     // page number last written
static byte dfFill;         // next byte available in buffer to store entries

static byte df_present () {
    return dfLastPage != 0;
}

static void df_enable () {
    // digitalWrite(ENABLE_PIN, 0);
    bitClear(PORTB, 0);
}

static void df_disable () {
    // digitalWrite(ENABLE_PIN, 1);
    bitSet(PORTB, 0);
}

static byte df_xfer (byte cmd) {
    SPDR = cmd;
    while (!bitRead(SPSR, SPIF))
        ;
    return SPDR;
}

void df_command (byte cmd) {
    for (;;) {
        cli();
        df_enable();
        df_xfer(0x05); // Read Status Register
        byte status = df_xfer(0);
        df_disable();
        sei();
        // don't wait for ready bit if there is clearly no dataflash connected
        if (status == 0xFF || (status & 1) == 0)
            break;
    }    

    cli();
    df_enable();
    df_xfer(cmd);
}

static void df_writeCmd (byte cmd) {
    df_command(0x06); // Write Enable
    df_deselect();
    df_command(cmd);
}

static void df_deselect () {
    df_disable();
    sei();
}

void df_read (word block, word off, void* buf, word len) {
    df_command(0x03); // Read Array (Low Frequency)
    df_xfer(block >> 8);
    df_xfer(block);
    df_xfer(off);
    for (word i = 0; i < len; ++i)
        ((byte*) buf)[(byte) i] = df_xfer(0);
    df_deselect();
}

void df_write (word block, const void* buf) {
    df_writeCmd(0x02); // Byte/Page Program
    df_xfer(block >> 8);
    df_xfer(block);
    df_xfer(0);
    for (word i = 0; i < 256; ++i)
        df_xfer(((const byte*) buf)[(byte) i]);
    df_deselect();
}

// wait for current command to complete
void df_flush () {
    df_read(0, 0, 0, 0);
}

static void df_wipe () {
    Serial.println("DF W");
    
    df_writeCmd(0x60);      // Chip Erase
    df_deselect();
    df_flush();
}

static void df_erase (word block) {
    Serial.print("DF E ");
    Serial.println(block);
    
    df_writeCmd(0x20);      // Block Erase
    df_xfer(block >> 8);
    df_xfer(block);
    df_xfer(0);
    df_deselect();
    df_flush();
}

static word df_wrap (word page) {
    return page < DF_LOG_LIMIT ? page : DF_LOG_BEGIN;
}

static void df_saveBuf () {
    if (dfFill == 0)
        return;

    dfLastPage = df_wrap(dfLastPage + 1);
    if (dfLastPage == DF_LOG_BEGIN)
        ++dfBuf.seqnum; // bump to next seqnum when wrapping
    
    // set remainder of buffer data to 0xFF and calculate crc over entire buffer
    dfBuf.crc = ~0;
    for (byte i = 0; i < sizeof dfBuf - 2; ++i) {
        if (dfFill <= i && i < sizeof dfBuf.data)
            dfBuf.data[i] = 0xFF;
        dfBuf.crc = _crc16_update(dfBuf.crc, dfBuf.data[i]);
    }
    
    df_write(dfLastPage, &dfBuf);
    dfFill = 0;
    
    // wait for write to finish before reporting page, seqnum, and time stamp
    df_flush();
    Serial.print("DF S ");
    Serial.print(dfLastPage);
    Serial.print(' ');
    Serial.print(dfBuf.seqnum);
    Serial.print(' ');
    Serial.println(dfBuf.timestamp);
    
    // erase next block if we just saved data into a fresh block
    // at this point in time dfBuf is empty, so a lengthy erase cycle is ok
    if (dfLastPage % DF_BLOCK_SIZE == 0)
        df_erase(df_wrap(dfLastPage + DF_BLOCK_SIZE));
}

static void df_append (const void* buf, byte len) {
    //FIXME the current logic can't append incoming packets during a save!

    // fill in page time stamp when appending to a fresh page
    if (dfFill == 0)
        dfBuf.timestamp = now();
    
    long offset = now() - dfBuf.timestamp;
    if (offset >= 255 || dfFill + 1 + len > sizeof dfBuf.data) {
        df_saveBuf();

        dfBuf.timestamp = now();
        offset = 0;
    }

    // append new entry to flash buffer
    dfBuf.data[dfFill++] = offset;
    memcpy(dfBuf.data + dfFill, buf, len);
    dfFill += len;
}

// go through entire log buffer to figure out which page was last saved
static void scanForLastSave () {
    dfBuf.seqnum = 0;
    dfLastPage = DF_LOG_LIMIT - 1;
    // look for last page before an empty page
    for (word page = DF_LOG_BEGIN; page < DF_LOG_LIMIT; ++page) {
        word currseq;
        df_read(page, sizeof dfBuf.data, &currseq, sizeof currseq);
        if (currseq != 0xFFFF) {
            dfLastPage = page;
            dfBuf.seqnum = currseq + 1;
        } else if (dfLastPage == page - 1)
            break; // careful with empty-filled-empty case, i.e. after wrap
    }
}

static void df_initialize () {
    // assumes SPI has already been initialized for the RFM12B
    df_disable();
    pinMode(DF_ENABLE_PIN, OUTPUT);
    df_command(0x9F); // Read Manufacturer and Device ID
    word info = df_xfer(0) << 8;
    info |= df_xfer(0);
    df_deselect();

    if (info == DF_DEVICE_ID) {
        df_writeCmd(0x01);  // Write Status Register ...
        df_xfer(0);         // ... Global Unprotect
        df_deselect();

        scanForLastSave();
        
        Serial.print("DF I ");
        Serial.print(dfLastPage);
        Serial.print(' ');
        Serial.println(dfBuf.seqnum);
    
        // df_wipe();
        df_saveBuf(); //XXX
    }
}

static void discardInput () {
    while (Serial.read() >= 0)
        ;
}

static void df_dump () {
    struct { word seqnum; long timestamp; word crc; } curr;
    discardInput();
    for (word page = DF_LOG_BEGIN; page < DF_LOG_LIMIT; ++page) {
        if (Serial.read() >= 0)
            break;
        // read marker from page in flash
        df_read(page, sizeof dfBuf.data, &curr, sizeof curr);
        if (curr.seqnum == 0xFFFF)
            continue; // page never written to
        Serial.print(" df# ");
        Serial.print(page);
        Serial.print(" : ");
        Serial.print(curr.seqnum);
        Serial.print(' ');
        Serial.print(curr.timestamp);
        Serial.print(' ');
        Serial.println(curr.crc);
    }
}

static word scanForMarker (word seqnum, long asof) {
    word lastPage = 0;
    struct { word seqnum; long timestamp; } last, curr;
    last.seqnum = 0xFFFF;
    // go through all the pages in log area of flash
    for (word page = DF_LOG_BEGIN; page < DF_LOG_LIMIT; ++page) {
        // read seqnum and timestamp from page in flash
        df_read(page, sizeof dfBuf.data, &curr, sizeof curr);
        if (curr.seqnum == 0xFFFF)
            continue; // page never written to
        if (curr.seqnum >= seqnum && curr.seqnum < last.seqnum) {
            last = curr;
            lastPage = page;
        }
        if (curr.seqnum == last.seqnum && curr.timestamp <= asof)
            lastPage = page;
    }
    return lastPage;
}

static void df_replay (word seqnum, long asof) {
    word page = scanForMarker(seqnum, asof);
    Serial.print("r: page ");
    Serial.print(page);
    Serial.print(' ');
    Serial.println(dfLastPage);
    discardInput();
    word savedSeqnum = dfBuf.seqnum;
    while (page != dfLastPage) {
        if (Serial.read() >= 0)
            break;
        page = df_wrap(page + 1);
        df_read(page, 0, &dfBuf, sizeof dfBuf); // overwrites ram buffer!
        if (dfBuf.seqnum == 0xFFFF)
            continue; // page never written to
        // skip and report bad pages
        word crc = ~0;
        for (word i = 0; i < sizeof dfBuf; ++i)
            crc = _crc16_update(crc, dfBuf.data[i]);
        if (crc != 0) {
            Serial.print("DF C? ");
            Serial.print(page);
            Serial.print(' ');
            Serial.println(crc);
            continue;
        }
        // report each entry as "R seqnum time <data...>"
        byte i = 0;
        while (i < sizeof dfBuf.data && dfBuf.data[i] < 255) {
            if (Serial.available())
                break;
            Serial.print("R ");
            Serial.print(dfBuf.seqnum);
            Serial.print(' ');
            Serial.print(dfBuf.timestamp + dfBuf.data[i++]);
            Serial.print(' ');
            Serial.print((int) dfBuf.data[i++]);
            byte n = dfBuf.data[i++];
            while (n-- > 0) {
                Serial.print(' ');
                Serial.print((int) dfBuf.data[i++]);
            }
            Serial.println();
        }
        // at end of each page, report a "DF R" marker, to allow re-starting
        Serial.print("DF R ");
        Serial.print(page);
        Serial.print(' ');
        Serial.print(dfBuf.seqnum);
        Serial.print(' ');
        Serial.println(dfBuf.timestamp);
    }
    dfFill = 0; // ram buffer is no longer valid
    dfBuf.seqnum = savedSeqnum + 1; // so next replay will start at a new value
    Serial.print("DF E ");
    Serial.print(dfLastPage);
    Serial.print(' ');
    Serial.print(dfBuf.seqnum);
    Serial.print(' ');
    Serial.println(millis());
}

#else // DATAFLASH

#define df_present() 0
#define df_initialize()
#define df_dump()
#define df_replay(x,y)
#define df_erase(x)

#endif

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

char helpText1[] PROGMEM = 
    "\n"
    "Available commands:" "\n"
    "  <nn> i     - set node ID (standard node ids are 1..26)" "\n"
    "               (or enter an uppercase 'A'..'Z' to set id)" "\n"
    "  <n> b      - set MHz band (4 = 433, 8 = 868, 9 = 915)" "\n"
    "  <nnn> g    - set network group (RFM12 only allows 212, 0 = any)" "\n"
    "  <n> c      - set collect mode (advanced, normally 0)" "\n"
    "  t          - broadcast max-size test packet, with ack" "\n"
    "  ...,<nn> a - send data packet to node <nn>, with ack" "\n"
    "  ...,<nn> s - send data packet to node <nn>, no ack" "\n"
    "  <n> l      - turn activity LED on PB1 on or off" "\n"
    "  <n> q      - set quiet mode (1 = don't report bad packets)" "\n"
    "Remote control commands:" "\n"
    "  <hchi>,<hclo>,<addr>,<cmd> f     - FS20 command (868 MHz)" "\n"
    "  <addr>,<dev>,<on> k              - KAKU command (433 MHz)" "\n"
;
char helpText2[] PROGMEM = 
    "Flash storage (JeeLink v2 only):" "\n"
    "  d                                - dump all log markers" "\n"
    "  <sh>,<sl>,<t3>,<t2>,<t1>,<t0> r  - replay from specified marker" "\n"
    "  123,<bhi>,<blo> e                - erase 4K block" "\n"
    "  12,34 w                          - wipe entire flash memory" "\n"
;

static void showString (PGM_P s) {
    for (;;) {
        char c = pgm_read_byte(s++);
        if (c == 0)
            break;
        if (c == '\n')
            Serial.print('\r');
        Serial.print(c);
    }
}

static void showHelp () {
    showString(helpText1);
    if (df_present())
        showString(helpText2);
    Serial.println("Current configuration:");
    rf12_config();
}

static void handleInput (char c) {
    if ('0' <= c && c <= '9')
        value = 10 * value + c - '0';
    else if (c == ',') {
        if (top < sizeof stack)
            stack[top++] = value;
        value = 0;
    } else if ('a' <= c && c <='z') {
        Serial.print("> ");
        Serial.print((int) value);
        Serial.println(c);
        switch (c) {
            default:
                showHelp();
                break;
            case 'i': // set node id
                config.nodeId = (config.nodeId & 0xE0) + (value & 0x1F);
                saveConfig();
                break;
            case 'b': // set band: 4 = 433, 8 = 868, 9 = 915
                value = value == 8 ? RF12_868MHZ :
                        value == 9 ? RF12_915MHZ : RF12_433MHZ;
                config.nodeId = (value << 6) + (config.nodeId & 0x3F);
                saveConfig();
                break;
            case 'g': // set network group
                config.group = value;
                saveConfig();
                break;
            case 'c': // set collect mode (off = 0, on = 1)
                if (value)
                    config.nodeId |= COLLECT;
                else
                    config.nodeId &= ~COLLECT;
                saveConfig();
                break;
            case 't': // broadcast a maximum size test packet, request an ack
                cmd = 'a';
                sendLen = RF12_MAXDATA;
                dest = 0;
                for (byte i = 0; i < RF12_MAXDATA; ++i)
                    testbuf[i] = i;
                break;
            case 'a': // send packet to node ID N, request an ack
            case 's': // send packet to node ID N, no ack
                cmd = c;
                sendLen = top;
                dest = value;
                memcpy(testbuf, stack, top);
                break;
            case 'l': // turn activity LED on or off
                activityLed(value);
                break;
            case 'f': // send FS20 command: <hchi>,<hclo>,<addr>,<cmd>f
                rf12_initialize(0, RF12_868MHZ);
                activityLed(1);
                fs20cmd(256 * stack[0] + stack[1], stack[2], value);
                activityLed(0);
                rf12_config(); // restore normal packet listening mode
                break;
            case 'k': // send KAKU command: <addr>,<dev>,<on>k
                rf12_initialize(0, RF12_433MHZ);
                activityLed(1);
                kakuSend(stack[0], stack[1], value);
                activityLed(0);
                rf12_config(); // restore normal packet listening mode
                break;
            case 'd': // dump all log markers
                if (df_present())
                    df_dump();
                break;
            case 'r': // replay from specified seqnum/time marker
                if (df_present()) {
                    word seqnum = (stack[0] << 8) || stack[1];
                    long asof = (stack[2] << 8) || stack[3];
                    asof = (asof << 16) | ((stack[4] << 8) || value);
                    df_replay(seqnum, asof);
                }
                break;
            case 'e': // erase specified 4Kb block
                if (df_present() && stack[0] == 123) {
                    word block = (stack[1] << 8) | value;
                    df_erase(block);
                }
                break;
            case 'w': // wipe entire flash memory
                if (df_present() && stack[0] == 12 && value == 34)
                    df_wipe();
                break;
            case 'q': // turn quiet mode on or off (don't report bad packets)
                quiet = value;
                break;
        }
        value = top = 0;
        memset(stack, 0, sizeof stack);
    } else if ('A' <= c && c <= 'Z') {
        config.nodeId = (config.nodeId & 0xE0) + (c & 0x1F);
        saveConfig();
    } else if (c > ' ')
        showHelp();
}

void setup() {
    Serial.begin(57600);
    Serial.println("\nsetup() started ...\n");  
    Serial.print(F("file: "));
    Serial.print(F(__FILE__));

  Serial.print(F(", date/time: "));
  Serial.print(F(__DATE__));
  Serial.print("/");
  Serial.println(F(__TIME__));
  Serial.println(F("based on jeelabs RF12demo.7"));
  
  rf22setup();

    if (rf12_config()) {
        config.nodeId = eeprom_read_byte(RF12_EEPROM_ADDR);
        config.group = eeprom_read_byte(RF12_EEPROM_ADDR + 1);
    } else {
        config.nodeId = 0x41; // node A1 @ 433 MHz
        config.group = 0xD4;
        saveConfig();
    }

    df_initialize();
    
    showHelp();
    quiet=1;
}

long okPacketsRecvd = 0;

void loop() {
    rf22serverloop();
    if (Serial.available())
        handleInput(Serial.read());

    if (rf12_recvDone()) {
        byte n = rf12_len;
        if (rf12_crc == 0) {

             okPacketsRecvd++;
             Serial.print("recvOK=");
             Serial.print(okPacketsRecvd);
             Serial.print(',');

        } else {
            if (quiet)
                return;
            Serial.print(" ?");
            if (n > 20) // print at most 20 bytes if crc is wrong
                n = 20;
        }
        if (config.group == 0) {
            Serial.print("G ");
            Serial.print((int) rf12_grp);
        }
        Serial.print(" src=");
        Serial.print((int) rf12_hdr);
        Serial.print(" ,");
        Serial.print(rf12_hdr, DEC);
        Serial.print(" ,");
        Serial.print(rf12_hdr, HEX);
        Serial.print(" ,");
        for (byte i = 0; i < n; ++i) {
            if ((rf12_data[i] > 31) && (rf12_data[i] < 127 )) {
              Serial.print((char)rf12_data[i]);
            } else {
              //if (!quiet) {
                Serial.print(" 0x");
                Serial.print(rf12_data[i], HEX);
                Serial.print(' ');
              //}
            }
        }
        Serial.println();
        
        if (rf12_crc == 0) {
            activityLed(1);
            
            if (df_present())
                df_append((const char*) rf12_data - 2, rf12_len + 2);

            if (RF12_WANTS_ACK && (config.nodeId & COLLECT) == 0) {
                Serial.println(" -> ack");
                rf12_sendStart(RF12_ACK_REPLY, 0, 0);
            }
            
            activityLed(0);
        }
    }

    if (cmd && rf12_canSend()) {
        activityLed(1);

        Serial.print(" -> ");
        Serial.print((int) sendLen);
        Serial.println(" b");
        byte header = cmd == 'a' ? RF12_HDR_ACK : 0;
        if (dest)
            header |= RF12_HDR_DST | dest;
        rf12_sendStart(header, testbuf, sendLen);
        cmd = 0;

        activityLed(0);
    }
}

