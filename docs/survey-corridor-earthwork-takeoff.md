# Multi-station corridor earthwork takeoff

Choose **Infrastructure → Transport → Road, Street, Footpath or Cycle Track → Corridor drawing → Earthwork takeoff: multi-station surveyed cross-sections**. Use a new linear concept without structures, parking or separate Spaces.

Enter the survey and benchmark reference, then paste ground and proposed `chainage,offset,level` triples in **metres**, either newline- or semicolon-separated. Group points by strictly increasing station; within a station, offsets must increase strictly. Looking toward increasing chainage, negative offsets are left of the centreline. Both lists must use the same station set and one level datum. Every proposed section must straddle zero and stay inside the surveyed width. Use 2–20 stations within a 20 km span. At each station up to 150 ground and 80 design points are supported.

Example:

- Ground: `100,-6,100;100,8,100;110,-6,100;110,8,100;135,-6,100;135,8,100`
- Design: `100,-4,99;100,0,101;100,6,98;110,-4,101;110,6,101;135,-4,99;135,6,99`
- Cut/fill areas: 5/2, 0/10 and 10/0 m², respectively. The interval lengths are 10 and 25 m. The **estimated totals are 150 m³ cut and 185 m³ fill**.

At each station the app integrates the difference between measured and proposed piecewise-linear profiles, separating cut and fill at surface intersections. For each interval, it averages the two cut areas and multiplies by the chainage difference; it does the same separately for fill. Totals sum the unrounded interval estimates. The average-end-area method estimates only what lies between supplied stations; abrupt or unsurveyed changes can make it inaccurate. No netting, curvature correction, stripping, tie-in, material bulking or compaction is applied.

Save to preview each section and inspect the interval schedule. The editable DXF lays sections out in model-space cells: read X relative to the marked centreline and Y relative to the drawn baseline and stated plot base. Vertical exaggeration applies only to the drawing, not to the quantities. The CSV has one row per interval plus totals, including the endpoint areas used in each interval. Both exports are blocked if a station is invalid; the brief remains saved and can be reopened from **Corridor earthwork takeoff** in Projects. This is a concept estimate, not a field-verified pay quantity.
