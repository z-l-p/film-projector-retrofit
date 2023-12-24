SPECTRAL Projector Conversion Guide
===================================

*Work In Progress! Composed in markdown format for github, to be adapted to filmlabs.org wiki*

Repository: [https://github.com/z-l-p/film-projector-retrofit](https://github.com/z-l-p/film-projector-retrofit)


Summary
=======

What we are doing and why

Major parts diagram

Theory of Operation and how the parts interact to make it all work

Preparation
===========

Purchase parts from the BOM (insert link to BOM)

Test projector with film before disassembly. It's important to find any problems before you start hacking!

Replace belts if necesary. In this project you will re-use all belts except for the motor belt.

Remove unused parts: power transformer, audio amp, motor

Remove and save the parts that you will re-use later: camtank, lamp holder, black exciter lamp cover, main selector switch (more?)

Lubricate projector (insert link to service manual)

Consider drilling holes in projector chassis first: (DC input jack, circuit breaker, UI holes on side ...)

3D print new parts (insert link to STL files)

Camtank and Shutter Pulley
==========================

The camtank contains the pulldown claw mechanism. The original shutter and pulley mounts to the outside, with a still frame clutch lever in between. We will remove the pulley, shutter and clutch mechanism. We will replace the pulley with a new one, and mount the encoder magnet on the shaft. [Camtank exploded view](images/eiki-camtank/01-Camtank-shutter-exploded.jpg)

1) Remove the M4 screw on the end of the pulley. This should release the pulley, shutter, and other hardware.

2) Remove the screws around the camtank perimeter. Lift the camtank lid to reveal the inside.

3) Clean the old grease from the cam, follower, and felt pad. Pack with new grease (Superlube) and lubricate the fulcrum. (Add info from service manual.) [Camtank internals](images/eiki-camtank/02-Camtank-open.jpg)

4) Check the tension on the spring that keeps the follower on the cam. Use a digital luggage scale or tension scale to check force required to lift pulldown claw away from cam. It should be 1.1 - 1.25 kg. (Carefully widen the spring coil to reduce tension if needed.) Consult service manual.

5) The still frame clutch lever needs to be removed from the camtank cover via 2 slotted screws. (The screws may be very tight, so be careful not to strip the heads.) [Camtank clutch plate removal](images/eiki-camtank/03-Camtank-cover-with-clutch.jpg)

6) Use the 3D-printed camtank cover (STL filename?) to cover the large hole in the camtank cover, then replace the cover. [Camtank with 3D-printed cover](images/eiki-camtank/04-Camtank-with-cover.jpg)

7) Attach the 80 tooth pulley to the camtank shaft (with about 3mm of shaft exposed at the end) and tighten the screws loosely. (You will tighten them later when the belt is installed.) If the pulley "wobbles" on the shaft, try shimming it with small piece of aluminum from a beer / soda can.

8) There are two 3D-printed parts for the magnet assembly (STL filenames?). Both should be printed at 1mm resolution and tested since they have small mating threads. Use CA glue to attach the sensor magnet to the cap. [Magnet assembly parts](images/eiki-camtank/05-Shutter-magnet-exploded.jpg)  
The base should attach to the camtank shaft using an M4 x 10mm screw. (The original Eiki screw is too long.) Tighten M4 screw and use threadlocker. [Old and new screws](images/eiki-camtank/06b-Shutter-screws-old-new.jpg)  
Screw the cap onto the base until finger-tight. [Finished magnet assembly](images/eiki-camtank/06-Shutter-magnet-assembled.jpg) [Finished camtank](images/eiki-camtank/07-camtank-finished.jpg) Screw the magnet magnet cap onto the threads until it stops. (The whole assembly will be rotated later to adjust the shutter timingt.)

9) Install the camtank in projector using original Eiki screws. (It may need adjustment later, after test film is loaded.)

User Interface
==========================
_(Do this first because it requires a lot of drilling into the projector chassis.)_

The primary controls are the (rewired) original Eiki selector switch, 2 push-buttons, and 6 potentiometers. Pots must be 17mm diameter or smaller. The pot's threaded collar must be at least 6mm deep. 8mm would be ideal. (INSERT IMAGE OF FINISHED CONTROLS)

The 3D-printed UI cover plate ("eiki_control_panel.stl") fits on the outside of the projector chassis. Use it as a template to mark the drill holes in the chassis for each control. (Some existing holes will be re-used, and others will be covered by the plate.) If your pots have anti-rotation pins, drll the appropriate holes for them in the chassis (SHOW IMAGE). 

Test-fit the pots and plan your wiring. Each pot will share a ground and 3.3v connection, so there will be short jumpers from pot to pot.

Before soldering, add a .01uF ("103") cap between ground and the wiper of each pot. This is essential to prevent noise on the ESP32 ADCs (which will be seen as moter speed fluctuations and lamp flicker). (PHOTO)

Rewire the existing Eiki selector switch (INSERT steps to remove original wires and add ground jumpers and color-coded wires to the micro-comtroller)

Assembly is a bit tricky: Push the controls through the chassis from the inside while holding the cover plate on the outside. Tighten it all together using the nuts for each control.

Do the same with the Eiki selector switch. There are holes in the cover plate to clear the mounting screws. Replace the selector knob.

Test each control by enabling debugging in the code ("debugUI = 1").

Power Wiring
============

Consult the main diagram for the basic flow. (INSERT DIAGRAM)

This diagram shows the power system wiring in detail. (INSERT DIAGRAM)

There are 2 possible power sources: A 12V DC adapter via 5.5/2.5mm coaxial jack or a 3S LiPo battery. A 3-position SPDT switch selects DC / OFF / Battery. The unregulated power flows through a circuit breaker before landing at a pair of terminal strips near the motor. The motor has a built-in regulator that supplies 6V DC to the rest of the projector.

All unregulated power wiring should be 18AWG or larger, because there are high currents involved. (16AWG is preferred.)

Cut two 6-position segments of eurostrip terminal block. (It will be mounted on the chassis near the motor.) Insert jumpers into one side of each strip.

Print the terminal block mount (STL FILENAME?) and screw it onto the projector chassis using an M3 x 5mm+ screw.

Cut a length of red/black power cable about 22cm long. Insert into the bottom position of each of the terminals. 

Use self--tapping screws to attach the termina blocks (ground on bottom, positive on top).

Mount 4 3D-printed cable clips (STL FILENAME?) in the projector chassis (PHOTO OF LOCATIONS). One also needs a cable clip mount (STL FILENAME). Route the cable carefully along the right side of the projector chassis. 

Remove the Eiki threading light and prepare the main power switch to go in the hole: Print the adapter ring ("eiki_pwr_switch_adapter.stl") and test the fit. (The ring on the adapter should grab a feature on the projector chassis to keep the switch from rotating.) 

Insert the DC jack and circuit breaker into the holes you drilled on the left side of projector chassis. (Insulate connections with heat-shrink tubing.)

Wire the 3-position SPDT switch before inserting into hole. (There is very little room hehind the switch, so turn the terminals backwards and insulate them with heat-shrink tubing.)

The battery input wires must be long enough to reach from the DC jack to the battery. (You will add an XT60 connector later, after you install the motor.)

Anchor the power cables so they stay below the belts and mechanics, but above the battery compartment / UI area.

Motor Prep and Wiring
=====================

The Hobbywing "Quicrun SE" 1200kv motor is made for radio controlled trucks. It is a brushless DC motor with built-in ESC (speed control) and uses FOC (field oriented control) to create smooth movement at low RPM while maintaining high torque. This is a BIG benefit for projection at slow speeds. (Other "540 size" DC motors and ESCs will also work, but they probably won't move smoothly at low speeds.)

The micro-controller will send a PWM signal to "impersonate" an RC receiver, but there are several things we must do to prepare the motor first. The motor's ESC has internal settings that we need to change. (INSERT SETTINGS TABLE) This normally requires a "programming card" to be attached to the PGM plug on the power button, but we reverse-engineered the protocol and included the settings in our micro-controller program. (To apply the settings, start the projector with button A and B held down. After 10 seconds, restart the projector and the settings should be applied.)

1) Test motor first with a servo tester or RC receiver. (We will void the warranty, so let's start with a working motor!)

 _Now we modify power switch and "servo" cable..._

2) Short the 2 red wires near power button to make motor start whenever power is applied

3) Cut off "servo" cable and extend wires to reach micro-controller. 

Red = 6v power coming from the motor. (We will use this to power the micro-controller).

White = Motor speed PWM signal from micro-controller

Black = Ground

4) Solder extension wire onto white wire near power button. (This is the serial signal that the micro-controller will use to insert the settings into the ESC.)

5) De-solder the XT60 connector and save it. (We will screw the motor power wires into nearby terminal strips, and re-use the XT60 as the main battery connector near the bottom of the projector.)

Motor & Belt Installation
==================

1) Prepare 3D-printed motor bracket (STL filename?). There are 3 pockets on the underside that need supports removed. Insert M3 nuts into the hexagonal pockets and secure with a drop of CA glue around the perimiter of each nut. (These will be for the encoder bracket added later.)

2) Use three M3 x 5mm screws to attach aluminum motor mount to 3D-printed bracket. (These should be included when you purchased the mount.) Secure with thread-locker. One will fit into a recessed pocket, as shown in photo. (This is required to clear an existing bolt on the Eiki chassis.) NEED BETTER PHOTO.

3) Screw the motor to aluminum motor mount using 2 M3 x 4mm countersunk screws. (The motor mount may include these screws but check the length.  I needed to file mine down by 1mm.) Secure screws with threadocker. See picture for motor orientation. (NEED PHOTO)

4) Attach 16 tooth pulley to motor shaft using 1/8" to 5mm adapter. You will need to replace 1 pulley set-screw with an M3 x 5mm+ to reach through the 1/8" adapter and grab the motor shaft. Slide the pulley close to the motor mount, so it's about 1mm away. Use thread-locker on the M3 screw. If the pulley seems off-center, try shimming it with small piece of aluminum from a beer / soda can. 

5) Loosely attach motor mount to projector using the 3 original Eiki screws. It should slide freely in the vertical dimension. If it won't slide, check the back of the mount to see if a screw head is striking some hardware on the projector.

6) Attach the 232mm belt to the pulleys and check to see if the belt is centered. If not, adjust the shutter pulley until it works. Then apply thread-locker to the set-screws on all pulleys.

7) Slide the motor mount to tension the belt, then lock in place with the 3 original Eiki screws.

Encoder Wiring
==============

The AS5047D magnetic encoder senses the rotation of a small magnet (to be mounted to the shutter shaft) and reports its angular position to the micro-controller. (There are cheaper and more common magnetic encoders like the AS5600 but they don't support the high RPM we need.) The AS5047D communicates using 2 interfaces:

**SPI** is used for sensor setup and polling the sensor for the absolute position of the shaft. It's a slow protocol so we only use it while the projector is stopped.

**ABI** is a quadrature signal (A,B) and an index pulse (I) that updates 100 times for each revolution of the shutter shaft. These pulses trigger an interrupt routine on the microcontroller that keeps track of the shutter shaft position and direction with high accuracy.

The sensor comes on an adapter board (AS5047D-TS_EK_AB) that needs preparation before installation:

1) Snip off the 3-pin jumper headers on the front of the sensor board (JP1). No need to desolder.

2) Use a small wire to bridge the right 2 pads of JP1.  
Remove resistor R1 (actually a 0 ohm jumper).  
Bridge the R2 pads.  

3) Solder 9 wires (on the back of the board) for micro-controller connections:

3V3, CLK, MOSI, MISO, GND  
B, A, I, V  
(see AS5047D-TS_EK_AB datasheet for full pinout info because the PCB markings are confusing)

NEED PICTURE OF WIRING ON BACK OF BOARD

4) Mount the encoder board to the 3D-printed encoder bracket ("encoder_bracket.stl"") using two M2.3 x 5mm self-tapping screws.

Encoder Mounting and Calibration
================

(Motor must be mounted first) Mount the encoder bracket to the motor bracket with two M3 x 8mm screws and washers. Adjust bracket so sensor chip is a few mm away from spinning magnet and centered in both dimensions. (Add washers behind encoder bracket if you need to move it closer to you.)

After the encoder has been wired to the ESP32, the magnet on the shutter pulley needs to be rotated to calibrate the digital shutter with the pulldown of each frame. In the code, set debugEncoder to 1. In the Arduino serial monitor you should see message whenever you turn the inching knob. (CONTINUE WITH FULL CALIBRATION INFO)  
