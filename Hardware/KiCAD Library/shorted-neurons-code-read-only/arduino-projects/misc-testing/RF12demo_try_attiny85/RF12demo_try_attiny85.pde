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

#define LED_PIN     8   // activity LED

#define COLLECT 0x20 // collect mode, i.e. pass incoming without sending acks

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

/*
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
*/
/*
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
*/

#define df_present() 0
#define df_initialize()
#define df_dump()
#define df_replay(x,y)
#define df_erase(x)


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/*
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
*/
/*
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
*/
/*
static void showHelp () {
    showString(helpText1);
    if (df_present())
        showString(helpText2);
    Serial.println("Current configuration:");
    rf12_config();
}
*/
/*
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
*/

void setup() {
    Serial.begin(57600);
    //Serial.print("\n[RF12demo.7]");

    if (rf12_config()) {
        config.nodeId = eeprom_read_byte(RF12_EEPROM_ADDR);
        config.group = eeprom_read_byte(RF12_EEPROM_ADDR + 1);
    } else {
        config.nodeId = 0x41; // node A1 @ 433 MHz
        config.group = 0xD4;
        saveConfig();
    }

    //df_initialize();
    
    //showHelp();
    quiet=1;
}

/*
void chkMem() {
  Serial.print("f=");
  int size = 2048;
  byte *buf;
  while ((buf = (byte *) malloc(--size)) == NULL);
  free(buf);
  Serial.println(size);

}
*/


void loop() {
  
    //chkMem();
    if (rf12_recvDone()) {
        byte n = rf12_len;
        if (rf12_crc == 0) {
            Serial.print("OK");
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
        Serial.print(' ');
        Serial.print((int) rf12_hdr);
        for (byte i = 0; i < n; ++i) {
            if ((rf12_data[i] > 31) && (rf12_data[i] < 127 )) {
              Serial.print(rf12_data[i]);
            } else {
              if (!quiet) {
                Serial.print(' 0x');
                Serial.print(rf12_data[i], HEX);
                Serial.print(' ');
              }
            }
        }
        Serial.println();
        
        if (rf12_crc == 0) {
            activityLed(1);

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
