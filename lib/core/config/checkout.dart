/// Lemon Squeezy checkout seam (0.1/0.2 rulings): the three one-time offerings
/// and a pure builder for their hosted-checkout URLs.
///
/// Pure + testable: [checkoutUrlFor] is a URL string builder with no IO. The
/// store slug and per-tier variant ids are compile-time config (owner supplies
/// live values via `--dart-define` at provision time); absent them the builder
/// returns null, so an unconfigured build simply has no buy links rather than
/// dead ones. Actually opening the URL is a thin platform launch that rides the
/// owner's live setup.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// One purchasable offering. One-time purchase (no subscriptions) — 0.2 ruling.
class Offering {
  const Offering({
    required this.tier,
    required this.label,
    required this.priceUsd,
  });

  final String tier; // matches the entitlement tier the webhook grants
  final String label;
  final String priceUsd; // display price, USD
}

/// The three offerings — Supporter $4.20 / Standard $6.99 / Patron $9.99.
const List<Offering> kOfferings = <Offering>[
  Offering(tier: 'supporter', label: 'Supporter', priceUsd: '4.20'),
  Offering(tier: 'standard', label: 'Standard', priceUsd: '6.99'),
  Offering(tier: 'patron', label: 'Patron', priceUsd: '9.99'),
];

/// Lemon Squeezy store slug (e.g. `breakdex` → `breakdex.lemonsqueezyzy.com`).
/// Empty by default; owner sets `--dart-define=LEMON_SQUEEZY_STORE=...`.
const String kLemonSqueezyStore = String.fromEnvironment(
  'LEMON_SQUEEZY_STORE',
  defaultValue: '',
);

/// Resolve offering ids per tier from the owner-supplied
/// `--dart-define=OFFERINGS_JSON`, a JSON object of `{tier: {id, variant}}`.
///
/// The env string is read once at compile time (`String.fromEnvironment` is a
/// const) and parsed lazily — absent or malformed JSON resolves to an empty
/// map, so a build with no `--dart-disable` (or a typo) disables the paid flow
/// for every tier rather than throwing. Per the 0.2 ruling there are no
/// hardcoded offering ids here; the owner supplies them at provision time.
///
/// Pure and testable: [OfferingsConfig] holds the parsed map and exposes
/// [resolve]; tests construct one with an explicit JSON string.
class OfferingsConfig {
  const OfferingsConfig._(this._byTier);

  /// Compile-time default: parsed from `--dart-define=OFFERINGS_JSON`. A const,
  /// so it is fixed per build — no runtime IO, no global mutable state.
  static const OfferingsConfig current = OfferingsConfig._(
    <String, _OfferingEntry>{},
  );

  final Map<String, _OfferingEntry> _byTier;

  /// Parse [json] into an [OfferingsConfig]. Absent/malformed JSON → empty
  /// config (paid flow disabled everywhere); a bad entry is skipped rather than
  /// failing the whole map. The public shape is a typed object, not raw JSON,
  /// so callers never touch string keys.
  factory OfferingsConfig.fromJsonString(final String json) {
    if (json.trim().isEmpty) return const OfferingsConfig._(<String, _OfferingEntry>{});
    final decoded = jsonDecode(json);
    if (decoded is! Map) return const OfferingsConfig._(<String, _OfferingEntry>{});
    final byTier = <String, _OfferingEntry>{};
    for (final entry in decoded.entries) {
      final tier = entry.key;
      final value = entry.value;
      if (tier is! String || value is! Map) continue;
      final id = value['id'];
      final variant = value['variant'];
      if (id is! String || id.isEmpty) continue;
      if (variant is! String || variant.isEmpty) continue;
      byTier[tier] = _OfferingEntry(id: id, variant: variant);
    }
    return OfferingsConfig._(byTier);
  }

  /// The offering id for [tier], or null when no offering is configured — the
  /// paid flow is disabled for that tier.
  String? resolveId(final String tier) => _byTier[tier]?.id;

  /// The checkout variant id for [tier], or null when no offering is configured.
  String? resolveVariant(final String tier) => _byTier[tier]?.variant;

  /// Whether any offering is configured (the paid flow is enabled somewhere).
  bool get hasAnyOffering => _byTier.isNotEmpty;
}

class _OfferingEntry {
  const _OfferingEntry({required this.id, required this.variant});
  final String id;
  final String variant;
}

/// Build the hosted-checkout URL for [tier], carrying the Appwrite [userId] as
/// custom data (the webhook reads it back to grant the right user) and, if the
/// LS store or the tier's variant is unconfigured, returning null. On success LS
/// redirects to [successUrl] (default: the app origin) so the flow lands back in
/// the app; the webhook is the source of truth for the grant.
///
/// [offeringConfig] defaults to the compile-time `OfferingsConfig.current`
/// (parsed from `--dart-define=OFFERINGS_JSON`); pass an explicit one in tests.
String? checkoutUrlFor(
  final String tier, {
  required final String userId,
  final String? email,
  final String? successUrl,
  final OfferingsConfig offeringConfig = OfferingsConfig.current,
}) {
  final variant = offeringConfig.resolveVariant(tier);
  if (kLemonSqueezyStore.isEmpty || variant == null) {
    return null;
  }
  final params = <String, String>{
    'checkout[custom][user_id]': userId,
    if (email != null && email.isNotEmpty) 'checkout[email]': email,
    if (successUrl != null && successUrl.isNotEmpty)
      'checkout[success_url]': successUrl,
  };
  final query = params.entries
      .map((final e) =>
          '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
  return 'https://$kLemonSqueezyStore.lemonsqueezy.com/checkout/buy/$variant?$query';
}

/// Keep `OfferingsConfig.current` referenced even when tree-shaken, so the
/// `--dart-define=OFFERINGS_JSON` the owner provisions actually compiles in.
// ignore: unused_element
const _keepAlive = kDebugMode ? null : OfferingsConfig.current;
