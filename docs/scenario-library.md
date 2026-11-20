# Scenario Library

Open **Projects → Scenario Library** to browse the complete existing project taxonomy as separate entries. Search by project type, category, configuration, floor or parking. Category and generation-status filters can be combined.

- Each category/group/type/configuration path is an independent scenario, including controlled Custom and a no-configuration entry. Its stable ID is derived from taxonomy IDs, never from display names.
- Low-rise residential room/BHK configurations also list separate ground-floor and G+1 variants for each of the four parking choices. These are catalogue records, not cloned drawings. Plot shape, dimensions and frontage remain user inputs rather than a static copy of the same scenario for each dimension.
- **CAD supported** means the exact variant has an implemented concept generator. A rectangular/square plot, a cardinal frontage and other fit checks are still required. **Input needed** identifies the parent of a supported variant, and **Brief only** means generation is not currently implemented. The ten implemented paths are explicitly registered, not inherited by a similar-looking type.
- Selecting a row opens a new brief with its path (and variant inputs when present) preselected. The user may change them. Saving derives the actual scenario ID from the final selection. Older saved briefs do not require migration.

The library ships all known catalogue entries together without claiming that every entry generates. Engine upgrades can assign additional scenario IDs to validated generators without changing other entries.
