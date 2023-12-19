// SPECTRAL "Wandering sounds + Images" projector mods
// Unless specified, all parts can print at 0.2mm layer height without supports

use <threads.scad>; // threads library from Dan Kirshner (GPL license)

////////////// GLOBAL VARIABLES ////////////////
heatsinkXY = 50; // size of LED heatsink
heatsinkZ = 20; // size of LED heatsink

////////////// GENERATE MODELS ////////////////
// (un-comment each module, render, and export STL) //

// For Eumig P26 and Eiki //
// ---------------------- //

//encoder_bracket(); // Bracket to attach encoder board - PRINT ROTATED, FLAT SIDE DOWN

// For Eiki only //
// ------------- //

//eiki_motormount(); // Mount to attach motor and rotary encoder - PRINT WITH SUPPORTS
//eiki_encoder_magnet_mount(); // 2-piece threaded part to attach encoder magnet to drive shaft - PRINT WITH 0.1mm LAYERS 
//eiki_camtank_cover(); // Cover for hole in camtank after shutter removal - PRINT ROTATED, FLAT SIDE DOWN
//eiki_LED_mount();
//eiki_LED_lens_holder(1); // export STL with 0 argument for holder, 1 argument for holder fingers
eiki_control_panel(); // flat faceplate for control panel on side of projector - PRINT UPSIDE DOWN
//eiki_power_switch_ring(); // adapter ring to mount power switch in hole for threading lamp

// For Eumig P26 only (NOTE: Other P26 parts were created in Blender! They aren't in this file.)
// ------------------ //

//p26_encoder_magnet_mount(); // 1-piece threaded part to attach encoder magnet to drive shaft
//p26_encoder_mount(); // mount to attach encoder bracket to P26 chassis


////////////// THE MODULES ////////////////

// adapter ring to mount power switch in hole for threading lamp
module eiki_power_switch_ring() {
    $fn=48;
    difference() {
        union() {
            cylinder(d=20, h=1.2); // outer flange
            cylinder(d=16.4, h=1.2+2.6); // outer
        }
        cylinder(d=12, h=10); // inner
    }
}

// flat faceplate for control panel on side of projector
// NOTE: It barely fits on my 200mm 3D printer bed. Orient diagonally and increase the rounded_rect corner radius to make it fit.
module eiki_control_panel() {
    plateDims = [250, 40, 1]; // dims of faceplate
    potD = 7.2; // dia of hole for potentiometer
    potPinD = 3; // dia of hole for potentiometer anti-twist pin (only used for audio volume pot because others mount to metal chassis)
    potPinOffset = 7.8; // offset of hole for potentiometer anti-twist pin
    buttonD = 6.6; // dia of hole for pushbutton
    selectorD = 14; // dia of hole for original Eiki selector switch
    selectroOffsetX = 29.2; // location of selector switch
    selectroOffsetY = 12.4; // location of selector switch
    selectorMountingD = 7.2; // dia of hole to clear the heads of original Eiki selector switch mount screws
    volumeOffsetX = 233; // location of audio volume pot
    volumeOffsetY = 20; // location of audio volume pot
    screwD = 3; // dia of hole for screws that hold faceplate onto projector
    rearThick = 2.6; // thickness of eiki metal housing
    difference() {
        union() {
            translate([1+plateDims[0]/2,plateDims[1]/2,0]) rounded_rect(plateDims[0], plateDims[1], plateDims[2],8); // main plate
            translate([175,19.6,-rearThick]) cylinder(d=8, h=2.8, $fn=36); // shutter blades pot
            translate([204.4,19.6,-rearThick]) cylinder(d=8, h=2.8, $fn=36); // shutter angle pot
            translate([232, 19, -rearThick]) rounded_rect(33, 20, 3, rearThick); // rear pad to fill rectangular hole
        }
        //faceplate holes (left to right)
        translate([selectroOffsetX,selectroOffsetY,-0.1]) cylinder(d=selectorD, h=5, $fn=36); // selector switch
        translate([selectroOffsetX+22,selectroOffsetY,-0.1]) cylinder(d=selectorMountingD, h=5, $fn=36); // selector switch mount screw
        translate([selectroOffsetX-22,selectroOffsetY,-0.1]) cylinder(d=selectorMountingD, h=5, $fn=36); // selector switch mount screw
        translate([60,33,-0.1]) cylinder(d=buttonD, h=5, $fn=36); // frame - button
        translate([72.5,20,-0.1]) cylinder(d=screwD, h=5, $fn=24); // screw hole left
        translate([80,33,-0.1]) cylinder(d=buttonD, h=5, $fn=36); // frame + button
        translate([100,33,-0.1]) cylinder(d=potD, h=5, $fn=36); // mot speed ramping pot
        translate([100,6,-0.1]) cylinder(d=potD, h=5, $fn=36); // mot speed pot
        translate([146,33,-0.1]) cylinder(d=potD, h=5, $fn=36); // lamp ramping pot
        translate([146,6,-0.1]) cylinder(d=potD, h=5, $fn=36); // lamp pot
        translate([175,19.6,-0.1]) cylinder(d=potD, h=20, $fn=36, center=true); // shutter blades pot
        translate([190,20,-0.1]) cylinder(d=screwD, h=5, $fn=24); // screw hole left
        translate([204.4,19.6,-0.1]) cylinder(d=potD, h=20, $fn=36, center=true); // shutter angle pot
        translate([volumeOffsetX,volumeOffsetY,0]) cylinder(d=potD, h=20, $fn=36, center=true); // audio volume pot
        translate([volumeOffsetX-potPinOffset,volumeOffsetY,-rearThick]) cylinder(d=potPinD, h=rearThick, $fn=24); // pin for audio volume pot
        
    }
}

// lens holder for Eiki LED, use option 0 for lens holder and option 1 for clips to grab heatsink
module eiki_LED_lens_holder(option) {
    cylinderOuterD = 46;
    cylinderOuterZ = 39.6;
    reflectorD = 42; //39.8
    reflectorZ = 34.8;
    lensD = 43.8;
    lensZ = 3.8;
    lensOffset = 35.8;
    supportZ = 10;
    supportD = 24;
    bracketX = 16.6;
    bracketZ = 8;
    screwD = 2; 
    
    // generate holder and clip from modules
    if (option == 0) {
        holder();
    } else {
        translate([0,-10,0]) holder_clip();
        translate([0,10,0]) holder_clip();
    }
    
    
    module holder(){
    difference() {
        union() {
            cylinder(d=cylinderOuterD, h=cylinderOuterZ, $fn=80); // reflector support outer
            translate([-bracketX/2,-heatsinkXY/2,0]) cube([bracketX,7,bracketZ]); // bracket to connect to clips
            rotate([0,0,180]) translate([-bracketX/2,-heatsinkXY/2,0]) cube([bracketX,7,bracketZ]); // bracket to connect to clips
        }
        translate([-4,0,bracketZ/2]) rotate([-90,0,0]) cylinder(d=screwD, h=100, $fn=16, center=true); // hole in bracket
        translate([4,0,bracketZ/2]) rotate([-90,0,0]) cylinder(d=screwD, h=100, $fn=16, center=true); // hole in bracket
        cylinder(d=reflectorD, h=lensOffset+0.1, $fn=80); // main pocket for reflector
        translate([0,0,lensOffset]) cylinder(d=lensD, h=lensZ+0.1, $fn=80); // pocket for lens rim
        
        // triangle cutouts for wires and cooling
        hull() {
            translate([0,0,30]) rotate([-90,0,45]) cylinder(d=0.1, h=100, $fn=8, center=true);
            translate([0,0,0]) rotate([-90,0,45]) cylinder(d=18, h=100, $fn=16, center=true);
        }
        hull() {
            translate([0,0,30]) rotate([-90,0,-45]) cylinder(d=0.1, h=100, $fn=8, center=true);
            translate([0,0,0]) rotate([-90,0,-45]) cylinder(d=18, h=100, $fn=16, center=true);
        }
        

        
    }
    
    difference() {
        union() {
            translate([-1,-(cylinderOuterD-0.2)/2,0]) cube([2,cylinderOuterD-0.4,supportZ]);
            rotate([0,0,90]) translate([-1,-(cylinderOuterD-0.2)/2,0]) cube([2,cylinderOuterD-0.4,supportZ]);
        }
        translate([0,0,supportZ-2]) cylinder(d=supportD, h=2.01, $fn=64); // lower reflector support inner pocket
        cylinder(d1=supportD+10, d2=supportD, h=supportZ-1.99, $fn=64); // lower reflector support inner pocket
    }
}

module holder_clip() {
        difference() {
            cube([bracketX,bracketZ+3+5,2]); // base
            translate([bracketX/2-4,bracketZ+3+5-4,0]) cylinder(d=screwD+0.5, h=10, $fn=16, center=true); // hole 1
            translate([bracketX/2+4,bracketZ+3+5-4,0]) cylinder(d=screwD+0.5, h=10, $fn=16, center=true); // hole 2
            
        }
        //fingers
        translate([0,0,0]) grid(5, 1, 3.6, 1, 0) {
            hull() {
                translate([0.55,0,5.6]) cube([1,5,1.4]); // chamfer
                cube([2.1,5,5.6]); // base
            }
        }
    }
}

module eiki_LED_mount() {
    mountZ = 4; // "floor" thickness
    sideThick = 4; // side rail thickness
    sideHeight = 20; // height of side rails
    mountX = 80;
    mountY = heatsinkXY+sideThick+sideThick+0.6; // heatsink size + side rails + extra wiggle room
    screwD = 3.2;
    slotD = 3.2; // dia of slots for sliding heatsink screws
    
    //translate([-10,heatsinkXY/2,mountZ]) rotate([90,0,-90]) heatsink(); // heatsink (just for visualization)
    
    difference() {
        union() {
            rounded_rect(mountX, mountY, mountZ, 0.01, facets=24); // main plate (not actually rounded, so radius set very low)
            translate([0,mountY/2,sideHeight/2]) rotate([90,0,0]) rounded_rect(mountX, sideHeight, sideThick, mountZ, facets=24); // side rail 1
            translate([0,-mountY/2+sideThick,sideHeight/2]) rotate([90,0,0]) rounded_rect(mountX, sideHeight, sideThick, mountZ, facets=24); // side rail 2
        }
        hull() {
            translate([28,0,mountZ+10]) rotate([90,0,0]) cylinder(d=slotD, h=100, $fn=16, center=true); // screw hole slot 1
            translate([-30,0,mountZ+10]) rotate([90,0,0]) cylinder(d=slotD, h=100, $fn=16, center=true); // screw hole slot 2
        }
        translate([-10,15,0]) rounded_rect(45, 6, 10, 3, facets=24); // vent slot
        translate([-10,0,0]) rounded_rect(45, 6, 10, 3, facets=24); // vent slot
        translate([-10,-15,0]) rounded_rect(45, 6, 10, 3, facets=24); // vent slot
        translate([23,-26,0]) eiki_lamp_bracket(); // the original eiki bracket (for screw holes)
    }
    
    module eiki_lamp_bracket() {
        screwD = 3.2; // holes to clear mount screws in original eiki bracket
        washerD = 8.2; // pocket to clear washers if floor of bracket is too thick
        screwSpanY = 38;
        screwSpanX = 5.8;
        translate([0,0,-6.01]) cube([17, 52, 6]); // mounting plate (just for visualization)
        translate([17,71, 0]) cylinder(d1=15, d2=12, h=42); // mounting post (just for visualization)
        translate([5.5,7+screwSpanY, -.01]) cylinder(d=screwD, h=10, $fn=16); // screw hole top
        translate([5.5+screwSpanX,7, -.01]) cylinder(d=screwD, h=10, $fn=16); // screw hole bottom
        translate([5.5,7+screwSpanY, 2]) cylinder(d=washerD, h=10, $fn=24); // screw hole top clearance pocket
        translate([5.5+screwSpanX,7, 2]) cylinder(d=washerD, h=10, $fn=24); // screw hole bottom clearance pocket
    }
}

// Just for visualization and to size other parts.
module heatsink() {
        XY = heatsinkXY;
        Z = heatsinkZ;
        baseZ = 3;
        bladeNum = 14;
        bladeThick = 1.4;
        
        cube([XY,XY,baseZ]); // heatsink base
        // grid(gridDimX, gridDimY, gridPitchX, gridPitchY, center)
        translate([0,0,baseZ]) grid(1, bladeNum, 1, (XY-bladeThick)/(bladeNum-1), 0) cube([XY,bladeThick,Z-baseZ]);
    }

module eiki_motormount() {
    // main dims
    mountX = 45;
    mountY = 140;
    mountTabX = 13.5;
    mountTabY = 13;
    mountZ = 4;
    
    // 3 main mounting holes in corners of mount
    holeSpanX = 32;
    holeSpanY = 138; //138
    holeD = 5.5;
    holeSlotOffset = 5; // mm of Y offset to turn holes into adjustable slots
    holeZ = 8; // height of towers around mounting holes (due to Eiki screw length) 
    
    // dims of metal motor bracket to hold 540 sized motor
    motorBracketX = 38.5;
    motorBracketY = 35;
    motorBracketZ = 3;
    motorBracketHoleD =3.2;
    motorBracketOffsetY = -24; // mm of Y offset between mount upper holes and motor bracket top edge
    motorBracketOffsetX = -12; // mm of X offset between mount left edge and motor bracket left edge
    
    // encoder bracket holes
    sensorBracketHolesOffsetX = 7; // mm of X offset between mount left edge and sensor bracket mounting holes
    sensorBracketHolesOffsetY = 105; // mm of Y offset between mount upper holes and sensor bracket hole span centerline
    sensorbracketHoleSpan = 33; // distance between mounting holes (must match "bracketHoleSpan" var in external function encoder_bracket()
    sensorBracketHoleD = 3.2; // dia of bracket mounting holes
    sensorBracketNutHoleD = 6.6; // "dia" of hexagonal pocket for nuts
    
    //calculated vars
    holeUpperY = mountY-mountTabY/2-(mountY-holeSpanY)/2; // Y location of upper holes
    holeLowerY = (mountY-holeSpanY)/2-mountTabY/2; // Y location of lower hole
    
    difference() {
    union() {
        translate([mountX/2,mountY/2,0]) rounded_rect(mountX, mountY, mountZ, 4); // main footprint
        translate([mountX-mountTabX+mountTabX/2,-mountTabY/2+5,0]) rounded_rect(mountTabX, mountTabY+10, mountZ, 4); // tab for 3rd hole
        translate([0,holeUpperY+motorBracketOffsetY-35/2,0]) rounded_rect(abs(motorBracketOffsetX)*2,50,mountZ, 5); // pad for bracket
        translate([motorBracketOffsetX,holeUpperY+motorBracketOffsetY,mountZ]) cube([mountX,3,3]); // rails for motor bracket
        translate([motorBracketOffsetX,holeUpperY+motorBracketOffsetY-35-3.2,mountZ]) cube([mountX,3,3]); // rails for motor bracket
        //hole tower top left
        hull(){
            translate([(mountX-holeSpanX)/2,holeUpperY+holeSlotOffset/2,0]) cylinder(d=holeD+5, h=holeZ, $fn=32 ); // hole tower top left 1
            translate([(mountX-holeSpanX)/2,holeUpperY-holeSlotOffset/2,0]) cylinder(d=holeD+5, h=holeZ, $fn=32 ); // hole tower top left 2
        }
        //hole tower top right
        hull(){
            translate([mountX-(mountX-holeSpanX)/2,holeUpperY+holeSlotOffset/2,0]) cylinder(d=holeD+5, h=holeZ, $fn=32 ); // hole tower top right 1
            translate([mountX-(mountX-holeSpanX)/2,holeUpperY-holeSlotOffset/2,0]) cylinder(d=holeD+5, h=holeZ, $fn=32 ); // hole tower top right 2
        }
        //hole tower lower
        hull(){
            translate([mountX-(mountX-holeSpanX)/2,holeLowerY+holeSlotOffset/2,0]) cylinder(d=holeD+5, h=holeZ, $fn=32 ); // hole tower lower 1
            translate([mountX-(mountX-holeSpanX)/2,holeLowerY-holeSlotOffset/2,0]) cylinder(d=holeD+5, h=holeZ, $fn=32 ); // hole tower lower 2
        }
        
        }
        hull(){
            translate([(mountX-holeSpanX)/2,holeUpperY+holeSlotOffset/2,0]) cylinder(d=holeD, h=50, center=true, $fn=16 ); // hole top left 1
            translate([(mountX-holeSpanX)/2,holeUpperY-holeSlotOffset/2,0]) cylinder(d=holeD, h=50, center=true, $fn=16 ); // hole top left 2
        }
        hull(){
            translate([mountX-(mountX-holeSpanX)/2,mountY-mountTabY/2-(mountY-holeSpanY)/2+holeSlotOffset/2,0]) cylinder(d=holeD, h=50, center=true, $fn=16 ); // hole top right 1
            translate([mountX-(mountX-holeSpanX)/2,mountY-mountTabY/2-(mountY-holeSpanY)/2-holeSlotOffset/2,0]) cylinder(d=holeD, h=50, center=true, $fn=16 ); // hole top right 2
        }
        hull(){
            translate([mountX-(mountX-holeSpanX)/2,holeLowerY+holeSlotOffset/2,0]) cylinder(d=holeD, h=50, center=true, $fn=16 ); // hole bottom 1
             translate([mountX-(mountX-holeSpanX)/2,holeLowerY-holeSlotOffset/2,0]) cylinder(d=holeD, h=50, center=true, $fn=16 ); // hole bottom 2
            }
        translate([mountX-(mountX-holeSpanX)/2-13,holeLowerY+5,0]) cylinder(d=8, h=50, center=true, $fn=16 ); // notch to clear feature on projector body
    
    translate([motorBracketOffsetX,holeUpperY+motorBracketOffsetY-motorBracketY,mountZ]) motorBracketfootprint(); // motor bracket mount holes
    
            // sensor bracket mount holes
    translate([sensorBracketHolesOffsetX,mountY-mountTabY/2-sensorBracketHolesOffsetY-sensorbracketHoleSpan/2,0]) {
            cylinder(d=sensorBracketHoleD, h=40,$fn=24, center=true); // sensor hole 1
            rotate([0,0,30]) cylinder(d=sensorBracketNutHoleD, h=mountZ-1,$fn=6); // nut pocket 1
    }
    translate([sensorBracketHolesOffsetX,mountY-mountTabY/2-sensorBracketHolesOffsetY+sensorbracketHoleSpan/2,0]) {
        cylinder(d=sensorBracketHoleD, h=40,$fn=24, center=true); // sensor hole 1
        rotate([0,0,30]) cylinder(d=sensorBracketNutHoleD, h=mountZ-1,$fn=6); // nut pocket 2
    }
    
 
    translate([25,30,-1]) rounded_rect(20, 40, mountZ+2, 4); // internal cutout for cable routing
    }
    


    
    // model of the base of the aluminum motor bracket that holds 540 motor
    module motorBracketfootprint() {
        cube([motorBracketX, motorBracketY, motorBracketZ]); // the bracket base
        translate([7.3,30.76,0]) cylinder(d=motorBracketHoleD, h=40,$fn=24, center=true); // hole 1
        translate([7.3,12.76,0]) cylinder(d=motorBracketHoleD, h=40,$fn=24, center=true); // hole 2
        translate([7.3,12.76,-mountZ]) cylinder(d=motorBracketHoleD*2, h=1,$fn=24); // hole 2 extra ring to make pocket in parent object
        translate([29.3,21.5,0]) cylinder(d=motorBracketHoleD, h=40,$fn=24, center=true); // hole 3
    }
}

// Use this to mount the generic encoder_bracket to a p26 projector
module p26_encoder_mount(){
    bracketX = 40;
    bracketY = 96;
    offsetX = 23;
    offsetY = 60;
    offsetZ = 14;
    bracketZ = 3;
    riserX = 15;
    riserY = 43; 

    mountHoleD = 3; // screws to attach bracket to mount
    mountHoleOffset = 20.5;
    mountHoleSpan = 15;
    
    bracketHoleD = 2.4;
    
    
    
    
    translate([offsetX+riserX/2,offsetY,0]) difference() {
        rounded_rect(riserX,riserY, offsetZ-2, 2); //riser for bracket
        translate([-riserX/2,-riserY/2+6,0]) cube([4,31,20]); // riser cutout for encoder board
        translate([-riserX/2+10.5,-riserY/2+5,0]) cylinder(d=bracketHoleD, h=20, $fn=16); // hole for bracket 1
        translate([-riserX/2+10.5,-riserY/2+38,0]) cylinder(d=bracketHoleD, h=20, $fn=16); // hole for bracket 2
        }
    //translate([offsetX,offsetY,offsetZ]) rotate([0,90,0]) rotate([0,0,-90]) encoder_bracket(); // for reference only
    difference(){
        translate([bracketX/2,bracketY/2-5,0]) rounded_rect(bracketX,bracketY,bracketZ,4); // bracket back plane
        translate([mountHoleOffset,0,0]) cylinder(d=mountHoleD, h=10, $fn = 16); // mount hole 1
        translate([mountHoleOffset+mountHoleSpan,0,0]) cylinder(d=mountHoleD, h=10, $fn = 16); // mount hole 2
        translate([12,49,0]) rounded_rect(15,65,20,4); // lightening hole
        translate([0,-5,0]) cube([10,12,10]); // hole to clear the notch in P26 for gate mounting from other side of projector
    }
}

// bracket to hold a AS5047D magnetic sensor dev board over a magnet on projector drive shaft (any projector)
// (centered on sensor's magnetic axis, but print it with main bracket facing the buildplate)
module encoder_bracket() {
    boardHoleSpanX = 18; // X span of dev board mounting holes
    boardHoleSpanY = 11; // Y span of dev board mounting holes
    boardHoleD = 1.6; // dia of drill holes to mount board onto bracket (for self-tapping screws, not)
    
    boardX = 22.4; // X dim of panel behind dev board
    boardY = 16.2; // Y dim of panel behind dev board
    boardZ = 1.4; // Z dim of panel behind dev board
    
    // note that this feature is rotated so Y and Z are swapped!
    bracketX = 43; 
    bracketY = 15;
    bracketZ = 4;
    bracketHoleD = 3.3; // actually slots, not holes
    bracketHoleSpan = 33; // span between center points of slots
    
    difference(){
        union(){
            
            translate([0,2,0]) rotate([90,0,0]) translate([0,bracketY/2,0]) difference(){

                union(){
                    rounded_rect(bracketX,bracketY,bracketZ,2); // bracket
                    translate([-boardX/2,-bracketY/2,0]) cube([boardX,bracketY/2,10]); // bracket riser to meet board
                }
                hull(){
                    translate([bracketHoleSpan/2-2,3,0]) cylinder(d=bracketHoleD, h=50,$fn=16, center=true); //bracket slot hole 1a
                    translate([bracketHoleSpan/2+2,3,0]) cylinder(d=bracketHoleD, h=50,$fn=16, center=true); //bracket slot hole 1b
                }
                hull(){
                    translate([-bracketHoleSpan/2-2,3,0]) cylinder(d=bracketHoleD, h=50,$fn=16, center=true); //bracket slot hole 1a
                    translate([-bracketHoleSpan/2+2,3,0]) cylinder(d=bracketHoleD, h=50,$fn=16, center=true); //bracket slot hole 1b
                }
            }
            
        }
        translate([-boardX/2,-boardY/2,0]) cube([boardX,boardY,boardZ]); // pocket for board
        //translate([boardHoleSpanX/2,boardHoleSpanY/2,0]) cylinder(d=boardHoleD, h=10,$fn=16, center=true); //mount hole
        //translate([-boardHoleSpanX/2,boardHoleSpanY/2,0]) cylinder(d=boardHoleD, h=10,$fn=16, center=true); //mount hole
        translate([boardHoleSpanX/2,-boardHoleSpanY/2,0]) cylinder(d=boardHoleD, h=10,$fn=16, center=true); //mount hole
        translate([-boardHoleSpanX/2,-boardHoleSpanY/2,0]) cylinder(d=boardHoleD, h=10,$fn=16, center=true); //mount hole

    }
}

module p26_encoder_magnet_mount() {
    magnetD = 6.1; // magnet dia
    magnetZ = 6; // magnet thickness
    shaftD = 14.2; // dia of the drive shaft collar
    shaftZ = 10; 
    screwD = 4.4;
    screwOffsetZ = 4.4;
    wallThick = 1;
    
    difference() {
        cylinder(d=shaftD+wallThick+wallThick, h=shaftZ+magnetZ, $fn=48); // outer cylinder
        cylinder(d=shaftD, h=shaftZ, $fn=48); // inner for shaft
        translate([0,0,shaftZ]) cylinder(d=magnetD, h=magnetZ, $fn=48); // inner for shaft
        translate([0,0,screwOffsetZ]) rotate([90,0,0]) cylinder(d=screwD, h=10, $fn=32);
        
    }
}

// 2-part adjustable mount to attach magnet to shutter shaft (for AS5047D sensor) 
module eiki_encoder_magnet_mount() {
    slugD = 12; // outer dia of threaded slug that holds magnet
    slugZ = 6; // actually the height of the collar. The threaded slug is shorter.
    magnetD = 6.1; // magnet dia
    magnetZ = 2.5; // magnet thickness
    screwHoleD = 4; // dia of screw hole in collar (to attach to shutter shaft)
    
    
     //collar to screw onto shaft
    difference(){
        union() {
            cylinder(d=slugD+4, h=slugZ-3, $fn=48); //outer collar base
            translate([0,0,slugZ-3]) cylinder(d1=slugD+4, d2=slugD+1, h=3, $fn=48); //outer collar bevel
        }
        
        translate([0,0,1]) metric_thread (slugD+.2, 1.4, slugZ-1, internal=true, leadin=1); // internal threads (arg: dia, pitch, length)
        cylinder(d=screwHoleD, h=50, $fn=32); // top bevel
    }
    
    //adjustable magnet holder "slug"
    translate([20,0,0]) difference(){
        union() {
            metric_thread (slugD, 1.4, slugZ*.75-magnetZ,leadin=3); // threaded column (arg: dia, pitch, length)
            translate([0,0,slugZ*.75-magnetZ]) cylinder(d=magnetD+2, h=magnetZ,$fn=32); // top bevel
            polar_array(6, 0 ) translate([-0.6,-(slugD-1.8)/2,slugZ*.75-magnetZ]) cube([1.2,slugD-1.8,magnetZ]); // finger grip
        }
        translate([0,0,slugZ*.75-magnetZ]) cylinder(d=magnetD, h=50, $fn=32); // magnet pocket
        cylinder(d1=slugD-4, d2=0.1, h=slugZ*.75-magnetZ+1, $fn=32); // conical undercut to make room for screw head
    }
    
}
 
// cover for shutter camtank, to plug the hole left by the removal of the shutter pulley and clutch
// centered on drive shaft
// print UPSIDE DOWN
module eiki_camtank_cover() {
    plugD = 32;//diameter of hole in camtank
    shaftD = 9; // diameter of hole for drive shaft to exit
    mountHoleD = 6.5; // diameter of mount holes
    coverZ = 1.8; // thickness of cover
    //offsets of 2 mount holes (origin = shaft)
    mountHole1_OffsetX = -76.4;
    mountHole1_OffsetY = 0;
    mountHole2_OffsetX = 33.4;
    mountHole2_OffsetY = 12;
    //rounded rectangle to clear claw arm
    rectX = 15;
    rectY = 25;
    rectR = 3;
    rect_OffsetX = 30;
    rect_OffsetY = -10;

    difference(){    
        union(){
            hull(){ // main outline
                translate([mountHole1_OffsetX,mountHole1_OffsetY,0]) cylinder(d=12, h=coverZ, $fn=32);
                cylinder(d=plugD+12, h=coverZ, $fn=48);
                translate([mountHole2_OffsetX,mountHole2_OffsetY,0]) cylinder(d=12, h=coverZ, $fn=32);
            }
            translate([0,0,-coverZ]) cylinder(d=plugD, h=coverZ, $fn=48); // plug hole (descends below origin)
        }
        
        translate([mountHole1_OffsetX,mountHole1_OffsetY,-.01]) cylinder(d=mountHoleD, h=20, $fn=16); // mount hole 1
        translate([mountHole2_OffsetX,mountHole2_OffsetY,-.01]) cylinder(d=mountHoleD, h=20, $fn=16); // mount hole 2
        cylinder(d=shaftD, h=20, $fn=48, center=true); // shaft hole
        translate([rect_OffsetX,rect_OffsetY, -0.1]) rounded_rect(rectX,rectY,20, rectR);
        
    }
}

    // module for making boxes with 4 rounded edges, CENTERED in XY plane and resting on XY plane
// note that rounded corner resolution (facets) has a default value and can be overridden by passing an argument
module rounded_rect(length, width, height, radius, facets=24){
    hull() {
        lengthSub = length-radius*2;
        widthSub = width-radius*2;
        translate([-lengthSub/2,widthSub/2,0]) cylinder(r=radius, h=height, $fn=facets);
        translate([lengthSub/2,widthSub/2,0]) cylinder(r=radius, h=height, $fn=facets);
        translate([lengthSub/2,-widthSub/2,0]) cylinder(r=radius, h=height, $fn=facets);
        translate([-lengthSub/2,-widthSub/2,0]) cylinder(r=radius, h=height, $fn=facets);
            

    }
}

// from https://www.openscad.info/index.php/2020/08/04/arrays/
//modded to auto-compute degrees based on assumption that we want a single 360 rotation
module polar_array( count, radius ){
    for ( i=[0: 360/count: 360]) {
       rotate( [0,0,i])
       translate([radius,0,0])
       children();
    }
}

// create XY array of objects, with optional centering
module grid(gridDimX, gridDimY, gridPitchX, gridPitchY, center) {
    if (center) {
        translate([-(gridPitchX*(gridDimX-1))/2,-(gridPitchY*(gridDimY-1))/2,0]) localgrid() children();
    } else {
        localgrid() children();
    }

    module localgrid(){
        for ( x=[0:gridPitchX:gridPitchX*gridDimX-1]) {
            for ( y=[0:gridPitchY:gridPitchY*gridDimY-1]) {
                translate([x,y,0])
                children();
            }
        }
    }
}