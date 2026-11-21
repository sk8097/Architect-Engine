# Measured battery storage yard CAD

In Project Wizard choose **Infrastructure / Public Works → Energy / utilities / communications → Battery Energy Storage**. On a cardinally aligned rectangular or square plot, opt into **Battery storage: measured equipment yard** (`cad_output=energy_measured_battery_yard`). Use a blank arrangement or Outdoor Yard, and an early design or site-development action. Leave enclosed floors, separate Parking and Space selections empty. This mode doesn't change the generic brief or other energy CAD templates.

- Enter identical rectangular equipment footprints, a position count per row and the maximum positions per group. Two matching rows run south–north. West-row equipment faces east and east-row equipment faces west, toward the central lane. The group count spans both rows.
- A normal gap separates positions within each group. A cross-aisle **replaces** that gap between groups. The final group may be partial; there is no cross-aisle after the last position. Both end reserves remain clear. Each cross-aisle also meets the submitted along-row unit separation minimum. A singleton group has no normal gap to check.
- Enter the actual and minimum widths for unit gaps, the central lane, cross-aisles, the outside-row reserves and the row-end reserves. These are user-supplied clearances, not prescribed design values. Use metres for yard inputs; the generator rounds lengths to mm. Locate the whole yard envelope from the west and south plot edges. Plot dimensions (converted from stored feet) run west–east and south–north. Setbacks use west as left and south as front.

For `n` positions per row, `k` positions per group and `c = floor((n − 1)/k)` cross-aisles, the envelope depth is `2 × end reserve + n × unit width + (n − 1 − c) × regular gap + c × cross-aisle width`. Yard width is `2 × (outer reserve + unit depth) + central lane width`.

The **editable DXF** contains labelled footprints, lane axes, cross-aisles and the full envelope in local mm. The **CSV** lists unit ID, row, group number, footprint bounding coordinates in local metres, and facing. Both use the southwest plot corner as origin. Geometric conflicts leave the saved brief available in Projects with a reason but no DXF, CSV or generic fallback.

Example: seven positions per row, groups of at most three, 2.5 × 6 m units (along × across the row), 1.2 m normal gaps, a 5 m central lane and 3.5 m cross-aisles, with 2 m side and 3 m end reserves, give **14 units in 3 groups**, **2 cross-aisles**, and a **21.000 × 35.300 m** envelope.

This is a static equipment layout, not a supplier layout approval, battery sizing or electrical design, a fire separation or emergency vehicle access assessment, a turning test, or a permit drawing.
