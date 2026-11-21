# Measured outdoor football pitch CAD

In Project Wizard choose **Institutional → Sports / recreation / public amenities**, then Stadium, Sports Complex, Sports Club or Training Centre. Opt into **Football: measured pitch, marking arcs and run-off**. Use a cardinally aligned rectangular or square plot, a blank activity setting or Outdoor, and an early design or site-development action. Leave building floors, separate Parking and Space selections empty. The athletics, long/triple jump and other sports options are unchanged.

Enter the pitch dimensions, centred goal-mouth width, goal and penalty area widths and depths, penalty spot distance, three arc radii, side and end run-offs and their submitted minimums. The goal ends face south and north. Plot width is west–east, depth is south–north; setbacks use west as left and south as front. Offsets locate the **full run-off envelope**, not the marked pitch. Inputs round to mm; centred marking coordinates can retain fractional mm.

The plan uses nested boxes sharing each end line and checks widths, depths, the penalty-spot location and marking clearances. Each penalty arc is the portion of the spot circle **beyond the front of the penalty area**. If `d` is the distance from the spot to that front line, and `r` is the penalty arc radius, the arc has sweep `π − 2 asin(d/r)` and the chord endpoints must lie strictly between the penalty-area sides. The centre circle and four corner arcs use editable arc entities. Goal mouths are differentiated end-line segments, not extra lines or goal structures.

The **editable DXF** uses local mm from the southwest plot corner. The **CSV** reports centreline length in metres by marking type. It counts the full perimeter including goal mouths once, includes arcs at their true lengths, and excludes spot drafting symbols and non-marking references. If the layout conflicts with the supplied limits, the saved brief stays in Projects with a reason but no export or generic fallback.

Example: a **68 × 105 m pitch** with 3 m touchline and 5 m end-line run-off gives a **74 × 115 m** envelope. Using 18.32 × 5.5 m goal areas, 40.32 × 16.5 m penalty areas, 11 m spots, 9.15 m centre and penalty radii, and 1 m corner radii gives **716.943 m** of marking centrelines, including **33.889 m** of penalty arcs.

This is measured geometry, not a sports-rules, safety, surface, drainage, goal anchorage or competition approval check. The CSV is not a paint quantity by area.
