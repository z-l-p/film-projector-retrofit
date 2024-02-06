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

Power Safety
============

Li-Ion batteries need protection from: 

1. Over-voltage above 4.2v/cell
1. Under-voltage below 3v/cell
1. Over-current above the "c-rating" of the battery (especially short-circuits, which could cause a serious fire)

The projector electronics need protection from:

1. Over-voltage above 13 volts: The motor's ESC expects 9 - 12.6V and has no over-voltage protection. The LED driver can withstand 22V.
1. Over-current: If the motor stalls or there is an internal short-circuit, the projector electronics could be badly damaged.
1. Reverse Polarity: If a battery or power supply were connected backwards, it would destroy the motor's ESC and possibly more. (The LED Driver has reverse polarity protection.)

Most Li-Ion battery packs have protection boards installed, but RC car batteries have none. The ISDT battery charger provides these protections during charging, but no charger should be left unattended (especially overnight). The Hobbywing motor has under-voltage disconnect but no protection against reverse polarity or over-voltage. 

The protections below are installed inside the projector to provide protection regardless of power supply. For maximum safety you could also install a "3S battery protection PCB" on the battery, but make sure it can pass at least 10A to prevent accidentally tripping the over-current protection.

1. A glass fuse provides over-current / short-circuit protection. Use a "fast-blow" fuse sized slightly above the maximum current draw of the projector. (We use 10A) Thermal circuit-breakers and resettable PTC fuses are more convenient but don't use them. They are much too slow!
1. DVB01 Voltage Protection Board (sold under many names with keywords like "Digital Window Voltage Comparator Overvoltage Undervoltage Protection Voltage Measurement Module"). This is an inexpensive module with a microcontroller, LED display, and 10A relay. (Make sure you have the 12v variation, not 5v or 24v). We will program it to monitor input voltage and only engage the relay if the voltage is between 9 and 13v. It also protects from reverse polarity. (The relay is normally off unless the micro-controller is powered, and its voltage regulator has reverse-polarity protection.) _Note: The circuit draws about 2mA of current even when the relay is switched off, so it won't protect the battery from under-voltage if you leave the projector switched on for days after running down the battery to the cutoff._

Power Wiring
============

The basic diagram gives an overview of the projector's systems. (Projector-Basic-Diagram.jpg)

The power wiring diagram shows the flow from power inputs to main terminal blocks. (Projector-Power-Wiring-Diagram.jpg)

There are 2 possible power sources: A 12V DC adapter (via 5.5/2.5mm coaxial jack) or a 3S LiPo RC car battery (via XT60 connector). A 3-position SPDT switch selects DC / OFF / Battery. The switched power flows through a fuse and DVB01 power protection board before landing at a pair of terminal blocks near the motor. This is the connection point for the LED driver and cooling fan, as well as the motor. The motor has a built-in regulator that supplies 6V DC to the micro-controller and other low-voltage circuits.

All power wiring should be 18AWG or larger, because there are high currents involved. (16AWG is preferred.) Cable with silicone insulation is recommended because it won't melt when heated. These steps are written mostly in the order of the signal flow through the system.


1. Drill holes in the front of projector chassis and install the DC jack and fuse holder.

1. The outer terminal of the DC jack will serve as a common ground for the power system. The positive signal path flows from sources (battery & DC in) -> switch -> fuse -> power protection board -> terminal block
	 
1. Remove the Eiki threading lamp and prepare the power switch (3-position SPDT) to go in the hole: Print the adapter ring ("eiki\_pwr\_switch\_adapter.stl") and test the fit. (The ring on the adapter should grab a feature on the projector chassis to keep the switch from rotating.) 

1. Wire the power switch before inserting into hole. (There is very little room behind the switch, so you can't solder it after mounting.) Turn the terminals backwards and insulate them with heat-shrink tubing as shown in photo.
	- Top: DC Input
	- Center: Output to fuse
	- Bottom: Battery Input
	
1. Add the battery cable. It must be long enough to reach from the battery (in the bottom of the projector) to these points:
	 - Positive: the bottom terminal of the power switch
	 - Negative: the outer terminal of the DC jack
	 - (Leave the battery side of the cable un-terminated. You will add an XT60 connector after you prepare the motor. These photos show the future connector already attached.)

1. 3D-Print the battery box (eiki\_battery\_box.stl) and collect the parts shown in the photo (4-position segments of eurostrip terminal block, 2 jumpers, DVB01 power protection board, 20mm x 22cm velcro strap).

1. The right side of the battery box has a slot to hold the ESP32 PCB. There is a lock for the PCB slot. Assemble it with an M3 x 12mm+ screw and 2 M3 washers. Mount as shown and tighten slightly.

1. Thread the velcro strap through the slots. (This will hold the battery in place.)

1. On the back of the battery box, add the terminal block strip (painted red/black as shown) with 2 M3 x 12mm+ screws and nuts.

1. Insert M3 x 10mm screws into the 4 PCB mounting holes and add 3D-printed standoffs from the battery box model.

1. Mount the DVB01 board with 4 M3 nuts.

1. Wire the power inputs shown in the photos (leaving enough slack in the cables to maneuver the battery box into place).
	- Projector Fuse output -> terminal block (+) with jumper to neighboring terminal
	- Projector DC jack (-) -> terminal block (-) with jumper to neighboring terminal
	
1. Connect the terminal block to the DVB01 board's left side, as shown in the photos. (These are low current connections, so thinner wires are OK.)
	- Terminal block (-) -> DVB01 (V-)
	- Terminal block (+) -> DVB01 (V+)
	- Terminal block (+) -> DVB01 (DC+)
	
1. Now program the DVB01 power protection board. Consult the instruction manual ("DVB01 Voltage Relay Module 12V User Manual.pdf") to understand the menu navigation:

	- P-0 (mode) = F-4 (engage relay when voltage is between limits)

	- P-1 (lower voltage limit) = 9v

	- P-2 (upper voltage limit) = 13v

	- P-3 (voltage correction) These modules are not well calibrated from the factory. If you have an accurate volt meter, adjust the +/- buttons until the module's flashing display matches your meter's measurement of the input voltage.

	- P-4 (time delay before relay engages) = 0.5

	- P-5 (time delay before relay disengages) = 0

	- If you have a variable power supply, test the module to make sure it works. The relay should only pass power if the voltage is between 9v and 13v. Reverse polarity on the input should not harm anything.

	- After testing, turn on "power saving mode": Long press SW1 until display blinks. It will turn off after 10 seconds of inactivity.

1. Cut a 50cm length of black/red power cable, and a shorter length of red power cable. Connect the power path through the DVB01's relay, as shown in photos.
	- Terminal block (+) -> DVB01 (NO) on right side of board (use the short red cable)
	- Terminal block (-) -> black wire of 50cm power cable
	- DVB01 (COM) on right side of board -> red wire of 50cm power cable
	- (You will terminate the 50cm power cable in a later step)
	
1. Mount the battery box: Flip it over and orient it so the tabs on the bottom engage with the slots on the projector chassis. There are 2 holes on top for M3 x 5mm screws. (The right hole is hard to reach, but you can detach part of the auto-load mechanism to reach it.) The velcro strap will hold the battery in the box (max battery size about 155 x 46 x 30 mm).

1. 3D-print the cable clips (eiki\_cable\_clip.stl) and install in the projector chassis with M3 x 5mm screws. You will use these to route the cables along the sides of the projector chassis. The clip in the upper right side also needs a mount (eiki\_cable\_clip\_mount.stl) to attach to the unthreaded hole where it belongs. Use a longer (10mm+) M3 screw for this clip.

1. 3D-print the terminal block mount (eiki\_terminal\_block\_mount.stl) and screw it onto the projector chassis using an M3 x 25mm screw. NOTE: You may need to tap this hole to make sure it is fully threaded. The screw should extend through the chassis and emerge on the other side, inside the lamphouse. (We will use this later.)

1. Cut two 6-position segments of eurostrip terminal block. Insert jumpers into the right side of each strip. Use red paint to mark one strip as positive and one as negative. (see later photos)

1. Use self--tapping screws to attach the termina blocks (ground on lower level, positive on the top level). They are wider than the mount, and need to be offset in different directions when mounted. See photo. (The circular overhang in the mount will allow the black cable to exit from the lower terminal block.)

1. Find the 50cm power cable you completed earlier. Route the cable around the right side of the projector using the cable clips to keep the belt area clear. Cut cable to length, then insert into the bottom position of each of the terminal blocks and tighten the jumper connections. (Remember to leave extra cable length in case you need to remove the terminal blocks or battery box.)

ESP32 PCB Mount
=====================
The micro-controller wiring comes later, but first we need to 3D-print the slotted mount to support the right side of its PC board. (The left slot is included on the battery box.)

Note: The PCB mounts are designed to fit "Solderable Breadboard" PCBs available online from China (see BOM). They look like the "Half-Sized Perma Proto" from Adafruit (# 1609) which is 8mm shorter. If you are using the Adafruit boards instead, you need to extend the battery box model in OpenSCAD: Change variable "mountBaseX" from 150 to 158.

1. 3D-print "eiki\_pcb\_mount.stl".

1. Remove the grounding nut from the Eiki chassis.

1. Attach the PCB mount onto the grounding rod. It should match the hole in the chassis and push down evenly.

1. Return the ground nut and use it to tighten the PCB mount onto the projector.

1. Test the PCB fit with a blank board.



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

1. Prepare 3D-printed motor bracket (eiki\_motormount.stl). There are 3 pockets on the underside that need supports removed. Insert M3 nuts into the hexagonal pockets and secure with a drop of CA glue around the perimeter of each nut. (These will be for the encoder bracket added later.)

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

LED Driver Wiring & Mounting
================
The TaskLED H6cc LED driver accepts 8-22V DC and provides a constant-current output up to 6.6A @ 6V to drive the Cree LED. (LEDs require a power source with precise current control. Do not connect the LED to unregulated power, or conventional constant-voltage regulators.)

In our application, we will control the LED brightness via pulse-width modulation PWM, using the dedicated PWM pin on the H6cc. (To reduce PWM flicker, we _could_ control the current instead, using the H6cc POT pin and a digital potentiometer. This would add complexity and would have limited dimming below 20%, but maybe worth trying in the future?)

Driver Wiring
----------
See LED Driver Wiring diagram (LED-Driver-Diagram-v1.2.jpg). NOTE: The driver will be mounted on a thin sheet of silicone thermal pad, so any sharp points under the board will pierce the sheet and short against the projector chassis. For this reason, all wires should be soldered on TOP of the board, rather than through the holes. (Use a soldering iron with a large tip.)

(CHECK H6CC DOCS for current pot default setting: Do we need to turn up current to get max amps?)

1. Cut 2 pieces of red/black power cable: 12cm and 20cm.

1. Solder the 12cm cable to the LED+ and LED- terminals. Attach a terminal block on the other side, marked with polarity.

1. Solder the 20cm cable to the IN+ and IN- terminals. 

The LED driver is designed to turn on whenever power is supplied. During projector startup, the driver will start sooner than the the ESP32, so the lamp will shine at full brightness until the ESP32 asserts control over the PWM pin. This will burn film! So we install a zener regulator and pullup resistor that keeps the PWM pin high (3 V) by default. When the ESP32 boots, it will overcome this resistor and pull PWM low (0 V) whenever it needs to turn on the LED.

1. Solder together the components (3V zener diode, 1k resistor, and 470R resistor) as shown in the wiring diagram.

1. Cover with insulating tape (kapton or PVC), leaving the ends exposed.

1. Prepare a wire for the PWM signal. It should be long enough to reach to the ESP32. (We used a shielded cable to prevent interference, but it's probably not necessary.)

1. Solder the components to the LED driver board (IN+, IN-, and PWM terminals).

1. Solder the PWM cable to the PWM terminal.

1. Cut a square of insulting tape (kapton or PVC) and apply to the grey square inductor on the driver.

Driver Mounting
----------
The H6cc is a circular PCB without mounting holes. (It was intended for flashlights where it would be compressed between parts of the aluminum flashlight body.) It should come with double-sided thermal tape (T-Global Li98), but you should not trust the adhesive to make a permanent bond. We will mount it to the projector chassis, so we'll use a combination of a plastic tray and metal clip to keep it in place.

1. 3D-Print the plastic tray (eiki\_LEDdriver\_tray.stl). This will hold the driver board in place laterally.

1. Remove the screw in the lamphouse. This is the back of an axle for a plastic arm on the other side of the projector chassis. Be careful to support the arm and catch the washer and spring that will fall from it when you remove the screw.

1. Install the plastic tray. It should fit over a pillar in the lamphouse. Secure the tray with the screw you removed earlier, and replace the plastic arm (and its washer and spring). Use thread-locker.

1. Cut the thermal tape into a circle to match the driver board. Remove the backing from one side and apply it to the board.

1. Remove the other backing and press the LED driver into the hole in the tray. Check the orientation to make sure it matches the photo.

1. Use stiff steel wire to make a clip. (We used the handle from a "binder clip".) It should be long on one side and folded into a short loop on the other side. See photos for dimensions.

1. Wrap the clip behind the projector chassis so it presses on the square grey inductor. The driver board should now be secure.

1. Mount the terminal block to the exposed threads of the protruding screw. Tighten with an M3 nut. Make sure the empty sides of the terminal block are accessible because you will add the LED cables here.

1. Pull the IN+ and IN- wires through the hole in the chassis and attach to the main terminal blocks. (This photo also shows the small fan wires from the LED module, which you will build next.)

LED Module Assembly
================

The Cree XHP70.3 HI LED needs to be mounted to a fan-cooled heatsink. Never turn it on without the heatsink. It could overheat in seconds! To focus the light on the film frame, we will use a combination of an aluminum reflector and a condenser lens. Everything will be mounted on a sliding rail to permit focusing.

1. Collect the parts: Approx. 25cm of red/black power wire, LED "star" board with plastic spacer ring, LED reflector and lens, 50mm heatsink and fan, 2 M2.5 x 5mm screws, 2 M3 x 8mm+ thumbscrews, 4 self-tapping M2.6 x 8mm screws, 4 M3 x 20mm+ screws, 3D-printed parts. You will need to drill and tap M2.5mm holes in the heatsink and tap the heatsink fins for M3 screws.

1. Solder the 25cm LED wires before you mount the LED on the heatsink. (It's hard to solder these boards because of their thermal mass. The heatsink will make it much worse.) Use a large soldering tip and consider 60/40 lead solder because it melts at a lower temperature than lead-free solder. The soldering pads are very close to the mounting holes, so you should offset your connections to one side to avoid the screw heads. (A short-circuit would be catastrophic.)

1. Your LED mounting holes must fall _between_ the heatsink fins. If you drill a hole that lands partially on a fin you will break your drill bit or tap! Print the paper template ("LED-Heatsink-Drill-Template.pdf"), cut it out, wrap it around the heatsink, and tape the edges down.

1. Use a center-punch to transfer the 2 hole locations onto the heatsink. (PHOTO) Drill 2mm holes and tap them with a 2.5mm tap.

1. Mount soldered LED to heatsink with the M2.5 x 6-8mm screws and nylon washers. Use thread-locker. Use a small amount of high quality thermal compound to promote heat transfer. Be careful to avoid a short-circuit since the LED terminals are so close to the screw heads.

1. Place the 3D-printed lens holder (eiki\_lens\_holder.stl) on the heatsink. Press the 3D-printed clips (eiki\_lens\_holder\_clip.stl) into the sides of the heatsink and attach to lens holder with self-tapping M2.6 x 8mm screws. These clips will keep the lens holder firmly attached to the heatsink. NOTE: Both LED wires should exit from the corner of the lens holder, matching the photos.

1. Add the plastic spacer ring to the top of the LED. This ring will hold the metal reflector in the correct position and prevent it from shorting the LED terminals. 

1. Insert the LED reflector into the lens holder. Push it down until it fully seats against the plastic ring on the LED.

1. Add the lens to the top of the lens holder and secure with a few drops of flexible solvent glue (E6000) around the perimeter.

1. Use an M3 tap to add threads to the 3rd row of slots in the heatsink. (The tap might want to wander around, so try to keep it straight.) Test with the M3 x 8mm thumbscrews.

1. Mount the fan and 3D-printed fan guard (eiki\_fan\_guard.stl) on back of heatsink. The spacing and orientation is important:
	- Hold heatsink with fins vertically, thumbscrew threads on left
	- Mount fan so it blows toward the heatsink, with cable exiting on your right
	- Fan will be offset to the right because there are an odd number of heatsink slots.
	- Use 4 M3 x 20+ mm screws to attach fan guard and fan. (They will cut their own threads between the heatsink fins. Don't over-tighten or you will strip the soft aluminum.)
	
1. Remove the original halogen lamp from the projector to reveal the metal mount.

1. Screw the 3D-printed rails for the LED assembly (eiki\_LED\_mount.stl) onto the metal mount. Use M3 x 5-8mm low profile button head screws. Add thread-locker.

1. Attach the LED module to the rails, using the M3 thumbscrews and washers. Tighten the screws gently so the LED module can slide along the rails. (Later you will focus LED and tighten the thumbscrews fully.)

1. Attach the LED wires to the terminal block near the LED driver.

1. Mount the finished assembly in the projector and secure with the original Eiki nut.

1. Pull the fan wires through the hole in the chassis near the LED driver. Attach them to the main terminal blocks near the motor. (See the photo from the LED Driver Mounting section.)

ESP32 Wiring
================

ESP32 Mounting
================

(Optional) Battery Meter
================
The ESP32 could monitor battery voltage and alert the user, but it would require a voltage divider and more pins for the ADC input and a visual indicator of some sort. Pre-made battery monitors are cheap and easy, so let's use one!

(INSERT STEPS) for configuring module, mounting in 3D-printed housing, wiring into main power block.

(Optional) Make the Rear Door Slimmer
================
Insert Loic and the hacksaw!


Calibration
================

Synchronize the Shutter
-------------

Before projecting film, the digital shutter needs to be synchronized to match the film movement.

1. Start with the projector assembled, tested, and threaded with film.

1. Set the shutter blades to 1 and the shutter angle to 180d. Set the lamp to a low brightness to avoid film burns. As you move the projector mechanism, you should see one LED blink per frame, but the timing will be wrong.

1. Hold the shutter pulley and use pliers to rotate the magnet mount until the LED is ON when the film is still, and OFF during pulldown movement.

1. Switch to 2 shutter blades (180d shutter angle) and repeat the calibration.

1. Switch to 3 shutter blades (180d shutter angle) and repeat. With these settings, it should be difficult to match the LED pulses to the film movement without illuminating a bit of pulldown. In practice you can just use a narrower shutter angle to eliminate it.


Focus the LED
-------------

The LED module needs to be adjusted to produce maximum brightness and even illumination. Do these steps in a projection environment, but without threading film.

1. In the lamphouse, adjust Eiki original nut to center the LED "hot spot" in the horizontal dimension. 
 
1. Slide the LED module in the rails to find the "flattest" light with the least "hot spot".

1. Lock the rail adjustment with the thumb-screws.
	
Troubleshooting
================
- The shutter shaft pulley needs thread-locker, or it will come loose. This would be bad because the lamp would stay on and burn the film!
