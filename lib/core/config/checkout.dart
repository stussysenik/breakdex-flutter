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

/// Lemon Squeezy store slug (e.g. `breakdex` → `breakdex.lemonsqueezy.com`).
/// Empty by default; owner sets `--dart-define=LEMON_SQUEEZY_STORE=...`.
const String kLemonSqueezyStore = String.fromEnvironment(
  'LEMON_SQUEEZY_STORE',
  defaultValue: '',
);

/// Per-tier Lemon Squeezy variant ids (the checkout buy targets). Empty by
/// default; owner sets them at provision time. Kept in lockstep with the
/// webhook's `LEMON_SQUEEZY_VARIANT_*` map (payments-webhook) so the variant a
/// user buys resolves to the same tier the webhook grants.
const Map<String, String> _variantByTier = <String, String>{
  'supporter': String.fromEnvironment('LEMON_SQUEEZY_VARIANT_SUPPORTER'),
  'standard': String.fromEnvironment('LEMON_SQUEEZY_VARIANT_STANDARD'),
  'patron': String.fromEnvironment('LEMON_SQUEEZY_VARIANT_PATRON'),
};

/// Build the hosted-checkout URL for [tier], carrying the Appwrite [userId] as
/// custom data (the webhook reads it back to grant the right user) and, if the
/// LS store or the tier's variant is unconfigured, returning null. On success LS
/// redirects to [successUrl] (default: the app origin) so the flow lands back in
/// the app; the webhook is the source of truth for the grant.
String? checkoutUrlFor(
  final String tier, {
  required final String userId,
  final String? email,
  final String? successUrl,
}) {
  final variant = _variantByTier[tier];
  if (kLemonSqueezyStore.isEmpty || variant == null || variant.isEmpty) {
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
