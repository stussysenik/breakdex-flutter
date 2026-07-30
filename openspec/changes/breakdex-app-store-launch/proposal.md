# Breakdex App Store Launch

## Context

Breakdex is a breakdancing training app (Flutter, v1.6.1) that catalogs moves,
builds combos, and tracks training through spaced repetition. The app is
feature-complete but needs App Store launch preparation.

**Current state:**
- SHA-256 content hashing exists (AssetHashService)
- Hash-based file index exists (SandboxHashIndex)
- Photo and video management exists but UX is unclear
- Web mirror exists (Next.js) but is secondary to the Flutter app

**Goal:** Launch on App Store with paid pricing ($10), ensuring data integrity,
clear UX, and production readiness.

## Requirements

### 1. App Store Readiness

- [ ] iOS build config (signing, provisioning, App Store Connect)
- [ ] Android build config (Play Store, signing)
- [ ] App icons (all sizes, adaptive for Android)
- [ ] Screenshots (iPhone, iPad, Android)
- [ ] App description, keywords, category
- [ ] Privacy policy URL
- [ ] In-app purchase setup (if needed) or paid app pricing

### 2. Data Integrity & Safety

- [ ] Cryptographic verification: all video files have SHA-256 hashes
- [ ] Index-first lookups: SandboxHashIndex is the authority, not stored paths
- [ ] Deduplication: no duplicate videos shown (hash-based)
- [ ] Data migration: safe schema evolution, no data loss
- [ ] Backup/restore: user data is portable

### 3. UX Clarity

- [ ] Photo gallery vs video feeds: distinct visual treatment
  - Photos: grid layout, thumbnail-focused
  - Videos: list/grid with duration, play button
- [ ] File management: go to file location, delete, manage
- [ ] No duplicate display: dedupe by content hash
- [ ] Clear content hierarchy: moves → combos → sets → journal

### 4. Search & Indexing

- [ ] Lexical search: moves, combos, notes searchable by name/tag
- [ ] Fast lookups: index-first, no full scans on UI thread
- [ ] sgrep-style: data is text-searchable (JSON/SQLite)

### 5. Privacy & Data Ownership

- [ ] Local-first: all data on device, no server required
- [ ] No telemetry: opt-in only
- [ ] Export: user can export all data (JSON + media)
- [ ] Delete: user can delete all data (GDPR-style)

## Non-Goals

- Web mirror is not the primary product (Flutter app is)
- No Stripe integration (App Store pricing)
- No cloud sync (local-first, optional Google Drive backup)
- No social features (single-user training app)

## Success Criteria

- [ ] App Store submission ready (iOS + Android)
- [ ] All data integrity gates pass (hash verification, index consistency)
- [ ] UX review: photo/video distinction is clear, no confusion
- [ ] Performance: UI stays 60fps during indexing/search
- [ ] User can export and delete all data

## Open Questions

1. What is the App Store pricing strategy? $10 one-time or subscription?
2. Is Google Drive backup in scope for launch, or post-launch?
3. What is the privacy policy requirement? (Need legal review)
4. Are there any third-party dependencies that need disclosure?

## References

- VALORIC factory pattern: scholar/teacher/student roles
- Breakdex ROADMAP.md: current priorities
- docs/manual/FACTORY.md: operating manual
