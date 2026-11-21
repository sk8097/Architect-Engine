# Measured transformer bund CAD

Choose **Infrastructure / Public Works → Energy / utilities / communications → Transformer Yard** in Project Wizard and opt into **Transformer yard: measured two-plinth bund**. Use an Outdoor Yard or blank arrangement and an early design or site-development action. Leave building floors, separate Parking and Space selections empty. The adjacent battery yard template and generic concept mode are unchanged.

The bund is one rectangular level-floor enclosure with uniform vertical walls. Two solid plinths with identical footprints and independently entered heights are centred side by side west–east. Enter the clear between-plinth gap and submitted minimum clearance, which applies between plinths and to all four inner walls. The full envelope includes the wall thickness and a service reserve on all sides. On the cardinally aligned rectangular or square plot, locate the envelope from west and south; setbacks use west as left and south as front.

At the entered design fill depth `F`, the gross prism is `inside width × inside length × F`. The net geometric containment subtracts `plinth footprint × (min(F, west height) + min(F, east height))`. Only submerged portions displace volume. The rim minus `F` must meet the submitted minimum freeboard, and net volume must meet the submitted target. Metre dimensions are converted to mm before checks; the volume target is compared before display rounding.

The **editable plan and true-scale section DXFs** use local mm. The section cuts west–east through both plinth centres with the bund floor as elevation zero. The fill line does not pass through a plinth at or above the fill level. A failed fit, clearance, freeboard or containment check leaves the brief in Projects with the reason and no export or generic fallback.

Example: a **10 × 8 m** inside bund, 0.25 m wall, 1.25 m reserve, 1.20 m rim and 0.90 m fill gives a **13 × 11 m** full envelope and **0.300 m** freeboard. Two **2 × 3 m** plinths at 0.40 m and 1.10 m heights displace **7.800 m³**, leaving **64.200 m³** net from **72.000 m³** gross.

This is geometric containment only, not an oil inventory/overflow check, rainfall or firewater allowance, drain, liner, permeability, structural, electrical or regulatory design. Unmodelled obstructions and reserved volume are not included.
