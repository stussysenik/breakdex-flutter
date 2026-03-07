# Manual iCloud Testing Checklist

> Run before each release on a physical device. These scenarios cannot be
> automated because they require real iCloud state and network conditions.

## Pre-conditions

- [ ] Physical iPhone with iCloud Photos enabled
- [ ] "Optimize iPhone Storage" ON (forces cloud-only videos)
- [ ] At least 3 videos NOT downloaded locally (show cloud icon in Photos)
- [ ] Breakdex app installed from latest build
- [ ] Device NOT connected to Xcode debugger (tests real crash behavior)

## Import from Photos

| # | Test Case | Expected Result | Pass? |
|---|-----------|-----------------|-------|
| 1 | Import cloud-only video | Progress bar appears, completes successfully | [ ] |
| 2 | Import cloud-only video on slow network (use Network Link Conditioner) | Timeout handled gracefully, retry option shown | [ ] |
| 3 | Cancel import mid-download (tap Cancel during progress) | No crash, no partial file left in Moves/ directory | [ ] |
| 4 | Import local (already downloaded) video | No progress bar, import is near-instant | [ ] |
| 5 | Import very large video (>500MB) | Memory stays stable, no OOM crash | [ ] |
| 6 | Import video, go to background during download, return | Download resumes or completes, no crash | [ ] |

## Import from Files (iCloud Drive)

| # | Test Case | Expected Result | Pass? |
|---|-----------|-----------------|-------|
| 7 | Import from iCloud Drive | Works same as Photos import | [ ] |
| 8 | Import from shared iCloud folder | File copies correctly | [ ] |
| 9 | Import .mov file from Files | Extension preserved, plays correctly | [ ] |

## Offline Behavior

| # | Test Case | Expected Result | Pass? |
|---|-----------|-----------------|-------|
| 10 | Airplane mode, tap import | Appropriate error message shown | [ ] |
| 11 | Airplane mode, view move with cloud video | "Video not found" card with ghost thumbnail | [ ] |
| 12 | Go offline mid-import | Graceful timeout, no crash | [ ] |

## Export

| # | Test Case | Expected Result | Pass? |
|---|-----------|-----------------|-------|
| 13 | Export with trim + speed change | Exported video plays at correct speed | [ ] |
| 14 | Export with rotation (90/180/270) | Video orientation is correct | [ ] |
| 15 | Export with aspect ratio crop (9:16, 1:1) | Crop applied, no black bars | [ ] |
| 16 | Cancel export mid-encoding | No crash, no partial file | [ ] |
| 17 | Export on low storage device | Clear error message, no data loss | [ ] |

## Sync (if Supabase account connected)

| # | Test Case | Expected Result | Pass? |
|---|-----------|-----------------|-------|
| 18 | Add move, verify sync badge shows pending | Badge count increments | [ ] |
| 19 | Manual sync with good network | All metadata syncs, videos upload | [ ] |
| 20 | Sync with intermittent network | Retry succeeds, no data loss | [ ] |
| 21 | Delete move, sync | Remote record removed | [ ] |

## Video Playback

| # | Test Case | Expected Result | Pass? |
|---|-----------|-----------------|-------|
| 22 | Play imported video in move detail | Smooth playback, controls work | [ ] |
| 23 | Fullscreen video, rotate device | Landscape mode activates correctly | [ ] |
| 24 | Seek bar scrubbing | Smooth seeking, no playback glitches | [ ] |
| 25 | Mute/unmute toggle | Audio responds correctly | [ ] |

## Notes

```
Date tested: _______________
iOS version: _______________
Device model: ______________
Build number: ______________
Tester: ____________________

Issues found:



```
