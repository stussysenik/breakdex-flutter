# combo-review-session

## ADDED Requirements

### Requirement: Free step switching in every review stage
While reviewing a combo card, the learner SHALL be able to switch the active combo step (move) at any time — in the watch stage **and** in the assessment stage. Switching steps SHALL swap the card's video to the selected move and update the active-step label. The step switcher SHALL be the beat grid timeline, with each block a tap target of at least 44pt height.

#### Scenario: Switching during assessment
- **WHEN** the learner taps "Assess" on a combo card and then taps the third block in the beat grid
- **THEN** the video swaps to the third move, the active-step label updates, and the rating buttons remain visible

#### Scenario: Step selection survives the stage transition
- **WHEN** the learner selects step 2 in the watch stage and then taps "Assess"
- **THEN** the assessment stage opens with step 2 still active

### Requirement: Assessment stage shows what is being rated
The assessment stage SHALL display the active step's name alongside the beat grid so the rating is anchored to a visible context (combo name + current move).

#### Scenario: Active step labelled
- **WHEN** the assessment stage renders with step "Windmill" active
- **THEN** the text "Windmill" is visible above or beside the rating buttons
