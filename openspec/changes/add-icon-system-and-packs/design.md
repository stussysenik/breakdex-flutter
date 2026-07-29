# Design — Icon System and Swappable Packs

## D1. Why a closed enum rather than a map

The obvious shape is `Map<String, IconData>` per pack, or a `String` key resolved at runtime.
Both were rejected for the same reason: they move pack completeness to runtime.

With a `Map`, a pack that omits `AppIcon.tombstone` compiles, ships, and renders a null or a
fallback box on the one screen that uses it — discovered by a user, on the surface where it
matters least often. With a closed `enum AppIcon` and a pack that resolves it through a
`switch` carrying **no `default` clause**, Dart's exhaustiveness analysis reports the missing
case as a compile error at the moment the vocabulary grows.

That property is the whole point of the change. The failure this capability exists to prevent
is *drift between packs*, and drift is exactly what a `Map` cannot see. It is also why the
vocabulary must be closed: an open vocabulary (any `String`) has no exhaustiveness to check.

The cost is real and accepted: adding an icon means editing every pack in the same commit.
With two packs that is two lines. It is the same trade the `Machine<S,E>` sealed classes
already make everywhere else in this codebase — the compiler carries the invariant.

## D2. Why the pack is a `ThemeExtension`, not a provider read at each call site

`fontFamilyProvider` and `accentColorProvider` are already read once in `theme.dart` and
folded into `ThemeData`; widgets consume the result through `Theme.of(context)` and never
watch the provider. Icons follow that established path rather than inventing a second one.

Consequences that decided it:

- A pack switch is one theme rebuild, app-wide, with no per-widget subscription.
- `resolve` needs only a `BuildContext`, which every widget already has — so a migrated call
  site is a local edit with no constructor threading and no `ConsumerWidget` conversion.
- Widget tests can override the pack by wrapping in a `Theme`, with no `ProviderScope`.

The provider still exists (`iconPackProvider`) as the persisted source of truth; `theme.dart`
is its only consumer.

## D3. The call-site shape

Two entry points, because the call sites genuinely have two shapes:

- **`AppIcon.add.resolve(context)` → `IconData`** is the primitive. It works everywhere an
  `IconData` is required — `Icon(...)`, `IconButton(icon:)` variants, `TextField`
  decorations, and any third-party API typed to `IconData`. Without it, some sites could not
  migrate at all and the conformance gate could never close.
- **`AppIconView(AppIcon.add)`** is a thin widget over it for the common case, carrying the
  default size and color so those stop being restated per call site.

The widget is not sugar for its own sake: 434 sites currently restate `size:` and `color:`
ad hoc, and the widget is where that becomes a token lookup once.

## D4. Curation: 228 glyphs → ≤ 80 semantic names

The reduction comes from three sources, in descending safety:

1. **Style-variant duplicates (51, value-preserving).** `close` / `close_rounded`,
   `add` / `add_rounded`, `check_circle` / `check_circle_outline`, `chevron_right` /
   `chevron_right_rounded` and 47 more. One meaning, two glyphs, no reason. The semantic name
   picks one; the other call sites change stroke terminal. This is a *visible* change on the
   losing sites, and it is the change the owner asked for — coherence.
2. **Singleton semantics (148 used once).** Most collapse into an existing meaning
   (`science_outlined`, `hub_outlined`, `scope`, `auto_awesome` are four different glyphs for
   "lab / experiment / discovery"). Each collapse is a design call, and each is recorded.
3. **Genuinely distinct meanings.** The residue is the vocabulary.

**The collapse ledger is mandatory.** Every merge of two glyphs into one name is a row in
`docs/design/TOKENS.md` naming the old glyphs, the new semantic name, and the files affected
— the same discipline the stacked-viewport change used when it enumerated the 43 off-scale
radii it deliberately left raw. A silent collapse is indistinguishable from a mistake at
review time; an enumerated one is a decision.

**The default pack is glyph-preserving where nothing collapses.** For every semantic name
with exactly one source glyph, `material` resolves to that same glyph, so the vast majority
of the app is pixel-identical after migration. That is what makes a 434-site sweep reviewable
at all: the diff is mechanical everywhere except the enumerated rows.

## D5. Why `lucide_icons_flutter` for the second pack

Considered: `lucide_icons_flutter` (MIT, 160/160 pub points, 185 likes, ~86k downloads),
`lucide_icons` (ISC, publisher `lucide.dev`, but 45/160 pub points — stale),
`phosphoricons_flutter` (MIT, 1500+ icons, six weights), `phosphor_flutter` (official
publisher, 55/160 — stale).

Chosen: **`lucide_icons_flutter`**. Lucide's even-stroke, rounded-terminal, geometric-but-
hand-tuned family is the closest open equivalent to the reference the owner named, and the
package is the healthiest of the Lucide bindings on every score. The official-publisher
alternative is two years behind Flutter's current icon-font handling.

Deferred rather than rejected: **Phosphor**, on the weight axis (thin / light / regular /
bold / fill / duotone). That axis is the interesting one and it rhymes with 6.5's
"light→bold weights" and 6.6's typography control — which is precisely why it should be
specified alongside those, once the vocabulary has stopped moving. Adding it now means
maintaining a third 80-row mapping through the curation churn.

Both candidate packages are third-party forks rather than first-party bindings. That risk is
bounded by D1: the pack is one file of `switch` cases behind our own enum, so replacing the
underlying package is a single-file edit and touches no call site.

## D6. Web payload

Flutter Web is the ranked-#1 surface, and a second icon font is a payload question, not a
free addition. `--tree-shake-icons` subsets each font to referenced code points, so the
inactive pack costs roughly its own subset — with a ≤ 80-name vocabulary, both subsets are
small, but "roughly" is not a number.

The release-build size delta is therefore **measured, not assumed** (Phase 5), and reported
in the change. If the delta is material, the fallback is deferred pack loading on web; that
is a contingency, not a plan, and is not designed until the number exists.

## D7. Migration order and the shrinking ledger

The conformance test carries a `_pendingFiles` allowlist that starts at the full 92 and must
only ever shrink. Each migration task removes a directory's files from it in the same commit
that migrates them — the same-commit ledger rule applied to the gate itself.

Directory order is chosen so the highest-traffic shared vocabulary settles first, which is
what lets later directories mostly reuse names rather than propose new ones:

`lib/shared` → `lib/core` → `lib/features/settings` → the five tab features → the remainder.

When `_pendingFiles` reaches empty the allowlist is deleted and the gate becomes an absolute
ban on `Icons.` under `lib/`, with `web-mirror/` out of scope entirely.

## D8. What is not decided here

- **Whether the vocabulary is exactly 80.** ≤ 80 is a target that falls out of the curation
  pass, not an input to it. The binding constraint is that every name is a meaning a screen
  can state, and that the ledger explains every collapse.
- **Whether a purchased icon set eventually replaces `lucide`.** The socket is built for it;
  the purchase is the owner's call.
- **How pack choice interacts with cohorts / remote config.** It is a local preference here.
  If invite cohorts later ship a default pack, that rides `add-web-first-release-and-
  monetization` Phase 1R, and the "a stored user preference is never overridden by a new
  default" non-negotiable already governs the interaction.
