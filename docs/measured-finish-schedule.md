# Measured finish schedule

Open **Projects → project menu → Measured finish schedule**. This is a separate takeoff for any saved project, including building, landscape, infrastructure and high-rise projects. You do not have to switch CAD modes. Use **Add measurement** for a face or linear run and tap an existing row to edit it. Rows save with that project; editing the project brief does not change them. A project copy gets its own copy of the schedule. Share the measured rows and material totals as UTF-8 CSV.

- **Faces:** floor, wall, ceiling, roof, façade, paving and coating. Enter measured length × width/height. For a sloped surface use its measured face dimensions, not its plan projection. Break composite faces into separately measured rectangles.
- **Runs:** skirting, trims/edges and linear marking. Enter the actual run length only.
- For repeated identical surfaces, enter the deduction **per item**, a repeat count, and a waste percentage. Use zero for no deduction or no waste. Each row must retain a positive net quantity.
- Use one material code per specification. Codes aggregate case-insensitively, but linear metres and square metres never combine. Use separate codes where specifications differ.

Example: two 4 × 3 m wall faces with a 2 m² opening in each and 10% waste have **24 m² gross, 20 m² net and 22 m² with allowance**. A 5 m linear trim with a 0.5 m deduction per repeat, repeated twice, totals **9 m**, not an area.

This tool does not extract finishes automatically from drawings, infer missing measurements, lay out tile cuts, round stock packages, select products, price work or verify compliance. Recheck measured quantities if the project plan changes.
