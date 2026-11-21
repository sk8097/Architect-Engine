# Measured freight weighbridge CAD

Choose **Infrastructure / Public Works → Transport infrastructure → Freight Terminal → Freight terminal: measured weighbridge and axle placement**. Use a cardinally aligned rectangular or square plot, a blank arrangement, Terminal / Depot or Linear Corridor, and an early design or site-development action. Leave separate floors, Parking and Space selections empty. Other freight and parking modes are unchanged.

This template draws one north-facing, centred three-axle vehicle in a straight corridor with a centred weighing platform and two clear approaches. An east bypass runs parallel beyond its own separator. Enter body width, largest tyre envelope, distance from front axle to the forward rear axle, rear tandem spread and body overhang on each end. The submitted per-side clearance applies independently to the body in the corridor and the tyres on the platform. The bypass is a width reserve only and does not share the weighing corridor.

Chainage zero is the start of the south approach. Let `A` be the south approach length, `P` the platform length, `D` the full corridor length, `S` the rearmost-to-front axle span and `M` the axle end margin. The rearmost axle may lie in `[A+M, A+P−M−S]` for the axles and `[rear overhang, D−S−front overhang]` for the body. The **intersection** is the allowable stopping range. A range can be a single exact point; the drawing places the truck at the midpoint. Offsets locate the full corridor and bypass envelope; setbacks use west as left and south as front. Measured inputs round to mm; a midpoint may retain half-mm precision.

The **editable DXF** shows platform, body, axles, the range marker and bypass in local mm. The **CSV** lists each axle's earliest, midpoint and latest chainage in metres. Failed geometry checks preserve the brief in Projects with a reason and no export or generic fallback.

Example: **18 m** platform, 6/5 m approaches, 0.8 m axle end margin, 6 m front-to-forward-rear wheelbase and 1.4 m rear tandem spread. With 1.5/2 m front/rear overhangs, the rearmost axle can stop from **Ch 6.800 to 15.800 m** and is drawn at **Ch 11.300 m**. A 5 m corridor, 1 m separator and 3.5 m bypass give a **9.500 × 29.000 m** envelope.

This is static geometry, not weighing accuracy, axle loading, level, braking, vehicle turning, queueing, bypass adequacy, structure or regulatory approval.
