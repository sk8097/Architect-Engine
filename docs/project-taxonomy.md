# Project taxonomy and requirements intake

The New Project wizard captures a project brief. Selectable types and requested outputs are **not** availability, approval, or engineering claims.

## How choices are organized

- [`project_taxonomy.dart`](../lib/data/project_taxonomy.dart) contains the eight categories, scoped type IDs, known configurations and space catalogues. New options are added under the existing relevant parent where possible. Farmhouse as a dwelling and farmhouse as an operating farm are intentionally separate scopes.
- [`project_requirements.dart`](../lib/data/project_requirements.dart) defines typed fields, units, validation, applicability, and explicit option IDs. Facility inputs inherit a shared profile and can add type-specific prompts. For example, a multiplex asks for screens and seats; cold storage asks for chambers and temperature zones; roads and bridges use alignment data and do not ask for a building footprint.
- Custom type and configuration require a description; custom spaces require a distinct name. Known options should be added to the registry rather than handled solely through Custom.

## Wizard sections

1. Category, subcategory, type and configuration.
2. Space program: quantity, room priority, sizes and area unit, occupancy, adjacency/separation, access, daylight, ventilation, services, equipment and specialist review notes. Entries marked Excluded remain in brief metadata, but are omitted from active quantities and cannot be an adjacency target.
3. Project information, site/plot or alignment, jurisdiction, rule reference and constraints.
4. Facility, technical and design requirements: common prompts plus profile/type-specific inputs; Vastu is advisory.
5. Budget, schedule, alternatives and requested deliverables, then review. Unsupported formats are marked unavailable.

Changing category, subcategory or type clears its dependent configuration, facility fields and space program. Common information is retained. Hidden/inapplicable responses are omitted from the saved brief. Survey boundary notes are captured as text, not as validated polygons. Optional missing values are not guessed; review surfaces major gaps. Field and cross-field validation catches examples such as a BHK/bedroom mismatch, an incomplete rectangular measurement pair, negative counts, conflicting room adjacency and reversed area ranges. It does not certify feasibility.

## Storage and compatibility

- Type identity is `(categoryId, subcategoryId, typeId)`. Versions and option IDs, not labels, identify selections. The separate requirements schema stores typed common/facility answers and per-space details; existing project briefs still load. Unknown schema versions are not editable in the wizard.
- Units shown in forms are the units of the stored values. Plot width and depth in the existing project model are in feet; the room area unit is stored with the room record. A future canonical geometry model must explicitly normalize these inputs to millimetres at its boundary.
- Authority inputs are user-supplied. Providing a reference is not verification. Formal rule-set checks and file-backed surveys are not implemented. Saving a supported 1 BHK or 2 BHK brief automatically opens a concept CAD plan with DXF export or a blocking explanation. See [automatic floor plan](automatic-floor-plan.md). The separate CAD editor is unchanged.
