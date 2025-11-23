// Stackable container
/* [Common Dimensions] */
ExtWidth = 110;
ExtDepth = 110;
ExtHeight = 88;
/* [Tuning] */
WallTh = 2;
StackDepth = 10;
CornerRadii = 5;
HexSize = 4;
Wiggle = 0.25;

// ###########################################

/* [Hidden] */
// Calculated Params
BinHeight = ExtHeight - StackDepth;
LandWidth = ExtWidth - ((WallTh + Wiggle) * 2);
LandDepth = ExtDepth - ((WallTh + Wiggle) * 2);

// Cuts
TrapBotWidth = ExtWidth * 0.60;
TrapTopWidth = ExtWidth * 0.70;
TrapHeight = StackDepth * 0.95;

// ###########################################

// Rounded Box
module RoundedCornerBox(size=[10,10,10], r=5)
{
   linear_extrude(height=size[2])
      offset(r=r) square([size[0]-2*r, size[1]-2*r]);
}

// Hexagon(..s are the bestagons)
module Hexagon(r)
{
   polygon(points=[for(i=[0:5]) [r*cos(i*60), r*sin(i*60)]]);
}

// Hexagonal wall pattern
// Filament save
module HexPattern(width, depth, height, hex_r, spacing)
{
   dx = 1.5*hex_r+spacing;
   dy = sqrt(3)*hex_r+spacing;
   nx = floor(width/dx);
   ny = floor(depth/dy);
   for(i=[0:nx-1])
      for(j=[0:ny-1])
      {
         offset_x = i*dx;
         offset_y = j*dy + (i%2==0 ? 0 : dy/2);
         translate([offset_x, offset_y, 0])
            linear_extrude(height=height)
            Hexagon(hex_r);
      }
}

// Bin
module BinShape()
{
   // BinBox
   RoundedCornerBox([LandWidth, LandDepth, BinHeight], CornerRadii);
   
   // Bang the catchers mitt outer on top and hull the shape
   hull()
   {
      translate([-WallTh-Wiggle, -WallTh-Wiggle, BinHeight])
         // Catchbox
         RoundedCornerBox([ExtWidth, ExtDepth, StackDepth], CornerRadii);
         translate([0, 0, BinHeight-StackDepth])
            RoundedCornerBox([LandWidth, LandDepth, Wiggle], CornerRadii);
   }
}

// Catch
module CutoutShape()
{
   // Binner cavity
   translate([0, 0, WallTh])
      RoundedCornerBox([LandWidth-2*WallTh, LandDepth-2*WallTh, ExtHeight], CornerRadii-WallTh);
   
   translate([-WallTh-Wiggle, -WallTh-Wiggle, BinHeight])
      // Catch cavity
      translate([0, 0, 0])
         RoundedCornerBox([ExtWidth-2*WallTh, ExtDepth-2*WallTh, ExtHeight], r=CornerRadii-WallTh);
   
   translate([WallTh*3, -StackDepth, BinHeight - StackDepth*2])
      rotate([270,0,0])
      // Hex pattern walls
      HexPattern(LandWidth-StackDepth, BinHeight - StackDepth*2, LandDepth + StackDepth, HexSize, WallTh);
   
   translate([LandWidth, WallTh*4, BinHeight - StackDepth*2])
      rotate([270,0,90])
      // Hex pattern walls
      HexPattern(LandDepth-StackDepth, BinHeight - StackDepth*2, LandWidth + StackDepth, HexSize, WallTh);
}

module CatchCut()
{
   // Trim the catch to save filament
   translate([-WallTh*3, ExtWidth-WallTh*2, BinHeight+WallTh])
      rotate([90,0,0])
         linear_extrude(height=ExtWidth*1.1)
            polygon([
               [ (ExtWidth-TrapBotWidth)/2, 0],
               [ (ExtWidth+TrapBotWidth)/2, 0],
               [ (ExtWidth+TrapTopWidth)/2, TrapHeight],
               [ (ExtWidth-TrapTopWidth)/2, TrapHeight]
            ]);
   
   translate([-WallTh*4, -WallTh*3, BinHeight+WallTh])
      rotate([90,0,90])
         linear_extrude(height=ExtWidth*1.1)
            polygon([
               [ (ExtWidth-TrapBotWidth)/2, 0],
               [ (ExtWidth+TrapBotWidth)/2, 0],
               [ (ExtWidth+TrapTopWidth)/2, TrapHeight],
               [ (ExtWidth-TrapTopWidth)/2, TrapHeight]
            ]);
}

module Bin()
{
difference()
   {
       BinShape();
       CutoutShape();
       CatchCut();
   }
}

// Render
Bin();
