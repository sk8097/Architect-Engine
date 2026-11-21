# Measured guyed telecom mast CAD

In Project Wizard choose **Infrastructure / Public Works → Energy / utilities / communications → Telecom Tower → Telecom tower: measured guyed mast siting**. This opt-in mode uses a cardinally aligned rectangular or square plot, a blank arrangement or Outdoor Yard, and New Design, Concept Design, Site Development or Feasibility Study. Leave building floors, separate Parking and Space selections empty. The ordinary brief and surveyed telecom duct-bank mode are unchanged.

Enter the mast centre and three anchor locations, the common mast attachment height, each signed anchor attachment level, and the square sizes of the pad and anchor reserves. Plan coordinates are measured east and north from the southwest plot corner. Elevation zero is **the mast base**, not the plot corner. The four squares are aligned with the plot. The entire squares must fit the supplied setbacks (front = south, left = west), with no positive-area overlap. Touching at an edge or corner is allowed. The guy spans are projections between centres, not plan clearance envelopes.

For each anchor, the app checks that it is off the mast centre and below the common attachment. If `R` is the horizontal mast-to-anchor distance and `H` is attachment height minus anchor level, the angle above horizontal is `atan2(H, R)` and the straight chord is `√(R² + H²)`. The angle must fit the entered range. Azimuth is clockwise from north as seen from the mast. The largest sorted gap **including the wrap through 360°** must fit the submitted limit. The input range for that limit is 120° to 179.999°, a geometric distribution constraint, not a structural criterion. Length inputs round to mm before checks; angles are checked before display rounding.

The editable **DXF** shows the plot, supplied setback limits, reserves and projected guy spans in local mm. The **CSV** shows each anchor's plan coordinates and level, run, azimuth, angle and straight chord. Geometric conflicts keep the brief accessible in Projects with a reason, without exports or generic CAD fallback.

Example: a mast at `(30,30)` m with attachment at `+15 m` and anchors `(30,50,0)`, `(48,18,+1)`, `(12,18,−1)` m gives a **123.690°** largest azimuth gap. The north anchor has a **20 m** run, **36.870°** upward angle and **25 m** straight chord.

This is geometric siting only. No loads, cable sag, tensions, cut lengths, ground clearance, foundation or anchor design, fall zone, RF exposure, permitting or construction approval is assessed.
