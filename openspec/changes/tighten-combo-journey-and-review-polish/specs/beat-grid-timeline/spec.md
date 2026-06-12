# beat-grid-timeline

## ADDED Requirements

### Requirement: Proportional visual weight
The beat grid SHALL render one block per combo move with width proportional to its beat count, so a move's share of the combo is readable as visual weight. Blocks SHALL be at least 44pt tall. The active block SHALL be filled with the accent color and animate its state change; inactive blocks use surface-container fill with a hairline border.

#### Scenario: Proportion readable
- **WHEN** a combo has moves of 4, 2, and 8 beats
- **THEN** the third block is twice the width of the first and four times the second

### Requirement: Legible labels with graceful degradation
Each block SHALL show its beat count (≥13px, bold, tabular figures) and the move name (≥10px, single line, ellipsized). When a block is too narrow (roughly under 44px) the name SHALL be hidden while the count remains — small text SHALL never be shrunk below 9px to fit.

#### Scenario: Narrow block degrades
- **WHEN** a 1-beat move renders in a 10-move combo on a phone width
- **THEN** the block shows only its count, with no sub-9px text anywhere in the grid

### Requirement: Beat ticks aligned by construction
The tick row SHALL allocate one equal-flex slot per beat — the same flex space as the blocks — so ticks and block boundaries always align at every width. Every 4th beat tick SHALL be emphasized with its beat number (4/4 count); other ticks are hairlines. The grid SHALL NOT render decorative elements that carry no information.

#### Scenario: Alignment at any width
- **WHEN** the grid renders at 320pt and at 560pt width
- **THEN** the tick under beat 5 sits exactly at the boundary between a 4-beat block and its successor in both cases
