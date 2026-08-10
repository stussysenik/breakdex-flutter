# Tasks — Add Self-Healing Video Reliability Runtime

> **Language: Dart (Flutter) + native iOS (PhotoKit).** Depends on: `appwrite`
> (cloud retrieval), `reverse-album-delete-archive` (managed Photos recovery).
> Implementation in a fresh student session — never this one.

Ledger rule: tick in the same commit that lands the work. Binary truth: no tick
without terminal-verified evidence (analyze/test/build output). The runtime is
local-first; server-driven policy is deferred (non-goal).

## Phase 1: Runtime Contract
- [ ] 1.1 Define explicit reliability states for local, Photos, cloud, blocked, and failed paths
- [x] 1.2 Define startup/resume/connectivity sweep triggers
- [x] 1.3 Define priority ordering for which assets should be verified first

## Phase 2: Recovery Policy
- [ ] 2.1 Define local-first recovery ordering across local, Photos, and cloud paths
- [ ] 2.2 Define bounded retry budgets and stop conditions
- [x] 2.3 Define which actions are automatic versus user-initiated

## Phase 3: Provenance Feedback
- [ ] 3.1 Define how provenance events influence future retry and diagnostics severity
- [x] 3.2 Define user/developer-visible explanations for blocked and failed states
- [ ] 3.3 Define test scenarios for repeated failures, successful recovery, and ambiguous availability

## Phase 4: Validation
- [x] 4.1 Implement the reliability state machine in Flutter
- [ ] 4.2 Add repair and inspection surfaces where needed
- [ ] 4.3 Run focused Flutter tests + analyzer on touched files
