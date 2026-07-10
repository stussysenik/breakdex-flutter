## Tasks

- [x] Remove `web-viewer/` (Next.js app) — `git rm -rf web-viewer`
- [x] Remove `scientific/` (Python/Julia/Lisp research) — `git rm -rf scientific`  
- [x] Remove `supabase/` (database migrations) — `git rm -rf supabase`
- [x] Clean root-level stale images — `rm verify-*.png`, `rm review-launcher-design.png`
- [x] Clean iOS device UDID directories — `rm -rf 00008130-* senik/`
- [x] Remove stale `.env.lcoal` typo file
- [x] Remove stale `scripts/science_doctor.sh`
- [x] Remove `science:*` scripts from `package.json`
- [x] Update `.maestro/review-launcher-design.yaml` screenshot reference
- [x] Remove `clojuredart/` — full ClojureDart project erroneously nested in Flutter repo
- [x] Remove `openspec/changes/add-clojuredart-edn-hiccup-design-system/` — stale migration proposal (already removed prior; kept openspec content per contract)
- [x] Reorganize README.md from first principles:
   - Flowdeck CLI commands (`flowdeck run`, `flowdeck test`, `flowdeck simulator` for iOS platform dev)
   - Flutter release mode commands (`flutter run --release`, `flutter build apk --release`, `flutter build ios --release`, `flutter build appbundle --release`)
   - Reorder sections: Quick Start → Features → Screenshots → Architecture → Development → Release → License
- [x] Add standalone `LICENSE` (ISC)
- [x] Verify `flutter analyze` passes
- [x] Commit and push to `main`
