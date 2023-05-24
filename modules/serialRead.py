import serial
serialcomm = serial.Serial('COM5', 38400,timeout=0.005)
lenOfOutputStr=50
# serialcomm.timeout = 1
from math import *
def decodeInfo(string):
    result = ['','','','','','']
    if len(string)==lenOfOutputStr:
        o=0
        i=3
        while i<len(string)-2:
            for j in range(5):
                result[o]+=string[i+j]
            o+=1
            i+=8
        for i in range(len(result)):
            result[i]=float(result[i])
    return result
# for i in range(100):
#     print(serialcomm.readline().decode('utf8', 'ignore'))

# define left 8
# define right 9
# define x A0
# define y A1
# define v3 7
# define BUTTON_K 8
# define BUTTON_A 2
# define BUTTON_B 3
# define BUTTON_C 4
# define BUTTON_D 5

# define BUTTON_F 7
# define BUTTON_E 6
int
X;
int
Y;

int
A;
int
B;
int
C;
int
D;

int
LEFT;
int
RIGHT;
int
SPACE;

void
setup()
{
// put
your
setup
code
here, to
run
once: \
    Serial.begin(9600);
pinMode(v3, OUTPUT);
digitalWrite(v3, HIGH);
pinMode(BUTTON_K, INPUT);
digitalWrite(BUTTON_K, HIGH);

pinMode(BUTTON_A, INPUT);
digitalWrite(BUTTON_A, HIGH);

pinMode(BUTTON_B, INPUT);
digitalWrite(BUTTON_B, HIGH);

pinMode(BUTTON_C, INPUT);
digitalWrite(BUTTON_C, HIGH);

pinMode(BUTTON_D, INPUT);
digitalWrite(BUTTON_D, HIGH);
}

void
loop()
{
// put
your
main
code
here, to
run
repeatedly: \
    X = analogRead(x);
Y = analogRead(y);
SPACE = 0;
if (digitalRead(BUTTON_E) == LOW)
{
    RIGHT = 1;
} else if (digitalRead(BUTTON_E) == HIGH) {
RIGHT =0;
}
if (digitalRead(BUTTON_F) == LOW) {
LEFT =1;
} else if (digitalRead(BUTTON_F) == HIGH) {
LEFT =0;
}
if (digitalRead(BUTTON_K) == LOW) {
SPACE =1;
} else if (digitalRead(BUTTON_K) == HIGH) {
SPACE =0;
}
if (digitalRead(BUTTON_A) == LOW) {
A =1;
} else if (digitalRead(BUTTON_A) == HIGH) {
A =0;
}
if (digitalRead(BUTTON_B) == LOW) {
B =1;
} else if (digitalRead(BUTTON_B) == HIGH) {
B =0;
}
if (digitalRead(BUTTON_C) == LOW) {
C =1;
} else if (digitalRead(BUTTON_C) == HIGH) {
C =0;
}
if (digitalRead(BUTTON_D) == LOW) {
D =1;
} else if (digitalRead(BUTTON_D) == HIGH) {
D =0;
}

Serial.print(X);
Serial.print(",");
Serial.print(Y);
Serial.print(",");
Serial.print(SPACE);
Serial.print(",");
Serial.print(A);
Serial.print(",");
Serial.print(B);
Serial.print(",");
Serial.print(C);
Serial.print(",");
Serial.print(D);
Serial.print(",");
Serial.print(LEFT);
Serial.print(",");
Serial.print(RIGHT);
Serial.print(",");
Serial.println("0");

}/*
 Get scaled and calibrated output of MPU6050
 */

#include <basicMPU6050.h>

// Create instance
basicMPU6050<> imu;

void setup() {
  // Set registers - Always required
  imu.setup();

  // Initial calibration of gyro
  imu.setBias();

  // Start console
  Serial.begin(38400);
}
float round1(float var){
    float value = (int)(var * 100 + .5);
    return (float)value / 100;
}
void loop() {
  // Update gyro calibration
  imu.updateBias();
  delay(300);
  //-- Scaled and calibrated output:
  // Accel

  Serial.print( "Ax:" );if(imu.ax()>0.00){Serial.print("+");}
  Serial.print( imu.ax() );
  Serial.print( "Ay:" );if(imu.ay()>0.00){Serial.print("+");}
  Serial.print( imu.ay() );
  Serial.print( "Az:" );if(imu.az()>0.00){Serial.print("+");}
  Serial.print( imu.az() );
  Serial.print( "Gx:" );if((imu.gx())>0.00){Serial.print("+");}
  Serial.print( imu.gx() );
  Serial.print( "Gy:" );if((imu.gy())>0.00){Serial.print("+");}
  Serial.print( imu.gy() );
  Serial.print( "Gz:" );if((imu.gz())>0.00){Serial.print("+");}
  Serial.print( imu.gz() );
  Serial.println();
}