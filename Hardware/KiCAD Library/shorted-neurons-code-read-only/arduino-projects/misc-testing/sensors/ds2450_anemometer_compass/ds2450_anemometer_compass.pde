#include <OneWire.h>
#include <DS2450.h>
#include <Streaming.h>
#include <PString.h>
// Flash has to come after Streaming because of conflicting definition of endl
#include <Flash.h>


DeviceAddress HVAC = { 0x20, 0x48, 0xC6, 0x0, 0x0, 0x0, 0x0, 0x85 };
//20 48 C6 0 0 0 0 85

int vrange = 1;        // 0 = 2.56v, 1 = 5.12v
int rez = 2;           // rez = 0-f bits where 0 = 16
bool parasite = 1;     // parasite power?
float vdiv = 0.5;      // voltage divider circuit value?


OneWire oneWire(8);
ds2450 my2450(&oneWire, HVAC, vrange, rez, parasite, vdiv);

void setup(void) {
  Serial.begin(57600);
  my2450.begin();
}

int8_t compass = -2;
char compassChars[8];
PString compassString(compassChars, sizeof(compassChars));


void loop(void) {
  my2450.measure();
  Serial.print("\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b");
/*
    with 2-bits precision, shift right 14 bits, 2=L, 3=H 0=M
    
    chA = 3     chB = 3     chC = 0     chD = 3        N
    chA = 3     chB = 0     chC = 0     chD = 3        NNE
    chA = 3     chB = 0     chC = 3     chD = 3        NE
    chA = 0     chB = 0     chC = 3     chD = 3        ENE
    chA = 0     chB = 3     chC = 3     chD = 3        E
    chA = 0     chB = 3     chC = 3     chD = 2        ESE
    chA = 3     chB = 3     chC = 3     chD = 2        SE
    chA = 3     chB = 3     chC = 2     chD = 2        SSE
    chA = 3     chB = 3     chC = 2     chD = 3        S
    chA = 3     chB = 2     chC = 2     chD = 3        SSW
    chA = 3     chB = 2     chC = 3     chD = 3        SW
    chA = 2     chB = 2     chC = 3     chD = 3        WSW
    chA = 2     chB = 3     chC = 3     chD = 3        W
    chA = 2     chB = 3     chC = 3     chD = 0        WNW
    chA = 3     chB = 3     chC = 0     chD = 0        NW
    chA = 3     chB = 3     chC = 0     chD = 3        NNW
    
*/
//  works at 4 bits rez
  unsigned int a = (((unsigned int)my2450.voltChA()) >> 8);
  unsigned int b = (((unsigned int)my2450.voltChB()) >> 10);
  unsigned int c = (((unsigned int)my2450.voltChC()) >> 12);
  unsigned int d = (((unsigned int)my2450.voltChD()) >> 14);
/*
  Serial.print("chA=");
  Serial.print(a,DEC);
  Serial.print(" chB=");
  Serial.print(b,DEC);
  Serial.print(" chC=");
  Serial.print(c,DEC);
  Serial.print(" chD=");
  Serial.print(d,DEC);
*/
  Serial.print("    u?=");
  unsigned int u=(a+b+c+d);
  Serial.print(u,DEC);
  Serial.print("   ");
  Serial.print((uint8_t)u,BIN);


  compassString.begin();      
  switch (u) {
    case 243:
      compassString << "N";
      compass=0;
      break;
    case 195:
      compassString << "NNE";
      compass=1;
      break;
    case 207:
      compassString << "NE";
      compass=2;
      break;
    case 15:
      compassString << "ENE";
      compass=3;
      break;
    case 63:
      compassString << "E";
      compass=4;
      break;
    case 62:
      compassString << "ESE";
      compass=5;
      break;
    case 254:
      compassString << "SE";
      compass=6;
      break;
    case 250:
      compassString << "SSE";
      compass=7;
      break;
    case 251:
      compassString << "S";
      compass=8;
      break;
    case 235:
      compassString << "SSW";
      compass=9;
      break;
    case 239:
      compassString << "SW";
      compass=10;
      break;
    case 175:
      compassString << "WSW";
      compass=11;
      break;
    case 191:
      compassString << "W";
      compass=12;
      break;
    case 188:
      compassString << "WNW";
      compass=13;
      break;
    case 252:
      compassString << "NW";
      compass=14;
      break;
    case 240:
      compassString << "NNW";
      compass=15;
      break;
    case 51:
      compassString << "N";
      compass=0;
      break;
    case 1950:
      compassString << "NNE";
      compass=1;
      break;
    case 2070:
      compassString << "NE";
      compass=2;
      break;
    case 1500:
      compassString << "ENE";
      compass=3;
      break;
    case 630:
      compassString << "E";
      compass=4;
      break;
    case 620:
      compassString << "ESE";
      compass=5;
      break;
    case 14:
      compassString << "SE";
      compass=6;
      break;
    case 10:
      compassString << "SSE";
      compass=7;
      break;
    case 11:
      compassString << "S";
      compass=8;
      break;
    case 43:
      compassString << "SSW";
      compass=9;
      break;
    case 47:
      compassString << "SW";
      compass=10;
      break;
    case 1750:
      compassString << "WSW";
      compass=11;
      break;
    case 143:
      compassString << "W";
      compass=12;
      break;
    case 1880:
      compassString << "WNW";
      compass=13;
      break;
    case 60:
      compassString << "NW";
      compass=14;
      break;
    case 510:
      compassString << "NNW";
      compass=15;
      break;

    default:
      compassString << "unknown";
      compass=-1;
      //Serial << "!u=" << u << endl;
      break;
  }

  Serial << " Compass direction = " << compass << ", ";  
  Serial.print(compassString);

/*
  Serial.print("chA = ");
  Serial.print(((unsigned int)my2450.voltChA()) >> 14);
  Serial.print("     chB = ");
  Serial.print(((unsigned int)my2450.voltChB()) >> 14);
  Serial.print("     chC = ");
  Serial.print(((unsigned int)my2450.voltChC()) >> 14);
  Serial.print("     chD = ");
  Serial.print(((unsigned int)my2450.voltChD()) >> 14);
*/

  Serial.print("        ");
  delay(100);
}
