# Measured aquaculture pond CAD

In the Project Wizard choose **Rural → Farm / farmhouse / agricultural estate → Fish Farm/Aquaculture** and **Farm: measured aquaculture pond and geometric water volume** under Automatic drawing. Use Production Site (or a blank arrangement), an early design or site-development action, and a cardinally aligned rectangular or square plot. Leave floors, separate parking and the Space program empty.

Enter the bottom width (east–west) and length (south–north), rim rise from the level bottom, equal horizontal side run on all four sides, and water depth above the bottom. Enter a uniform reserve beyond the rim and locate its southwest corner with west/left and south/front offsets. All four setbacks apply to the *entire* envelope, not only the waterline or rim. Linear inputs are normalized to millimetres; derived waterline intersections are not snapped to whole millimetres.

At elevation `z`, each toe edge moves out by `run × z / rimRise`. The horizontal area `A(z)` is the product of the two enlarged bottom dimensions. With water depth `h`, volume is exactly `h × (A(0) + 4 × A(h/2) + A(h)) / 6` for this quadratic area function. The mode checks the submitted minimum `H:1V` ratio, freeboard and volume, all inclusive at equality. Water must be strictly below the rim.

The editable local-mm plan DXF shows the plot, reserve, rim, waterline, bottom toe and west–east section cut. The separate true-scale A–A DXF has the west envelope edge at horizontal zero and level bottom at elevation zero. Both are available via the saved project's **Aquaculture pond CAD** action. A failed brief stays saved and shows the reason without either DXF or generic zoning fallback.

## Check case

A 12 × 20 m bottom, 2 m rim rise, 4 m side run, 1.5 m water depth and 1.5 m reserve on every side give a 20 × 28 m rim and **23 × 31 m** full envelope. Water covers **468 m²** (18 × 26 m); volume is **522 m³**. Freeboard is **0.500 m**, and the side slope is **2H:1V**. Offsets of 2 m west and 3 m south fit exactly in a 29 × 38 m plot with 4 m east and north setbacks.

Geometry only: this does not verify soil or bank stability, earthworks quantities, liners, drainage or overflow, water quality, usable stocking capacity, or operating approval.
