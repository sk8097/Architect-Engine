# Architect Engine — 10-Scenario Pilot Acceptance Criteria

## Scope
Validate 10 farmhouse requirement combinations before scaling the template library. The scenarios in `test-scenarios.json` are inputs, not certified plans. Dimensions in the selection catalogue are feet; convert to millimetres once, at the input boundary, and retain explicit units in metadata.

## Required output per scenario
- Canonical JSON geometry
- SVG rendered from that geometry
- PNG preview rendered from that SVG
- DXF generated from the same canonical geometry
- Validation report with individual checks, engine/schema versions, content hashes, and a final status

## Mandatory checks
1. Input schema and unit conversion.
2. Plot boundary and setback/buildable-area checks when a ruleset is configured.
3. Room bounds, actual clear dimensions, wall thickness, and expected-dimension reconciliation.
4. Door/window intervals intersect the correct wall and do not conflict with other openings.
5. Door swing and circulation checks.
6. Furniture containment and collision checks.
7. Multi-floor stair/access consistency for G+1 and above.
8. SVG parses; PNG decodes and is not clipped; DXF parses and preserves units/coordinates.
9. Duplicate detection on canonical geometry plus meaningful design metadata.
10. Watermark is present on free preview; clean paid assets are not exposed publicly.

## Result statuses
- PASS: every mandatory automated check passed.
- REVIEW: ambiguous rule or manual architectural review required.
- REJECT: mandatory geometry/schema/export check failed. Store a machine-readable reason.
- NOT_RUN: test has not been executed.

Do not convert a rejected scenario into a successful image by hiding geometry errors. A scenario can be correctly rejected when its requirements cannot fit.

## Accuracy gate
Do not use “99% accuracy” as a subjective visual rating. Track:
- Geometry pass rate = scenarios passing mandatory geometry checks / scenarios run.
- Dimension correctness = verified dimensions / dimensions checked.
- Opening correctness = correctly placed openings / openings checked.
- Export parity = outputs whose geometry matches canonical JSON / exports checked.
- Rendering integrity = valid, unclipped PNG/SVG previews / previews checked.
- Scenario acceptance = scenarios meeting all required checks / scenarios run.

For a 10-scenario pilot, report raw counts as well as percentages (for example, 10/10); a 99% target cannot be meaningfully demonstrated by only 10 samples. Require 10/10 passing on deterministic checks before scaling, and keep a larger independent validation set before claiming ~99% reliability.

## GitHub review checklist
- [ ] Each scenario has a stable ID.
- [ ] Inputs and units are explicit.
- [ ] Every generated asset is linked to its source scenario and geometry hash.
- [ ] Failed scenarios include reproducible rejection reasons.
- [ ] SVG, PNG, JSON, and DXF are all inspected.
- [ ] No plan is labelled code-compliant or construction-ready without ruleset verification and appropriate professional review.
