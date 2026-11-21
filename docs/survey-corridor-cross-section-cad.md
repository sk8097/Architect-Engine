# Surveyed corridor cross-section CAD

Choose **Infrastructure → Transport → Road, Street, Footpath or Cycle Track**. Under **Corridor drawing**, select **Cross-section: surveyed ground and proposed surface**. This draws one transverse section, independent of corridor plans and longitudinal profiles. Leave structures, parking and separate Space selections empty.

Supply the chainage, survey/benchmark reference and two lists of `offset,level` pairs in metres. Use one line per pair or separate pairs with semicolons. Looking toward increasing chainage, left is negative, centreline is 0 and right is positive. Offsets in each list must be strictly increasing. Enter up to 150 surveyed points and 80 proposed points at millimetre precision. The design must straddle the centreline and the survey must cover its full width; it can extend farther for context. The app does not extrapolate the survey or find tie-ins outside the design limits.

For a quick check at chainage `125.250 m`, use ground `-6,100;8,100` and design `-4,99;0,101;6,98`. Inside the design width, the two profiles cross at offsets −2 m and +2 m. The app reports **5.000 m² cut** and **2.000 m² fill**. Each profile is interpolated linearly between entered points. Areas integrate the true vertical differences, splitting wherever those differences change sign. Proposed slopes are signed from left to right.

Save to preview or reopen **Corridor cross-section CAD** in Projects. Valid sections export an editable DXF: X is signed offset in millimetres; Y is level minus the labelled plot base, in millimetres, multiplied by the selected 1×, 5× or 10× vertical scale. Ground, proposed surface, axes and cut/fill marks use separate layers. Exaggeration changes the drawing only, not slopes or areas. An invalid brief stays saved without DXF or plan-view zoning fallback.

This is a single section, not an earthwork quantity estimate in cubic metres. It does not design pavement, drainage, grading tie-ins or regulatory crossfall limits.
