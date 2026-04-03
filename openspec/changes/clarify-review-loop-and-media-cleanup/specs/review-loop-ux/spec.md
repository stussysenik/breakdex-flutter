# Review Loop UX

## ADDED Requirements

### Requirement: State-based launcher counts due cards only
The state-based review launcher MUST show counts for cards that are due now, grouped by visible learning state.

#### Scenario: Future learning card is excluded
Given two learning cards exist and one is due tomorrow
When the launcher renders
Then only the due-now learning card contributes to the learning count

#### Scenario: Brand-new move without FSRS row still appears as New
Given a move exists with no `fsrs_cards` row
When the launcher renders
Then the move contributes to the `New` count and can be launched immediately

### Requirement: Active review shows one reveal-first card
The active review session MUST show one centered card at a time and MUST NOT expose swipe-preview navigation between cards.

#### Scenario: Assessment controls stay hidden until reveal
Given a review session is active
When the current card is still unrevealed
Then rating controls are not visible

#### Scenario: Reveal enables assessment
Given a review session is active
When the learner reveals the current card
Then the video surface and rating controls become available for that card only

### Requirement: FSRS result drives visible state
Move review updates MUST persist the visible move state from the committed FSRS result, not from a pre-FSRS optimistic transition guess.

#### Scenario: Move row reflects committed mastery
Given a move review graduates the card into FSRS review state
When the review is saved
Then the move's visible state becomes `MASTERY`

### Requirement: Only the primary visible media surface may keep playing
Playback MUST pause when a video surface is covered by navigation, hidden by branch switching, or superseded by another media surface.

#### Scenario: Branch switch pauses covered playback
Given a move detail video is playing in one bottom-nav branch
When the learner switches to another branch
Then the original video's playback stops

#### Scenario: Session refresh preserves the current card
Given a review session is active on a specific card
When the underlying move/video data refreshes during the session
Then the session keeps the learner on the same card when it still exists
