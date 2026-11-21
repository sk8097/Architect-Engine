# Measured district cooling pipe loop CAD

Choose **Infrastructure / Public Works → Energy / utilities / communications → District Cooling → District cooling: measured pipe loop and clearance band**. Use a cardinally aligned rectangular or square plot, a blank arrangement or Outdoor Yard, and an early design or site-development action. Leave floors, separate Parking and Space selections empty.

The template draws one level U-offset with west/east tie-ins on a common baseline. Between the leads, four equal 90° centreline bends connect two equal north–south straight legs and one north link. Enter the straight lengths **between tangent points**. The horizontal tie-in separation is `west lead + east lead + 4 × radius + north link`; the northward centreline reach is `2 × radius + leg`; total centreline length is `west lead + east lead + 2 × leg + north link + 2π × radius`.

The effective pipe outside diameter includes insulation if present. The offset to the clearance boundary is `q = OD/2 + clearance`. The centreline radius must meet the submitted minimum and be strictly larger than `q`. The pipe edges and clearance edges are exact parallel offsets with concentric bend arcs. The clearance band extends `q` beyond both tie-ins with square caps; the resulting fitting box adds `2q` to both the horizontal separation and northward reach. Offsets place that box from west and south. Setbacks use west as left and south as front. Inputs round to mm, retaining half-mm radius offsets and exact derived arc lengths.

Export the **editable plan DXF** (local mm) and **bend schedule CSV**. The schedule follows the route west to east, with cumulative centreline chainage, segment lengths, bend directions and radii in metres. A failed geometry check leaves the brief in Projects with the reason and no exports or generic fallback.

Example: **1.5 m** radius, 4/5 m leads, 3 m legs, 2.5 m link, **0.501 m** OD and **0.500 m** additional clearance yield **26.925 m** centreline length and a **19.001 × 7.501 m** fitting box.

This is geometry only. It does not determine expansion absorption, stresses, supports, anchors, clearance to other services, pressure losses, thermal performance or safe installation.
