# Measured enclosed CAD and straight-corridor bands

## Enclosed CAD

Choose **Measured enclosed floor plan** in New Project's **Automatic drawing** field. Enter the measured rectangular plot and frontage, an explicit building plate and offsets, and user-supplied wall, passage and door dimensions. Add at least one enclosed room and enter clear dimensions in its Space details. An exterior window length is optional and must fit the supplied wall. Exact widths are the default; allowing full lane width is an explicit choice. One storey is supported by this generator; the existing tower generator is a separate common-plate path.

Saving generates a layered, editable DXF and a room schedule or reports why that request could not be solved. The solver places rooms on a central passage, preserves exact depth, and checks plate containment, partition overlaps, connected doors, requested exterior edge, shared-wall adjacency and non-adjacency, and supplied caps. Taxonomy profiles influence the order of public/private/service rooms, not a project type's engineering. Separation is only a non-adjacency check, not a fire, security or clinical separation rating. Supplied targets/preferences are advisory; no specialist performance is certified. A failed detailed generation does not automatically produce a zoning drawing as a substitute.

This is concept CAD for new enclosed rooms, not a fully specialised generator per type. Existing surveyed structures, attached bathroom access, parking/manoeuvring, terrace access, special-purpose safety systems, plumbing, and detailed technical routing are not generated. In exact-width mode an exterior window requires the room to span its lane. Unsupported cases must not be presented as complete designs.

## Straight corridor

A confirmed straight measured corridor can include parallel bands, e.g. `Footway:1.5; Carriageway:6; Footway:1.5` (metres) under Site / plot / land. The specified bands run the length of the supplied station axis and are placed in the entered order, starting at the lower drawing edge. Their cumulative width cannot exceed the measured right-of-way. Optional measured zones are allocated only in the remaining strip. This is a plan representation of supplied dimensions, not a geometric road design: curves, grade, transitions, regulation, and traffic safety are outside its scope.
