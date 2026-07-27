# Stale tests quarantined post-redesign — tracking ledger

**Status:** 0 tests quarantined. All 7 + 2 tests have been repaired and restored. The visual-first redesign
and the flat hash-addressed video-path refactor migrations have full test coverage.

**Latent note (not a blocker, worth a ticket):** the review matrix counts by the `learningState`
column while session-items derive state from FSRS card state. Normal flows keep them in sync, but
if a move's column ever drifts from its FSRS card the two counts diverge. Track separately.
