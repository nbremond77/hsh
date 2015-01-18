#include <Ethernet.h>

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 1, 220 };
byte gateway[] = { 192, 168, 1, 1 };
byte server[] = { 71, 196, 146, 152 };

Client client(server, 80);


const int wiz811resetPin = 9;


void setup()
{
  Serial.begin(115200);
  pinMode( wiz811resetPin, OUTPUT );
  digitalWrite(wiz811resetPin, LOW);
  Serial.print("resetting ethernet... ");  
  delay(50);
  Serial.println("done");
    digitalWrite(wiz811resetPin, HIGH);
  delay(200);
  Serial.print("initializing ethernet... ");  
  Ethernet.begin(mac, ip, gateway);
  Serial.println("done");  
  
  delay(4000);
  
  pinMode( 4, INPUT );
  pinMode( 5, INPUT );

}








// begin temp stuff
#include <OneWire.h>

/* DS18S20 Temperature chip i/o */

OneWire  ds(8);  // on pin 10
int HighByte, LowByte, TReading, SignBit, Tc_100, Whole, Fract, Tf_100, fWhole, fFract;
int qsensors = 0;
byte smac[8];

void tempLoop(void) {
  byte i;
  byte present = 0;
  byte data[12];
  byte addr[8];
  
  if ( !ds.search(addr)) {
//    Serial.print("No more addresses.\n");
    ds.reset_search();
    delay(250);
    qsensors=0;
    return;
  } else {
    qsensors++;
  }
  ds.search(addr);
  
  
  Serial.print("R=");
  for( i = 0; i < 8; i++) {
    Serial.print(addr[i], HEX);
    Serial.print(" ");
    smac[i] = addr[i];
  }

  if ( OneWire::crc8( addr, 7) != addr[7]) {
      Serial.print("CRC is not valid!\n");
      return;
  }
  
  if ( addr[0] != 0x28) {
      Serial.print("Device is not a DS18B20 family device.\n");
      return;
  }

  // The DallasTemperature library can do all this work for you!

  ds.reset();
  ds.select(addr);
  ds.write(0x44,1);         // start conversion, with parasite power on at the end
  
  delay(1000);     // maybe 750ms is enough, maybe not
  // we might do a ds.depower() here, but the reset will take care of it.
  
  present = ds.reset();
  ds.select(addr);    
  ds.write(0xBE);         // Read Scratchpad

  Serial.print("P=");
  Serial.print(present,HEX);
  Serial.print(" ");
  for ( i = 0; i < 9; i++) {           // we need 9 bytes
    data[i] = ds.read();
    Serial.print(data[i], HEX);
    Serial.print(" ");
  }
  Serial.print(" CRC=");
  Serial.print( OneWire::crc8( data, 8), HEX);
//  Serial.println();
  
  LowByte = data[0];
  HighByte = data[1];
  TReading = (HighByte << 8) + LowByte;
  SignBit = TReading & 0x8000;  // test most sig bit
  if (SignBit) // negative
  {
    TReading = (TReading ^ 0xffff) + 1; // 2's comp
  }
  Tc_100 = (6 * TReading) + TReading / 4;    // multiply by (100 * 0.0625) or 6.25

  Tf_100 = Tc_100 * 9/5 + 3200;
//  fWhole = (Tc_100/100) * 9/5 + 32;
  fWhole = Tf_100 / 100;
  fFract = Tf_100 % 100;
	


  Whole = Tc_100 / 100;  // separate off the whole and fractional portions
  Fract = Tc_100 % 100;

  
  

  if (SignBit) // If its negative
  {
     Serial.print("-");
  }
  Serial.print(Whole);
  Serial.print(".");
  if (Fract < 10)
  {
     Serial.print("0");
  }
  Serial.print(Fract);
  Serial.print("C, which is ");


  if (SignBit) // If its negative
  {
     Serial.print("-");
  }
  Serial.print(fWhole);
  Serial.print(".");
  if (fFract < 10)
  {
     Serial.print("0");
  }
  Serial.print(fFract);

  Serial.print("\n");


}


// end temp stuff













void httpTempPoster() {
  
          // print out the last temp we got          
//          client.print("GET sbs/oww_feed.php?oww_feed=avr&oww_sensor=avr_ds18b20_001&v1=&v2=56.3");
          client.print("GET /sbs/oww_feed.php?oww_feed=avr&oww_sensor=avr_ds18b20_002&v1=");
          if (SignBit) // If its negative
          {
            client.print("-");
          }
          client.print(Whole);
          client.print(".");
          if (Fract < 10)
          {
             client.print("0");
          }
          client.print(Fract);
          client.print("&v2=");


          if (SignBit) // If its negative
          {
             client.print("-");
          }
          client.print(fWhole);
          client.print(".");
          if (fFract < 10)
          {
             client.print("0");
          }
          client.print(fFract);
          client.print(" HTTP/1.0");
//          client.print("F</b>ahrenheit.  <br/>&nbsp;<font color=grey>or thats what sensor at 1-wire addr (");
//          
//          for( int i = 0; i < 8; i++) {
//            client.print(smac[i], HEX);
//            client.print(":");
//          }
//          client.print(") seems to think</font><br/><br/>");

}






void loop()
{
  tempLoop();
  
  if (digitalRead(4) && digitalRead(5)) {  
      Serial.println("connecting...");
  
    if (client.connect()) {
      Serial.println("connected");
      httpTempPoster();
      client.print("\n\n");
      while (client.connected()) {
        if (client.available()) {
          char c = client.read();
          Serial.print(c);
        }
  
        if (!client.connected()) {
          Serial.println();
          Serial.println("disconnecting.");
          client.stop();
        }
      }

    } else {
      Serial.println("connection failed");
    }
  } else {
    Serial.println("one or both switches are off...");
  }
  Serial.println("waiting 60 seconds");
  delay(60000);

}
