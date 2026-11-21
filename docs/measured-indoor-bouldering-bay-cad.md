# Measured indoor bouldering bay CAD

In Project Wizard choose **Institutional → Sports / recreation / public amenities**, then **Indoor Arena, Sports Complex or Recreation Centre → Climbing: measured indoor bouldering bay**. Use Indoor or a blank setting, one ground-floor hall, and an early design or site-development action. Leave separate Parking and Space selections empty. Other sports templates stay unchanged.

Use a cardinally aligned rectangular or square plot and locate the **clear hall** by west/south offsets. The mode draws one centred two-panel wall toward its north side. The lower panel is vertical; the upper panel projects south to the lip. Enter the vertical rises and horizontal projection, not the sloped length. Hall overhead level is measured up from the finished mat. The lip angle from vertical is `atan2(projection, upper rise)`; total panel surface is `wall width × (lower rise + √(upper rise² + projection²))`.

The app checks the supplied maximum angle, minimum overhead space, and minimum remaining mat depth beyond the projected lip. The mat spans the wall width plus the two side extensions. Its south edge is followed by a separate clear access rectangle. The rear reserve, mat and access strip must fit the hall depth; the whole clear hall must fit the plot and setbacks (west = left, south = front). Metre inputs round to mm and derived checks precede display rounding.

The **editable plan DXF** shows the clear hall, upper panel projection, mat and access strip. The **true-scale section DXF** uses the wall foot at finished mat level as origin, with positive x toward the south. The mat and access extents shown below the datum are annotation lines, not construction thickness. A failed check leaves the brief in Projects with the reason and no export or generic fallback.

Example: an **8 m** wide wall, **1.5 m** lower rise, **2 m** upper rise and **1.5 m** projection give a **3.500 m** lip at **36.870°** from vertical and **32.000 m²** of measured panel surface. A 6 m overhead elevation leaves **2.500 m** above the lip; a 5 m mat depth leaves **3.500 m** past the lip projection.

This is geometry only. It does not calculate fall paths, certify a mat, detail holds or anchors, or check structure, occupancy, access compliance or climbing safety.
