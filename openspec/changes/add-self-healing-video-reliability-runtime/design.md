# Add Self-Healing Video Reliability Runtime — Design

## Product Contract

Breakdex should treat video reliability as a subsystem with explicit policy, not a collection of unrelated fixes. The app should be able to verify, retry, recover, and explain video availability state in a bounded and deterministic way.

## Reliability State Model

### Core states

The runtime should distinguish at least:

- available locally
- recoverable from Photos
- recoverable from cloud
- blocked by policy or connectivity
- failed after bounded retries

### Why explicit states matter

Without explicit states, the app cannot clearly answer whether a missing video is:

- truly gone
- merely not local
- waiting for permission/network
- likely recoverable automatically

## Sweep Design

### Priority order

The runtime should prioritize:

1. moves currently visible or recently opened
2. assets with recent failures
3. assets referenced by upcoming review surfaces
4. broader background verification candidates later

### Trigger points

Sweeps should be considered on:

- startup after critical initialization
- app resume
- connectivity improvement
- explicit user request to repair or inspect

## Recovery Action Loop

### Local-first policy

The runtime should prefer the cheapest credible recovery path first:

- use local verified file if present
- restore from managed Photos asset if possible
- retrieve from cloud if policy allows
- mark blocked or failed explicitly if conditions are not met

### Retry budgets

Retries must be bounded by:

- attempt count
- time window
- connectivity and policy conditions

Provenance events should record these transitions so the system can explain why it stopped retrying.

## Provenance Feedback Loop

The runtime should use provenance not just for debugging, but for policy:

- repeated retrieval failures can lower automatic retry confidence
- repeated startup DB recovery failures can escalate diagnostics severity
- successful recoveries can suppress false-alarm incident noise

## BEAM Alignment

### Near-term Flutter role

Flutter owns immediate local sweeps and local-first remediation while the backend is absent.

### Future BEAM role

Phoenix/Gleam should eventually own:

- cross-session retry policy refinement
- correlation of repeated failures across installs
- server-driven incident scoring or repair suggestions

## Risks

- over-aggressive automatic recovery causing churn or wasted battery/network
- unclear boundaries between user-initiated and automatic recovery
- mixing verification policy with UI concerns

## Acceptance Criteria

This design is accepted when the repo clearly states:

- the explicit video reliability states
- the sweep trigger and priority model
- the bounded retry posture
- the provenance-to-policy feedback loop
