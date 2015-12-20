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
  {off, off, off, off, off, off},//43
  {off, off, off, off, off, off},//43

  {A, off, off, off, off, off},//0
  {off, A, off, off, off, off},//1
  {off, off, A, off, off, off},//2
  {off, off, off, A, off, off},//3
  {off, off, off, off, A, off},//4
  {off, off, off, off, off, A},//5
  {A, A, off, off, off, off},//6
  {A, off, A, off, off, off},//7
  {A, off, off, A, off, off},//8
  {A, off, off, off, A, off},//9
  {A, off, off, off, off, A},//10
  {off, A, A, off, off, off},//11
  {off, A, A, off, off, off},//12
  {off, A, off, A, off, off},//13
  {off, A, off, off, A, off},//14
  {off, A, off, off, off, A},//15
  {off, off, A, A, off, off},//16
  {off, off, A, off, A, off},//17
  {off, off, A, off, off, A},//18
  {off, off, off, A, A, off},//19
  {off, off, off, A, off, A},//20
  {off, off, off, off, A, A},//21
  {A, A, A, off, off, off},//22
  {A, A, off, A, off, off},//23
  {A, A, off, off, A, off},//23
  {A, A, off, off, off, A},//24
  {A, off, A, A, off, off},//25
  {A, off, A, off, A, off},//26
  {A, off, A, off, off, A},//27
  {A, off, off, A, A, off},//28
  {A, off, off, A, off, A},//29
  {A, off, off, off, A, A},//30
  {off, A, A, A, off, off},//31
  {off, A, A, off, A, off},//32
  {off, A, A, off, off, A},//33
  {off, A, off, A, A, off},//34
  {off, A, off, A, off, A},//35
  {off, A, off, off, A, A},//36
  {off, off, A, A, A, off},//37
  {off, off, A, A, off, A},//38
  {off, off, A, off, A, A},//39
  {off, off, off, A, A, A},//40
  {A, A, A, A, off, off},//41
  {A, A, A, off, off, A},//42
  {A, A, off, A, off, A},//43
};
uint8_t** current_lib;

void setup() {
  Serial.begin(250000);
  int index = random(0, 44);
  while (!Serial) ;
  Serial.println("DRV test");
  uint8_t motor_ids[6] = {0, 1, 4, 5, 6, 7};
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
    current_lib = lib[incomingByte - 1];
    for (int q = 0; q < 6 ; q++) {
      tcaselect(motor_ids[q]);
      drv.setRealtimeValue(current_lib[q][0]);
    }
  }
}
