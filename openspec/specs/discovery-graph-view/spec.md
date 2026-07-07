# discovery-graph-view Specification

## Purpose
TBD - created by archiving change add-discovery-graph-interface. Update Purpose after archive.
## Requirements
### Requirement: Interactive node-edge graph with live layout

The system SHALL render the projected graph as an interactive node-edge diagram with a dynamic
force-directed layout, so the owner can see relationships across the whole library at once.

#### Scenario: Graph renders the library
- **WHEN** the owner opens the graph view with a non-empty library
- **THEN** nodes and edges from the projection are displayed
- **AND** the layout settles into a stable arrangement without manual intervention

#### Scenario: Empty library
- **WHEN** the owner opens the graph view with no moves or combos
- **THEN** an explanatory empty state is shown instead of a blank canvas

### Requirement: Filter by node and edge kind

The graph view SHALL let the owner filter visible nodes and edges by kind (e.g. show only moves and
`aura-affinity` edges), so the working set stays legible.

#### Scenario: Filter to a single edge kind
- **WHEN** the owner enables only the `aura-affinity` edge filter
- **THEN** only aura-affinity edges and the nodes they connect remain visible

### Requirement: Focus and neighborhood navigation

The graph view SHALL let the owner focus a node to reveal its immediate neighborhood (directly
connected nodes), so a large graph can be explored locally.

#### Scenario: Focus reveals neighbors
- **WHEN** the owner focuses a move node
- **THEN** the view emphasizes that node and the nodes directly connected to it

### Requirement: Click-through to detail and playback

Selecting a node SHALL navigate to that entity's existing detail/playback surface, reusing the
current viewer rather than introducing a parallel one.

#### Scenario: Open a move from the graph
- **WHEN** the owner selects a move node that has video
- **THEN** the existing playback surface opens for that move

#### Scenario: Graph view is read-only
- **WHEN** the owner interacts with the graph view (filter, focus, select)
- **THEN** no underlying entity is modified by those interactions

