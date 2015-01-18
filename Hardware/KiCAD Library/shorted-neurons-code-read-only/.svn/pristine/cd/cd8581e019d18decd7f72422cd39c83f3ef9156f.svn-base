/*
 *
 *  inspired by EEPROM Read example, but extensively modified and embelished
 *  "Anything worth doing is worth over-doing."  -- Bill W., c. 1980-ish(?)
 *  See further notes below on motivation and conclusions.  sbs, 4-8-14
 *
 */

#include <EEPROM.h>
//#include <inttypes.h>    // apparently not needed for functions used even though
//#include <avr/io.h>      // these were indicated in sample code referenced below
#include <avr/pgmspace.h>

// you may want to run this with the following line commented out before uncommenting it
// #define DEBUG              // see notes below for the significance of this

// following values for atmega386, adjust appropriately
#define MEM_LINES_EEPROM 64     // 64x16 bytes = 1024
#define MEM_LINES_SRAM 128      // 128x16 bytes = 2048
#define MEM_LINES_PROGMEM 2016  // 2016x16 bytes = 32256

void setup()
{
  // initialize serial and wait for port to open:
  Serial.begin(57600);
  while (!Serial) {
    ; // wait for serial port to connect (needed for Leonardo only)
  }

// look at EEPROM contents first, which is where this all got started ...
//
// NOTE about the NOTE following: BUMMER!  Not reproducible!  :-(  I'm certain I saw
// previous behavior described below.  There must be something I'm not observing that
// I changed without being aware of the effects.  On to the note anyhow ...
//
// Hmmmm.  This just got a bit convoluted.  Should I suggest that you skip the note
// above, this one, and the YAN paragraph below, and just read the NOTE first??  :-)
// As it turns out, it's more accurate than I thought.  :-)
//
// YAN (Yet Another Note): just discovered that I might not be going nuts afterall!
// Well, perhaps I am, but figured out what might be happening WRT the above note ...
// When substituting a different junkstr3[], with DEBUG turned off, I still find
// that the OLD junkstr3 still shows up in PROGMEM, old meaning from a previous
// compilation/load.  This confirms that the compiler really does optimize out
// variables that aren't used, and further, that it's smart enough also to load only
// the areas of memory that are to be used.  This explains seeing some of these strings
// (such as the table headers lines) more than once, sometimes fragmented.  I've also seen
// PROGMEM filled beyond my expectation with odd random-looking stuff.  Some of this is
// seems certain to be from other previously run programs (on this atmega).  I'll have
// to sometime try clearing PROGMEM before running this (although not sure how to do
// that).  I've got a new board, not been used yet, which might be helpful to solve
// part of this mystery.
//
// NOTE: the junk strings (junkstr1, ...) demonstrate that the compiler really does
// optimize, so much so that these strings, if just declared but not used (as seen
// by the compiler), apparently don't show up in memory anywhere.  It's only by using
// some portion of them that they are included: note a char from each string is used for
// assembling the char[] junk, which is then printed.  If not used, their declarations are
// optimized out of the object file to be uploaded to the avr.  Interesting!  Test this
// by commenting out the #define DEBUG statement above, then re-run the program.  One
// difference will be that result of the Serial.print statement after the heading below
// won't print.  The other is that the recognizable junk strings below won't be seen in
// the PROGMEN (2nd) segment of memory dump.
//
// Ragarding what practical use can be made of this?  I think I know too little about it
// to suggest that it might actually be useful, as is, in any way.  Perhaps small segments
// of sections of memory might be printed for troubleshooting something.  Seems most
// useful might be to reveal and check the EEPROM contents, which is why this got started.
// The aim, at the beginning, was to investigate freeing up some RAM by using EEPROM to
// store a largish struct of data and pointers, and to store an array of output char
// strings to be accessed via pointers contained in the structure.  Remains to be seen
// if any of this comes to pass.  An obvious improvement is to use a case statement to
// select the various memeory areas to print, rather than repeating all of the code
// three times, but that's left as an exercise for sometime when I'm not so busy trying
// to get something else accomplished.
//
// BTW, part of wanting to do this was attempting to grasp memory use in avr-land.  I
// found this page somewhat helpful:
// learn.adafruit.com/memories-of-an-arduino/optimizing-sram
// -- sbs, 4-8-14
//
// look at EEPROM contents first, which is where this all got started ...
//
  char junkstr1[] = "AAAAAAAAAAAAAABBBBBBBBBBBBBBBBB";  // optimized out if not used
  char outstring[80] = "\0";
  char charstring[21] = "                   \0";
  char junkstr2[] = "CCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDD";  // won't show if not used
  Serial.println(F("\n*********************** EEPROM contents ***********************\n"));
  Serial.println(F("\n hex   (dec)  00 01 02 03 04 05 06 07  08 09 0A 0B 0C 0D 0E 0F   01234567 89ABCDEF"));
  Serial.println(F("---- -------- -----------------------  -----------------------   -------- --------"));
  // char junkstr3[] = "EEEEEEEEEEEEEEEEEEEEEEEEEFFFFFFFFFFFFFFFF";  // won't show if not used
  // char junkstr3[] = "FFFFFFFFFFFFFFFFFFFFEEEEEEEEEEEEEEEEEEEEE";  // won't show if not used
  char junkstr3[] = "GGGGGGGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHHH";  // won't show if not used
#ifdef DEBUG
  char junk[5] = "   \0";
  junk[0] = junkstr1[25];
  junk[1] = junkstr2[25];
  junk[2] = junkstr3[25];
  Serial.println(junk);   // note that junkstr* above will be in mem only if they're used.
#endif

for (int row=0; row<MEM_LINES_EEPROM; row++) {
    int offset = 13;
    int charoffset = 3;
    sprintf(outstring, "%04X (",row*16);
    sprintf(&outstring[6], "%04d",row*16);
    sprintf(&outstring[10], "d): ");
    for (int i=0; i<16; i++) {
      // Note about following line: this won't work with ch declared as char, which
      // suggests char is 16 bits wide sometimes.  A bug, methinks?  sbs, 4-7-14
      // char ch = EEPROM.read(16*row+i);
      char ch = EEPROM.read(16*row+i);
      sprintf(&outstring[offset], " %02X", ch);
      offset += 3;
      if(i==7) {  // add an extra space between groups for readability
        sprintf(&outstring[offset], " "); // insert one extra space
        offset++;  // increase appropriately
      }
    // build string of char representation of the data ...
    if ((ch > 32) && (ch < 128))
      charstring[charoffset++] = ch;
    else
      charstring[charoffset++] = '-';
    if (charoffset == 11) charstring[charoffset++] = ' ';  // add extra space
    }
  Serial.print(outstring);
  Serial.println(charstring);
  }

// used snip of code from www.nongnu.org/avr-libc/user-manual/FAQ.html
// and www.nongnu.org/avr-libc/user-manual/group__avr__pgmspace.html
// to extend this tool to ccover PROGMEM (flash) ...

// now do it for PROGMEM (flash)

  Serial.println(F("\n\n*********************** PROGMEM contents ***********************\n"));
  Serial.println(F(" hex   (dec)  00 01 02 03 04 05 06 07  08 09 0A 0B 0C 0D 0E 0F   01234567 89ABCDEF"));
  Serial.println(F("------------- -----------------------  -----------------------   -------- --------"));
  for (int row=0; row<MEM_LINES_PROGMEM; row++) {
    int offset = 13;
    int charoffset = 3;
    sprintf(outstring, "%04X(",row*16);
    sprintf(&outstring[5], "%05d",row*16);
    sprintf(&outstring[10], "d): ");
    for (int i=0; i<16; i++) {
      // note about following line: this won't work with ch declared as char, which
      // suggests char is 16 bits wide sometimes, if char is hex FF - bug?  sbs, 4-7-14
      // char ch = EEPROM.read(16*row+i);
      // byte ch = EEPROM.read(16*row+i);           // for EEPROM
      // byte ch = *((char*)(16*row+i));            // for SRAM
      byte ch = pgm_read_byte(16*row+i);            // for PROGMEM
      sprintf(&outstring[offset], " %02X", ch);     // for either
      offset += 3;
      if(i==7) {  // add an extra space between groups for readability
        sprintf(&outstring[offset], " "); // insert one extra space
        offset++;  // increase appropriately
      }
    // build string of char representation of the data ...
    if ((ch > 32) && (ch < 128))
      charstring[charoffset++] = ch;
    else
      charstring[charoffset++] = '-';
    if (charoffset == 11) charstring[charoffset++] = ' ';  // add extra space
    } 
  Serial.print(outstring);
  Serial.println(charstring);
  }

// now do it for SRAM ...

  Serial.println(F("\n\n*********************** SRAM contents ***********************\n"));
  Serial.println(F(" hex   (dec)  00 01 02 03 04 05 06 07  08 09 0A 0B 0C 0D 0E 0F   01234567 89ABCDEF"));
  Serial.println(F("------------- -----------------------  -----------------------   -------- --------"));
  for (int row=0; row<MEM_LINES_SRAM; row++) {
    int offset = 13;
    int charoffset = 3;
    sprintf(outstring, "%04X(",row*16);
    sprintf(&outstring[5], "%05d",row*16);
    sprintf(&outstring[10], "d): ");
    for (int i=0; i<16; i++) {
      // note about following line: this won't work with ch declared as char, which
      // suggests char is 16 bits wide sometimes, if char is hex FF - bug?  sbs, 4-7-14
      // char ch = EEPROM.read(16*row+i);
      // byte ch = EEPROM.read(16*row+i);           // for EEPROM
      byte ch = *((char*)(16*row+i));               // for SRAM
      sprintf(&outstring[offset], " %02X", ch);     // for either
      offset += 3;
      if(i==7) {  // add an extra space between groups for readability
        sprintf(&outstring[offset], " "); // insert one extra space
        offset++;  // increase appropriately
      }
    // build string of char representation of the data ...
    if ((ch > 32) && (ch < 128))
      charstring[charoffset++] = ch;
    else
      charstring[charoffset++] = '-';
    if (charoffset == 11) charstring[charoffset++] = ' ';  // add extra space
    } 
  Serial.print(outstring);
  Serial.println(charstring);
  }
}

void loop()
{
// nothing to do here
}
