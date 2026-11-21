# Survey-based T-junction CAD

Select **Infrastructure / Public Works → Transport infrastructure → Intersection**. Under **Junction drawing** choose **Survey controls: orthogonal T-junction CAD**, and choose **Node / Interchange** for Arrangement or leave Arrangement unspecified. This mode does not use generic route length, a plot rectangle or separate Space selections.

In Site, enter the projected grid/CRS, survey source and four Easting,Northing pairs in metres: **A; J; B; C**. A and B are the straight main-road ends on opposite sides of the tangent intersection J. C is the branch end, on either side of the main road. The basis follows J→B. The app checks the line and perpendicular offsets against **both 0.05 m and 0.05°**; it snaps in-tolerance geometry to the orthogonal basis but leaves purple survey control ticks at the actual supplied positions. Allow no more than 2 km per arm. Do not enter geographic latitude and longitude.

Enter full carriageway widths and full ROW widths for the main and branch, each centred about its corresponding axis. Enter the two measured curb-return radii individually for the A and B sides. The app constructs a square T-shaped ROW envelope, checks that both tangent points are within the available arm lengths and that neither circular curb return exceeds the ROW. Variable-width ROW, skew or four-arm intersections, medians and roundabouts are outside this drawing mode.

**Example**: `345000,2110000;345040,2110000;345090,2110000;345040,2110035`, main/branch carriageways **8/7 m**, main/branch ROW **20/17 m**, A/B curb radii **6/8 m**. DXF preserves the projected position in millimetres with separate carriageway/ROW lines, exact `ARC` entities, axes and raw control markers. Save opens the preview or reports a blocker without exporting fallback geometry. The drawing reopens from **Survey T-junction CAD** in Projects.

This is a measured concept, not an approval or design check. It does not determine property rights, design lanes or markings, or assess swept paths, sight distance, signals, pedestrian facilities, pavement, levels, drainage or road safety.
