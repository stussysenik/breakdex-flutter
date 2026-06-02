/// Extension types for absolute storage type safety.
///
/// By using extension types (branding), we prevent "Stringly-Typed" logic where
/// raw strings are accidentally passed to filesystem operations.
///
/// A [CanonicalPath] is guaranteed to be a relative path within the app's 
/// managed storage (e.g., 'Moves/Power moves/Okayy - hash.mp4').
extension type const CanonicalPath(String value) implements String {
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;
}

/// A [ContentHash] is a verified SHA-256 hex string identifying a unique asset.
extension type const ContentHash(String value) implements String {
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;
  
  /// Returns a shortened version for human-readable filenames (e.g., '8125026a').
  String get short => value.length > 8 ? value.substring(0, 8) : value;
}
