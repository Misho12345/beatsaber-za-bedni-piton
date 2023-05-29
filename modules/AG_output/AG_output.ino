/*
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
  delay(100);
  //-- Scaled and calibrated output:
  // Accel
  
  Serial.print( "Ax:" );
  if(imu.ax()>0.00){Serial.print("+");}
  Serial.print( imu.ax() );
  
  Serial.print( "Ay:" );
  if(imu.ay()>0.00){Serial.print("+");}
  Serial.print( imu.ay() );
  
  Serial.print( "Az:" );
  if(imu.az()>0.00){Serial.print("+");}
  Serial.print( imu.az() );
  
  Serial.print( "Gx:" );
  if(fabs(imu.gx())<0.01){
    Serial.print("+0.00");
  }else{
    if(imu.gx()>0.00){Serial.print("+");}
    Serial.print( imu.gx() );
  }

  Serial.print( "Gy:" );
  if(fabs(imu.gy())<0.01){
    Serial.print("+0.00");
  }else{
    if(imu.gy()>0.00){Serial.print("+");}
    Serial.print( imu.gy() );
  }

  Serial.print( "Gz:" );
  if(fabs(imu.gz())<0.01){
    Serial.print("+0.00");
  }else{
    if(imu.gz()>0.00){Serial.print("+");}
    Serial.print( imu.gz() );
  }
  
//  Serial.print( "Gy:" );
//  if(imu.gy()>0.00){Serial.print("+");}
//  Serial.print( imu.gy() );
//  
//  Serial.print( "Gz:" );
//  if(imu.gz()>0.00){Serial.print("+");}
//  Serial.print( imu.gz() );

  
  Serial.println();
}
