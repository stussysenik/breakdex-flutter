# Session Log - Running DevTools & Profile Mode on Physical Device

## Intent
The user is asking for instructions on how to run Flutter DevTools and Profile Mode on a physical device. We need to provide a clear, comprehensive guide covering Android and iOS platforms.

## Update (2026-05-29)
The user is attempting to deploy to a physical iOS device (`senik`) wirelessly, and it is hanging on "Installing and launching...".

## Update 2 (2026-05-29)
We ran the build via USB and discovered that the build failed because the Mac's host disk is full (`database or disk is full` in Xcode DerivedData).
We verified that the disk `/System/Volumes/Data` has only **118Mi** of free space remaining. This explains the other reported issues:
- **Database updates (learning state)** fail because SQLite cannot write WAL/journal files or transactions when the disk is full.
- **Video export** fails because there is no room to write the generated video file.
- **Shake detector** needs to be checked after the disk space is restored.

We ran `flutter clean` and proposed clearing Xcode DerivedData to free up several gigabytes.

## Update 3 (2026-05-30)
The user confirmed they now have plenty of space. We verified host disk space (314Gi available) and ran the build using `flutter run --profile -d senik` (wireless). The Xcode build succeeded in 230.5s. During launching, the console showed successful native initialization:
`[CapabilityRegistry] Done.`
However, the app remains frozen on the device, likely waiting for the wireless Dart VM Service handshake to connect back to the host Mac.

## Update 4 (2026-05-30)
The user indicated that nothing is running on the device. We killed the hanging background task `task-479` and will now query the available devices using `flutter devices` to find the correct device target, then re-run.

## Update 5 (2026-05-30)
Before running the application on device, we verified the codebase has no syntax errors using static analysis. We will now run the relevant test suites (video editor and flashcard review tests) to confirm compilation and unit logic success.

## Update 6 (2026-05-30)
All 60 tests passed successfully. We are now running the application on the USB-connected device `senik` via `flutter run -d senik`.

## Update 7 (2026-05-30)
The user reported that the video is not updating (the same old video is kept and the changes are lost/not saved). We will analyze the video save/export and DB path update implementation in `provider.dart` and see why the saved video path or content doesn't reload.

## Update 8 (2026-05-30)
We diagnosed two critical issues:
1. **Review Page Rebuild Crash**: The review page crashed with a Riverpod assertion because `BottomNavShell.build` was updating `currentTabIndexProvider` during the build phase. We resolved this by wrapping the update in a `WidgetsBinding.instance.addPostFrameCallback`.
2. **Video Caching Issue**: Since editing a video in-place results in the same file path, Flutter's widget tree reused the `RobustVideoPlayer` state and played the cached video file instead of reloading the modified file. We resolved this by including the move's `contentHash` in the `RobustVideoPlayer` `ValueKey` in all parent views (combo detail, create combo, review card, and review screen). Whenever the video is edited, the content hash changes, forcing the player to rebuild and reload the video file.

We verified these fixes via the automated widget tests and restarted the app on device `senik` successfully.

## Update 9 (2026-05-30)
Proposed integrating the Patrol testing framework. Created the implementation plan mapping out the native dependencies and proposed migrating the existing integration tests to use Patrol. Presented trade-offs for native Patrol CLI vs. using Patrol Finders via standard integration runners.

## Update 10 (2026-05-30)
Executed the approved Patrol integration:
1. Installed `patrol: ^4.6.1` and `patrol_finders: ^3.4.0` dev dependencies. Activated `patrol_cli` globally.
2. Programmatically added the `RunnerUITests` target (iOS UI Test Bundle, ObjC, matching deployment version) in Xcode project using the `xcodeproj` Ruby gem. Created the required `RunnerUITests.m` and `Info.plist` files.
3. Updated the project `Podfile` to declare the `RunnerUITests` target and executed `pod install` to resolve and link the native Patrol pod dependency.
4. Configured Android `build.gradle.kts` defaults and test runner dependencies (`PatrolJUnitRunner` & Android Test Orchestrator) and created `MainActivityTest.kt`.
5. Migrated `integration_test/app_test.dart` to Patrol syntax and added a comprehensive test case `Settings renames learning tags and Review screen updates` to verify the tag customization propagation from Settings to Review screen.
6. Triggered the background test compilation and execution runner against the iOS simulator.
