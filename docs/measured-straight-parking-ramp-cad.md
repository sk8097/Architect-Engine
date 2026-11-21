# Measured straight parking ramp CAD

In the Project Wizard, choose **Infrastructure / Public Works → Transport infrastructure → Parking Structure**. On a rectangular or square plot, opt into **Parking structure: measured straight vehicle ramp** (`cad_output=parking_measured_straight_ramp`). Use no arrangement or Linear Corridor; choose New Design, Concept Design, or Feasibility Study. Leave building floors, separate Parking and Space selections empty. The ordinary concept mode, outdoor angled parking, EV layout and public pedestrian switchback ramp are unchanged.

## Measurements and checks

- Give the horizontal rise/run brief: vertical deck rise, horizontal ramp run **excluding** the flat landings, equal horizontal transition lengths at both ends, and two flat landing lengths. The transitions each use half of the constant main grade. The main grade is `100 × rise / (ramp run − one transition length)`; the absolute change at each of the four breaks is half that grade. Both are checked against entered limits (percent and percentage points, respectively).
- Enter clear width, the equal edge reserves and offsets locating the whole strip. Plot width is east–west and depth south–north; vehicle ascent is south to north. The footprint including both flat landings and both edge reserves must fit the plot and supplied setbacks (front = south, left = west). Plot dimensions are converted from stored feet. Geometric inputs in metres are rounded to local millimetres before calculation.
- Supply one linear **centreline** soffit segment by its two chainages and levels. Chainage zero is the south edge of the lower landing, whose level is the vertical datum. The minimum vertical gap over that span is checked at its endpoints and at every ramp break inside it. Nothing is inferred about overhead conditions beyond the submitted span.

Two editable DXFs (plan and true-scale longitudinal profile) use independent local mm origins. The plan shows plot footprint, clear strip edges, grade breaks and ascent; a side marker denotes the soffit span, not its width. The profile shows the driving surface, soffit and measured minimum vertical gap. If a geometric check fails, the saved brief remains available in Projects with the reason and without DXF export or a generic fallback.

Example: 3 m rise over 24 m ramp with 4 m transitions and 4 m/5 m landings gives **15% main grade**, **7.5% transition grade** and **7.5 percentage points** per break. A 4 m clear strip plus 0.5 m each side yields a **5 × 33 m** footprint. Soffit levels 3.25 m at Ch 6 and 5.65 m at Ch 30 yield **2.350 m minimum vertical headroom at Ch 24**.

This is static longitudinal geometry, not a vehicle breakover or swept-envelope test, off-centre clearance check, traffic design, structural or drainage design, or approval. It does not draw parking bays, the deck or the rest of the building.
