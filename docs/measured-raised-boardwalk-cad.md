# Measured raised boardwalk CAD

Choose **Infrastructure / Public Works → Public realm / landscape / waste → Public Park or Public Garden → Public space: measured raised boardwalk and support set-out**. Use a cardinally aligned rectangular or square plot, a blank arrangement or Public Open Space, and an early design or site-development action. Leave building floors, separate Parking and Space selections empty. The surveyed waterfront promenade and other park templates remain separate.

Enter a constant-width, level south–north deck. Provide the deck-top elevation, depth to the continuous soffit, and ground elevations on the centreline at the south end, an interior break and the north end, using the same datum. Ground is interpolated linearly between the three measurements. The highest ground knot controls the minimum vertical gap, even when it is between supports. If the highest elevation occurs at several knots the earliest chainage is reported.

Enter both end distances to the support centrelines, a maximum end overhang, maximum support pitch, square support footprint and equal side inset. The app divides the interval between the first and last pair into the fewest equal bays satisfying the submitted maximum centre-to-centre pitch. It checks support footprints under the deck and requires separation. At most 100 support pairs are drawn. The full plan envelope includes the supplied reserve around the deck. Offsets locate that envelope; west is left and south is front for setbacks. Metric dimensions/elevations are rounded to mm; equal-pitch coordinates retain fractional mm.

The **editable plan DXF** shows the support footprints and envelope. The **true-scale centreline profile DXF** shows the ground, top/soffit, pair centrelines and minimum gap. The profile's vertical zero is the lowest input ground elevation and is labelled with its RL. Geometric conflicts keep the brief in Projects with a reason and no DXF or generic fallback.

Example: a **24 × 3 m** deck with 1.2/1.8 m end overhangs and 4 m maximum pitch yields **7 support pairs at 3.500 m pitch**. Deck top RL 102.000 m and 0.250 m depth give soffit RL 101.750 m. The peak ground RL 101.100 m at **Ch 8.300 m** leaves **0.650 m** minimum gap, between supports. With a 0.75 m reserve, the full envelope is **4.500 × 25.500 m**.

This is geometry only. The centreline ground is neither a cross-section nor a flood level. The mode does not check loads, connections, foundations, drainage, guards, end access, accessibility or construction approval.
