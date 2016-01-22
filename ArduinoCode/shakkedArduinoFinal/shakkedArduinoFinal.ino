//#include <fuck.h>
#include <Wire.h>
#include "fuck.h"
int incomingByte = 0;
Adafruit_DRV2605 drv;
#define TCAADDR 0x70
void tcaselect(uint8_t i) {
  if (i > 7) return;
  Wire.beginTransmission(TCAADDR);
  Wire.write(1 << i);
  Wire.endTransmission();
}

//define states of each motor (A, off)
uint8_t A[] = {0x40};
uint8_t off[] = {0x00};
uint8_t* lib[][6] = {
  {off, off, off, off, off, off},//0
  {off, off, off, off, off, off},//1
  {off, off, A, off, off, A},//2
  {A, off, off, A, A, off},//3
  {A, A, off, off, off, A},//4
  {off, off, off, A, off, off},//5
  {A, off, off, A, off, off},//6
  {off, A, off, off, off, A},//7
  {off, off, off, off, A, off},//8
  {off, A, A, off, off, off},//9
  {A, off, A, off, off, off},//10
  {A, off, A, A, off, off},//11
  {off, A, off, off, A, off},//12
  {off, A, off, A, A, off},//13
  {off, A, A, off, off, off},//14
  {A, off, A, off, off, A},//15
  {off, A, A, A, off, off},//16
  {off, off, A, A, A, off},//17
  {A, A, off, off, A, off},//18
  {off, A, A, off, off, A},//19
  {off, off, off, off, off, A},//20
  {off, off, off, A, A, off},//21
  {A, A, off, A, off, off},//22
  {A, off, off, off, A, A},//23
  {off, off, off, A, off, A},//24
  {off, A, off, off, A, A},//25
  {off, off, A, A, off, off},//26
  {A, off, off, off, A, off},//27
  {A, off, off, off, off, A},//28
  {off, A, off, off, off, off},//29
  {A, off, A, off, A, off},//30
  {A, A, A, off, off, off},//31
  {off, off, A, off, off, off},//32
  {A, A, off, off, off, off},//33
  {A, off, off, A, off, A},//34
  {A, off, off, off, off, off},//35
  {off, A, off, A, off, A},//36
  {off, off, off, off, A, A},//37
  {off, A, off, A, off, off},//38
  {off, A, A, off, A, off},//39
  {off, off, A, off, A, off},//40
  {off, off, A, A, off, A}//41
};
uint8_t** current_lib;

void setup() {
  Serial.begin(250000);
  int index = random(0, 44);
  while (!Serial) ;
  Serial.println("DRV test");
  uint8_t motor_ids[6] = {0, 1, 2, 3, 4, 6};
  for (  uint8_t motor_ids_index = 0; motor_ids_index < 1 + sizeof(motor_ids); motor_ids_index++) {
    tcaselect(motor_ids[motor_ids_index]);
    drv.begin();
  }
}

void loop() {
  Serial.begin(250000);
  while (!Serial) ;
  uint8_t motor_ids[6] = {0, 1, 2, 3, 4, 6};
  if (Serial.available() > 0) {
    incomingByte = Serial.read();
    current_lib = lib[incomingByte];
    for (int q = 0; q < 6 ; q++) {
      tcaselect(motor_ids[q]);
      drv.setRealtimeValue(current_lib[q][0]);
    }
  }
}
