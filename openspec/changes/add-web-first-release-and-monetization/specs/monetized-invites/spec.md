# monetized-invites

## ADDED Requirements

### Requirement: Invite-code redemption binds entitlement and cohort

The system SHALL support owner-minted invite codes with bounded uses and expiry. Redemption SHALL
be atomic and idempotent per (user, code), and SHALL bind the redeeming account to an entitlement
tier and a remote-config cohort in one operation.

#### Scenario: Valid code grants access
- **WHEN** a signed-in user redeems an unexpired code with remaining uses
- **THEN** exactly one use is consumed and the user holds the code's entitlement tier and cohort

#### Scenario: Double submission consumes one use
- **WHEN** the same user submits the same code twice (retry, double-tap)
- **THEN** the code's use count increases by exactly one and the outcome is identical

#### Scenario: Exhausted or expired code is rejected
- **WHEN** a user redeems a code that is expired or fully used
- **THEN** redemption fails with a typed error and no entitlement is written

### Requirement: Released builds gate on entitlement without harming existing users

Released builds SHALL require an entitlement (invite-granted or purchased) to use the app, with
an invite-entry first-run for new users. The owner account, development builds, and existing
device users with local data SHALL never be gated. Losing an entitlement SHALL at most lock the
account read-only — it SHALL never delete or hide the user's data irrecoverably.

#### Scenario: Grandfathered device user
- **WHEN** an existing user with local library data opens a released build
- **THEN** they are not blocked by the entitlement gate

#### Scenario: Downgrade preserves data
- **WHEN** a purchase is refunded and the entitlement is downgraded
- **THEN** the user's data remains intact and exportable

### Requirement: Offerings priced for the community

Paid offerings SHALL be priced within the $4.20–$9.99 USD band, purchasable on web via a
merchant-of-record checkout whose webhook writes the same entitlement shape as invites
(idempotent per provider event). On iOS store builds, the same offerings SHALL map to StoreKit
in-app purchases; the backend entitlement document remains the cross-platform truth.

#### Scenario: Web purchase grants entitlement
- **WHEN** the payment provider delivers a verified purchase webhook
- **THEN** the purchaser's entitlement is written once, and replaying the same event writes nothing new
