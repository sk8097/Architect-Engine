# High-rise concept planner

Open **Projects → High-rise planner (up to 100 levels)**, or select **Special / Complex → High-complexity buildings → High-Rise / Supertall Building** in New Project.

1. Enter the total level count (2–100 inclusive; level 1 is ground), measured rectangular plot, rectangular common floor plate, west/south offsets, and ground entrance side. Dimensions are entered in metres and stored as integer millimetres.
2. Enter your source for the core/circulation dimensions, wall thickness, corridor and door widths. Add stair, lift and shaft reserves with a minimum clear width and exact depth. The app does not determine the number or engineered size of these components; at least one of each is a data requirement for this planner, not a code rule.
3. Assign all levels to non-overlapping contiguous ranges. Add room or zone dimensions once per range. Optional exterior window width is user-supplied. The solver places rooms along a straight corridor on two sides, expands widths to the lane width, and preserves depths. The common core stays in exactly the same locations. An entry sheet is split off for ground when a range includes it.
4. **Save & generate CAD** validates the full set. Missing levels, overlaps, widths that don't fit or unplaceable depths block the export and report the problem. The result shows a floor selector, per-floor sqft (gross plate, planned incl. walls/core, unallocated), zoomable drawing, floor schedule, and an editable layered DXF for either the selected sheet or all sheets arranged in model space. Reopen or edit from Projects. Layout is deterministic and computed locally; no external CAD engine or hardware is required.

## Scope

This is a concept generator for a **single common plate and aligned core**, not a general high-rise design engine. Different plate shapes/sizes (podium, setbacks, offsets by floor), basements, detailed stairs/lifts/shafts, parking circulation or stall geometry, egress design, floor-to-floor heights, fire refuge strategy, structural/MEP design and statutory checks are not generated. A parking-labeled rectangular zone is only that—not a parking design. Unallocated area is geometric residue, not necessarily usable space. Rejected dimensions are not evidence that a different layout could not work. Specialist verification is always pending.
