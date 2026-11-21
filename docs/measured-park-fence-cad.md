# Measured park fence CAD

Choose **Infrastructure / Public Works → Public realm / landscape / waste → Public Park, Public Garden or Playground**. Opt into **Public space: measured fence panels and gate opening**. Use a cardinally aligned rectangular or square plot, a blank arrangement or Public Open Space, and an early design or site-development action. Leave building floors, separate Parking and Space selections empty. This mode is separate from school fence and playground clearance templates.

Enter fence width and depth **between corner post centres**, the side of the square posts, and the required south gate opening. Measure the gate offset from the southwest post centre to the **west inner face of the clear opening**, not the gate post centre. The gate width is face-to-face. Locate the whole fence footprint from the west and south plot edges. The corner posts add a half post to each side of the centreline rectangle. Setbacks use west as left and south as front.

The five runs are south-west and south-east of the opening, east, north and west. Each gets the fewest equal panels that meet the maximum clear span. For run centre distance `L`, post side `P` and maximum clear span `M`, count `n = ceil(L / (P + M))` gives clear panel span `L/n − P`. If that span is below the submitted minimum, adding more panels only shortens it, so the brief is flagged. Input lengths are rounded to mm; count limits are checked before output rounding and exact half-mm gate centres are preserved. Layouts above 500 panels are outside the scope of this template.

The **editable DXF** uses local mm and shows face-to-face panel spans, shared corner posts, and two gate posts with a clear opening. The **CSV** lists run length, panel count, equal clear span, intermediate posts, and an overall unique post count including the six corner/gate endpoints. Failed checks preserve the brief in Projects with the reason and no export or generic fallback.

Example: **23 × 12 m** post-centre rectangle, 201 mm posts, a **2.000 m** clear gate at a **9 m** offset and allowed panel spans **2–3 m**. The five runs use **3, 4, 4, 8 and 4 panels**: **23 panels**, **24 unique posts**, and a **23.201 × 12.201 m** full footprint.

This is geometric set-out only. No gate swing, hardware, footing design, loads, finishes, ground levels or enclosure safety approval is included.
