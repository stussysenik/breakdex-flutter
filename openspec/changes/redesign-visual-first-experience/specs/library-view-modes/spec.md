# Library View Modes

## ADDED Requirements

### Requirement: Three ordered view modes

The library SHALL offer exactly three view modes ordered from easiest to hardest way of
seeing: **Glance** (large media-first gallery, thumbnail + duration only), **Scan** (dense
list, name + state), and **Study** (rich cards with inline playback, counts, category, and
notes preview). The mode toggle SHALL cycle in that fixed order.

#### Scenario: Mode cycling order

- **WHEN** the user activates the view-mode toggle repeatedly
- **THEN** the library cycles Glance → Scan → Study → Glance

#### Scenario: Each mode renders the same collection

- **GIVEN** a filtered library (search or category active)
- **WHEN** the user switches modes
- **THEN** the same result set renders in the new presentation with scroll position preserved
  as closely as the layout allows

### Requirement: View mode persists with legacy migration

The selected mode SHALL persist across restarts under the existing `arsenal_view_mode`
preference. Legacy values SHALL migrate on first read (`grid` → Glance, `list` → Scan) so no
existing user's choice is lost.

#### Scenario: Persisted across restart

- **GIVEN** a user in Study mode
- **WHEN** the app restarts
- **THEN** the library opens in Study mode

#### Scenario: Legacy value migration

- **GIVEN** a stored value `grid` from a previous version
- **WHEN** the library first reads the preference
- **THEN** it resolves to Glance and re-persists the new value
