# Set Builder

## ADDED Requirements

### Requirement: Horizontal move sequencer
Sets SHALL display linked moves as a horizontal scrollable sequence with drag-drop reordering.

#### Scenario: Display set moves in order
Given a set "Round 1" has 4 moves at indices 0-3
When set detail is opened
Then moves display left-to-right in sequence order

#### Scenario: Drag to reorder
Given a set with moves [Toprock, 6-Step, Air Flare]
When user drags Air Flare before 6-Step
Then sequence becomes [Toprock, Air Flare, 6-Step]

### Requirement: Drag moves from Arsenal
Users SHALL be able to add Arsenal moves to a lab/set via drag-and-drop from the linked moves section.

#### Scenario: Add move to set
Given set "Round 1" exists and Arsenal move "Toprock" is not linked
When user drags Toprock into the set
Then lab_moves record is created at the next available sequenceIndex

### Requirement: Aura-based transition indicators
In set view, adjacent moves SHALL show a colored indicator between them based on the active Bboy Aura affinity.

#### Scenario: Natural transition shows green
Given moves A and B are adjacent in a set
And aura_links has A→B with affinity "natural"
Then a green indicator appears between them

#### Scenario: No aura link shows neutral
Given moves A and B are adjacent with no aura_link
Then a neutral/gray indicator appears between them
