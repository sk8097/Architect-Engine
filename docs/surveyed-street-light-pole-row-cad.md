# Surveyed street-light pole row CAD

Choose **Infrastructure / Public Works → Energy / utilities / communications → Street Lighting Network**. Under **Street lighting drawing**, select **Surveyed pole row: equal spacing and exclusions**. Leave Facility arrangement blank or select Outdoor Yard. Leave separate Space selections empty.

Enter a projected metre-grid reference and two straight roadside controls A and B, up to 2 km apart. Chainage starts at A. Choose the side looking from A toward B and give the perpendicular offset to the pole centres. Enter the fixed start and end pole chainages and an inclusive minimum and maximum pole-centre spacing.

Optional no-pole windows are `start,end` chainage pairs in metres, separated by semicolons or line breaks. Use up to 60 windows within A–B. Their endpoints are excluded as well as their interiors; overlapping or touching windows are treated as one. Windows fully outside the pole row do not constrain it. If a window contains a fixed end, neither end is moved and the drawing is blocked.

The app tries the widest allowable equal spacing first by dividing the fixed span into an integer number of equal intervals. It returns the valid layout with the fewest poles, up to 200 including both ends. Intermediate stations are checked before rounding. It never slides individual poles or substitutes uneven spacing.

**Example:** A `(1000,2000)` and B `(1060,2080)`, pole centres offset **3 m left**, first/last at **Ch 10/90 m**, and spacing allowed **14–22 m**. A no-pole window at **Ch 29–31 m** blocks the first attempt at **20 m** spacing. The winning layout has **six poles at 16 m spacing**: Ch **10, 26, 42, 58, 74, 90 m**.

Export a layered **DXF in projected millimetres** and a **CSV** of pole IDs, chainages, eastings and northings in metres. Saved briefs reopen in Projects → **Surveyed street-light pole CAD**. Failed checks retain the brief with the reason and block both exports without generic fallback. Pole symbols mark centres only: there is no lighting performance, glare, wiring, foundation or utility clearance assessment. Do not use this as an installation approval or treat the displayed coordinate precision as survey accuracy.
