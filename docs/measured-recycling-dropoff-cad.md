# Measured recycling drop-off CAD

In Project Wizard choose **Infrastructure / Public Works → Public realm / landscape / waste → Recycling Centre → Recycling centre: measured container drop-off**. This opt-in mode uses a cardinally aligned rectangular or square plot, a blank arrangement or Support Facility, and an early design or site-development action. Leave building floors, separate Parking and Space selections empty. The ordinary brief and the composting windrow mode are unchanged.

- Supply a rectangular container footprint, the clear gap between containers, a clear end reserve per side, the minimum and maximum bay counts, and the south offset of the whole envelope. Container fronts face the **south public apron**; their collection faces open toward the **north collection aisle**. The two continuous clear strips span the full width including both end reserves. Their depths are checked against independent submitted minimums.
- Plot width runs west–east, depth south–north. Setbacks use west as left and south as front. `usable width = plot width − left setback − right setback`. The largest count satisfying `2 × end reserve + count × frontage + (count − 1) × gap ≤ usable width` is capped at the submitted maximum. If fewer than the required minimum fit, neither export is available. The row is centred within that usable width, not on the overall plot centreline.
- The envelope depth is apron depth + container depth + collection aisle depth. The full envelope must lie within the front and rear plot limits at the nominated south offset. Metric inputs are rounded to mm for fitting; centring can produce half-mm coordinates.

**Exports:** editable plan DXF in local mm and bay schedule CSV with footprint coordinates in local metres, public face and collection face. Both start at the southwest plot corner. A geometry failure leaves the brief accessible in Projects with the reason but without export or generic fallback.

**Example:** on a 29.001 × 16 m plot with 2/3 m west/east setbacks and 2/3 m front/rear setbacks: 3 × 3.2 m containers, 0.6 m gaps, 1.5 m end reserves, 2.5 m public apron and 5.3 m collection aisle give **6 bays in a 24 × 11 m envelope**. The first container starts at `(3.5005 m, 4.5000 m)`.

These are geometric reserves only, not barriers or traffic-control measures. The drawing does not check approach routes, vehicle turning, parking, accessibility, container handling, waste capacity, drainage or regulatory approval.
