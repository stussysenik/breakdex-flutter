# Labs System — Architecture Design

## Data Model (Schema v12)

### Entity Hierarchy
```
Lab (project | set)
├── Milestones (progress markers)
├── Lab_Moves (join to Arsenal moves, ordered)
└── Lab_Entries (daily log / attempts)

Achievement (per-move tier tracking)
├── Seed → Sprouting → Growing → Mastered

Aura_Links (move-to-move transition affinities)
Aura_Presets (saved style profiles)
```

### Tables

| Table | PK | Key FKs | Purpose |
|-------|-----|---------|---------|
| labs | id (UUID) | — | Project/set containers |
| milestones | id (UUID) | labId → labs | Progress markers |
| lab_moves | labId+moveId | labs, moves | Ordered move references |
| lab_entries | id (UUID) | labId → labs (nullable) | Daily log entries |
| achievements | id (UUID) | moveId → moves | Per-move tier tracking |
| aura_links | fromMoveId+toMoveId | moves, moves | Transition affinities |
| aura_presets | id (UUID) | — | Named style profiles |

### Status Flow (Kanban)
```
Idea → Attempting → Landed → Clean
```

### Achievement Tiers
```
Seed (created) → Sprouting (first review) → Growing (5+ good reviews) → Mastered (FSRS stable)
```

### Aura Affinities (Pokemon-inspired)
```
Natural (super effective) → Possible (neutral) → Stretch (not very effective)
```

## Architecture Decisions

### SRP File Organization
Each table gets its own file. Each DAO gets its own file. Each widget has one purpose. Providers grouped by domain (lab, achievement, aura).

### Reuse Existing Patterns
- `lab_moves` mirrors `combo_moves` (join with sequenceIndex)
- Lab list/board reuses `AppSegmentedControl` toggle
- Notes reuse `NotesSection` widget
- Achievement celebrations reuse `CelebrationOverlay`
- DAO pattern follows `MovesDao` (watchAll/getAll/insert/update/delete)

### Drag & Drop Strategy
- Flutter `LongPressDraggable` + `DragTarget`
- Lightweight payloads (IDs only, not full objects)
- Spring animations for drop landings
- Accessibility: `MediaQuery.disableAnimations` check

### Navigation
- 5th tab in `StatefulShellRoute`
- `/lab` → list/board view
- `/lab/:id` → lab detail
- GoRouter branch integration
