# Breakdex — Rider's Guide

Your breaking notebook that actually remembers. Log your moves, build combos and
sets, and let the app quiz you on them so they stay in your body — not just your
camera roll.

This guide is for **you, the bboy/bgirl using Breakdex** — not for engineers.
It covers what the app is, how to open it, how it stays up to date, and — most
important — that **your data is yours** and how to take it with you.

---

## What Breakdex is

Breakdex is built around three things, smallest to biggest:

- **Move** — one thing you do. A footwork pattern, a freeze, a power move. Give it
  a name, a category, and (optionally) a clip.
- **Combo** — moves strung together, move-after-move, on a count. This is where the
  real vocabulary lives.
- **Set** — combos arranged into something you'd actually throw down in a round.

You film and label your moves, group them into combos and sets, and Breakdex uses a
proven memory engine (spaced repetition — the same idea flashcard apps use) to bring
moves back around for review right before you'd forget them. Drill the ones going
cold; leave the ones you own alone.

### The five tabs

| Tab | What it's for |
| --- | --- |
| **Breakdex** | Your library — every move you've logged, grouped how you like. |
| **Add** | Capture or create — film/attach a clip, name a move, start a combo. |
| **Review** | The practice session — Breakdex shows you what's due, you rate how it felt. |
| **Stats** | Your progress — what's mastered, what's slipping, how much you've trained. |
| **Settings** | Look and feel, categories, and your backups (see below). |

You don't have to use every part. A lot of people just log moves and glance at Stats.
That's fine — the review engine is there when you want it.

---

## Getting in

### Web (available now)

Open **https://breakdex.vercel.app** in any modern browser (Chrome, Safari, Edge,
Firefox). No install, no app store. Add it to your home screen if you want it to
feel like an app.

- **Sign in with Google** to sync across your devices, or
- **just start using it** — Breakdex works fully on one device without any account.
  Your data lives right there in the browser.

### iOS and Android (coming)

TestFlight (iPhone) and Play testing (Android) land after the web version has soaked
with real riders. When they're ready, this section grows a step-by-step for each.
Same app, same data model — nothing you log on the web is wasted.

---

## Your data is yours

This is the part that matters most, so it's plain:

- **Everything lives on your device first.** Your moves, combos, reviews, and stats
  are stored locally. The app works offline. You are never locked out of your own
  library because a server is down.
- **Sync is private and per-person.** If you sign in with Google, you get your own
  isolated space on **your own Google Drive** — your clips, your quota, nobody else's
  eyes. There's no shared feed, no crew mixing, no cross-user anything. It's your
  notebook, synced to your account.
- **Your video clips stay on your Drive.** Breakdex keeps a pointer, not a copy on
  someone else's server. If you delete the app, the footage on your Drive is still
  yours.

### Backing up and exporting

**Settings → Library → Backup & Reset:**

- **Export Full JSON Backup** — writes your entire library (moves, combos, reviews,
  battle results, categories) to a single file you keep. This is your parachute.
- **Import from JSON** — bring a backup back, either **Replace All** or **Merge**
  (skip duplicates, keep everything).
- **Export Stats Summary** — a plain-text snapshot of your progress you can share.
- **Clear Data** — wipes the library on this device. Breakdex **automatically writes
  a backup first** before it clears anything, so a wrong tap isn't a disaster.

> **A cloud auto-backup to your Drive is arriving** — a safety net that copies your
> notebook up on its own. It's built but off by default while it soaks; until it's
> switched on, the **Export Full JSON Backup** above is your manual backup. Use it
> before anything big (a reinstall, a device switch, clearing data).

### Leaving

There's no lock-in. Export your JSON backup, keep your clips on your Drive, and
you've got everything. Nothing about quitting Breakdex costs you your data.

---

## How updates arrive

- **On the web, updates are automatic.** Refresh the page (or reopen the tab) and
  you're on the latest version — there's nothing to download or reinstall.
- **Occasionally Breakdex will show a note** at the bottom of the screen — a gentle
  "there's a newer version" nudge you can dismiss, or, rarely, a "please refresh to
  keep going" screen when an old version can't safely run anymore. These only appear
  when there's a real reason; most updates you'll never notice.
- **You almost never need to reinstall or migrate anything.** Your local data carries
  forward across updates. On the rare occasion a change needs a one-time step, the
  app will tell you exactly what to do — and your backup (above) is always the safe
  fallback.

If a release is being rolled back for any reason, the web app simply serves the
previous good version — you don't do anything.

---

## Versions and release notes

Breakdex uses plain **MAJOR.MINOR.PATCH** version numbers (like `1.3.0`) with a
single build number that only ever goes up across web, iPhone, and Android — so
"which version am I on" always has one honest answer.

Every release's changes are written down in
[`docs/CHANGELOG.md`](docs/CHANGELOG.md). That's the user-visible face of the app's
"nothing ships without a note" rule — if it changed, it's in the log.

---

## Quick answers

- **Do I need an account?** No. Sign in with Google only if you want sync across
  devices.
- **Where are my videos?** On your own Google Drive (if signed in), or on your device.
- **Will I lose data on an update?** No. Local data carries forward; export a backup
  before big moves anyway.
- **How do I get everything out?** Settings → Backup & Reset → Export Full JSON Backup.
- **Is my stuff shared with anyone?** No. Every space is private and per-person.

Now go log some moves.
