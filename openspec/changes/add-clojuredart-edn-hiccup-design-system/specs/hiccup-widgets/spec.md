## ADDED Requirements

### Requirement: Widgets as data structures
The system SHALL represent Flutter widgets as pure EDN data structures rather than class hierarchies.

#### Scenario: Text widget definition
- **WHEN** developer defines `[:text "Hello"]`
- **THEN** Text widget is rendered
- **AND** text content is "Hello"

#### Scenario: Elevated button with handler
- **WHEN** developer defines `[:elevated-button {:on-pressed #(do-something)} "Click me"]`
- **THEN** ElevatedButton is rendered
- **AND** pressing triggers handler

#### Scenario: Column composition
- **WHEN** developer nests `[col [[text "A"] [text "B"]]]`
- **THEN** Column widget contains both children

### Requirement: Widget property mapping
The system SHALL map Hiccup keywords to Flutter widget properties.

#### Scenario: Style mapping
- **WHEN** developer provides `:style {:color :red}`
- **THEN** Flutter widget receives red color

#### Scenario: Padding/margin via :padding key
- **WHEN** developer provides `:padding 16`
- **THEN** Padding widget wraps the child

### Requirement: Composable widget namespace
Developer SHALL be able to compose new widgets from existing ones.

#### Scenario: Reusable component
- **WHEN** developer defines `(defwidget card [title content] [card [:column title content]])`
- **THEN** card can be used as `card "Title" content`