# Measured playground clearance CAD

Choose **Institutional & Public Utility → Sports / recreation / public amenities → Playground**, or **Infrastructure / Public Works → Public realm / landscape / waste → Playground**. Under **Automatic drawing**, choose **Playground: measured equipment and clearance zones**. Select Outdoor or Public Open Space as appropriate, or leave the setting blank. Leave floors, parking and separate Space selections empty.

Use a cardinally aligned rectangular or square plot. The origin is the southwest plot corner, positive x points east and positive y points north. Setbacks use west as left and south as front. In Configuration enter the west edge and width of the reserved north–south path and the required extra separation. The path spans between the supplied front and rear setback lines (or plot edges if blank); it does not connect to equipment or to a street by itself.

In **Site**, enter 1–24 equipment records, one per line or separated by semicolons, in metres:

```text
ID,west offset,south offset,width,depth,west clearance,east clearance,south clearance,north clearance
```

Do not paste the header. Enter the equipment footprint's southwest corner and plan dimensions. Enter rectangular clearances you have independently verified for each piece; the app never supplies defaults or derives fall zones. IDs must be unique (case-insensitive), start with a letter, and contain only letters, digits, underscore or hyphen, up to 16 characters. Dimensions are rounded to millimetres. Equipment widths/depths and each clearance are limited to 100 m. Both zones and path must fit inside the setbacks. Zones must not overlap each other or the path; the extra separation measures true minimum edge-to-edge distance, using corner distance for diagonally separated zones. At zero extra separation, touching boundaries are accepted geometrically; that is not a safety recommendation.

**Example for geometry only:** a 24 × 25 m plot, 2 m setbacks on all sides, a 2 m-wide path starting 11 m east of the west edge, and 2 m extra separation. These sample measurements produce **102 m² of gross zones** (includes the footprints) and a **42 m² path reserve**. They are not recommended equipment clearances.

```text
A1,4,5,3,4,1,2,2,1
B2,5,15,2,3,2,1,1,2
C3,16,6,3,3,1,1,2,1
```

The editable DXF separates equipment, clearance boundaries, the path and setbacks in local millimetres. The CSV lists each ID, footprint origin and dimensions, zone boundaries and gross area. Reopen from Projects using **Playground clearance CAD**. Conflicting briefs are kept without DXF, CSV or generic zoning. This mode does not verify equipment use or fall height, impact surfacing, accessibility, installation, openings/fencing, or safety compliance.
