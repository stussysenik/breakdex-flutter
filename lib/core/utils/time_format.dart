/// Compact relative time formatter for UI display.
///
/// Returns human-readable strings like "now", "3m ago", "2h ago", "5d ago",
/// "2w ago", "1mo ago". Used across lab cards, timelines, and quick-log feeds.
String relativeTime(final DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}
