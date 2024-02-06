// ------------------------------------------
// SPECTRAL Wandering Sounds + Images Seminar
// ------------------------------------------
// Projector control software for ESP32 micro-controller
// On some 38pin ESP32 boards you need to press GPIO 0 [right] button each time you upload code. If so, solder 10uF cap between EN and GND to enable auto reset.
// Controlling Hobbywing "Quickrun Fusion SE" motor/ESC combo using ESP32 LEDC peripheral (using 16bit timer for extra resolution)
// Note: Hobbywing motor/esc needs to be programmed via "programming card" to disable braking, otherwise it will try to hold position when speed = 0
// (If you hack the ESC wiring according to our docs, you can program it with the ESCprogram() function instead of a programming card)
// "Digital shutter" is accomplished via AS5047 magnetic rotary encoder, setup via SPI registers and monitored via ABI quadrature pulses
// LED is dimmed via CC LED driver board with PWM input, driven by ESP32 LEDC (which causes slight PWM blinking artifacts at low brightness levels)
// Future option exists for current-controlled dimming (set LedDimMode=0): Perhaps a log taper digipot controlled via SPI? Probably can't dim below 20% though.

// TODO Urgent:
// every time FPStarget = 0 and shutter is open, we should advance projector to blanking point so shutter is "closed"
// add single-frame capability to button callback functions
// February 2023 Eiki UI will have settings for "safe" mode where lamp brightness is linked to speed and shutter angle to prevent film burns. This will change UI input logic.
// Test each part of modular UI
// add RGB LED feedback for different functions (maybe different color for each speed?)

// TODO Nice but not essential:
// put UI vars in struct, in case we want to receive them from a remote ESP connected via radio
// Add closed-loop PID motor speed, eliminating hand-tuned motMinUS & motMaxUS values (Maybe this could also enable cheaper motor/ESC since PID would boost low speed torque and control?)
// if ESP32 Arduino core ever gets support for ledc output_invert method, we can simplify the ISR inverted condition

// Include the libraries
// NOTE: In 2023 this code was developed using the ESP32 Arduino core v2.0.9.
// When ESP32 Arduino core v3.x is released there will be breaking changes because LEDC setup will be different!
#include <AS5X47.h>         // https://github.com/adrien-legrand/AS5X47
#include <elapsedMillis.h>  // https://github.com/pfeerick/elapsedMillis
#include <Ramp.h>           // https://github.com/siteswapjuggler/RAMP
//#include <ResponsiveAnalogRead.h>  // https://github.com/dxinteractive/ResponsiveAnalogRead
#include <SimpleKalmanFilter.h>  // https://github.com/denyssene/SimpleKalmanFilter
#include <Button2.h>             // https://github.com/LennartHennigs/Button2
#include <Adafruit_NeoPixel.h>   // https://github.com/adafruit/Adafruit_NeoPixel

// Debug Levels (Warning: debug messages might cause loss of shutter sync. Turn off if not needed.)
int debugEncoder = 0;  // serial messages for encoder count and shutterMap value
int debugUI = 0;       // serial messages for user interface inputs (pots, buttons, switches)
int debugFrames = 0;   // serial messages for frame count and FPS
int debugMotor = 0;    // serial messages for motor info
int debugLed = 0;      // serial messages for LED info

// Basic setup options (enable the options based on your hardware choices)
#define enableShutter 1      // 0 = LED stays on all the time (in case physical shutter is installed), 1 = use encoder to blink LED for digital shutter
#define enableShutterPots 1  // 0 = use hard-coded shutterBlades and shutterAngle variables, 1 = use pots to control these functions
#define enableSlewPots 1     // 0 = use hard-coded ledSlewMin and motSlewMin variables, 1 = use pots to control these functions
#define enableMotSwitch 1    // 0 = single pot for motor direction/speed (center = STOP), 1 = use switch for FWD-STOP-BACK & pot for speed
#define enableSafeSwitch 1   // 0 = use hard-coded safeMode variable to limit LED brightness, 1 = use switch to enable/disable safe mode
#define enableButtons 1      // 1 = use buttons A and B (for single frame FORWARD / BACK)
#define enableStatusLed 1    // 1 = use NeoPixel status LED(s) for user feedback

// INPUT PINS //
// UI
#define motPotPin 33         // analog input for motor speed pot
#define motSlewPotPin 32     // analog input for motor slew rate pot
#define ledPotPin 35         // analog input for LED dimming pot
#define ledSlewPotPin 34     // analog input for LED dimming slew rate pot
#define shutBladesPotPin 39  // analog input for # of shutter blades pot
#define shutAnglePotPin 36   // analog input for shutter angle pot
#define motDirFwdSwitch 27   // digital input for motor direction switch (forward)
#define motDirBckSwitch 14   // digital input for motor direction switch (backward)
#define buttonApin 26        // digital input for single frame forward button
#define buttonBpin 25        // digital input for single frame backward button
#define safeSwitch 12        // switch to enable "safe mode" where lamp brightness is automatically dimmed at slow speeds


// Encoder
#define EncI 17   // encoder pulse Index (AS5047 sensor)
#define EncA 16   // encoder pulse A (AS5047 sensor)
#define EncB 4    // encoder pulse B (AS5047 sensor)
#define EncCSN 5  // encoder SPI CSN Pin (AS5047 sensor) - Library also reserves GPIO 18, 19, 23 for SPI

// OUTPUT PINS //
#define escPin 22         // PWM output for ESC
#define escProgramPin 21  // serial output to program ESC (needs 10k resistor to 3.3v)
#define ledPin 2          // PWM output for LED (On 38pin HiLetGo ESP32 board, GPIO 2 is the built-in LED)
#define NeoPixelPin 15    // output pin for NeoPixel status LED(s)

// Kalman Filter Library Setup
float kalmanMEA = 2;    // "measurement noise" (also used to seed estimated noise)
float kalmanQ = 0.005;  // "Process Noise" (smaller numbers = more smoothing but more lag)

SimpleKalmanFilter motPotKalman(kalmanMEA, kalmanMEA, kalmanQ);
SimpleKalmanFilter ledPotKalman(kalmanMEA, kalmanMEA, kalmanQ);

#if (enableSlewPots)
SimpleKalmanFilter motSlewPotKalman(kalmanMEA, kalmanMEA, kalmanQ);
SimpleKalmanFilter ledSlewPotKalman(kalmanMEA, kalmanMEA, kalmanQ);
#endif

#if (enableShutterPots)
SimpleKalmanFilter shutBladesPotKalman(kalmanMEA, kalmanMEA, kalmanQ);
SimpleKalmanFilter shutAnglePotKalman(kalmanMEA, kalmanMEA, kalmanQ);
#endif

#if (enableButtons)
// Bounce2 Library setup for single frame buttons
Button2 buttonA;
Button2 buttonB;
#endif

int ledSlewVal = 0;
int ledSlewValOld;
int ledSlewMin = 0;      // the minumum slew value when knob is turned down (msec).
int ledSlewMax = 10000;  // the max slew value when knob is turned up (msec).

int motSlewVal = 0;
int motSlewValOld;
int motSlewMin = 0;      // the minumum slew value when knob is turned down (msec).
int motSlewMax = 10000;  // the max slew value when knob is turned up (msec).

int shutBladesPotVal;
int shutBladesVal;
int shutBladesValOld;
int shutAnglePotVal;
float shutAngleVal;
float shutAngleValOld;


// Ramp library setup
rampInt motAvg;  // ramp object for motor speed slewing
rampInt ledAvg;  // ramp object for LED brightness slewing


#if (enableStatusLed)
  // NeoPixel library setup
#define NUMPIXELS 1  // How many NeoPixels are attached?

Adafruit_NeoPixel pixels(NUMPIXELS, NeoPixelPin, NEO_RGB + NEO_KHZ800);
// last argument should match your LED type. Add together as needed:
//   NEO_KHZ800  800 KHz bitstream (most NeoPixel products w/WS2812 LEDs)
//   NEO_KHZ400  400 KHz (classic 'v1' (not v2) FLORA pixels, WS2811 drivers)
//   NEO_GRB     Pixels are wired for GRB bitstream (most NeoPixel products)
//   NEO_RGB     Pixels are wired for RGB bitstream (5mm LEDS, v1 FLORA pixels, not v2)
//   NEO_RGBW    Pixels are wired for RGBW bitstream (NeoPixel RGBW products)
#endif

// UI VARS (could also be updated by remote control in future. Put these in a struct for easier radiolib management?)
int motPotVal = 0;  // current value of Motor pot (not necessarily the current speed since we might be ramping toward this value)
int motPotFPS = 0;  // current requested FPS based on motPotVal and scaling
int motPotFPSOld = 0;
int ledPotVal = 0;  // current value of LED pot (not necessarily the current LED brightness since we might be fading or strobing)
int ledPotValOld;
int shutterBlades = 3;     // How many shutter blades: (minimum = 1 so lower values will be constrained to 1)
float shutterAngle = 0.5;  // float shutter angle per blade: 0= LED always off, 1= LED always on, 0.5 = 180d shutter angle

// LED VARS //
int safeMode = 0;                // 0 = normal, 1 = ledBright is limited by speed and shutter angle to prevent film burns (NOT YET IMPLEMENTED!)
int LedDimMode = 1;              // 0 = current-controlled dimming (NOT YET IMPLEMENTED!), 1 = PWM dimming
int LedInvert = 1;               // set to 1 to invert LED output signal so it's active-low (required by H6cc driver board)
int ledBright = 0;               // current brightness of LED (range depends on Res below. If we're ramping then this will differ from pot value)
const int ledBrightRes = 12;     // bits of resolution for LED dimming
const int ledBrightFreq = 1000;  // PWM frequency (500Hz is published max for H6cc LED driver, 770Hz is closer to shutter segment period, 1000 seems to work best)
const int ledChannel = 0;        // ESP32 LEDC channel number. Pairs share settings (0/1, 2/3, 4/5...) so skip one to insure your settings work!

// MOTOR VARS We are using ESP32 LEDC to drive the RC motor ESC via 1000-2000uS PWM @50Hz (standard servo format)
int motSpeedUS = 0;                       // speed of motor (in pulsewidth uS from 1000-2000)
const int motPWMRes = 16;                 // bits of resolution for extra control (standard servo lib uses 10bit)
const int motPWMFreq = 50;                // PWM frequency (50Hz is standard for RC servo / ESC)
int motPWMPeriod = 1000000 / motPWMFreq;  // microseconds per pulse
const int motPWMChannel = 2;              // ESP32 LEDC channel number. Pairs share settings (0/1, 2/3, 4/5...) so skip one to insure your settings work!
int motMinUS = 1788;                      // motor pulse length at -24fps (set this by testing)
int motMaxUS = 1220;                      // motor pulse length at +24fps (set this by testing)


// prototypes for ISR functions that will be defined in later code 
// (prototype must be declared _before_ we attach interrupt because ESP32 requires "IRAM_ATTR" flag which breaks typical Arduino behavior)
void IRAM_ATTR pinChangeISR();  
void IRAM_ATTR send_LEDC();
// Start connection to the sensor.
AS5X47 as5047(EncCSN);
// will be used to read data from the magnetic encoder
ReadDataFrame readDataFrame;
const int countsPerRev = 100;            // how many encoder transitions per revolution (should be 4x the num pulses in AS5047 setup code)
volatile bool shutterMap[countsPerRev];  // array holding values for lamp state at each position of digital shutter
volatile bool shutterStateOld = 0;       // stores the on/off state of the shutter from previous encoder position
static byte abOld;                       // Initialize state
volatile int count;                      // current rotary count
int countOld;                            // old rotary count
volatile int EncIndexCount;              // How many times have the A or B pulses transitioned while index pulse has been high
int as5047MagOK = 0;                     // status of magnet near AS5047 sensor
int as5047MagOK_old = 0;

// Machine Status Variables
volatile long frame = 0;     // current frame number (frame counter)
long frameOld = 0;           // old frame number
volatile float FPSreal = 0;  // measured FPS
float FPSsafe = 0; // non-volatile measured FPS
float FPStarget = 0;         // requested FPS

// Settings for HobbyWing Quicrun Fusion SE motor
#define ESC_WRITE_BIT_TIME_WIDTH 2500  // uSec length of each pulse ("2500" = 400 baud)
char ESC_settings[] = {
  0,                // RPM Throttle Matching enabled
  2,                // 3S LiPo cells
  1,                // "Low" battery cutoff threshold (Low / Med / High)
  0,                // 105C temp cutoff
  0,                // CCW rotation
  0,                // 6V BEC
  0,                // Drag brake force disabled
  4,                // Drag brake rate 5
  3,                // Max reverse force 100%
  5, 0, 4, 2, 0, 0  // extra bytes sniffed with logic analyzer, don't know what they're for
};

// timers
//elapsedMicros framePeriod;  // microseconds since last frame transition (used for FPS calc)
elapsedMicros countPeriod;  // microseconds since last encoder count transition (used for FPS calc)
elapsedMillis timerUI;      // MS since last time we checked/updated the user interface

/////////////////////////
//// ---> SETUP <--- ////
/////////////////////////

void setup() {
  Serial.begin(115200);  // Setup Serial Monitor

  pinMode(ledPin, OUTPUT);  // LEDC setup will take care of this later, but force it now just in case we're using current-controlled dimming
  digitalWrite(ledPin, 1);  // turn off LED during startup to prevent film burns

  if (enableMotSwitch) {
    pinMode(motDirFwdSwitch, INPUT_PULLUP);
    pinMode(motDirBckSwitch, INPUT_PULLUP);
  }
#if (enableButtons)
  // Attach buttons (Bounce2 library handles pinmode settings for us)
  buttonA.begin(buttonApin, INPUT_PULLUP, true);
  buttonA.setDebounceTime(5);
  buttonA.setTapHandler(buttonTap);

  buttonB.begin(buttonBpin, INPUT_PULLUP, true);
  buttonB.setDebounceTime(5);
  buttonB.setTapHandler(buttonTap);
#endif
  if (enableSafeSwitch) {
    pinMode(safeSwitch, INPUT_PULLUP);
  }
  if (enableShutter) {
    pinMode(EncA, INPUT);
    pinMode(EncB, INPUT);
    pinMode(EncI, INPUT);
    attachInterrupt(EncA, pinChangeISR, CHANGE);
    attachInterrupt(EncB, pinChangeISR, CHANGE);
  }

  abOld = count = countOld = 0;

#if (enableStatusLed)
  pixels.begin();                // INITIALIZE NeoPixel object
  updateStatusLED(0, 32, 0, 0);  // start with LED red while booting
#endif

  //delay(100);
  Serial.println("-----------------------------");
  Serial.println("SPECTRAL Projector Controller");
  Serial.println("-----------------------------");

// Program the ESC settings if user holds down both buttons during startup
#if (enableButtons)
  if (digitalRead(buttonApin) == 0 && digitalRead(buttonBpin) == 0) {
    ESCprogram();
    while (1)
      ;  // don't continue setup since the ESC needs to be rebooted before we can continue
  }
#endif



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

  // LED PWM setup (BYPASSED because we set up the LEDC on each shutter blade now, and doing it here causes LED to come on during startup)
  // if (LedDimMode) {
  //   ledcSetup(ledChannel, ledBrightFreq, ledBrightRes);   // configure LED PWM function using LEDC channel
  //   ledcAttachPin(ledPin, ledChannel); // attach the LEDC channel to the GPIO to be controlled
  //   ledcWrite(ledChannel, 1); // turn it off
  // }

  // Motor PWM setup
  ledcSetup(motPWMChannel, motPWMFreq, motPWMRes);  // configure motor PWM function using LEDC channel
  ledcAttachPin(escPin, motPWMChannel);             // attach the LEDC channel to the GPIO to be controlled

  //it's important to send the ESC a "0" speed signal (1500us) whenever the motor is stopped. Otherwise the ESC goes into "failsafe" mode thinking that our RC car has lost contact with the TX!
  ledcWrite(motPWMChannel, (1 << motPWMRes) * 1500 / motPWMPeriod);  // duty = # of values at current res * US / pulse period
  Serial.print("Sending neutral signal to ESC...");
  delay(4000);
  Serial.println("Done");

#if (enableStatusLed)
  updateStatusLED(0, 0, 32, 0);  // green LED
#endif

  fixCount();                                     // at startup we don't know the absolute position via ABI, so ask SPI
  updateShutterMap(shutterBlades, shutterAngle);  //generate initial shutter map ... (1, 0.05 = 1 PPF and narrowest shutter angle)
}

////////////////////////
//// ---> LOOP <--- ////
////////////////////////

void loop() {
  
 

  // update these functions @ 50 Hz
  if (timerUI >= 20) {
    as5047MagCheck();  // check for encoder magnet proximity

  if (countPeriod > 100000) {
      //FPSsafe = 0; // if we're stopped, the encoder stops counting so FPSreal will never indicate 0 FPS
      //Serial.println(countPeriod);
      //send_LEDC();
    }

    readUI();
    updateLed();
    updateMotor();

    timerUI = 0;
  }

  // These happen once per encoder count
  if (countOld != count) {
    FPSsafe = FPSreal; // copy volatile global from ISR so it's safe for other routines
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
  enum { upMask = 0x66,
         downMask = 0x99 };
  byte abNew = (digitalRead(EncA) << 1) | digitalRead(EncB);
  byte criterion = abNew ^ abOld;
  // Execute if this is a valid transition on A or B
  if (criterion == 1 || criterion == 2) {
    FPSreal = 10000.0 / countPeriod;  // update FPS calc based on period between the 100 encoder counts
    countPeriod = 0;
    // There are 3 A or B transitions during each Index pulse. (We count them here, then take action in a child loop.)
    if (digitalRead(EncI)) {
      EncIndexCount++;
    } else {
      EncIndexCount = 0;
    }
    // moving forwards
    if (upMask & (1 << (2 * abOld + abNew / 2))) {
      if (EncIndexCount == 2) {  // reset counter on 'middle" transition during index condition
        count = 0;
        frame++;
        //FPSreal = 1000000.0 / framePeriod;  // update FPS calc
        //framePeriod = 0;
      } else {
        count++;
      }
    } else {
      // moving backwards
      if (EncIndexCount == 2) {  // reset counter on 'middle" transition during index condition
        count = 0;
        frame--;
        //FPSreal = 1000000.0 / framePeriod;  // update FPS calc
        //framePeriod = 0;
      } else {
        count--;
      }
      // wrap around the circle instead of using negative steps
      if (count < 0) {
        count = countsPerRev - 1;
      }
    }
  }
  abOld = abNew;  // Save new state

  // Update LED status for this encoder step

  bool shutterState = shutterMap[count];  // copy shutter state to local variable in case it changes during the ISR execution
  if (shutterState != shutterStateOld) {  // only update LED if shutter state changes (not every step)
    send_LEDC();                          // actual update code is abstracted so it can be run in different contexts
  }
  shutterStateOld = shutterState;  // store to global variable for next time
}


// send info to the LEDC peripheral to update LED PWM (abstracted here because it's called from loop or ISR)
void IRAM_ATTR send_LEDC() {
  bool shutterState = shutterMap[count];  // copy shutter state to local variable in case it changes during the ISR execution
  //float FPSlocal = FPSsafe; // copy to local variable
  //if (FPSlocal < 0.2) shutterState = 0;   // cheat the shutter closed in case we're stopped, to prevent film burns

  if (LedDimMode) {  // PWM mode
    if (shutterState == 1 || enableShutter == 0) {
      // LED ON for this step of shutter OR shutter is disabled so LED is always on
      ledcSetup(ledChannel, ledBrightFreq, ledBrightRes);  // configure LED PWM function using LEDC channel
      ledcAttachPin(ledPin, ledChannel);                   // attach the LEDC channel to the GPIO to be controlled
      if (LedInvert) {
        ledcWrite(ledChannel, (1 << ledBrightRes) - ledBright);  // set lamp to desired brightness (inverted)
      } else {
        ledcWrite(ledChannel, ledBright);  // set lamp to desired brightness
      }

    } else if (shutterState == 0 && enableShutter == 1) {
      // LED OFF for this segment of shutter
      ledcDetachPin(ledPin);  // detach the LEDC channel to the GPIO to be controlled
      if (LedInvert) {
        digitalWrite(ledPin, 1);  // send pin high to turn off LED
      } else {
        // detach will take care of turning off pin
      }
    }
  } else {
    if (LedInvert) {
      if (enableShutter) {
        digitalWrite(ledPin, !(shutterState));  // active low, using shutter
      } else {
        digitalWrite(ledPin, 0);  // active low, no shutter
      }
    } else {
      if (enableShutter) {
        digitalWrite(ledPin, shutterState);  // active high, using shutter
      } else {
        digitalWrite(ledPin, 1);  // active high, no shutter
      }
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
      fixCount();  // magnet is back after loss, so fix the count using SPI
    } else {
      Serial.println("Magnet ERROR");
      fixCount();  // magnet is back after loss, so fix the count using SPI
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
  if (shutterBlades < 1) shutterBlades = 1;          // it would break if set to 0
  shutterAngle = constrain(shutterAngle, 0.0, 1.0);  // make sure it's 0-1
  for (int myBlade = 0; myBlade < shutterBlades; myBlade++) {
    int countOffset = myBlade * (countsPerRev / shutterBlades);
    for (int myCount = 0; myCount < countsPerRev / shutterBlades; myCount++) {
      if (myCount < countsPerRev / shutterBlades * (1.0 - shutterAngle)) {
        shutterMap[myCount + countOffset] = 0;
      } else {
        shutterMap[myCount + countOffset] = 1;
      }
    }
  }
}

// Read user interface buttons and pots
// NOTE incurs 12ms blocking delay to help calm down crappy ADC between readings.
void readUI() {

#if (enableButtons)
  buttonA.loop();  // update button managed by Bounce2 library
  buttonB.loop();  // update button managed by Bounce2 library
#endif

  // update each pot using Kalman filter to reduce horrible terrible awful ADC noise

  motPotVal = motPotKalman.updateEstimate(analogRead(motPotPin));
  delay(2);
  ledPotVal = ledPotKalman.updateEstimate(analogRead(ledPotPin));
  delay(2);

#if (enableSlewPots)
  motSlewVal = motSlewPotKalman.updateEstimate(analogRead(motSlewPotPin));
  delay(2);
  ledSlewVal = ledSlewPotKalman.updateEstimate(analogRead(ledSlewPotPin));
  delay(2);
#endif

#if (enableShutterPots && enableShutter)
  shutBladesPotVal = shutBladesPotKalman.updateEstimate(analogRead(shutBladesPotPin));
  delay(2);
  shutAnglePotVal = shutAnglePotKalman.updateEstimate(analogRead(shutAnglePotPin));
  delay(2);
  // using custom scaling for shutBladesPotVal to make control feel right
  if (shutBladesPotVal < 800) {
    shutBladesVal = 1;
  } else if (shutBladesPotVal < 2500) {
    shutBladesVal = 2;
  } else {
    shutBladesVal = 3;
  }
  shutAngleVal = mapf(shutAnglePotVal, 0, 4095, 0.1, 1.0);  // map ADC input to range of shutter angle
#endif

#if (enableSafeSwitch)
  safeMode = !digitalRead(safeSwitch);  // active low so we invert it
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
    Serial.print("Mot Speed: ");
    Serial.print(motPotVal);
#if (enableSlewPots)
    Serial.print(", Mot Slew: ");
    Serial.print(motSlewVal);
#endif
    Serial.print(", Lamp Bright: ");
    Serial.print(ledPotVal);
#if (enableSlewPots)
    Serial.print(", Lamp Slew: ");
    Serial.print(ledSlewVal);
#endif
#if (enableShutterPots)
    Serial.print(", Shut Blade: ");
    Serial.print(shutBladesPotVal);
    Serial.print(", Shut Angle: ");
    Serial.print(shutAnglePotVal);
#endif
#if (enableSafeSwitch)
    Serial.print(", Safe Switch: ");
    Serial.print(safeMode);
#endif
    Serial.println("");
  }
}


// compute LED brightness (note that the ISR ultimately controls the LED state if enableShutter = 1)
void updateLed() {
  noInterrupts();

  if (shutBladesVal != shutBladesValOld || shutAngleVal != shutAngleValOld) {
    if (enableShutter) {
      updateShutterMap(shutBladesVal, shutAngleVal);
    }
  }

#if (enableSlewPots)
  ledSlewVal = map(ledSlewVal, 0, 4095, ledSlewMin, ledSlewMax);  // turn slew val pot into ms ramp time
#endif
  ledAvg.update();  // LED slewing managed by Ramp library
  // if knobs have changed sufficiently, calculate new slewing ramp time
  if (abs(ledSlewVal - ledSlewValOld) >= 50 || abs(ledPotVal - ledPotValOld) >= 50) {
    //Serial.println("(SHUTTERMAP CALC)");
    ledAvg.go(ledPotVal, ledSlewVal);  // set next ramp interpolation in ms
    ledSlewValOld = ledSlewVal;
    ledPotValOld = ledPotVal;
  }

  ledBright = ledAvg.getValue();  // set brightness to slewed version of pot value
  //ledBright = 2000;
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
  // at slow speeds OR if the shutter is fully open OR shutter disabled, update the LED PWM directly because ISR isn't firing unless in motion
  if (countPeriod > 5000 || shutAngleVal == 1.0 || !enableShutter) {
    send_LEDC();
  }
}

void updateMotor() {

  // Depending on the motor direction switch, we translate the pot ADC to FPS with optional negative scaling
  // (The Ramp library is currently set up for ints, so our float FPS is multiplied by 100 to make it int 2400)

  if (enableMotSwitch) {
    // Motor UI is switch + pot, so use normal 0-24fps pot scaling
    if (!digitalRead(motDirFwdSwitch)) {
      motPotFPS = mapf(motPotVal, 0, 4095, 20, 2400);  // convert mot pot value to FPS x 100
    } else if (!digitalRead(motDirBckSwitch)) {
      motPotFPS = mapf(motPotVal, 0, 4095, -20, -2400);  // convert mot pot value to FPS x 100
    } else {
      motPotFPS = 0;
    }
  } else {
    // Motor UI is only pot, so use Use FORWARD-STOP-BACK pot scaling with deadband in center
    int bandWidth = 500;  // width of "deadband" in middle of pot range where speed is forced to 0
    int bandMin = 2048 - bandWidth / 2;
    int bandMax = 2048 + bandWidth / 2;

    if (motPotVal < bandMin) {
      motPotFPS = mapf(motPotVal, 0, bandMin, -2400, 0);
    } else if (motPotVal > bandMax) {
      motPotFPS = mapf(motPotVal, bandMin, 4095, 0, 2400);
    } else {
      motPotFPS = 0;
    }
  }

#if (enableSlewPots)
  motSlewVal = map(motSlewVal, 0, 4095, motSlewMin, motSlewMax);  // turn slew val pot into ms ramp time
#endif
  motAvg.update();  // Motor slewing managed by Ramp library
  // if knobs have changed sufficiently, calculate new slewing ramp time
  if (abs(motSlewVal - motSlewValOld) >= 10 || abs(motPotFPS - motPotFPSOld) >= 10) {
    //Serial.println("(MOT RAMP CALC)");
    motAvg.go(motPotFPS, motSlewVal);  // set next ramp interpolation in ms
    motSlewValOld = motSlewVal;
    motPotFPSOld = motPotFPS;
  }

  FPStarget = motAvg.getValue() / 100.0;  // use slewed value for target FPS (dividing by 100 to get floating point FPS)
  // These values may be negative, but fscale only handles positive values, so...
  //float FPStargetScaled;
  if (FPStarget < 0.0) {
    // negative FPS values
    FPStarget = FPStarget * -1.0;                                     // make it positive before fscale function
    FPStarget = (fscale(0.0, 24.0, 0.0, 24.0, FPStarget, 4) * -1.0);  // reverse log scale and turn it negative again
  } else {
    FPStarget = fscale(0.0, 24.0, 0.0, 24.0, FPStarget, 4);  // number is positive so just reverse log scale it
  }

  motSpeedUS = mapf(FPStarget, -24.0, 24.0, motMinUS, motMaxUS);  // convert FPS to motor pulse width in uS
  int motDuty = (1 << motPWMRes) * motSpeedUS / motPWMPeriod;     // convert pulse width to PWM duty cycle (duty = # of values at current res * US / pulse period)
  ledcWrite(motPWMChannel, motDuty);                              // update motor speed
  if (debugMotor) {
    Serial.print("Mot Slew: ");
    Serial.print(motSlewVal);
    Serial.print(", FPS Target: ");
    Serial.print(FPStarget);
    Serial.print(", FPS Real: ");
    Serial.print(FPSreal);
    Serial.print(", Mot uS: ");
    Serial.print(motSpeedUS);
    Serial.print(", Mot PWM Duty: ");
    Serial.println(motDuty);
  }
}

#if (enableButtons)
void buttonTap(Button2& btn) {
  if (btn == buttonA) {
    if (debugUI) {
      Serial.println("Button A clicked");
    }
    // insert single frame code here
  } else if (btn == buttonB) {
    if (debugUI) {
      Serial.println("Button B clicked");  // insert single frame code here
    }
    // insert single frame code here
  }
}
#endif

// ESC programming via Arduino, for HobbyWing Quicrun Fusion SE motor
void ESCprogram() {
  // adapted from these sources:
  // https://www.rcgroups.com/forums/showthread.php?1454178-Reversed-Engineered-a-ESC-Programming-Card
  // https://www.rcgroups.com/forums/showthread.php?1567736-Program-configure-ESC-with-Arduino

  // (ESC settings chart and LED programmer use options 1-9 but the data is 0-8)
  // BEC power turns on 7 ms after power is applied.
  // If program data line is pulled high at boot, ESC goes into program mode ...
  // ESC sends init message 140 ms after power is applied, then waits for ACK from programmer (responds about 1200 ms after init msg starts)
  // if no ACK within 4 sec from init message start, ESC continues to boot (motor winding beeps for LiPo count then periodic single pulses on programmer line)
  // if ACK, then boot pauses indefinitely, waiting for settings from programmer
  // After programmer sends settings, ESC responds with ACK and pauses indefinitely
  // Then ESC power must be toggled to reboot with new settings. (There is no way for programmer to send a "reboot" command)

#if (enableStatusLed)
  updateStatusLED(0, 32, 0, 0);  // red LED while we wait for programming
#endif

  Serial.println("Waiting for HobbyWing ESC ...");

  // wait for beginning of init message from ESC
  pinMode(escProgramPin, OUTPUT);
  digitalWrite(escProgramPin, HIGH);
  pinMode(escProgramPin, INPUT_PULLUP);
  while (digitalRead(escProgramPin) == 0)
    ;
  while (digitalRead(escProgramPin) == 1)
    ;
  while (digitalRead(escProgramPin) == 0)
    ;
  while (digitalRead(escProgramPin) == 1)
    ;
#if (enableStatusLed)
  updateStatusLED(0, 20, 5, 0);  // orange LED
#endif
  Serial.println("ESC booted");
  delay(1300);  // wait for ESC init message to pass before sending ACK (we don't parse it, just waiting for it to pass)

#if (enableStatusLed)
  updateStatusLED(0, 32, 0, 0);  // red LED
#endif
  Serial.println("Sending ACK...");
  ESC_send_ACK();  // tell ESC that we're here
  delay(100);      // wait before sending settings

#if (enableStatusLed)
  updateStatusLED(0, 20, 5, 0);  // orange LED
#endif
  Serial.println("Sending Settings...");
  for (byte i = 0; i < sizeof(ESC_settings); i++) {
    ESC_ser_write(ESC_settings[i]);
  }
  ESC_send_ACK();  // tell ESC that we're done
#if (enableStatusLed)
  updateStatusLED(0, 0, 32, 0);  // green LED
#endif
  Serial.println("DONE");
}

// writes a byte to a psuedo 10-bit UART
void ESC_ser_write(unsigned char x) {
  digitalWrite(escProgramPin, HIGH);  // make sure
  pinMode(escProgramPin, OUTPUT);
  delayMicroseconds(ESC_WRITE_BIT_TIME_WIDTH);

  digitalWrite(escProgramPin, LOW);  // signal start
  delayMicroseconds(ESC_WRITE_BIT_TIME_WIDTH);

  digitalWrite(escProgramPin, HIGH);  // first bit always 1
  delayMicroseconds(ESC_WRITE_BIT_TIME_WIDTH);

  digitalWrite(escProgramPin, LOW);  // 2nd bit always 0
  delayMicroseconds(ESC_WRITE_BIT_TIME_WIDTH);

  // send the byte LSB first
  char i;
  for (i = 0; i < 8; i++) {
    if ((x & (1 << i)) == 0) {
      digitalWrite(escProgramPin, LOW);
    } else {
      digitalWrite(escProgramPin, HIGH);
    }
    delayMicroseconds(ESC_WRITE_BIT_TIME_WIDTH);
  }
  digitalWrite(escProgramPin, HIGH);  // leave as input
  pinMode(escProgramPin, OUTPUT);
}

// must be sent after receiving configuration from ESC upon initialization
void ESC_send_ACK() {
  digitalWrite(escProgramPin, HIGH);  // make sure
  pinMode(escProgramPin, OUTPUT);     // assert pin
  delayMicroseconds(ESC_WRITE_BIT_TIME_WIDTH);
  // send pulses
  char i;
  for (i = 0; i < 6; i++) {
    digitalWrite(escProgramPin, LOW);  // signal start
    delayMicroseconds(ESC_WRITE_BIT_TIME_WIDTH);

    digitalWrite(escProgramPin, HIGH);  // first bit always 1
    delayMicroseconds(ESC_WRITE_BIT_TIME_WIDTH);
  }
  pinMode(escProgramPin, INPUT_PULLUP);  // float pin
}

#if (enableStatusLed)
void updateStatusLED(int x, int R, int G, int B) {
  // pixels.Color() takes RGB values, from 0,0,0 up to 255,255,255
  pixels.setPixelColor(x, pixels.Color(R, G, B));
  pixels.show();  // Send the updated pixel colors to the hardware.
}
#endif

// map function like Arduino core, but for floats
double mapf(double x, double in_min, double in_max, double out_min, double out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
/* fscale https://playground.arduino.cc/Main/Fscale/
 Floating Point Autoscale Function V0.1
 Paul Badger 2007
 Modified from code by Greg Shakar
 */
float fscale(float originalMin, float originalMax, float newBegin, float newEnd, float inputValue, float curve) {

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

  curve = (curve * -.1);   // - invert and scale - this seems more intuitive - postive numbers give more weight to high end on output
  curve = pow(10, curve);  // convert linear scale into lograthimic exponent for other pow function

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

  if (newEnd > newBegin) {
    NewRange = newEnd - newBegin;
  } else {
    NewRange = newBegin - newEnd;
    invFlag = 1;
  }

  zeroRefCurVal = inputValue - originalMin;
  normalizedCurVal = zeroRefCurVal / OriginalRange;  // normalize to 0 - 1 float

  /*
  Serial.print(OriginalRange, DEC);  
   Serial.print("   ");  
   Serial.print(NewRange, DEC);  
   Serial.print("   ");  
   Serial.println(zeroRefCurVal, DEC);  
   Serial.println();  
   */

  // Check for originalMin > originalMax  - the math for all other cases i.e. negative numbers seems to work out fine
  if (originalMin > originalMax) {
    return 0;
  }

  if (invFlag == 0) {
    rangedValue = (pow(normalizedCurVal, curve) * NewRange) + newBegin;

  } else  // invert the ranges
  {
    rangedValue = newBegin - (pow(normalizedCurVal, curve) * NewRange);
  }

  return rangedValue;
}