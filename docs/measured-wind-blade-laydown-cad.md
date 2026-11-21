# Measured wind-blade laydown CAD

In Project Wizard choose **Infrastructure / Public Works → Energy / utilities / communications → Wind Support Facility → Wind support: measured blade laydown and pad reserves**. Use a cardinally aligned rectangular or square plot, a blank arrangement or Outdoor Yard, and an early design or site-development action. Leave floors, separate Parking and Space selections empty. The ordinary brief and other equipment-yard options are unchanged.

The template uses a **symmetric plan envelope**, not the true blade shape. Give its root, widest station and tip widths, and the widest station's chainage. Width interpolates linearly on each side of that station. The south root is chainage zero, the tip is north, and zero tip width gives a point. Enter the centres, equal along-axis length and individual widths of two rectangular pad reserves. Each pad must be entirely within the blade chainage interval, and the pads must have at least the separately supplied positive gap.

The width check uses the **widest blade section anywhere over each pad**. The maximum of the linear segments occurs at a pad end or the widest blade station if it lies inside the pad. The geometric margin on each side equals half the difference between pad width and that local maximum. The site footprint encloses the widest of the blade and pads plus side reserves; the blade length plus end reserves defines the depth. Plot setbacks use west as left and south as front. Measured dimensions round to mm; half-mm pad endpoints and unrounded interpolations are used for checks.

Export an editable **plan DXF** in local mm and **pad schedule CSV** with along-blade ends, critical chainage, maximum width and minimum each-side margin in metres. Conflicts leave the brief accessible in Projects with a reason and no export or generic fallback.

Example: a **60 m** blade envelope with 4 m root, 6 m at Ch 12 and 0.4 m tip; two 4 m long pad reserves at Ch 12/42 with widths 7/4 m. The minimum per-side margins are **0.500 m at Ch 12** and **0.633 m at Ch 40**; the clear pad gap is **26.000 m**. With 2 m side and 3 m end reserves the full envelope is **11 × 66 m**.

This is geometric pad reservation only. It does not verify manufacturer support points, contact, blade deflection, bearing, wind, lifting, transport, access or safe handling.
