# Add Self-Healing Video Reliability Runtime — Design

## Product Contract

Breakdex treats video reliability as a subsystem with explicit policy, not a collection
of unrelated fixes. The app verifies, retries, recovers, and explains video availability
state in a bounded and deterministic way. The runtime is **local-first**: it runs the
same logic on every surface without depending on a server-driven policy layer.

## Reliability State Model

### Core states

The runtime distinguishes at least:

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

The runtime prioritizes:

1. moves currently visible or recently opened
2. assets with recent failures
3. assets referenced by upcoming review surfaces
4. broader background verification candidates later

### Trigger points

Sweeps run on:

- startup after first frame
- app resume
- connectivity improvement
- explicit user request to repair or inspect

## Recovery Action Loop

### Local-first policy

The runtime prefers the cheapest credible recovery path first:

- use local verified file if present
- restore from managed Photos asset if possible (composes `reverse-album-delete-archive`)
- retrieve from cloud if policy allows (Appwrite)
- mark blocked or failed explicitly if conditions are not met

### Retry budgets

Retries are bounded by:

- attempt count
- time window
- connectivity and policy conditions

Provenance events record these transitions so the system can explain why it stopped
retrying.

## Provenance Feedback Loop

The runtime uses provenance not just for debugging, but for policy:

- repeated retrieval failures lower automatic retry confidence
- repeated startup DB recovery failures escalate diagnostics severity
- successful recoveries suppress false-alarm incident noise

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
