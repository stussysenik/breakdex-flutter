# Lab Data Model

## ADDED Requirements

### Requirement: Lab entity persistence
Labs (projects and sets) are stored in a `labs` table with UUID primary key, name, type (project/set), status (idea/attempting/landed/clean), optional markdown notes, and timestamps.

#### Scenario: Create a new lab project
Given a user creates a lab named "Learn Air Flare" of type "project"
When the lab is inserted
Then it appears in watchAll stream with status "idea" and createdAt set

#### Scenario: Create a new battle set
Given a user creates a lab named "Round 1" of type "set"
When the lab is inserted
Then it has labType "set" and can hold ordered moves

### Requirement: Milestone tracking within labs
Milestones are progress markers within labs, stored in `milestones` table with labId FK, title, optional notes, and nullable completedAt.

#### Scenario: Add milestone to lab
Given a lab "Air Flare" exists
When a milestone "First rotation" is added
Then it appears in lab detail with completedAt = null

#### Scenario: Complete a milestone
Given milestone "First rotation" exists with completedAt = null
When user marks it complete
Then completedAt is set to current timestamp

#### Scenario: Delete lab cascades milestones
Given a lab with 3 milestones
When the lab is deleted
Then all 3 milestones are also deleted

### Requirement: Lab-move join table
`lab_moves` links Arsenal moves to labs with sequenceIndex for ordering, using composite PK (labId + moveId).

#### Scenario: Link move to lab
Given lab "Air Flare" and move "Air Flare" exist
When move is linked to lab at index 0
Then lab_moves record is created with addedAt timestamp

#### Scenario: Reorder moves in set
Given a set with 3 moves at indices 0, 1, 2
When move at index 2 is dragged to index 0
Then all sequenceIndex values update to reflect new order

### Requirement: Lab entries (daily log)
`lab_entries` stores daily log entries with optional lab association, markdown content, optional video, and timestamp.

#### Scenario: Create standalone log entry
Given no lab is selected
When user writes "Good practice session today"
Then entry is created with labId = null

#### Scenario: Create lab-attached entry
Given lab "Air Flare" exists
When user writes "Got 2 rotations!" attached to that lab
Then entry appears in lab's timeline

### Requirement: Achievement persistence
`achievements` tracks per-move tier progression (seed/sprouting/growing/mastered) with moveId FK and unlockedAt timestamp.

#### Scenario: Move creation triggers seed achievement
Given a new move "Toprock" is created
When achievement backfill runs
Then an achievement with tier "seed" is created for that move

### Requirement: Aura link persistence
`aura_links` stores directional move transition affinities (natural/possible/stretch) with composite PK (fromMoveId + toMoveId).

#### Scenario: Rate a transition
Given moves "Toprock" and "6-Step" exist
When user rates Toprock → 6-Step as "natural"
Then aura_links record is created

### Requirement: Aura presets
`aura_presets` stores named style profiles with isDefault flag.

#### Scenario: Create aura preset
Given user has rated several transitions
When user saves preset "Power Style"
Then preset appears in picker with isDefault = false

### Requirement: Schema v12 migration
Migration from v11 to v12 creates all 7 new tables, adds cascade delete triggers, and backfills achievements for existing moves.

#### Scenario: Fresh install
Given a fresh database
When app launches
Then all 7 tables exist and are empty

#### Scenario: Upgrade from v11
Given a v11 database with 10 moves
When migration runs
Then 7 new tables are created and 10 seed achievements are backfilled
