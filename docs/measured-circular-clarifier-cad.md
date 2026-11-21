# Measured circular clarifier CAD

Choose **Infrastructure / Public Works → Water / wastewater / stormwater → Sewage Treatment Plant → Sewage treatment: measured circular clarifier geometry**. Use a cardinally aligned rectangular or square plot, a blank arrangement or Plant, and an early design or site-development action. Leave building floors, separate Parking and Space selections empty. Other water infrastructure modes are unchanged.

The inside diameter includes the peripheral launder. Under this concentric, level-floor model, the **nominal weir radius** is the inside radius minus launder width. The annular settling area is `π × (weir radius² − outside feedwell radius²)`; the nominal weir circumference is `2π × weir radius`. The app checks the supplied minimum annular area and radial width. Weir circumference is not an effective discharge length or capacity calculation.

Levels use the basin floor as zero. Water and nominal weir share an elevation; rim minus water must meet the supplied freeboard. The launder bottom must be below the weir. The feedwell lower edge is below water and its upper edge is above water. Wall thickness and service reserve enlarge the circular envelope. Locate the full circle by its offsets from the west and south plot edges. The west/east/south/north extremities must meet setbacks. Metric lengths round to mm; radii and centres retain half-mm precision. Area is checked before display rounding.

The **plan DXF** uses editable concentric arc entities. The **true-scale diametral section DXF** shows the nominal water level, schematic launder, exterior feedwell limits and basin outline. Both are in local mm. Conflicts preserve the brief in Projects with the reason and no export or generic fallback.

Example: **20 m** inside diameter, a **1 m** launder and a **4 m** feedwell give **7.000 m** clear radial width, **241.903 m²** annular area and **56.549 m** nominal weir circumference. A 0.3 m wall and 1.7 m reserve give a **24.000 m** envelope diameter. With rim at 4 m and water at 3.4 m the freeboard is **0.600 m**.

This is geometry only. No process sizing, surface loading, weir hydraulics, inlet/outlet details, sludge removal, equipment, structure, operating safety or regulatory approval is assessed.
