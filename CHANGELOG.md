# [1.1.0](https://github.com/stussysenik/breakdex-flutter/compare/v1.0.0...v1.1.0) (2026-03-24)


### Bug Fixes

* **nav:** complete /arsenal → /moves route migration + UX improvements ([f4ca855](https://github.com/stussysenik/breakdex-flutter/commit/f4ca855940eeaa4dd29a8dfed3975a86f0038a23))
* **video:** improve fullscreen player UX and iOS export queuing ([05078a9](https://github.com/stussysenik/breakdex-flutter/commit/05078a92b1ca91a37d5548aa2b877357a3da4162))


### Features

* **db:** add content-addressable sync tables, DAOs, and schema v9 ([c811f48](https://github.com/stussysenik/breakdex-flutter/commit/c811f482004bb21c7b97a17a0fd08a5e595458ec))
* **db:** add notes column to moves and combos (schema v11) ([531853c](https://github.com/stussysenik/breakdex-flutter/commit/531853c751b5b5d1c24c944ecf94edda968ad5c7))
* **db:** add schema v12 with lab system tables and DAOs ([cab8ce1](https://github.com/stussysenik/breakdex-flutter/commit/cab8ce125a5a6bb4b8ef40f822ee3e811d0ab595))
* **export:** bump export schema to v7 with notes fields ([8a7e019](https://github.com/stussysenik/breakdex-flutter/commit/8a7e01917a2ac7ac67e41fedfd6f90cc4bacbe44))
* **flow:** improve graph layout, add multi-select set creation, fix chip overflow ([99271e2](https://github.com/stussysenik/breakdex-flutter/commit/99271e24cfe0dde30ace9f784c2bd6ce2cf0ee03))
* immersive review card, lab system, flow graph, and nav rebrand ([9a94160](https://github.com/stussysenik/breakdex-flutter/commit/9a94160242df90b9de71bdf725bf4c825f6826df))
* **ios:** configure iCloud entitlements, Google OAuth URL scheme, and connectivity auto-retry ([4900b4e](https://github.com/stussysenik/breakdex-flutter/commit/4900b4e77d09268d73a45a949d55cb62c6e64589))
* **lab:** add lab feature with projects, sets, milestones, and aura ([adbc140](https://github.com/stussysenik/breakdex-flutter/commit/adbc1402fc83a05f8b74887056ecd559746c2528))
* **nav:** rebrand 5-tab navigation (Moves, Drill, Progress, Lab, Flow) ([13e6632](https://github.com/stussysenik/breakdex-flutter/commit/13e6632fc6da355e2464967403c7e5e1a6b7241a))
* **notes:** add NotesSection widget with markdown, [@mentions](https://github.com/mentions), auto-save ([a1befba](https://github.com/stussysenik/breakdex-flutter/commit/a1befba0b4011cf839e4cdf3fe3dd14239d42ef9))
* **review:** enhance flashcard review with immersive card layout ([b6339c3](https://github.com/stussysenik/breakdex-flutter/commit/b6339c3aba20d329ebef8d767b49b4ce84f07407))
* **stats:** add timeline calendar view to progress screen ([eb15edf](https://github.com/stussysenik/breakdex-flutter/commit/eb15edf59a788c2f0bd837fc2ed1f61aa9b9575d))
* **sync:** add cloud sync engine with retry, backoff, and multi-provider support ([a93c7f1](https://github.com/stussysenik/breakdex-flutter/commit/a93c7f15e543f17bec6dc8f3b0aa88fbc3dc1d61))
* **sync:** add state transition audit logging and defensive guards ([c367ccb](https://github.com/stussysenik/breakdex-flutter/commit/c367ccbc2a01402ebcfc1970107953a735d77d90))
* **ui:** add settings gear button and rename Arsenal to Moves ([13b7e7f](https://github.com/stussysenik/breakdex-flutter/commit/13b7e7f55c0c55654f6c52c4eb74f5f59afbe14e))
* **ui:** add sync health indicators, cloud video overlay, onboarding, and web viewer ([aa2bdee](https://github.com/stussysenik/breakdex-flutter/commit/aa2bdeeebf30de8fa84be62d33324e54064a4ac9))

# 1.0.0 (2026-03-13)


### Bug Fixes

* **maestro:** correct appId in scroll_performance.yaml ([29a684c](https://github.com/stussysenik/breakdex-flutter/commit/29a684c832bde6b472aed68e7cfa9468d299a996))
* **nav:** raise FAB above frosted glass bottom navigation ([bbd01b6](https://github.com/stussysenik/breakdex-flutter/commit/bbd01b6c39c952f7683d27b89e5ffd4957179e37))
* prevent crashes by adding safety checks to startup ([9cd0d1d](https://github.com/stussysenik/breakdex-flutter/commit/9cd0d1dd15667b36c3207ed083d3201b535a0d1d))
* stabilize review flows and iOS startup ([1a77bf1](https://github.com/stussysenik/breakdex-flutter/commit/1a77bf147461952654c7dd11163e3b4805ecd1f7))


### Features

* add combo editing and review step scrubbing ([710a712](https://github.com/stussysenik/breakdex-flutter/commit/710a7128662e32eb20c398cfd245224deaebe34a))
* add Dart services, pose models, move analysis feature, and 3D view ([7e9cd72](https://github.com/stussysenik/breakdex-flutter/commit/7e9cd72abd9237c4ec3f9a1bd11d453fe31ecf7c))
* add iOS camera vision and 3D skeleton viewer to the app ([3324abd](https://github.com/stussysenik/breakdex-flutter/commit/3324abdecd987bbeb3c6e2ee04bc726a03b4773e))
* **arsenal:** shimmer placeholder for loading thumbnails ([f25339f](https://github.com/stussysenik/breakdex-flutter/commit/f25339f7afc9ba4145381fb9bac51931032e4a9f))
* **design:** add layered shadow system and noise grain texture overlay ([a363d45](https://github.com/stussysenik/breakdex-flutter/commit/a363d45de7b9e0b3a2cc19e134b1eff388ceaa0e))
* **detail:** hero transition from grid thumbnail to detail player ([e1d37c0](https://github.com/stussysenik/breakdex-flutter/commit/e1d37c01628d43de936c43607707903cde014b06))
* **merge:** connect the camera vision to the app so you can analyze moves ([d7a9838](https://github.com/stussysenik/breakdex-flutter/commit/d7a9838ecb0f35c9e5fd6f0fe6cde4c96a5dfc31))
* **merge:** improve the video editor for trimming and playing clips ([92485e5](https://github.com/stussysenik/breakdex-flutter/commit/92485e52343d7064dd361ec0100f9fdf3c9251d4))
* **merge:** iOS can now see your body and show a 3D skeleton ([86f06f9](https://github.com/stussysenik/breakdex-flutter/commit/86f06f9d365ed412dc6be571e215bc2be4125c0e))
* **merge:** redesign the flashcard review screens for practicing moves ([013bff4](https://github.com/stussysenik/breakdex-flutter/commit/013bff49689143f507ddf17c18a966a4f7c64511))
* **nav:** frosted glass bottom navigation with backdrop blur ([57a3594](https://github.com/stussysenik/breakdex-flutter/commit/57a3594425911fe63d93ca2fe3d616877dfe7dbb))
* overhaul review flow, move list, and shared widgets ([a22f9e8](https://github.com/stussysenik/breakdex-flutter/commit/a22f9e8bc096f1a01536890c449c4d5a916a0828))
* overhaul review, stats, and media workflows ([29fef83](https://github.com/stussysenik/breakdex-flutter/commit/29fef831ae5fba917a6b0704b0eef9688970174f))
* **review:** add breathing animation to review card when idle ([7cddae9](https://github.com/stussysenik/breakdex-flutter/commit/7cddae993575354b50010034dc53588720727d51))
* update video editor screen and video player widget ([dadee2f](https://github.com/stussysenik/breakdex-flutter/commit/dadee2f0f94a87a0558727081a66a2b8bce52265))


### Performance Improvements

* **arsenal:** migrate to CustomScrollView slivers with press physics and RepaintBoundary ([232b9ce](https://github.com/stussysenik/breakdex-flutter/commit/232b9ce35e1ca173bae913276b2694e8c4fdb372))
* **fonts:** bundle Inter font family as static asset ([c43affe](https://github.com/stussysenik/breakdex-flutter/commit/c43affeff04ac929feee4776a74c2fe9d80159e8))
* **rendering:** add spring physics curves and depth system, remove unused google_fonts ([7b4bed5](https://github.com/stussysenik/breakdex-flutter/commit/7b4bed5edc298c028e0db4185fc7736a1b8a6f1a))
* **stats:** add granular stats providers for focused rebuilds ([1a4965f](https://github.com/stussysenik/breakdex-flutter/commit/1a4965f6c770a24633ddc0fe0c517d56f694d451))
* **thumbnails:** viewport-aware load coordinator with priority queue ([884b9de](https://github.com/stussysenik/breakdex-flutter/commit/884b9de43beb31eee14029264a468e3e735c9f23))
* **video:** wrap transport controls in RepaintBoundary ([8b3798a](https://github.com/stussysenik/breakdex-flutter/commit/8b3798ac6939a553e3dbd5770a406368b75f82f6))

# Changelog

All notable changes to Breakdex will be documented in this file.
This file is auto-generated by [semantic-release](https://github.com/semantic-release/semantic-release).
