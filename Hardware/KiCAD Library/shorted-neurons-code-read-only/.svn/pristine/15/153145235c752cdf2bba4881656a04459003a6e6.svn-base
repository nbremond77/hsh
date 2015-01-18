/**************************************************************************
 *                                                                         *
 * ADXL345 Driver for Arduino                                              *
 *                                                                         *
 ***************************************************************************
 *                                                                         * 
 * This program is free software; you can redistribute it and/or modify    *
 * it under the terms of the MIT License.                                  *
 * This program is distributed in the hope that it will be useful,         *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
 * MIT License for more details.                                           *
 *                                                                         *
 ***************************************************************************
 * 
 * Revision History
 * 
 * Date  By What
 * 20100515 TJS Initial Creation 
 * 20100524 TJS Modified to run with Kevin Stevenard's driver
 */
#include "Wire.h"
#include "ADXL345.h"

ADXL345 Accel;

void setup(){
  digitalWrite(A4, HIGH); //pullup
  digitalWrite(A5, HIGH); //pullup
  Serial.begin(115200);
  delay(1);
  Wire.begin();
  delay(1);
  //Serial.println("Here");
  Accel.powerOn();
  Accel.setLowPower(false);  
  Accel.setFullResBit(true); 
  Accel.setRangeSetting(4); 
  delay(100);
  Accel.set_bw(ADXL345_BW_200);
  Serial.print("BW_OK? ");
  Serial.println(Accel.status, DEC);
  delay(2000);
}

int i;
int acc_data[3];
int r;
int l = 0;
long m;
long t;
int x;
int y;
int z;

void loop(){

  m=millis();

  for (r=0; r<1001; r++) {


    //Accel.get_Gxyz(acc_data);
    Accel.readAccel(acc_data);
    if(Accel.status){
      //float length = 0.;
      Serial.print(millis());
      Serial.print("ms ");
      for(i = 0; i < 3; i++){
        //length += (float)acc_data[i] * (float)acc_data[i];
        Serial.print(acc_data[i]);
        Serial.print(" ");
      }
      //length = sqrt(length);
      //Serial.print(" length=");
      //Serial.println(length);
      Serial.println("");
      //delay(1);
    }
    else{
      Serial.println("ERROR: ADXL345 data read error");
    }
  }

  t=(millis() - m);   
  Serial.print("iteration ");
  Serial.print(l, DEC);
  Serial.print(" took ");
  Serial.print(t, DEC);
  Serial.println("ms");
  delay(1000);
  l++;
}

