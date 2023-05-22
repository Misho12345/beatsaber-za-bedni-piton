// define global variables for analog pins.

// X values will be read from pin 0 and Y from pin 1

#define PIN_ANALOG_X 0

#define PIN_ANALOG_Y 1

 

void setup() {

 // Start serial because we will observe values at serial monitor

 Serial.begin(38400);

}

 

void loop() {

 // Print x axis values

 Serial.print("Ax:+1.04Ay:-0.03Az:-0.23Gx:+0.00Gy:+0.00Gz:+0.00Jx:0");
 Serial.print(float(analogRead(PIN_ANALOG_X)/100.00));
 

 // Print y axis values

 Serial.print("Jy:0");
 Serial.print(float(analogRead(PIN_ANALOG_Y)/100.00));
 Serial.println();

 

 // Some delay to clearly observe your values on serial monitor.

 delay(100);
  
}
