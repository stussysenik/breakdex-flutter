# Spec Delta — sync-release-gate

## ADDED Requirements

### Requirement: Multi-user sync release is a measured declaration

The project SHALL declare Google-Drive-backed multi-user sync released only when all
four gates hold with linked evidence: (a) asset truth — the sandbox-rescue and
terminal-classification work is device-proven with a flat failed-operation count;
(b) sync totality — every user-data table syncs per the registry change; (c) Phase M —
cross-surface soak and config flip are ticked; (d) a fresh second user has been proven
end-to-end. Absent any gate, release-facing surfaces SHALL NOT claim sync is done.

#### Scenario: A gate regression blocks the declaration

- **GIVEN** three gates ticked and the totality change incomplete
- **WHEN** release readiness is assessed
- **THEN** sync is not declared released and the gate doc names the open gate

### Requirement: A second real user is proven isolated end-to-end

Before release, a non-owner Google account SHALL complete the full journey — one-button
sign-in, provisioning on their own Drive quota, importing a video, seeing it on their
own web login — with server-side verification that their documents carry only their
userId and the owner's data is untouched.

#### Scenario: User #2 lives entirely in their own space

- **GIVEN** a fresh non-owner Google account completing sign-in, import, and web login
- **WHEN** backend documents are inspected with existing API access
- **THEN** every document created carries user #2's userId, their video bytes sit on
  their own Drive quota, and user #1's row counts are unchanged

#### Scenario: The declaration is dated and traceable

- **GIVEN** all four gates ticked with evidence links
- **WHEN** the owner declares sync released
- **THEN** the gate doc records the date and links each gate's evidence, and ROADMAP.md
  reflects the done state
