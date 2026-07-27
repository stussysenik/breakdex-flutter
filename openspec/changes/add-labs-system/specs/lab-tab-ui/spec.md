# Lab Tab UI

## ADDED Requirements

### Requirement: 5th navigation tab
A "Lab" tab SHALL be added as the 5th bottom navigation item with a science/flask icon. Tapping it navigates to /lab.

#### Scenario: Tab renders in bottom nav
Given the app is running
When the bottom navigation bar renders
Then 5 tabs are visible: Arsenal, Review, Stats, Lab, Settings

### Requirement: List/Board view toggle
The Lab screen SHALL support two views — List and Board — toggled via AppSegmentedControl.

#### Scenario: Default view is List
Given user navigates to Lab tab
When the screen loads
Then List view is shown by default

#### Scenario: Switch to Board view
Given user is on Lab List view
When user taps "Board" segment
Then kanban columns (Idea/Attempting/Landed/Clean) are displayed

### Requirement: Lab list view
List view SHALL show lab cards sorted by updatedAt DESC with status pill, progress bar, and metadata (attempt count, days since creation).

#### Scenario: Empty state
Given no labs exist
When user views Lab list
Then empty state shows "Start your first lab" with create button

#### Scenario: Lab card displays metadata
Given a lab "Air Flare" exists with status "attempting" and 12 linked moves
When displayed in list view
Then card shows name, status pill, progress bar, and "12 moves" count

### Requirement: Lab board view (Kanban)
Board view SHALL group labs into 4 horizontal-scroll columns by status: Idea, Attempting, Landed, Clean.

#### Scenario: Labs grouped by status
Given 2 labs with status "attempting" and 1 with "landed"
When Board view is shown
Then Attempting column has 2 cards and Landed column has 1

### Requirement: Quick log input
A persistent text input at the top SHALL allow quick daily log entries, optionally attached to a lab.

#### Scenario: Create standalone log
Given quick log input is focused
When user types "Good session" and submits
Then a lab_entry with labId=null is created

### Requirement: Create lab flow
Users SHALL be able to create new labs with a name and type (project or set).

#### Scenario: Create project lab
Given user taps the + FAB on Lab tab
When they enter "Air Flare" and select "Project"
Then a new lab with labType "project" and status "idea" is created
