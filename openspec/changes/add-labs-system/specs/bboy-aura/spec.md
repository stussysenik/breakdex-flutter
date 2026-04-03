# Bboy Aura

## ADDED Requirements

### Requirement: Move transition affinity rating
Users can rate the affinity between two moves as natural, possible, or stretch (Pokemon-inspired).

#### Scenario: Rate transition from move detail
Given moves "Toprock" and "6-Step" exist
When user rates Toprock → 6-Step as "natural"
Then aura_links record is created with affinity "natural"

#### Scenario: Update existing rating
Given Toprock → 6-Step is rated "natural"
When user changes it to "possible"
Then the existing record is updated (upsert)

### Requirement: Aura visualization
A radial/graph view shows the user's personal transition style fingerprint.

#### Scenario: Display move connections
Given 3 aura links exist: A→B natural, A→C possible, B→C stretch
When aura view is opened
Then a visual graph shows moves as nodes with colored edges

### Requirement: Aura presets (style profiles)
Users can save and switch between named aura configurations.

#### Scenario: Save current aura as preset
Given user has 10 aura links configured
When user saves preset "Power Style"
Then preset is created and can be loaded later

#### Scenario: Switch active aura
Given presets "Power Style" and "Footwork Flow" exist
When user activates "Footwork Flow"
Then it becomes the default (isDefault=1) and all others become 0

### Requirement: Set Builder integration
The Set Builder uses the active Bboy Aura to suggest compatible next moves.

#### Scenario: Highlight natural transitions in set builder
Given user's active aura has Toprock → 6-Step as "natural"
When Toprock is the last move in a set being built
Then 6-Step is highlighted as a suggested next move
