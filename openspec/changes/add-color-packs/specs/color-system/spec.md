# Color System

## ADDED Requirements

### Requirement: Color is addressed by role, and a pack resolves every role

The app SHALL address color through a closed role vocabulary covering both surfaces
(`ColorScheme`) and product signals (`AppSemanticTheme`). A `ColorPack` SHALL be a function of
`Brightness` to both halves.

A pack SHALL resolve every role through a `switch` with no `default` clause, so that an
unresolved role is a compile error. A pack SHALL NOT return a nullable color and SHALL NOT
substitute a placeholder.

A pack SHALL extend the existing `AppSemanticTheme` extension rather than introduce a second
extension carrying the same signals.

#### Scenario: A role is added to the vocabulary

- **WHEN** a new role is added and only one pack gains a case for it
- **THEN** `flutter analyze` fails on the other packs' non-exhaustive switches, before any
  build or test runs

#### Scenario: A widget reads a signal color

- **WHEN** a widget asks for the mastery-state color
- **THEN** it reads it from `AppSemanticTheme`, which is the only source for that value

### Requirement: A pack's weight ramp is perceptually derived

A pack SHALL be declared as a seed set plus a derived light→bold weight ramp. Derivation
SHALL occur in a perceptually uniform space (OKLCH), so that one ramp definition yields
evenly-perceived steps across every hue in the pack.

The ramp SHALL be monotonic in lightness and SHALL preserve hue within a stated tolerance
across its steps. Ramp derivation SHALL NOT introduce a runtime dependency.

#### Scenario: Two hues are ramped

- **WHEN** a yellow seed and a blue seed are each ramped to the same weight step
- **THEN** the two results read as equally light, rather than the yellow reading far brighter
  as it would under an HSL ramp

#### Scenario: A ramp is asserted in test

- **WHEN** the ramp test runs over every pack
- **THEN** each ramp's lightness increases monotonically and each step's hue stays within
  tolerance of its seed

### Requirement: The accessibility overlay outranks pack selection

Pack, brightness, and `AccessiblePalette` SHALL be orthogonal axes applied in that order,
with the accessibility overlay applied last. Pack selection SHALL NOT be able to alter or
defeat the colors an accessible palette guarantees.

Selecting an accessible palette SHALL NOT erase the stored pack or its per-role overrides;
they SHALL return unchanged when the palette returns to `standard`.

#### Scenario: A pack is chosen while deuteranopia is active

- **WHEN** the user is on the deuteranopia palette and selects any pack
- **THEN** the seven signal colors remain the Okabe–Ito values, and the pack supplies only
  the surfaces and accent that the overlay leaves untouched

#### Scenario: A pack is chosen while monochrome is active

- **WHEN** the user is on the monochrome palette and selects a pack
- **THEN** the rendered result is unchanged, and the interface states that the palette is
  overriding the pack rather than leaving the user to infer that their choice did nothing

#### Scenario: The accessible palette is set back to standard

- **WHEN** the user returns to `standard`
- **THEN** the previously selected pack and every per-role override are in effect exactly as
  they were before

### Requirement: Shipped packs pass contrast; user overrides are informed, not blocked

Every pack shipped with the app SHALL pass the contrast thresholds asserted by
`accessible_palette_test.dart` for every contrast-sensitive role pair, in both brightnesses.
A shipped pack that fails SHALL fail CI.

A user-supplied per-role override SHALL be accepted even when it fails a threshold, and the
interface SHALL display the live contrast ratio and its pass/fail state as the color is being
chosen. An override SHALL NOT be silently accepted without that signal, and SHALL NOT be
blocked.

#### Scenario: A shipped pack regresses contrast

- **WHEN** a pack's text-on-surface pair drops below its threshold
- **THEN** the test suite fails, naming the pack, the role pair, and the measured ratio

#### Scenario: The user picks a low-contrast accent

- **WHEN** the user drags to a color that fails against the surface behind it
- **THEN** the picker shows the failing ratio as the color changes, and the choice is still
  applied if the user keeps it

### Requirement: Pack choice is persisted, catalogued, and never silently overridden

The selected pack and per-role overrides SHALL persist to `SharedPreferences` and survive
restart. An unset preference SHALL resolve to `classic`. A stored preference SHALL NOT be
overridden when the default changes or a pack is added.

An unrecognised stored pack key SHALL fall back to `classic` without throwing.

Packs SHALL be presented as a catalogue organised into named collections, browsable by season
and by year, so a pack is chosen by looking rather than by reading a key. Catalogue data
SHALL be supplied through an interface, so that the data source can change without touching
the pack mechanism.

#### Scenario: The app is relaunched

- **WHEN** the user selected a pack and relaunches
- **THEN** the app renders that pack from first frame, with no flash of `classic`

#### Scenario: A pack is removed in a later release

- **WHEN** a client has a now-unknown pack key stored
- **THEN** the app starts on `classic` and replaces the stored value, rather than failing to
  resolve

#### Scenario: The catalogue's data source changes

- **WHEN** the curated collection set is replaced by a licensed one
- **THEN** the change is confined to the catalogue source, and no pack, role, ramp, or call
  site is edited

### Requirement: The default pack is byte-identical to today's palette

The `classic` pack SHALL resolve every role to the value that role renders before this
change. No screen SHALL change appearance until a different pack is selected.

#### Scenario: The app runs with no stored preference

- **WHEN** an existing user updates to the release carrying this change
- **THEN** every surface, signal, and accent renders exactly as it did before the update
