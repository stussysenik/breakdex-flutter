# Tasks — Add BEAM Web Architecture Foundation

## Phase 1: Product Contract
- [x] 1.1 Add a repo-level PRD describing the current app, future web access, state model, sync model, and storage direction
- [x] 1.2 Explicitly document the MVU/data-oriented/Riverpod posture and the non-default status of CRDTs
- [x] 1.3 Document the stance on Phoenix, BEAM, Gleam, S3-compatible storage, and optional Cloudinary usage

## Phase 2: Documentation Exposure
- [x] 2.1 Update `README.md` to link the new PRD
- [x] 2.2 Add a short architecture-direction summary to `README.md`
- [x] 2.3 Keep the README honest about near-term Flutter shipping versus long-term system evolution

## Phase 3: Follow-on Implementation Planning
- [ ] 3.1 Define backend domain boundaries for moves, reviews, graph edges, assets, and sync
- [ ] 3.2 Define provider interfaces for storage and media delivery
- [ ] 3.3 Define what future collaboration surfaces, if any, justify CRDTs
- [ ] 3.4 Define the first web-access slice that can ship without rewriting the mobile app

## Phase 4: Future Validation
- [ ] 4.1 Validate the PRD against TestFlight learnings and real-device media/sync behavior
- [ ] 4.2 Revisit vendor choices once the first web-access slice is scoped
- [ ] 4.3 Keep BYOK/BYOB deferred until the managed path is stable
