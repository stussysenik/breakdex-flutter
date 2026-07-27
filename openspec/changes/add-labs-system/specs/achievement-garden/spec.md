# Achievement Garden

## ADDED Requirements

### Requirement: Automatic tier progression
Achievement tiers SHALL advance automatically based on review activity and FSRS state.

#### Scenario: Move creation → Seed tier
Given a new move "Toprock" is created
When achievement check runs
Then an achievement with tier "seed" exists for Toprock

#### Scenario: First review → Sprouting tier
Given move "Toprock" has tier "seed"
When the first review is completed for Toprock
Then tier advances to "sprouting"

#### Scenario: Consistent practice → Growing tier
Given move "Toprock" has 5+ reviews with >60% rated good or easy
When achievement check runs
Then tier advances to "growing"

#### Scenario: FSRS mastery → Mastered tier
Given move "Toprock" has FSRS state "review" and stability > 7 days
When achievement check runs
Then tier advances to "mastered" and a celebration overlay appears

### Requirement: Achievement garden grid
A visual grid SHALL display all moves at their current achievement tier with tier-appropriate icons.

#### Scenario: Garden renders all moves
Given 4 moves exist at tiers seed, sprouting, growing, mastered
When achievement garden is displayed
Then 4 tiles render with icons: rock, seedling, plant, gem

### Requirement: Tier unlock celebration
When a move advances to a new achievement tier, a celebration animation SHALL play.

#### Scenario: Advancing to mastered shows celebration
Given move "6-Step" advances from growing to mastered
When the tier change is detected
Then CelebrationOverlay plays with the gem icon and move name
