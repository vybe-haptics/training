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
  {A, off, off, off, off, off},//2
  {off, A, off, off, off, off},//3
  {off, off, A, off, off, off},//4
  {off, off, off, A, off, off},//5
  {off, off, off, off, A, off},//6
  {off, off, off, off, off, A},//7
  {A, A, off, off, off, off},//8
  {A, off, A, off, off, off},//9
  {A, off, off, A, off, off},//10
  {A, off, off, off, A, off},//11
  {A, off, off, off, off, A},//12
  {off, A, A, off, off, off},//13
  {off, A, A, off, off, off},//14
  {off, A, off, A, off, off},//15
  {off, A, off, off, A, off},//16
  {off, A, off, off, off, A},//17
  {off, off, A, A, off, off},//18
  {off, off, A, off, A, off},//19
  {off, off, A, off, off, A},//20
  {off, off, off, A, A, off},//21
  {off, off, off, A, off, A},//22
  {off, off, off, off, A, A},//23
  {A, A, A, off, off, off},//24
  {A, A, off, A, off, off},//25
  {A, A, off, off, A, off},//26
  {A, A, off, off, off, A},//27
  {A, off, A, A, off, off},//28
  {A, off, A, off, A, off},//29
  {A, off, A, off, off, A},//30
  {A, off, off, A, A, off},//31
  {A, off, off, A, off, A},//32
  {A, off, off, off, A, A},//33
  {off, A, A, A, off, off},//34
  {off, A, A, off, A, off},//35
  {off, A, A, off, off, A},//36
  {off, A, off, A, A, off},//37
  {off, A, off, A, off, A},//38
  {off, A, off, off, A, A},//39
  {off, off, A, A, A, off},//40
  {off, off, A, A, off, A},//41
  {off, off, A, off, A, A},//42
  {off, off, off, A, A, A},//43
  {A, A, A, A, off, off},//44
  {A, A, A, off, off, A},//45
  {A, A, off, A, off, A},//46
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
