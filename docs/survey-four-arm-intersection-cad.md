# Surveyed four-arm intersection CAD

In **Infrastructure → Transport → Intersection**, select **Survey controls: skew four-arm intersection CAD** under **Junction drawing**. This is a plan-only Node / Interchange. Leave parking, structures and separate Space selections empty.

In Site, enter five `Easting,Northing` pairs in **A; J; B; C; D** order. Use projected metres, up to three decimal places, with one stated grid and source reference. A/B and C/D are two straight axes that cross at J. Each opposing pair must be straight within **0.05 m and 0.05°**, and adjacent arms must meet at **30–150°**. Arms can extend up to 2 km from J. The B and C controls define the two bearings. Small accepted differences in A and D are snapped to those axes in the drawing; the original survey marks remain at their entered coordinates.

Enter the full carriageway and right-of-way widths for both axes (the form labels C/D as the branch), and separate circular curb-return radii for **AC, BC, BD and AD**. Each arm must extend past its ROW corners and both tangent points. The check tests the entire circular arc against the supplied ROW, not just the tangent points.

Example: `345000,2110000;345040,2110000;345090,2110000;345061,2110028;345016,2109968`. The adjacent angles alternate between about 53.13° and 126.87°. Use carriageways **8 m / 7 m**, ROW **20 m / 17 m**, and radii **AC 5 m, BC 7 m, BD 8 m, AD 6 m**.

Save to preview the junction, or reopen **Survey four-arm intersection CAD** in Projects. Editable DXF preserves projected millimetres, with native `ARC` entities and separate carriageway, ROW, centreline and control layers. A conflicting brief remains saved without an export or generic zoning fallback. The existing orthogonal T-junction mode is unchanged.

This drawing does not establish property boundaries, lanes, turn capacity, pedestrian crossings, levels, drainage, sight distance or approval compliance.
