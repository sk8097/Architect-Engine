# Surveyed longitudinal profile CAD

Under **Infrastructure / Public Works → Transport infrastructure**, select **Road, Street, Footpath or Cycle Track**. In Configuration choose **Corridor drawing → Longitudinal profile: survey levels and proposed grades**. This is a standalone vertical profile, not a plan-view alignment. It uses no generic ROW width, XY coordinates or separate Space selections.

In Site, supply the common benchmark/datum reference. Paste 2–150 **ground** `chainage,level` pairs and 2–50 **proposed** `chainage,level,curve_length` triples in metres (up to three decimals), one per line or separated by semicolons. Both lists have increasing chainages and must start and end at the same stations. Use zero curve length at endpoints or a straight grade break; a positive length is a symmetrical parabolic vertical curve centred on that grade intersection. The app blocks overlap and insufficient chainage. Sample profile span is capped at 20 km.

Example:

- Ground `500,100;525,102;540,105;550,103;560,104;575,101;600,100`
- Proposed `500,100,0;550,105,40;600,100,0`

The 40 m crest transitions between +10% and −10%, with tangent points at 530 and 570 m. At chainage 550 m the true proposed level is 104 m (the intersection of the unrounded tangents is 105 m). Against ground at 103 m, the vertical difference is 1 m fill. These values illustrate the calculation, not recommended road grades.

**Save** opens the profile and the true-level station/curve schedules, or explains why DXF is blocked while retaining the brief. Reopen from Projects. Export editable DXF with separate ground, grade, station, cut/fill and vertical-curve marker layers. The grade profile uses editable chords within 5 mm of the analytic curve vertically before display scaling, and station calculations use the analytic curve. X is true chainage in millimetres; Y is level above the stated plot base in millimetres, multiplied by the chosen vertical exaggeration (1×, 5× or 10×). Neither axis represents surveyed map coordinates.

No earthwork volumes, grade compliance, stopping/sight distance, drainage, pavement or construction design is verified.
