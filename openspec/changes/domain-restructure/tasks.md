# Tasks

## 3. Domain Restructure

- [x] 3.1 Produce the domain source map: moves, combos, sets/labs, backup/media, sync, auth, kernel, and shared UI; include current legacy paths.
- [x] 3.2.0 Normalize `lib/` to `package:breakdex/…` imports (prerequisite found by 3.1; owner-approved 2026-07-28) so every later folder move is a single greppable path find-replace.
- [ ] 3.2 Move one low-risk domain slice mechanically, update imports, and prove `flutter analyze` remains green.
- [ ] 3.3 Add temporary compatibility exports for any hot legacy imports that cannot be fully migrated in one batch.
- [ ] 3.4 Repeat domain moves in atomic batches; each batch must contain no behavior edits.
- [ ] 3.5 Remove compatibility exports only after `rg` proves no production imports still use them.
