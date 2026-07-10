# sync-media-cleanup Specification

## Purpose
TBD - created by archiving change clarify-review-loop-and-media-cleanup. Update Purpose after archive.
## Requirements
### Requirement: Arsenal rows reconcile from synced FSRS cards
After remote sync pulls review metadata, legacy move rows MUST reconcile their visible learning state from `fsrs_cards`.

#### Scenario: Remote mastery updates Arsenal
Given a move is still `NEW` locally but its synced FSRS card is in review state
When sync completes
Then the move row shows `MASTERY`

### Requirement: Pending video uploads survive later metadata writes
Sync logging MUST preserve an existing pending video upload flag when the same sync row is rewritten for metadata changes.

#### Scenario: Metadata update does not clear pending upload
Given a move sync row has `videoSynced=false`
When a later metadata-only update is logged
Then the sync row still has `videoSynced=false`

### Requirement: Delete cleanup removes app-managed local media
Deleting a move or combo MUST remove its local file and generated thumbnail.

#### Scenario: Relative-path move delete cleans both files
Given a move video exists under the app documents directory with a generated thumbnail
When the move is deleted
Then both the video file and its thumbnail are removed

### Requirement: Delete sync removes remote uploaded video
Deleting a synced move or combo MUST remove the remote object from storage as part of the delete push.

#### Scenario: Synced move delete removes storage object
Given a synced move has an uploaded remote video
When the delete sync entry is pushed
Then the corresponding storage object is removed

### Requirement: Move detail shows deterministic media filenames
The individual move page MUST expose the current source filename and the app-managed Photos album filename derived from the same semantic naming scheme used during album export.

#### Scenario: Move detail shows album filename
Given a move has a stored video and a name/category
When the move detail screen renders
Then the media metadata section shows the source filename and the derived album filename

