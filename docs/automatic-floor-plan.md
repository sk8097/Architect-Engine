# Automatic floor-plan preview

The first offline generator starts after a successful local save for **Residential → House / low-rise dwelling → Independent House → 1 BHK**. It replaces the wizard with the result. The project menu reopens the preview from the saved brief, using the current generator version; it does not store a frozen drawing. All other profiles can still be saved without a drawing.

## Supported inputs

- Measured rectangular or square plot: frontage and front-to-back depth in feet, normalized to integer millimetres. Select a cardinal front-facing side. The compass is north-up in the preview. An explicitly selected road edge must match that side.
- One above-ground floor, no basement, mezzanine or parking, with one bedroom, living room, closed kitchen, shared bathroom and connected entry passage. These are the selected profile's base spaces; extra rooms are not silently dropped.
- Supplied setbacks constrain the footprint on their respective sides. Supplied coverage or FAR caps are used as concept limits, not verified rules. When a setback is missing, that side is limited by the plot edge in the search and the preview warns that the setback was not checked.
- Room minimum/maximum areas, clear width and length (across frontage and front-to-back), and wall adjacency/separation for included spaces are hard constraints. Room and built-up area targets are preferences; a warning appears when the template cannot match them closely. Other brief fields are retained, and the preview warns that unmapped preferences/technical inputs were not evaluated.

The layout search is intentionally limited to a single template family and known profile; a failure means no supported template fit, not that the site is undevelopable. Canonical geometry uses disjoint room, wall and opening rectangles; validation checks containment, coverage, overlaps, and door connectivity from the entrance. This is a concept, not structural, accessibility, fire, daylight or statutory validation. DXF and PDF export are future work for this preview flow.
