// Stackable container
/* [Common Dimensions] */
ExtWidth = 230;
ExtDepth = 230;
ExtHeight = 50;
/* [Tuning] */
WallTh = 2;
StackDepth = 10;
CornerRadii = 5;
HexSize = 2;
Wiggle = 0.1;

/* [Logo] */
// Add logo?
Logo="N"; // [Y:Yes, N:No]
// Logo SVG
LogoFile = "./_media/OBC.svg";
LogoScaleDiv = 15;

// ###########################################

// Render selection
RenderMode = "Both"; // [Bin, Divider, Both]

// ###########################################

/* [Hidden] */

$fn = 120;
// Calculated Params
BinHeight = ExtHeight - StackDepth;
LandWidth = ExtWidth - ((WallTh + Wiggle) * 2);
LandDepth = ExtDepth - ((WallTh + Wiggle) * 2);

// Cuts
TrapBotWidth = ExtWidth * 0.60;
TrapTopWidth = ExtWidth * 0.70;
TrapBotDepth = ExtDepth * 0.60;
TrapTopDepth = ExtDepth * 0.70;
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
               if (Logo == "Y")
               {
                  rotate([0,0,10])
                     scale(hex_r / LogoScaleDiv)
                        import(LogoFile, center = true);
               }
               else
               {
                  Hexagon(hex_r);
               }
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
   
   translate([WallTh*2.5, -StackDepth, BinHeight - StackDepth*2])
      rotate([270,0,0])
      // Hex pattern walls
      HexPattern(LandWidth-StackDepth, BinHeight - StackDepth*2, LandDepth + StackDepth, HexSize, WallTh);
   
   translate([LandWidth, WallTh*2.5, BinHeight - StackDepth*2])
      rotate([270,0,90])
      // Hex pattern walls
      HexPattern(LandDepth-StackDepth, BinHeight - StackDepth*2, LandWidth + StackDepth, HexSize, WallTh);
}

module CatchCut()
{
   // Trim the catch to save filament
   translate([-WallTh*4, ExtDepth-WallTh*2, BinHeight+WallTh])
      rotate([90,0,0])
         linear_extrude(height=ExtDepth*1.1)
            polygon([
               [ (ExtWidth-TrapBotWidth)/2, 0],
               [ (ExtWidth+TrapBotWidth)/2, 0],
               [ (ExtWidth+TrapTopWidth)/2, TrapHeight],
               [ (ExtWidth-TrapTopWidth)/2, TrapHeight]
            ]);
   
   translate([-WallTh*4, -WallTh*3.5, BinHeight+WallTh])
      rotate([90,0,90])
         linear_extrude(height=ExtWidth*1.1)
            polygon([
               [ (ExtDepth-TrapBotDepth)/2, 0],
               [ (ExtDepth+TrapBotDepth)/2, 0],
               [ (ExtDepth+TrapTopDepth)/2, TrapHeight],
               [ (ExtDepth-TrapTopDepth)/2, TrapHeight]
            ]);
}

module Dividers()
{
   dividerTh = WallTh;
   
   LandDepth = LandDepth - WallTh*2 - Wiggle*2;
   LandWidth = LandWidth - WallTh*2 - Wiggle*2;

   rows = 5;
   rowHeight = LandDepth / rows;

   colWidth = LandWidth / 3;

   xLeftCenter = colWidth;
   xCenterRight = 2*colWidth;
   centralWidth = colWidth / 2;

   // ---- Horizontal dividers ----
   for(r = [1:rows-1])
   {
      y = r * rowHeight - dividerTh/2;
      translate([0, y, 0])
         cube([LandWidth, dividerTh, BinHeight]);
   }

   // ---- Vertical dividers per row ----
   // Rows 1-4 (middle split)
   for(r = [0:3])
   {
      yStart = r * rowHeight;

      // Left / Center
      translate([xLeftCenter - dividerTh/2, yStart, 0])
         cube([dividerTh, rowHeight, BinHeight]);

      // Center / Right
      translate([xCenterRight - dividerTh/2, yStart, 0])
         cube([dividerTh, rowHeight, BinHeight]);

      // Central column split
      translate([xLeftCenter + centralWidth - dividerTh/2, yStart, 0])
         cube([dividerTh, rowHeight, BinHeight]);
   }

   // ---- Row 5 (bottom row) special ----
   yStart = 4 * rowHeight;

   // Left / Center-left divider stays
   translate([xLeftCenter - dividerTh/2, yStart, 0])
      cube([dividerTh, rowHeight, BinHeight]);

   // Central-right merges into right column
   translate([xLeftCenter + centralWidth - dividerTh/2, yStart, 0])
      cube([dividerTh, rowHeight, BinHeight]);
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
if (RenderMode == "Bin")
{
   Bin();
}
else if (RenderMode == "Divider")
{
   Dividers();
}
else if (RenderMode == "Both")
{
   Bin();
   translate([-WallTh*1.5, -WallTh*1.5, 0])
      Dividers();
}
