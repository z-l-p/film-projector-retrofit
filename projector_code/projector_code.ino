// ------------------------------------------
// SPECTRAL Wandering Sounds + Images Seminar
// ------------------------------------------
// Projector control software for ESP32 micro-controller
// On HiLetGo 38pin ESP32 board, solder 10uF cap between EN and GND to enable auto loading (otherwise you need to press GPIO 0 [right] button each time you download the code)
// Controlling Hobbywing "Quickrun Fusion SE" motor/ESC combo using ESP32 LEDC peripheral (using 16bit timer for extra resolution)
// Note: Hobbywing motor/esc needs to be programmed via "programming card" to disable braking, otherwise it will try to hold position when speed = 0
// "Digital shutter" is accomplished via AS5047 magnetic rotary encoder, setup via SPI registers and monitored via ABI quadrature pulses
// LED is dimmed via CC LED driver board with PWM input, driven by ESP32 LEDC (which causes slight PWM blinking artifacts at low brightness levels)
// Future option exists for current-controlled dimming (set LedDimMode=0): Perhaps a log taper digipot controlled via SPI? Probably can't dim below 20% though.


// TODO Urgent: 
// startup with lamp disabled!!!! Otherwise film will burn! (Actually, at startup we should advance projector to blanking point at each startup so shutter is closed)
// add forward/backward buttons to code (currently connected but unused)
// February 2023 Eiki UI will have settings for "safe" mode where lamp brightness is linked to speed and shutter angle to prevent film burns. This will change UI input logic.
// Test each part of modular UI
// finish adding single frame button actions in callback function
// Figure out ESC on/off button hack, then add ESP output pin to turn ESC on after boot
// (also if ESC loses its settings then we might need to set throttle config, etc on startup too!)  
// when slew rate is reduced, the slew buffer should be truncated so previous history doesn't influence future values when slew is turned back up (tried to fix in line 468 but failed. I should replace averaging library with my own function so I have direct access to buffer array.)
// add RGB LED feedback for battery charge, etc (or just buy batt meter board?)

// TODO Nice but not essential:
// put UI vars in struct, in case we want to receive them from a remote ESP connected via radio 
// Add closed-loop PID motor speed, eliminating hand-tuned motMinUS & motMaxUS values (Maybe this could also enable cheaper motor/ESC since PID would boost low speed torque and control?)
// if ESP32 Arduino core ever gets support for ledc output_invert method, we can simplify the ISR inverted condition

// Include the libraries
// NOTE: In 2023 this code was developed using the ESP32 Arduino core v2.0.9. 
// When ESP32 Arduino core v3.x is released there will be breaking changes because LEDC setup will be different!
#include <AS5X47.h>             // https://github.com/adrien-legrand/AS5X47
#include <elapsedMillis.h>      // https://github.com/pfeerick/elapsedMillis
#include <movingAvg.h>          // https://github.com/JChristensen/movingAvg
#include <ResponsiveAnalogRead.h> // https://github.com/dxinteractive/ResponsiveAnalogRead
#include <Button2.h>              // https://github.com/LennartHennigs/Button2

// Debug Levels (Warning: excessive debug messages might cause loss of shutter sync. Turn off if not needed.)
int debugEncoder = 0; // serial messages for encoder count and shutterMap value
int debugUI = 1; // serial messages for user interface inputs (pots, buttons, switches)
int debugFrames = 0; // serial messages for frame count and FPS
int debugMotor = 0; // serial messages for motor info
int debugLed = 0; // serial messages for LED info

// Basic setup options (enable the options based on your hardware choices)
#define enableShutterPots 1 // 0 = use hard-coded shutterBlades and shutterAngle, 1 = use pots
#define enableSlewPots 1 // 0 = use hard-coded ledSlewMin and motSlewMin, 1 = use pots
#define enableMotSwitch 1 // 0 = single pot for motor direction/speed (center = STOP), 1 = use switch for FWD-STOP-BACK & pot for speed
#define enableSafeSwitch 1 // 0 = use hard-coded safeMode to limit LED brightness, 1 = use switch to enable/disable safe mode
#define enableSingleButtons 1 // 1 = use buttons for single frame FORWARD / BACK

// INPUT PINS //
  // UI
#define motPotPin 34 // analog input for motor speed pot
#define motSlewPotPin 35 // analog input for motor slew rate pot
#define ledPotPin 32 // analog input for LED dimming pot
#define ledSlewPotPin 33 // analog input for LED dimming slew rate pot
#define shutBladesPotPin 25 // analog input for # of shutter blades pot
#define shutAnglePotPin 26 // analog input for shutter angle pot
#define motDirFwdSwitch 27 // digital input for motor direction switch (forward)
#define motDirBckSwitch 14 // digital input for motor direction switch (backward)
#define buttonApin 36 // digital input for single frame forward button
#define buttonBpin 39 // digital input for single frame backward button
#define safeSwitch 12 // switch to enable "safe mode" where lamp brightness is automatically dimmed at slow speeds


  // Encoder
#define EncI 17 // encoder pulse Index (AS5047 sensor)
#define EncA 16 // encoder pulse A (AS5047 sensor)
#define EncB 4 // encoder pulse B (AS5047 sensor)
#define EncCSN 5 // encoder SPI CSN Pin (AS5047 sensor) - Library also reserves GPIO 18, 19, 23 for SPI

// OUTPUT PINS //
#define escPin 22 // PWM output for ESC
#define ledPin 2  // PWM output for LED (On 38pin HiLetGo ESP32 board, GPIO 2 is the built-in LED)

// ResponsiveAnalogRead Library Setup https://github.com/dxinteractive/ResponsiveAnalogRead#analog-resolution
int AnalogReadThresh = 64; // "Activity Threshold" for ResponsiveAnalogRead library (higher = less noise but may ignore small changes)
float AnalogReadMultiplier = 0.001; // "Snap Multiplier" for ResponsiveAnalogRead library (lower = smoother)
ResponsiveAnalogRead motPot(motPotPin, true, AnalogReadMultiplier);
ResponsiveAnalogRead ledPot(ledPotPin, true, AnalogReadMultiplier);
#if (enableSlewPots) 
  ResponsiveAnalogRead motSlewPot(motSlewPotPin, true, AnalogReadMultiplier);
  ResponsiveAnalogRead ledSlewPot(ledSlewPotPin, true, AnalogReadMultiplier);
#endif
#if (enableShutterPots)
  ResponsiveAnalogRead shutBladesPot(shutBladesPotPin, true, AnalogReadMultiplier);
  ResponsiveAnalogRead shutAnglePot(shutAnglePotPin, true, AnalogReadMultiplier);
#endif

#if (enableSingleButtons)
  // Bounce2 Library setup for single frame buttons
  Button2 buttonA;
  Button2 buttonB;
#endif

int ledSlewVal;
int ledSlewMin = 1; // the minumum slew value when knob is turned down (1-200)
int motSlewVal;
int motSlewMin = 20; // the minumum slew value when knob is turned down (1-200)
int motSlewValOld;
int shutBladesVal;
int shutBladesValOld;
float shutAngleVal;
float shutAngleValOld;

// moving average library setup
movingAvg motAvg(200); // 200 samples @ 50/sec = 10 sec maximum buffer
movingAvg ledAvg(200); // 200 samples @ 50/sec = 10 sec maximum buffer

// UI VARS (could also be updated by remote control in future. Put these in a struct for easier radiolib management?)
int motPotVal = 0; // current value of Motor pot (not necessarily the current speed since we might be ramping toward this value)
int ledPotVal = 0; // current value of LED pot (not necessarily the current LED brightness since we might be fading or strobing)
int shutterBlades = 2; // How many shutter blades: (minimum = 1 so lower values will be constrained to 1)
float shutterAngle = 0.5; // float shutter angle per blade: 0= LED always off, 1= LED always on, 0.5 = 180d shutter angle

// LED VARS //
int safeMode = 0; // 0 = normal, 1 = ledBright is limited by speed and shutter angle to prevent film burns (NOT YET IMPLEMENTED!)
int LedDimMode = 1; // 0 = current-controlled dimming (NOT YET IMPLEMENTED!), 1 = PWM dimming
int LedInvert = 1; // set to 1 to invert LED output signal so it's active-low (required by H6cc driver board)
int ledBright = 0; // current brightness of LED (range depends on Res below. If we're ramping then this will differ from pot value)
const int ledBrightRes = 12; // bits of resolution for LED dimming
const int ledBrightFreq = 1000; // PWM frequency (500Hz is published max for H6cc LED driver, 770Hz is closer to shutter segment period, 1000 seems to work best)
const int ledChannel = 0; // ESP32 LEDC channel number. Pairs share settings (0/1, 2/3, 4/5...) so skip one to insure your settings work!

// MOTOR VARS We are using ESP32 LEDC to drive the RC motor ESC via 1000-2000uS PWM @50Hz (standard servo format) 
int motSpeedUS = 0; // speed of motor (in pulsewidth uS from 1000-2000)
const int motPWMRes = 16; // bits of resolution for extra control (standard servo lib uses 10bit)
const int motPWMFreq = 50; // PWM frequency (50Hz is standard for RC servo / ESC)
int motPWMPeriod = 1000000/motPWMFreq; // microseconds per pulse
const int motPWMChannel = 2; // ESP32 LEDC channel number. Pairs share settings (0/1, 2/3, 4/5...) so skip one to insure your settings work!
int motMinUS = 1816;  // motor pulse length at -24fps (set this by testing)
int motMaxUS = 1163;  // motor pulse length at +24fps (set this by testing)


// Rotary Encoder & Digital Shutter Vriables
void IRAM_ATTR pinChangeISR(); // prototype for ISR function that will be defined in later code (prototype must be declared _before_ we attach interrupt because ESP32 requires "IRAM_ATTR" flag which breaks typical Arduino behavior)
// Start connection to the sensor.
AS5X47 as5047(EncCSN);
// will be used to read data from the magnetic encoder
ReadDataFrame readDataFrame;
const int countsPerRev = 100; // how many encoder transitions per revolution (should be 4x the num pulses in AS5047 setup code)
volatile bool shutterMap[countsPerRev]; // array holding values for lamp state at each position of digital shutter
volatile bool shutterStateOld = 0; // stores the on/off state of the shutter from previous encoder position
static  byte abOld;     // Initialize state
volatile int count;     // current rotary count 
         int countOld;     // old rotary count
volatile int EncIndexCount;     // How many times have the A or B pulses transitioned while index pulse has been high
int as5047MagOK = 0; // status of magnet near AS5047 sensor
int as5047MagOK_old = 0;

// Machine Status Variables
volatile long frame = 0;    // current frame number (frame counter)
         long frameOld = 0; // old frame number
volatile float FPSreal = 0; // measured FPS
         float FPStarget = 0; // requested FPS

// timers
elapsedMicros framePeriod; // microseconds since last frame transition (used for FPS calc)
elapsedMillis timerUI; // MS since last time we checked/updated the user interface

/////////////////////////
//// ---> SETUP <--- ////
/////////////////////////

void setup() {

  pinMode(EncA, INPUT);
  pinMode(EncB, INPUT);
  pinMode(EncI, INPUT);
  if (!LedDimMode) pinMode(ledPin, OUTPUT); // only used for current-controlled dimming. Otherwise LEDC setup will take care of this
  if (enableMotSwitch) {
    pinMode(motDirFwdSwitch, INPUT_PULLUP);
    pinMode(motDirBckSwitch, INPUT_PULLUP);
  }
  if (enableSingleButtons) {
    // Attach buttons (Bounce2 library handles pinmode settings for us)
    buttonA.begin(buttonApin, INPUT_PULLUP, true);
    buttonA.setDebounceTime(5);
    buttonA.setTapHandler(buttonTap);

    buttonB.begin(buttonBpin, INPUT_PULLUP, true);
    buttonB.setDebounceTime(5);
    buttonB.setTapHandler(buttonTap);
  }
  if (enableSafeSwitch) {
    pinMode(safeSwitch, INPUT_PULLUP);
  }
  attachInterrupt(EncA, pinChangeISR, CHANGE);
  attachInterrupt(EncB, pinChangeISR, CHANGE);
  abOld = count = countOld = 0;

  motPot.setAnalogResolution(4096);
  motPot.setActivityThreshold(AnalogReadThresh);
  ledPot.setAnalogResolution(4096);
  ledPot.setActivityThreshold(AnalogReadThresh);

  #if (enableSlewPots)
    motSlewPot.setAnalogResolution(4096);
    motSlewPot.setActivityThreshold(AnalogReadThresh);
    ledSlewPot.setAnalogResolution(4096);
    ledSlewPot.setActivityThreshold(AnalogReadThresh);
  #endif

  #if  (enableShutterPots == 1)
    shutBladesPot.setAnalogResolution(4096);
    shutBladesPot.setActivityThreshold(AnalogReadThresh);
    shutAnglePot.setAnalogResolution(4096);
    shutAnglePot.setActivityThreshold(AnalogReadThresh);
  #endif

  motAvg.begin(); // start the moving average for slewing
  ledAvg.begin(); // start the moving average for slewing

  // Setup Serial Monitor
  Serial.begin(115200);
  delay(100);
  Serial.println("-----------------------------");
  Serial.println("SPECTRAL Projector Controller");
  Serial.println("-----------------------------");
  
  // Set rotation direction (see AS5047 datasheet page 17)
  Settings1 settings1;
  settings1.values.dir = 0;
  as5047.writeSettings1(settings1);
  
  // Set ABI output resolution (see AS5047 datasheet page 19)
  // (pulses per rev: 5 = 50 pulses, 6 = 25 pulses, 7 = 8 pulses)
  Settings2 settings2;
  settings2.values.abires = 6;
  as5047.writeSettings2(settings2);

  // Disable ABI output when magnet error (low or high) exists (see AS5047 datasheet page 24)
  Zposl zposl;
  Zposm zposm;
  zposl.values.compLerrorEn = 1;
  zposl.values.compHerrorEn = 1;
  as5047.writeZeroPosition(zposm, zposl);

  // This command prints the debug information to the Serial port.
  // All registers of the encoder will be read and printed.
  // as5047.printDebugString();
  
  // LED PWM setup
  if (LedDimMode) {
    ledcSetup(ledChannel, ledBrightFreq, ledBrightRes);   // configure LED PWM function using LEDC channel
    ledcAttachPin(ledPin, ledChannel); // attach the LEDC channel to the GPIO to be controlled
    ledcWrite(ledChannel, 0); // turn it off
  }

  // Motor PWM setup
  ledcSetup(motPWMChannel, motPWMFreq, motPWMRes);   // configure motor PWM function using LEDC channel
  ledcAttachPin(escPin, motPWMChannel); // attach the LEDC channel to the GPIO to be controlled
  
  //it's important to send the ESC a "0" speed signal (1500us) whenever the motor is stopped. Otherwise the ESC goes into "failsafe" mode thinking that our RC car has lost contact with the TX!  
  ledcWrite(motPWMChannel, (1<<motPWMRes) * 1500 / motPWMPeriod); // duty = # of values at current res * US / pulse period
  Serial.print("Sending neutral signal to ESC...");
  delay(4000);
  Serial.println("Done");

  fixCount(); // at startup we don't know the absolute position via ABI, so ask SPI
  updateShutterMap(shutterBlades, shutterAngle); //generate initial shutter map ... (1, 0.05 = 1 PPF and narrowest shutter angle)
}

////////////////////////
//// ---> LOOP <--- ////
////////////////////////

void loop() {
  // update every time
  buttonA.loop(); // update button managed by Bounce2 library
  buttonB.loop(); // update button managed by Bounce2 library

  // update these functions @ 50 Hz
  if (timerUI >= 20) {
      as5047MagCheck(); // check for encoder magnet proximity
      readPots();
      updateLed();
      updateMotor();
      
      timerUI = 0;
    }
    
  // These happen once per encoder count  
  if (countOld != count) {
    if (debugEncoder) {
      Serial.print("Count: ");
      Serial.print(count);
      Serial.print(", Lamp: ");
      Serial.print(shutterMap[count]);
      Serial.print(", Brightness: ");
      Serial.println(ledBright);
    }
    countOld = count;
  }

  // These happen once per frame
  if (frameOld != frame) {
    if (debugFrames) {
      Serial.print("FRAME: ");
      Serial.print(frame);
      Serial.print(" (");
      Serial.print(FPSreal);
      Serial.println(" real fps)");
    }
    frameOld = frame;
  }
}

/////////////////////////////
//// ---> FUNCTIONS <--- ////
/////////////////////////////

// On interrupt, read input pins, compute new state, and adjust count
// This rotary encoder method counts all state changes (so 4x the number of "notches" on encoder) and is reliable with bouncy encoders
// From https://arduino.stackexchange.com/questions/16365/reading-from-a-ky-040-rotary-encoder-with-digispark/16420#16420
void IRAM_ATTR pinChangeISR() {
  enum { upMask = 0x66, downMask = 0x99 };
  byte abNew = (digitalRead(EncA) << 1) | digitalRead(EncB);
  byte criterion = abNew^abOld;
  // Execute if this is a valid transition on A or B
  if (criterion==1 || criterion==2) { 
    // There are 3 A or B transitions during each Index pulse. (We count them here, then take action in a child loop.)
    if (digitalRead(EncI)) {
      EncIndexCount++;
    } else {
      EncIndexCount = 0;
    }
    // moving forwards
    if (upMask & (1 << (2*abOld + abNew/2))) {
      if (EncIndexCount == 2) { // reset counter on 'middle" transition during index condition
        count = 0;
        frame++;
        FPSreal = 1000000.0 /framePeriod; // update FPS calc
        framePeriod = 0;
      } else {
        count++;
      }
    } else {
      // moving backwards
      if (EncIndexCount == 2) { // reset counter on 'middle" transition during index condition
        count = 0;
        frame--;
        FPSreal = 1000000.0 /framePeriod; // update FPS calc
        framePeriod = 0;
      } else {
        count--;
      }
      // wrap around the circle instead of using negative steps
      if (count < 0) {
        count = countsPerRev-1;
      }
    }
  }
    abOld = abNew;        // Save new state
    
  // Update LED status for this encoder step
 
    bool shutterState = shutterMap[count]; // copy shutter state to local variable in case it changes during the ISR execution
    if (shutterState != shutterStateOld) { // only update LED if shutter state changes (not every step)
        send_LEDC(); // actual update code is abstracted so it can be run in different contexts
    }
    shutterStateOld = shutterState; // store to global variable for next time

}
  
// send info to the LEDC peripheral to update LED PWM (abstracted here because it's called from loop or ISR)
void send_LEDC() {
  bool shutterState = shutterMap[count]; // copy shutter state to local variable in case it changes during the ISR execution

    if (LedDimMode) { // PWM mode
        if (shutterState) {
          // LED ON for this step of shutter
          ledcSetup(ledChannel, ledBrightFreq, ledBrightRes);   // configure LED PWM function using LEDC channel
          ledcAttachPin(ledPin, ledChannel); // attach the LEDC channel to the GPIO to be controlled
          if (LedInvert) {
            ledcWrite(ledChannel, (1<<ledBrightRes) - ledBright); // set lamp to desired brightness (inverted)
          } else {
            ledcWrite(ledChannel, ledBright); // set lamp to desired brightness
          }
        } else {
          // LED OFF for this segment of shutter
          ledcDetachPin(ledPin); // detach the LEDC channel to the GPIO to be controlled
          if (LedInvert) {
            digitalWrite(ledPin, 1); // send pin high to turn off LED
          } else {
            // detach will take care of turning off pin
          }
          
        }
      } else { // current controlled mode so we're just toggling the LED pin here and adjusting brightness in some other way
        if (LedInvert) {
          digitalWrite(ledPin, !(shutterState));
        } else {
          digitalWrite(ledPin, shutterState);
        }
      }
}



// check for encoder magnet proximity
void as5047MagCheck() {
  
  // read magnet AGC data from sensor registers
  readDataFrame = as5047.readRegister(DIAGAGC_REG);
  Diaagc diaagc;
  diaagc.raw = readDataFrame.values.data;
  //Serial.println(diaagc.values.magl);
  
  // check result for magnet errors and update global var
  if (diaagc.values.magh || diaagc.values.magl) {
    as5047MagOK = 0;
  } else {
    as5047MagOK = 1;
  }

  // take action if global var has changed
  if (as5047MagOK_old != as5047MagOK) {
    if (as5047MagOK) {
      Serial.println("Magnet OK");
      fixCount(); // magnet is back after loss, so fix the count using SPI
    } else {
      Serial.println("Magnet ERROR");
      fixCount(); // magnet is back after loss, so fix the count using SPI
    }
      as5047MagOK_old = as5047MagOK;
  }

}

// Correct the encoder count by asking the sensor for real value over SPI
// This is required during setup since interrupt counts are relative but SPI is absolute
// Also useful if we ever need to recover from a temporary loss of magnet position
void fixCount() {
  count = map(as5047.readAngle(), 0, 360, 0, countsPerRev);
  Serial.println("   (Updated count via SPI)");
}

// fill shutterMap array with boolean values to control LED state at each position of shutter rotation
void updateShutterMap(byte shutterBlades, float shutterAngle) {
  // shutterBlades: number of virtual shutter blades (must be > 0)
  // shutterAngle: ratio between on/off for each shutter blade segment (0.5 = 180d)
  if (shutterBlades < 1) shutterBlades = 1; // it would break if set to 0
  shutterAngle = constrain(shutterAngle, 0.0, 1.0); // make sure it's 0-1
  for (int myBlade = 0; myBlade < shutterBlades; myBlade++) {
    int countOffset = myBlade*(countsPerRev/shutterBlades);
    for (int myCount = 0; myCount < countsPerRev/shutterBlades; myCount++) {
      if (myCount < countsPerRev/shutterBlades*(1.0-shutterAngle)) {
        shutterMap[myCount+countOffset] = 0;
      } else {
        shutterMap[myCount+countOffset] = 1;
      }
    }
  }
}

void readPots() {
  // update each pot using responsiveRead library, then get its value
  // NOTE: buttons are read with a callback (setTapHandler) so they aren't in the loop
  ledPot.update();
  motPot.update();
  ledPotVal = ledPot.getValue();
  motPotVal = motPot.getValue();

  #if (enableSlewPots)
    ledSlewPot.update();
    motSlewPot.update();
    ledSlewVal = ledSlewPot.getValue();
    motSlewVal = motSlewPot.getValue();
  #endif

  #if (enableShutterPots) 
    shutBladesPot.update();
    shutAnglePot.update();
    int shutBladesVal1 = shutBladesPot.getValue();
    int shutAngleVal1 = shutAnglePot.getValue();
    shutBladesVal = map(shutBladesVal1, 0, 4095, 1, 3); // map ADC input to range of number of shutter blades
    shutAngleVal = mapf(shutAngleVal1, 0, 4095, 0.1, 1.0); // map ADC input to range of shutter angle
  #endif

  #if (enableSafeSwitch)
    safeMode = !digitalRead(safeSwitch); // active low so we invert it
  #endif
  


  if (debugUI) {
    if (enableMotSwitch) {
      // print selector switch debug info , even though we aren't using it inside this function
      // Motor UI is switch + pot, so use normal pot scaling
      if (!digitalRead(motDirFwdSwitch)) {
        Serial.print("Mot For, ");
      } else if (!digitalRead(motDirBckSwitch)) {
        Serial.print("Mot Back, ");
      } else {
        Serial.print("Mot Stop, ");
      }
    }
    Serial.print("Mot Speed Pot: ");
    Serial.print(motPotVal);
    Serial.print(", Lamp Bright Pot: ");
    Serial.print(ledPotVal);
    #if (enableSlewPots)
      Serial.print(", Mot Slew Pot: ");
      Serial.print(motSlewVal);
      Serial.print(", Lamp Slew Pot: ");
      Serial.print(ledSlewVal);
    #endif
    #if (enableShutterPots) 
      Serial.print(", Shut Blade Pot: ");
      Serial.print(shutBladesVal1);
      Serial.print(", Shut Angle Pot: ");
      Serial.print(shutAngleVal1);
    #endif
    #if (enableSafeSwitch)
      Serial.print(", Safe Switch: ");
      Serial.print(safeMode);
    #endif
    Serial.println("");
  }
}

// compute LED brightness (note that the ISR ultimately controls the LED state since it acts as the digital shutter)
void updateLed() {
  noInterrupts();
  
  if (shutBladesVal != shutBladesValOld || shutAngleVal != shutAngleValOld) {
    updateShutterMap(shutBladesVal, shutAngleVal);
  }


  ledAvg.reading(ledPotVal); // update the average ledPotVal
  ledSlewVal = map(ledSlewVal,0,4095,ledSlewMin,200);
  ledPotVal = ledAvg.getAvg(ledSlewVal);
  ledBright = ledPotVal; // set brightness to slewed version of pot value
  interrupts();

   if (debugLed) {
    Serial.print("LED Slew: ");
    Serial.print(ledSlewVal);
    Serial.print(", LED Pot: ");
    Serial.print(ledPotVal);
    Serial.print(", LED Bright: ");
    Serial.print(ledBright);
    Serial.print(", Shutter Blades: ");
    Serial.print(shutBladesVal);
    Serial.print(", Shutter Angle: ");
    Serial.println(shutAngleVal);
   }
   // at slow speeds OR if the shutter is fully open, update the LED PWM directly because ISR isn't firing unless in motion
   if (framePeriod > 500000 || shutAngleVal == 1.0) {
    send_LEDC();
   }
}

void updateMotor() {
    
    // Depending on the motor direction switch, we translate the pot ADC to FPS with optional negative scaling
    // (The slewing averager only deals with ints, so our FPS is multiplied by 100 to make it int 2400)
    int motPotFPS;
    if (enableMotSwitch) {
      // Motor UI is switch + pot, so use normal pot scaling
      if (!digitalRead(motDirFwdSwitch)) {
        motPotFPS = mapf(motPotVal,0,4095,20,2400); // convert mot pot value to FPS x 100
      } else if (!digitalRead(motDirBckSwitch)) {
        motPotFPS = mapf(motPotVal,0,4095,-20,-2400); // convert mot pot value to FPS x 100
      } else {
        motPotFPS = 0;
      }
    } else {
       // Motor UI is only pot, so use Use FORWARD-STOP-BACK pot scaling
       motPotFPS = mapf(motPotVal,0,4095,-2400,2400); // convert mot pot value to FPS x 100
    if (motPotFPS > -20 && motPotFPS < 20) motPotFPS = 0; // add "deadband" in middle to make it easier to find the "stop" position
    }
    //int motSlewMin = 20; // the minumum slew value (1-200) REPLACED WITH GLOBAL VARIABLE
    motAvg.reading(motPotFPS); // update the average motPotFPS
    motSlewVal = map(motSlewVal,0,4095,motSlewMin,200);

    // CURRRENTLY BROKEN - FIX IT LATER
    // if (motSlewVal <= motSlewMin && motSlewValOld != motSlewVal) {
    //   motAvg.reset();    // if slewing knob is reduced, reset the slewing buffer so when we turn it back up we won't include the previous history in the buffer
    //   Serial.println("MotSlewVal RESET");
    // }
    // motSlewValOld = motSlewVal;
    FPStarget = motAvg.getAvg(motSlewVal)/100.0; // use slewed value for target FPS (dividing by 100 to get floating point FPS)
    // These values may be negative, but fscale only handles positive values, so...
    float FPStargetScaled;
    if (FPStarget < 0.0) {
      // negative FPS values
      FPStarget = FPStarget * -1.0; // make it positive before fscale function
      FPStarget = (fscale(0.0,24.0,0.0,24.0,FPStarget,4) * -1.0); // reverse log scale and turn it negative again
    } else {
      FPStarget = fscale(0.0,24.0,0.0,24.0,FPStarget,4); // number is positive so just reverse log scale it
    }
    motSpeedUS = mapf(FPStarget,-24.0,24.0,motMinUS,motMaxUS); // convert FPS to motor pulse width in uS 
    int motDuty = (1<<motPWMRes) * motSpeedUS / motPWMPeriod; // convert pulse width to PWM duty cycle (duty = # of values at current res * US / pulse period)
    ledcWrite(motPWMChannel, motDuty); // update motor speed
    if (debugMotor) {
      Serial.print("Mot Slew: ");
      Serial.print(motSlewVal);
      Serial.print(", FPS Target: ");
      Serial.print(FPStarget);
      Serial.print(", Mot uS: ");
      Serial.print(motSpeedUS);
      Serial.print(", Mot PWM Duty: ");
      Serial.println(motDuty);
    }
}

void buttonTap(Button2& btn) {
    if (btn == buttonA) {
      if (debugUI) {
        Serial.println("Button A clicked"); 
      }
      // insert single frame code here
    } else if (btn == buttonB) {
      if (debugUI) {
        Serial.println("Button B clicked"); // insert single frame code here
      }
      // insert single frame code here
    }
}

// map function like Arduino core, but for floats
double mapf(double x, double in_min, double in_max, double out_min, double out_max)
{
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
/* fscale https://playground.arduino.cc/Main/Fscale/
 Floating Point Autoscale Function V0.1
 Paul Badger 2007
 Modified from code by Greg Shakar
 */
float fscale( float originalMin, float originalMax, float newBegin, float newEnd, float inputValue, float curve) {

  float OriginalRange = 0;
  float NewRange = 0;
  float zeroRefCurVal = 0;
  float normalizedCurVal = 0;
  float rangedValue = 0;
  boolean invFlag = 0;


  // condition curve parameter
  // limit range

  if (curve > 10) curve = 10;
  if (curve < -10) curve = -10;

  curve = (curve * -.1) ; // - invert and scale - this seems more intuitive - postive numbers give more weight to high end on output
  curve = pow(10, curve); // convert linear scale into lograthimic exponent for other pow function

  /*
   Serial.println(curve * 100, DEC);   // multply by 100 to preserve resolution  
   Serial.println();
   */

  // Check for out of range inputValues
  if (inputValue < originalMin) {
    inputValue = originalMin;
  }
  if (inputValue > originalMax) {
    inputValue = originalMax;
  }

  // Zero Refference the values
  OriginalRange = originalMax - originalMin;

  if (newEnd > newBegin){
    NewRange = newEnd - newBegin;
  }
  else
  {
    NewRange = newBegin - newEnd;
    invFlag = 1;
  }

  zeroRefCurVal = inputValue - originalMin;
  normalizedCurVal  =  zeroRefCurVal / OriginalRange;   // normalize to 0 - 1 float

  /*
  Serial.print(OriginalRange, DEC);  
   Serial.print("   ");  
   Serial.print(NewRange, DEC);  
   Serial.print("   ");  
   Serial.println(zeroRefCurVal, DEC);  
   Serial.println();  
   */

  // Check for originalMin > originalMax  - the math for all other cases i.e. negative numbers seems to work out fine
  if (originalMin > originalMax ) {
    return 0;
  }

  if (invFlag == 0){
    rangedValue =  (pow(normalizedCurVal, curve) * NewRange) + newBegin;

  }
  else     // invert the ranges
  {  
    rangedValue =  newBegin - (pow(normalizedCurVal, curve) * NewRange);
  }

  return rangedValue;
}