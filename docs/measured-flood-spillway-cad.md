# Measured flood spillway CAD

In Project Wizard choose **Infrastructure / Public Works → Water / wastewater / stormwater → Flood-Control Structure** and opt into **Flood control: measured spillway and bed profile** (`cad_output=water_measured_spillway`). Use a cardinally aligned rectangular or square plot, a blank arrangement or Drainage System, and New Design, Concept Design, Site Development or Feasibility Study. Leave building floors, separate Parking and Space selections empty. The detention basin and culvert modes are unaffected.

The spillway runs south to north. Four consecutive plan segments share one centreline: an inlet transition rising to the throat, a flat rectangular crest, a chute widening toward the toe, and a flat apron at the toe width. Either transition may have parallel edges. Enter widths and **horizontal** runs in metres. The inlet bed is elevation zero; the crest elevation is the entered rise, and the toe elevation is rise minus drop, so the toe and apron can finish below zero.

- The two end widths must be at least the throat width. The horizontal crest length must meet the submitted minimum.
- Bed grades are `100 × rise / inlet run` and `−100 × drop / chute run`; the chute limit is a positive magnitude. Each transition's plan taper is `50 × (end width − throat width) / transition run`, the sideways shift per 100 m of run for **one edge**. Both tapers must meet the same submitted maximum.
- The fitting envelope is the axis-aligned bounding rectangle of all four segments, plus the entered reserve on all four sides. Place the envelope by its west and south offsets. Plot width is west–east and depth south–north. Setbacks use west as left and south as front. Stored plot feet are converted to mm; geometry inputs round to mm before checks. Centred edges retain fractional mm if needed.

Two editable DXFs have independent local-mm origins. The **plan** shows plot, full envelope, segment edges and transverse station lines; the **true-scale longitudinal profile** shows the centreline bed and grade breaks. A failed check leaves the brief saved in Projects with a reason and no DXF or generic CAD fallback.

Example: 10/4/12 m inlet/throat/outlet widths, 20/5/15/8 m segment runs, a 2 m crest rise, 3.6 m drop, and 2 m reserve yield a **16 × 52 m** envelope. The inlet rises at **+10%**, chute falls at **−24%**, and edge tapers are **15%** and **26.667%**. The apron is **1.600 m below** the inlet bed datum.

This is geometry only. The plan and profile do not assess discharge, floodwater levels or risk, overtopping, energy dissipation, scour, civil structure or regulatory approval.
