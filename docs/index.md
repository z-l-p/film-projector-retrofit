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

1. Purchase parts from the Bill of Materials ("BOM"): 
	- [Google Sheets link, to be replaced by static CSV file](https://docs.google.com/spreadsheets/d/1z_asHddtIuv7a7RkZ9WCBqF81oMiJ9spwqh7lCQfW5E)

1. Test projector with film before disassembly. It's important to find any problems before you start hacking!

1. Replace belts if necessary. In this project you will re-use all belts except for the motor belt.

1. Remove unused parts: 
	- power transformer
	- audio amp module
	- motor
	- threading lamp

1. Remove and save the parts that you will re-use later: 
	- camtank
	- lamp holder
	- black exciter lamp cover
	- main selector switch
	- flywheel
	- (OTHERS?)

1. Lubricate projector (insert link to service manual)

1. Consider drilling holes in projector chassis before you start, to prevent metal chips from ruining the electronics:
	- DC input jack
	- circuit breaker
	- Holes on side for controls (See "User Interface" section below)
	- ANYTHING ELSE? (drilled and tapped holes for mounting things?)

1. 3D print new parts (insert link to STL files)

Camtank and Shutter Pulley
==========================

The camtank contains the pulldown claw mechanism. The original shutter and pulley mounts to the outside, with a still-frame clutch lever in between. We will remove the pulley, shutter and clutch mechanism. We will replace the pulley with a new one, and mount the encoder magnet on the shaft.

1. Remove the M4 screw on the end of the pulley. This should release the pulley, shutter, and other hardware.

1. Remove the screws around the camtank perimeter. Lift the camtank lid to reveal the inside.

1. Clean the old grease from the cam, follower, and felt pad. Pack with new grease (Superlube) and lubricate the fulcrum. (Add info from service manual.)

1. Check the tension on the spring that keeps the follower on the cam. Use a digital luggage scale or tension scale to check force required to lift pulldown claw away from cam. It should be 1.1 - 1.25 kg. (Carefully widen the spring coil to reduce tension if needed.) Consult service manual.

1. The still frame clutch lever needs to be removed from the camtank cover via 2 slotted screws. (The screws may be very tight, so be careful not to strip the heads.) 

1. Use the 3D-printed camtank cover (STL filename?) to cover the large hole in the camtank cover, then replace the cover. 

1. Attach the 80 tooth pulley to the camtank shaft (with about 3mm of shaft exposed at the end) and tighten the screws loosely. (You will tighten them later when the belt is installed.) If the pulley "wobbles" on the shaft, try shimming it with small piece of aluminum from a beer / soda can.

1. There are 2 3D-printed parts for the magnet assembly (STL filename?): a base and a cap. They should be printed at 1mm resolution and tested since they have small mating threads. (In your slicing software, adjust or disable any "horizontal expansion" for these parts.) 
	- Use CA glue to attach the sensor magnet to the cap.  
	- The base should attach to the camtank shaft using an M4 x 5-10mm screw. (The original Eiki screw is too long.) Tighten M4 screw and use thread-locker. 
	- Screw the cap onto the base.
	- (The whole magnet assembly will be rotated later to adjust the shutter timing.)

1. Install the camtank in projector using original Eiki screws. (It may need adjustment later, after test film is loaded.)

User Interface
==========================
_(Do this first because it requires a lot of drilling into the projector chassis. When viewed from the inside of the projector, these controls are the "deepest" layer so they will be partially hidden by later steps.)_

The modified projector controls replace the original knobs on the side of the chassis. You can choose to include basic or advanced controls to suit your needs. (Controls can be disabled in the ESP32 code and the OpenSCAD file that generates the 3D-printed control panel.) These are the controls:

(INSERT LABELED IMAGE OF FINISHED CONTROLS)

- The original Eiki selector switch (rewired for our use)

- 2 push-buttons for single-frame advance

- 6 potentiometers (Pots must be 17mm diameter or smaller. The pot's threaded collar must be at least 6mm deep. 8mm deep would be ideal.)
	- Motor Speed
	- Motor Speed Ramp Time ("slewing")
	- Lamp Brightness
	- Lamp Brightness Ramp Time ("slewing")
	- Number of virtual shutter blades (1-3)
	- Shutter Angle (up to 360d)

- 5mm NeoPixel RGB status LED

- Optional volume pot for optical audio pickup

Steps:

1. The 3D-printed UI control panel ("eiki\_control\_panel.stl") fits on the outside of the projector chassis. If your pots and switches are different than mine, customize the "eiki\_control\_panel()" module in the OpenSCAD file, render, and export a new STL to fit your needs before printing. 

1. Use the printed part as a template to mark the drill holes in the projector chassis for each control. (Some existing chassis holes will be re-used, and others will be covered by the panel.) If your pots have anti-rotation pins, drill the appropriate holes for them in the chassis. 

1. Use the control panel to temporarily hold the controls while you solder your wiring. Each pot will share a ground and 3.3v connection, so there will be short jumpers from pot to pot. Use approx 55cm of 10-conductor ribbon cable (+ 1 more wire for the NeoPixel LED) and use a wire-tie to secure the cables and relieve stress.

1. If you will use the NeoPixel Status LED, wire it according to the photo and bend the legs to attach it to the motor speed pot, so it can fit into the nearby hole. You will also need a .1uF cap (marked "104") between 3.3v and GND near the LED. (This stabilizes the voltage and prevents communication errors.)  

	_Note: Later you will add a .01uF ("103") capacitor between ground and the wiper of each pot. This is essential to prevent noise on the ESP32 ADCs (which will be seen as moter speed fluctuations and lamp flicker). To be effective, these components must be soldered to the ESP32 end of each cable (not the pot end that we are soldering here)._

1. Assembly is a bit tricky: Push the controls through the chassis from the inside while holding the control panel on the outside. Tighten it all together using the washers and nuts for each control.

1. Rewire the existing Eiki selector switch (INSERT steps to remove original wires and add ground jumpers and color-coded wires to the micro-controller)

1. Insert the Eiki selector switch into the projector chassis. There are holes in the control panel to clear the mounting screws. Replace the selector knob.

1. Test each control by enabling debugging in the code ("debugUI = 1"), compile, upload, and observe the Arduino serial console. You should see 0-4095 range on each pot, and the status of the switches and buttons.

Power Wiring
============

The basic diagram gives an overview of the projector's systems. (Projector-Basic-Diagram.jpg)

The power wiring diagram shows the flow from power inputs to main terminal blocks. (Projector-Power-Wiring-Diagram.jpg)

There are 2 possible power sources: A 12V DC adapter (via 5.5/2.5mm coaxial jack) or a 3S LiPo RC car battery (via XT60 connector). A 3-position SPDT switch selects DC / OFF / Battery. The switched power flows through a fuse and (optional) power protection board before landing at a pair of terminal blocks near the motor. This is the connection point for the LED driver and cooling fan, as well as the motor. The motor has a built-in regulator that supplies 6V DC to the micro-controller and other low-voltage circuits.

All unregulated power wiring should be 18AWG or larger, because there are high currents involved. (16AWG is preferred.) Cable with silicone insulation is recommended because it won't melt when heated. These steps are written mostly in the order of the signal flow through the system.


1. Drill holes in the front of projector chassis near the rear cover latching point. Insert the DC jack and fuse holder.

1. The outer terminal of the DC jack will serve as a common ground for the system. The positive signal path flows from switch -> fuse -> power protection board -> terminal block
	 
1. Remove the Eiki threading lamp and prepare the power switch (3-position SPDT) to go in the hole: Print the adapter ring ("eiki\_pwr\_switch\_adapter.stl") and test the fit. (The ring on the adapter should grab a feature on the projector chassis to keep the switch from rotating.) 

1. Wire the power switch before inserting into hole. There is very little room behind the switch, so you can't solder it after mounting. Turn the terminals backwards and insulate them with heat-shrink tubing as shown in photo.
	- Top: DC Input
	- Center: Output to fuse
	- Bottom: Battery Input
	
1. Add the battery cable. It must be long enough to reach from the battery (in the bottom of the projector) to these points:
	 - Positive: the bottom terminal of the power switch
	 - Negative: the outer terminal of the DC jack
	 - (Leave the battery side of the cable un-terminated. You will add an XT60 connector after you prepare the motor. These photos show the future connector already attached.)

1. 3D-Print the battery box (eiki\_battery\_box.stl). If using the power protection circuit, mount its terminal blocks to the back of the battery box with 2 M3 x 10mm screws/nuts. (The screw heads should be recessed to make more room for the battery.)

1. If using the power protection circuit, wire it like this (leaving enough slack in the cables to maneuver the battery box into place).
	- Fuse output -> power protection board (+) -> terminal block (+)
	- DC jack outer -> power protection board (-) -> terminal block (-)
	- (The terminal blocks are explained in the next step, so leave the output cables long for now.)
	
1. Mount the battery box. The tabs on the bottom should engage with the slots on the bottom of the projector chassis. There are 2 holes on top for M3 x 5mm screws. (The right hole is hard to reach, but you can detach part of the auto-load mechanism to reach it.) The box will hold the battery in place (max battery size 155 x 46 x 30 mm) and protect the pots and switches of the UI.

1. 3D-print the cable clips (eiki\_cable\_clip.stl) and install in the projector chassis with M3 x 5mm screws (PHOTO OF LOCATIONS). You will use these to route the cables along the sides of the projector chassis. The clip in the upper right side also needs a mount (eiki\_cable\_clip\_mount.stl) to attach to the unthreaded hole where it belongs. Use a longer (10mm+) M3 screw for this clip.

1. 3D-print the terminal block mount (eiki\_terminal\_block\_mount.stl) and screw it onto the projector chassis using an M3 x 5mm+ screw.

1. Cut two 6-position segments of eurostrip terminal block. Insert jumpers into the right side of each strip. Use red paint to mark one strip as positive and one as negative. (see later photos)

1. Use self--tapping screws to attach the termina blocks (ground on lower level, positive on the top level). They are wider than the mount, and need to be offset in different directions when mounted. See photo. (The circular overhang in the mount will allow the black cable to exit from the lower terminal block.)

1. Find the power cable you completed in the earlier steps (from power protection board if installed, otherwise from the fuse). Route the cable around the right side of the projector using the cable clips to keep the belt area clear. Cut cable to length, then insert into the bottom position of each of the terminal blocks and tighten the jumper connections. (Remember to leave extra cable length in case you need to remove the terminal blocks or battery box.)

Power Protection Circuit
============
The fuse is essential to protect the projector and battery in case of a short circuit. There are other risks that can be reduced by using an additional power protection circuit...

Li-Ion batteries need protection from: 

1. Over-voltage above 4.2v/cell
1. Under-voltage below 3v/cell
1. Over-current above the "c-rating" of the battery (especially short-circuits, which could cause a serious fire)

The projector electronics need protection from:

1. Over-voltage above 13 volts: The motor's ESC expects 9-12.6v and has no over-voltage protection. The LED driver can withstand much higher voltages.
1. Over-current: If the motor stalls or there is an internal short-circuit, the projector electronics could be badly damaged.
1. Reverse Polarity: This would instantly destroy most of the electronics.

Most Li-Ion battery packs have protection boards installed, but RC car batteries have none. The ISDT battery charger provides these protections during charging, but no charger should be left unattended (especially overnight). The Hobbywing motor has a low voltage disconnect but no built-in protection against reverse polarity or over-voltage. The circuit I describe can be installed inside the projector to provide some protections regardless of power supply. For maximum safety you could also install a "3S battery protection PCB" on each battery, but make sure it can pass at least 10A to prevent accidentally tripping the over-current protection. Our protection circuit contains:

1. Fuse: Provides over-current / short-circuit protection. Use a "fast-blow" fuse sized slightly above the maximum current draw of the projector. (We use 10A) Thermal circuit-breakers and resettable PTC fuses are more convenient but unsuitable because they are too slow.
1. Ideal Diode PCB: Provides reverse polarity protection. This board uses an IC and MOSFETs to instantly disconnect the load if the polarity is backwards. It is much more efficient that a simple series diode, which is often used for this purpose. (Note: If you include the crowbar circuit below then you could replace this PCB with a large diode in parallel with the load. This would create a short-circuit if the power was connected backwards, blowing the fuse.) The diode must be sized to handle the full current of the power supply until the fuse blows. (20-30A would be fine, like the Infineon IDP15E65D1)
1. "Crowbar" circuit: Protects against over-voltage by creating a short-circuit when the voltage exceeds the zener diode voltage + turn-on voltage of the triac (= about 13.3v). This blows the fuse to protect the power source and projector.

Power protection board steps:

1. Solder wires to the ideal diode board to accommodate terminal blocks. On the Eiki projector, the total length of the assembly should be 100mm to fit between the terminal blocks.

1. Identify the pins of the triac. A BTA41 is shown in the photos. we will use this as a "crowbar" to short the power supply when the zener diode senses an over-voltage condition.

1. Turn the triac over so the metal tab faces up. Carefully bend the leads so the gate turns up and the others turn down. Bend the + and - leads match the spacing on the ideal diode board.

1. Add a 220 ohm resistor between gate and - 

1. Add a 12v zener diode between gate and + (with the stripe facing +)

1. Solder the triac assembly on top of the ideal diode board, in parallel with the output pads.

1. If you have an adjustable power supply with current limiting, test the circuit before installation: attach a small DC load like a fan or lamp. Set a current limit around 500mA and increase the voltage slowly. When it exceeds approximately 13 volts the triac should cause a short-circuit and the power supply should go into current-limiting until you remove power. If you connect the power with the wrong polarity, no current will flow to the load and nothing will be harmed.

1. After testing, use 20mm heat-shrink tubing or electrical tape to insulate the circuit. (Be sure to mark the direction of current flow.)

1. Attach terminal blocks to either end, and mark their polarity.

Further reading:

MiniBar crowbar circuit: https://a-2-z.tech/home/projects/minibar-crowbar-circuit/

Reverse polarity and over-voltage protection: https://electronics.stackexchange.com/questions/452935/overvoltage-and-reverse-polarity-protection

Complete Guide to Electronic Protection Circuits: https://www.circuitbasics.com/protection-circuits/

Crowbar Circuit | Design using Thyristor: https://www.electronicshub.org/crowbar-circuit/

Motor Prep and Wiring
=====================

The Hobbywing "Quicrun SE" 1200kv motor is made for radio controlled trucks. It is a brushless DC motor with built-in ESC (speed control) and uses FOC (field oriented control) to create smooth movement at low RPM while maintaining high torque. This is a BIG benefit for projection at slow speeds. (Other "540 size" DC motors and ESCs will also work, but they probably won't move smoothly at low speeds.)

The micro-controller will send a PWM signal to "impersonate" an RC receiver, but there are several things we must do to prepare the motor first. The motor's ESC has internal settings that we need to change. (INSERT SETTINGS TABLE) This normally requires a "programming card" to be attached to the PGM plug on the power button, but we reverse-engineered the protocol and included the settings in our micro-controller program. (To apply the settings, start the projector with button A and B held down. After 10 seconds, restart the projector and the settings should be applied.)

Test motor first with a servo tester or RC receiver. (We will modify the motor wiring, so let's start with a working motor!)

 _Now we modify power switch and throttle cable..._

1. Prepare a length of 4-conductor ribbon cable, about 50cm long.

1. Cut the insulation on the 2 red wires near the power button. Solder them together to make motor start whenever power is applied.

1. Cut the insulation on the white cable near the power button. (This is the serial signal that the micro-controller will use to insert the settings into the ESC.) Solder to a wire from the ribbon cable (yellow in photo).

1. Cut off the connector of the throttle cable and solder to the ribbon cable. 

	- Red = 6v power coming from the motor. (We will use this to power the micro-controller).

	- White = Motor speed PWM signal from micro-controller

	- Black = Ground

1. Insulate all connections with heat-shrink tubing or electrical tape.

1. De-solder the XT60 power connector from the motor. (We will screw the motor power wires into nearby terminal strips instead.) Solder the XT60 connector onto the battery input wires you prepared during the Power Wiring step.

Motor & Belt Installation
==================

1. Prepare 3D-printed motor bracket (STL filename?). There are 3 pockets on the underside that need supports removed. Insert M3 nuts into the hexagonal pockets and secure with a drop of CA glue around the perimeter of each nut. (These will be for the encoder bracket added later.)

1. Use three M3 x 5mm screws to attach aluminum motor mount to 3D-printed bracket. (These should be included when you purchased the mount.) Secure with thread-locker. One will fit into a recessed pocket, as shown in photo. (This is required to clear an existing bolt on the Eiki chassis.)

1. Screw the motor to aluminum motor mount using 2 M3 x 4mm countersunk screws. (The motor mount may include these screws but check the length.) Secure screws with thread-locker. See pictures for motor orientation.

1. Attach 16 tooth pulley to motor shaft using 1/8" to 5mm adapter. You will need to replace 1 pulley set-screw with an M3 x 5mm+ to reach through the 1/8" adapter and grab the motor shaft. Slide the pulley close to the motor mount, so it's about 1mm away. Use thread-locker on the M3 screw. If the pulley seems off-center, try shimming it with small piece of aluminum from a beer / soda can. 

1. Loosely attach motor mount to projector using the 3 original Eiki screws. It should slide freely in the vertical dimension. If it won't slide, check the back of the mount to see if a screw head is striking some hardware on the projector.

1. Attach the 232mm belt to the pulleys and check to see if the belt is centered. If not, adjust the shutter pulley until it works. Then apply thread-locker to the set-screws on all pulleys.

1. Slide the motor mount to tension the belt, then lock in place with the 3 original Eiki screws.

1. Connect the motor power wires to the bottom terminals of the terminal strips, observing correct polarity.

1. Coil the extra wires neatly and zip-tie them to the motor. Route the ribbon cable with the power wires, attached to the cable clips. (You will add more wires to this bundle later.)

Encoder Wiring
==============

The AS5047D magnetic encoder senses the rotation of a small magnet (to be mounted to the shutter shaft) and reports its angular position to the micro-controller. (There are cheaper and more common magnetic encoders like the AS5600 but they don't support the high RPM we need.) The AS5047D communicates using 2 interfaces:

**SPI** is used for sensor setup and polling the sensor for the absolute position of the shaft. It's a slow protocol so we only use it while the projector is stopped.

**ABI** is a quadrature signal (A,B) that updates 100 times for each revolution of the shutter shaft, and an index pulse (I) that updates once per revolution. These pulses trigger an interrupt routine on the microcontroller that keeps track of the shutter shaft position and direction with high accuracy.

The sensor comes on an adapter board (AS5047D-TS\_EK\_AB) that needs preparation before installation:

1. Snip off the 3-pin jumper headers on the front of the sensor board (JP1). No need to desolder.

1. Use a small wire to bridge the right 2 pads of JP1.  

1. Remove resistor R1 (actually a 0 ohm jumper).  

1. Use a small wire to bridge the R2 pads.  

1. Solder 9 wires (on the back of the board) for micro-controller connections. (See AS5047D-TS\_EK\_AB datasheet for full pinout info because the PCB markings are confusing):
	- Top row: 3V3, CSn, CLK, MOSI, MISO, GND  
	- Bottom row: B, A, I/PWM

1. Mount the encoder board to the 3D-printed encoder bracket ("encoder\_bracket.stl") using two M2.3 x 5mm self-tapping screws. Make sure it sits flat and perpendicular to the mount.

Encoder Mounting and Calibration
================

_(The motor must be mounted first, with the belt properly tensioned)_

1. Mount the encoder bracket to the motor bracket with two M3 x 8mm+ screws and washers. 

1. Adjust bracket so sensor chip is a few mm away from spinning magnet and centered in both dimensions. (Add washers behind encoder bracket if you need to move it closer to you.)

1. Route the encoder ribbon cable down the right side of the projector, following the path of the motor cables. Anchor the cable bundle with the cable clips.

1. Later, when the ESP32 has been installed and connected, you will need to calibrate the encoder magnet position so the digital shutter is in sync the pulldown of each frame:
	 - In the code, set "debugEncoder" to 1, compile, upload, and observe the Arduino serial monitor. 
	 - You should see message whenever you turn the inching knob. 
	 - (CONTINUE WITH FULL CALIBRATION INFO)

LED Driver Mounting and Wiring
================

LED Module Assembly
================

LED Module Mounting
================

ESP32 Wiring
================

ESP32 Mounting
================

Make the Rear Door Slimmer
================
Insert Loic and the hacksaw!

Hand Crank Option
================
