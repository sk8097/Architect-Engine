# Detention / retention basin CAD

Choose **Infrastructure → Water / wastewater / stormwater → Detention/Retention Pond → Automatic drawing → Detention / retention basin: plan, section and storage**. Use **Storage** or **Drainage System**, no floors or parking, and leave separate Space selections empty. The plot must be a measured rectangle or square aligned with the cardinal axes. Width is west–east, depth south–north; the optional setbacks use south as front and west as left.

Enter the basin bottom width and length, the two pairs of opposing side slopes as horizontal distance per unit vertical, and the inner crest offsets from the west and south plot edges. Enter all elevations on one stated datum: **floor ≤ normal pool < design high water < inner crest**. To model a dry basin use the floor elevation as normal pool. The template draws only the inner basin; outside slopes, berm width, fencing and access are not included in the geometry.

At height `h` above the floor, the water surface is `(W + 2*sx*h) × (L + 2*sy*h)`. The app integrates this area up to each stage. Active storage is the difference between design-water and normal-pool storage, not total storage below design water. Freeboard is the vertical difference between crest and design water. Supply your required active-storage target and minimum freeboard; both must fit, as must the inner crest footprint and entered setbacks.

Example: on a **50 × 45 m** plot, use a **12 × 20 m** bottom and slopes of **3H:1V east/west** and **2H:1V north/south**. Offset the crest 5 m west-to-east and 6 m south-to-north. Use levels **100.000 floor, 101.000 normal, 102.000 design, 102.500 crest**. The inner crest is **27 × 30 m**, normal-pool storage is **332 m³**, high-water storage is **880 m³**, and active storage is **548 m³** with **0.500 m** freeboard.

Save to preview the measured local plan, true-scale west-to-east section and stage–storage schedule. Both sheets export as layered editable DXFs. The section includes stage levels, surface areas and storage, and uses the floor as its vertical origin. Reopen from **Detention basin CAD** in Projects. A failed fit preserves the brief but blocks both files.

This is a geometric check, not hydrologic routing, inlet/outlet or spillway design, an excavation estimate, a geotechnical or safety assessment, or an approval drawing.
