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
//eiki_LED_lens_holder(0); // export STL with 0 argument for holder, 1 argument for holder fingers
//eiki_LEDdriver_tray(); // tray to keep the LED driver in place
//projection() { // optional 2D projection of the control panel, used for SVG export for control panel label design.
eiki_control_panel(); // flat faceplate for control panel on side of projector - PRINT UPSIDE DOWN
//}
//eiki_power_switch_ring(); // adapter ring to mount power switch in hole for threading lamp
//eiki_terminal_block_mount(); // mount to hold electrical terminal blocks
//eiki_cable_clip(); // cable clip that mounts on bosses inside projector
//eiki_cable_clip_mount(); // expanding cleat to insert into large holes inside projector
//eiki_battery_box(); // battery box (with mounting points for voltage protection board and ESP32 PCB slot)
//translate([160,-64+2.6,0]) rotate([-90,0,0]) eiki_PCB_mount(); 
//eiki_PCB_mount();

// For Eumig P26 only (NOTE: Other P26 parts were created in Blender! They aren't in this file.)
// ------------------ //

//p26_encoder_magnet_mount(); // 1-piece threaded part to attach encoder magnet to drive shaft
//p26_encoder_mount(); // mount to attach encoder bracket to P26 chassis
//P26_esp_mount();


////////////// THE MODULES ////////////////

// adapter ring to mount power switch in hole for threading lamp
module eiki_power_switch_ring() {
    $fn=48;
    flangeZ = 2;
    chassisZ = 2.6;
    slotWidth = 1.6;
    holeOD = 16.4;
    holeID = 12;
    FlangeD = 24;
    
    satelliteD = 9;
    satelliteOffset = 26;
    satelliteAngle = 38;
    
    difference() {
        union() {
            hull() {
                cylinder(d=FlangeD, h=flangeZ); // outer flange
                rotate([0,0,satelliteAngle]) translate([0,satelliteOffset-3,0]) cylinder(d=satelliteD+3, h=flangeZ); // satellite flange
            }
            cylinder(d=holeOD, h=flangeZ+chassisZ); // outer
            
        }
        cylinder(d=holeID, h=10); // inner
        rotate([0,0,satelliteAngle]) translate([0,satelliteOffset,0]) cylinder(d=satelliteD, h=10); // satellite hole
    }
    
    translate([-slotWidth/2,-(holeID/2+slotWidth/2),0]) cube([slotWidth,slotWidth,flangeZ+chassisZ]); // slot guide
}

// cable clip that mounts on bosses inside projector
module eiki_cable_clip() {
    mountHoleD = 3.4;
    mountX = 15;
    mountZ = 2;
    
    difference() {
        translate([-mountX/2,-mountX/2,0]) cube([mountX,mountX,mountZ]); // base
        cylinder(d=mountHoleD, h=mountZ+1, $fn=24); // mount hole
    }
    translate([mountX/2-mountZ,0,0]) wing(); // wing1
    translate([-mountX/2,0,0]) wing(); // wing2
    translate([-mountX/2,-mountX/2,mountZ]) cube([mountX,mountZ,mountZ/2]); // side rail 1
    translate([-mountX/2,mountX/2-mountZ,mountZ]) cube([mountX,mountZ,mountZ/2]); // side rail 2
    
    module wing() {
        difference() {
            translate([0,0,mountZ]) rotate([0,90,0]) cylinder(d=mountX, h=mountZ, $fn=64); // wing cylinder
            translate([-1,0,mountZ-4.3]) rotate([45,0,0]) cube([6,6,6]); // subtract cutout
            translate([0,0,-25]) cube([50,50,50], center=true); // cut off bottom
        }
    }
}

// expanding cleat to insert into large holes inside projector
module eiki_cable_clip_mount(){
    pillarHoleD = 5.6; // inside dia of pillar hole on projector
    pillarHoleZ = 20; // depth of pillar hole on projector
    
    mountHoleD = 3.2;
    mountHoleZ = 6; // depth of mount screw hole inside this mount

    
    difference() {
        union() {
            cylinder(d=pillarHoleD, h=pillarHoleZ-2, $fn=24); // outer cylinder
            translate([0,0,pillarHoleZ-2]) cylinder(d1=pillarHoleD, d2=pillarHoleD-2, h=2, $fn=24); // outer cylinder taper
            cylinder(d=21, h=1, $fn=6); // ring
        }
        cylinder(d=mountHoleD, h=mountHoleZ-4, $fn=32); // hole
        translate([0,0,mountHoleZ-4]) cylinder(d1=mountHoleD, d2=mountHoleD-1, h=4, $fn=32); // hole top taper
        translate([-5,-(mountHoleD-1.2)/2,1]) cube([10,mountHoleD-1.2,pillarHoleZ+1]); // slit
    }
}

// mount to hold 2 electrical terminal blocks
module eiki_terminal_block_mount() {
    baseZ = 8;
    baseY = 48;
    
    term1X = 27;
    term1MountCenterX=10;
    term1OffsetY = 10;
    
    term2X = 20;
    term2MountCenterX=37;
    term2OffsetY = 5;
    term2Z = baseZ+18;
    
    mountHoleLoc = ([10,16,0]);
    mountHoleD = 3.2;
    termMountHoleD = 2.5;
    
    tabX = 33;
    tabY = 15;
    tabZ = 3;
    tabOffsetY = 20.4;
 
    // main part
    difference() {
        translate([(term1X+term2X)/2,baseY/2,0]) rounded_rect(term1X+term2X,baseY,baseZ,3); // base of terminal 1 + terminal2
        translate(mountHoleLoc) cylinder(d=mountHoleD, h=50, $fn=24); // mount hole for the object
        translate([mountHoleLoc[0],mountHoleLoc[1],3]) cylinder(d=mountHoleD*2.6, h=50, $fn=24); // pocket to clear head
        translate([term1MountCenterX,term1OffsetY,0]) term_holes(); // holes for terminal block 1
    }
    // tower for term 2
    difference() {
        translate([term1X+term2X/2,baseY/2-2,0]) rounded_rect(term2X,baseY-4,term2Z,3); // tower for terminal 2
        translate([term2MountCenterX,term2OffsetY,term2Z-8]) term_holes(); // holes for terminal block 2
        translate([0,-9,baseZ]) rotate([0,90,0]) cylinder(d=35, h=100, $fn=96); // undercut for cable clearance
    }
    // anti-rotation tab for bottom
    translate([tabX/2,tabY/2+tabOffsetY,-tabZ]) rounded_rect(tabX,tabY,tabZ,2); // anti-rotation tab

    module term_holes() {
        cylinder(d=termMountHoleD, h=50, $fn=24); // bottom mount hole for terminal strip
        translate([0,30,0]) cylinder(d=termMountHoleD, h=50, $fn=24); // top mount hole for terminal strip
    }

    

    
}

// battery box and mounting point for battery protection board
module eiki_battery_box() {
    // Origin is center of left mounting hole. Everything is relative to this!
    mountBaseX = 150; // width of main plate
    mountBaseInsideY = 64; // height of main plate interior (from mount hole center down to inside of chassis floor)
    mountBaseExtra = 8; // Extra margin on top and sides
    mountBaseZ = 3; // thickness of main plate
    mountHoleD = 3.2; // dia of screw holes for mounting this plate to chassis
    mountHoleSpan = 90; // X distance between mount holes
    
    termMountOffsetX = 6; // terminal block holes, X offset from origin 
    termMountOffsetY = 30; // top terminal block hole, Y offset from origin (lower hole will be 20mm lower)
    termMountD = 3.2; // dia of screw holes for mounting terminal blocks to this plate
    termNutHoleD = 6.6; // dia of pocket for screw heads
    
    boardMountOffsetX = 30; // upper left mount hole for DVB01, X offset from origin
    boardMountOffsetY = 16; // upper left mount hole for DVB01, Y offset from origin
    boardSpanX = 60; // X distance between holes
    boardSpanY = 37; // Y distance between holes
    
    strapX = 21; // slot for velcro strap to keep battery in place
    strapY = 2; // slot for velcro strap to keep battery in place
    strapOffsetX = 53.6;
    
    lockOffsetZ = 4.8; // height offset of PCB lock relative to top edge of wall

    ceilingOffsetY = 23; // offset of ceiling
    floorY = 1; // thickness of floor lip and stiffening gusset on bottom of model
    sideZ = 50; // height of ceiling and right side wall to enclose battery area
    
    tabY = 3; // height of tabs
    tab1OffsetX = 2;
    tab1Dims = [30,tabY,mountBaseZ]; // dims of left tab that protrudes through chassis
    tab2OffsetX = 45;
    tab2Dims = [38,tabY,mountBaseZ]; // dims of middle tab that protrudes through chassis
    tab3OffsetX = 101;
    tab3Dims = [38,tabY,mountBaseZ]; // dims of right tab that protrudes through chassis
    
    
    notchD = 18; //dia of notches to clear chassis features
    notch1Offset = [73, 7, 0];
    notch2Offset = [105, -ceilingOffsetY+notchD/2+mountBaseZ, 0]; // notch for upper right feature
    
    boardSlotYOffset = 23; // location of slot for ESP32 PCB - This is measured from the FLOOR of the projector, NOT the same origin as the other parts (Why? So we can use the same offset for another PCB support model that will hold the other side of the board.)
    boardSlotX = 5; // depth of slot for PCB
    boardSlotY = 2; // width of slot for PCB
        
    difference() {
        union() {

            translate([mountBaseX/2-mountBaseExtra/2,-(mountBaseInsideY+mountBaseExtra/2)/2+mountBaseExtra/2,0.1]) rounded_rect(mountBaseX, mountBaseInsideY+mountBaseExtra/2, mountBaseZ, 4); // main plate
            

            translate([-(mountBaseExtra-8)/2,-mountBaseInsideY,mountBaseZ]) cube([mountBaseX-8, floorY, 3]); // bottom rail (fits against floor of chassis
            translate([tab1OffsetX,-mountBaseInsideY-tabY,0]) cube(tab1Dims); // chassis tab 1
            translate([tab2OffsetX,-mountBaseInsideY-tabY,0]) cube(tab2Dims); // chassis tab 2
            translate([tab3OffsetX,-mountBaseInsideY-tabY,0]) cube(tab3Dims); // chassis tab 3
            
            //translate([-mountBaseExtra/2,-ceilingOffsetY,0]) cube([mountBaseX, mountBaseZ, sideZ]); // ceiling wall
            
            // ceiling wall with rounded corner
            hull() {
                translate([0,-ceilingOffsetY,0]) cube([mountBaseX-mountBaseExtra/2, mountBaseZ, sideZ]); // ceiling wall
                translate([0,-ceilingOffsetY+mountBaseZ, sideZ-mountBaseExtra/2]) rotate([90,0,0]) cylinder(d=mountBaseExtra, h=mountBaseZ, $fn=24); // upper rounded corner
                translate([-mountBaseExtra/2,-ceilingOffsetY,0]) cube([10, mountBaseZ, 10]); // lower square corner
            }
            translate([mountBaseX-mountBaseExtra/2-mountBaseZ,-mountBaseInsideY,0]) cube([mountBaseZ, mountBaseInsideY, sideZ]); // right side wall
            
            hull(){
                translate([mountBaseX-mountBaseExtra/2-mountBaseZ-20,-mountBaseInsideY,0]) cube([20, floorY, 3]); // gusset for side wall
                translate([mountBaseX-mountBaseExtra/2-mountBaseZ,-mountBaseInsideY,0]) cube([mountBaseZ, floorY, sideZ]); // gusset for side wall
            }
        }
    cylinder(d=mountHoleD, h=50, $fn=24); // mount hole 1
    translate([mountHoleSpan,0,0]) cylinder(d=mountHoleD, h=50, $fn=24); // mount hole 2

    translate([termMountOffsetX,-termMountOffsetY,0]) mountHole(); // top term block mount hole
    translate([termMountOffsetX,-termMountOffsetY-20,0]) mountHole(); // top term block mount hole
    
    translate([boardMountOffsetX,-boardMountOffsetY,0]) mountHole(); // top left board mount hole
    translate([boardMountOffsetX+boardSpanX,-boardMountOffsetY,0]) mountHole(); // top right board mount hole
    translate([boardMountOffsetX,-boardMountOffsetY-boardSpanY,0]) mountHole(); // bottom left board mount hole
    translate([boardMountOffsetX+boardSpanX,-boardMountOffsetY-boardSpanY,0]) mountHole(); // bottom right board mount hole
        
    translate([strapOffsetX,-ceilingOffsetY-strapY,0])  cube([strapX, strapY, 50]); // top slot for velcro strap
    translate([strapOffsetX,-mountBaseInsideY,0])  cube([strapX, strapY, 50]); // bottom slot for velcro strap
        
        
    
        // notch 1 to clear chassis feature
        translate(notch1Offset) cylinder(d=notchD, h=60, $fn=24);
    
        // notch 2 to clear chassis feature
        hull() {
            translate([notch2Offset[0],100,notch2Offset[2]]) cylinder(d=notchD, h=60, $fn=24); // notch upper
            translate(notch2Offset) cylinder(d=notchD, h=60, $fn=24); // notch on axis
            translate([notch2Offset[0]+100,notch2Offset[1],notch2Offset[2]]) cylinder(d=notchD, h=60, $fn=24); // notch right
        }

    }
    
    // print 4 standoffs along edge, for the DVB01 board
    translate([105,-12,0]) standoff();
    translate([115,-12,0]) standoff();
    translate([125,-12,0]) standoff();
    translate([135,-12,0]) standoff();
    
    // print PCB lock
    //translate([mountBaseX-mountBaseExtra/2+mountBaseZ/2, -ceilingOffsetY,sideZ]) PCBlock(); // simulate assembly
    translate([110, 0,lockOffsetZ+2]) rotate([0,180,90]) PCBlock();
    
    // support for PCB lock
    difference() {
        hull() {
            translate([mountBaseX-mountBaseExtra/2, -ceilingOffsetY-3,0]) cube([0.1, 6, sideZ]); // flat part
            translate([mountBaseX-mountBaseExtra/2+mountBaseZ/2, -ceilingOffsetY,sideZ-10]) cylinder(r=mountBaseZ,h=10, $fn=24); // round part
        }
        translate([mountBaseX-mountBaseExtra/2+mountBaseZ/2, -ceilingOffsetY,sideZ-10]) cylinder(d=3,h=20, $fn=24); // hole for PCB lock
}
    
   // PCB board slot
   difference() {
       translate([mountBaseX-mountBaseExtra/2, -mountBaseInsideY+boardSlotYOffset-mountBaseZ,0]) cube([boardSlotX, boardSlotY+mountBaseZ+mountBaseZ, sideZ]); // outer support
       translate([mountBaseX-mountBaseExtra/2, -mountBaseInsideY+boardSlotYOffset,2]) cube([boardSlotX, boardSlotY, sideZ]); // inner slot
       translate([mountBaseX-mountBaseExtra/2, -mountBaseInsideY+boardSlotYOffset+boardSlotY/2,sideZ-boardSlotY*1.333]) rotate([45,0,0]) cube([20, boardSlotY*2, boardSlotY*2]); // interior bevel
   }

    // mounting hole with pocket for screw head
    module mountHole() {
        cylinder(d=termMountD, h=50, $fn=24); // term block mount hole
        translate([0,0,1])  cylinder(d=termNutHoleD, h=50); // term block mount hole pocket
    }
    
    // standoff for mounting DVB01 board
    module standoff() {
        difference(){
            cylinder(d=7, h=3.2, $fn=48); // outer
            cylinder(d=mountHoleD+0.2, h=4, $fn=48); // cut hole (a little big so it doesn't get stuck)
        }
    }
    
    // hinged lock to keep PCB in place
    module PCBlock() {
        
        
        difference() {
            union() {
                cylinder(r=mountBaseZ, h=lockOffsetZ, $fn=24); // pedestal
                hull() {
                    translate([0,0,lockOffsetZ]) cylinder(r=mountBaseZ, h=2, $fn=24); // hull upper
                    translate([0,-mountBaseInsideY+boardSlotYOffset+ceilingOffsetY,lockOffsetZ])cylinder(r=mountBaseZ*2, h=2, $fn=36); // hull lower
                }
        }
        cylinder(d=mountHoleD+0.2, h=30, $fn=16, center=true); // cut hole (a little big so it doesn't get stuck)
        }
    }
}


// mount for right side of ESP32 PCB (Left side of PCB is supported by slot on battery box)
// (PRINT THIS WITH SUPPORTS - BIG FLAT SIDE ON THE BUILD PLATE)
// Note that part is drafted with the bottom resting on the XY axis, unlike its brother the battery box!
module eiki_PCB_mount() {
    baseZ = 3;
    baseX = 16;
    baseInsideY = 47.2; // Y depth from center of screw hole to inside of PCB slot
    baseYbottomCut = 5; // Remove this much from the back of the base to clear the eiki microswitch assembly
    
    boardSlotZOffset = 23-2.6; // location of slot for ESP32 PCB - This is measured up from the FLOOR of the projector. (also accounts for 2.6mm rise on chassis floor)
    boardSlotX = 5; // depth of slot for PCB
    boardSlotZ = 2; // width of slot for PCB
    
    screwD = 4; //hole for mounting screw (was originally the Eiki grounding post)
    screwExtensionY = 19; // length of "peninsula" for screw
    pinD = 11; // dia of pin that protrudes from bottom of mount to engage hole in chassis
    screwOffsetY = 19;
    
    baseY = baseInsideY-screwOffsetY+baseX/2;
    baseYbottom = baseInsideY-baseYbottomCut-screwOffsetY+baseX/2;
    
    translate([0,0,-3]) cylinder(d=pinD, h=3, $fn=48); // locator pin
    
    difference() {
        hull() {
            translate([0,0,0]) cylinder(d=screwD*2, h=baseZ, $fn=24); // peninsula
            translate([0,-19,0]) cylinder(d=screwD*2, h=baseZ, $fn=24); // peninsula
        }
        translate([0,-screwOffsetY,0]) cylinder(d=screwD, h=10, $fn=24); // screw hole
    }
    
    
        hull() {
            translate([-baseX/2,-baseX/2,0]) cube([baseX,baseYbottom,baseZ]); // main base bottom
            translate([baseX/2-boardSlotX-2,-baseX/2,boardSlotZOffset-2]) cube([boardSlotX+2,baseInsideY-screwOffsetY+baseX/2,0.01]); // main base top
        }
        difference() {
            translate([baseX/2-boardSlotX-2,-baseX/2,boardSlotZOffset-2]) cube([boardSlotX+2,baseInsideY-screwOffsetY+baseX/2,2+boardSlotZ+2]); // main base top
            translate([baseX/2-2-10, -baseX/2-2, boardSlotZOffset]) cube([10,baseY,boardSlotZ]); // slot for PCB
            translate([baseX/2-boardSlotX-2, -baseX/2, boardSlotZOffset-boardSlotZ]) rotate([45,0,0]) cube([boardSlotX, boardSlotZ*2, boardSlotZ*2]); // interior bevel
    }
    
}

// flat faceplate for control panel on side of projector
// NOTE: It barely fits on my 200mm 3D printer bed. Orient diagonally and increase the rounded_rect corner radius to make it fit.
module eiki_control_panel() {
    plateDims = [250, 40, 1]; // dims of faceplate
    ledD = 5.4; // dia of hole for status LED
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
        translate([77.7,6.3,-0.1]) cylinder(d=ledD, h=5, $fn=24); // status LED
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
    reflectorD = 39.8;
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

// rails with slots for LED module slide into focus. Attaches to existing Eiki lampholder mount.
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

// tray to hold LED driver board
module eiki_LEDdriver_tray() {
    // origin is 4mm screw hole
    trayZ =3;
    wallThick = 2;
    
    pcbOffset = [0,20,0];
    pillarOffset = [-17, 42, 0];
    
    difference() {
        hull() {
            cylinder(d=4+wallThick*2,h=trayZ, $fn=32); // screw hole
            translate(pcbOffset) cylinder(d=31+wallThick*2,h=trayZ, $fn=64); // PCB hole
            translate(pillarOffset) cylinder(d=9+wallThick*2,h=trayZ, $fn=32); // hole to wrap around pillar
        }
        
        cylinder(d=4.2,h=trayZ+1, $fn=32); // screw hole
        translate(pcbOffset) cylinder(d=31,h=trayZ+1, $fn=64); // PCB hole
        translate(pillarOffset) cylinder(d=9,h=trayZ+1, $fn=32); // hole to wrap around pillar
    }
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

// temporary set of standoffs for mounting ESP board to P26 projector
module P26_esp_mount() {
    span = 73.6;
    height = 20;
    width = 16;
    
    P26_esp_standoff();
    translate([span,0,0]) P26_esp_standoff();
    difference() {
        hull() {
            cylinder(d=width, h=2, $fn=48); // lower 
            translate([span,0,0]) cylinder(d=width, h=2, $fn=48); // lower
        }
    translate([span/2,0,0]) cylinder(d=3, h=10, $fn=24);
}
    
    module P26_esp_standoff() {
        difference(){
            union() {
                cylinder(d=7, h=height, $fn=48); // outer
                translate([0,0,2]) cylinder(d1=width, d2 = 7, h=height/2-2, $fn=48); // lower flange
                cylinder(d=width, h=2, $fn=48); // lower flange
            }
            translate([0,0,height-9]) cylinder(d=3, h=10, $fn=48); // cut hole a little small so M3 can cut its own threads
            
        }
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
            cylinder(d=slugD+6, h=slugZ-3, $fn=8); //outer collar base
            translate([0,0,slugZ-3]) cylinder(d1=slugD+6, d2=slugD+3, h=3, $fn=8); //outer collar bevel
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