# Surveyed stormwater plan + profile CAD

Select **Infrastructure / Public Works → Water / wastewater / stormwater → Stormwater Drain or Drainage Network**. Under **Drainage drawing** choose **Gravity stormwater: surveyed plan and pipe profile**. Use **Drainage System** or **Network** (or leave Arrangement unspecified). This mode uses one buried, unbranched run, not a complete drainage network or catchment design. Leave separate Space selections empty.

In Site enter the projected grid and common elevation datum/source. Enter 2–60 rows in upstream-to-downstream order as `ID,Easting,Northing,ground,invert` in metres, with up to three decimal places. IDs start with a letter and are unique. Each reach is straight in plan and profile. The same invert continues through each node; drops, branches, pumps and free outfalls are not modelled. Chainage starts at zero and is calculated from cumulative projected plan distances (maximum 20 km).

Supply the measured rise from the invert to the **outside crown**, not a nominal pipe diameter unless it represents that distance, and your minimum geometric fall and cover criteria. The rise is constant throughout the run. Optional intervening samples `chainage,ground level` let you represent dips or hogs between nodes. Ground is linearly joined between the supplied samples and nodes; the app checks cover against that line, not against unsurveyed terrain. It also checks for coincident controls, crossing/overlapping reaches and downstream fall. A failed check retains the brief but blocks both drawings.

Example input (metres):

- Nodes: `A,345000,2110000,101.5,100;B,345040,2110000,101.2,99.6;C,345070,2110040,100.8,99.1`
- Additional ground: `20,100.99;65,100.9`
- Crown rise 0.55 m, minimum cover 0.60 m, minimum fall 1%. Both reaches fall at 1%; the minimum cover is 0.640 m at chainage 20 m. These are demonstration values, not design defaults or recommendations.

**Save** opens the surveyed plan, pipe profile and reach schedule. Select either sheet to export editable DXF. Plan coordinates stay in projected millimetres. The profile X is cumulative chainage in millimetres and Y is height above the annotated plot datum times the selected vertical scale (1×, 5× or 10×; default 10×). Node symbols are not construction dimensions. Reopen **Stormwater plan + profile CAD** in Projects.

This is not hydraulic design. Pipe sizing, tailwater, flood levels, runoff quantities, utility conflicts, crossing clearances, construction, discharge and approvals require a specialist.
