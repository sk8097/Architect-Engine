# Measured skate transition CAD

Choose **Infrastructure / Public Works → Public realm / landscape / waste → Public Park or Playground** and opt into **Skate: measured circular transition and deck**. Use a cardinally aligned rectangular or square plot, a blank arrangement or Public Open Space, and an early design or site-development action. Leave building floors, separate Parking and Space selections empty. Other park and playground drawing options remain unchanged.

The template uses one constant-width strip, with a flat south run-in, circular transition and flat north deck at the lip level. Enter radius `R` and lip rise `H` above the run-in datum. The transition is tangent to the run-in and restricted to `0 < H ≤ R` so it never overhangs. Its horizontal run is `√(H(2R − H))`; its lip tangent is `atan2(run, R − H)` and its arc length is radius times the angle in radians. The deck meets the arc at the lip point but is not tangent to it. There is no coping detail.

The mode checks the submitted maximum lip tangent angle, minimum flat run-in and deck lengths, and fit of the whole surface and its end/side reserves. Plan reserves are geometric offsets only. Plot width is west–east and depth south–north; setbacks use west as left and south as front. The measured inputs round to mm, but the derived curve and envelope are checked before display rounding.

The editable **plan DXF** shows the envelope and the three surface zones. The **true-scale profile DXF** uses a native circular arc; chainage starts at the south start of the run-in and the run-in level is zero. Both files are in local mm. Conflicts preserve the saved brief in Projects with the reason and block exports and generic fallback.

Example: **3.000 m radius** and **1.200 m rise** give a **2.400 m** horizontal run, **2.782 m** arc length and **53.130°** lip tangent. A 4 m wide strip with 4 m run-in, 1.8 m deck, 0.75 m side and 1 m end reserves has a **5.500 × 10.200 m** envelope.

This is geometry only. It does not check rideability, impact zones, barriers, coping, materials, drainage, supporting structure or safety and construction approval.
