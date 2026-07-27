// H.8 lint triage — avoid_slow_async_io: async filesystem stat is intentional
// (avoids blocking the UI isolate); sync alternatives would block.
// ignore_for_file: avoid_slow_async_io

import 'package:path/path.dart' as p;

import 'package:breakdex/core/platform/io.dart';
import 'package:breakdex/core/sync/asset_hash_service.dart';

/// Video extensions the sandbox holds. Matches the picker's APP VIDEOS scan.
const _videoExtensions = {'.mp4', '.mov', '.m4v'};

/// The sandbox roots that hold canonical video bytes.
const _sandboxRoots = ['Moves', 'Combos'];

/// The hash token embedded in a canonical video filename, or null when the
/// name carries none.
///
/// Two canonical forms exist and both are load-bearing:
///   * `<fullhash>.ext`        — the canonical store's own naming (64 hex)
///   * `Name - hash8.ext`      — the semantic naming built by
///     `VideoPathResolver.semanticVideoPath` (the first 8 of the same hash)
///
/// Returned lowercase. A name with no `' - '` separator and no full-hash
/// basename yields null rather than the whole basename — the widespread
/// `split(' - ').last` idiom silently returns non-hash text for such files,
/// and an index keyed on that would map junk tokens onto real paths.
String? sandboxHashToken(final String basename) {
  final stem = p.basenameWithoutExtension(basename).toLowerCase();

  if (_isHex(stem) && stem.length == 64) return stem;

  const separator = ' - ';
  final index = stem.lastIndexOf(separator);
  if (index < 0) return null;

  final tail = stem.substring(index + separator.length);
  return tail.length == 8 && _isHex(tail) ? tail : null;
}

bool _isHex(final String s) =>
    s.isNotEmpty && RegExp(r'^[0-9a-f]+$').hasMatch(s);

/// Where the bytes for a content hash actually live, found by scanning the
/// sandbox rather than by trusting any stored path.
///
/// The manifest's `localPath` and the owning entity's `videoPath` are both
/// *hints* — they go stale on renames, category moves, and container-UUID
/// churn, and an asset whose owner was deleted has no hint left at all. The
/// bytes themselves are the authority, and the hash embedded in every
/// canonical filename makes them addressable by identity (design D10).
class SandboxHashIndex {
  /// token (full hash or hash8) → relative paths carrying it.
  final Map<String, List<String>> _byToken;

  const SandboxHashIndex(this._byToken);

  bool get isEmpty => _byToken.isEmpty;

  /// One recursive pass over the sandbox roots under [documentsPath].
  static Future<SandboxHashIndex> scan(final String documentsPath) async {
    final byToken = <String, List<String>>{};

    for (final root in _sandboxRoots) {
      final dir = Directory(p.join(documentsPath, root));
      if (!await dir.exists()) continue;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        // Thumbnails live beside the videos and share the semantic name.
        if (entity.path.contains('/.thumbs/') || name.startsWith('.')) continue;
        if (!_videoExtensions.contains(p.extension(name).toLowerCase())) {
          continue;
        }

        final token = sandboxHashToken(name);
        if (token == null) continue;

        final relative = p.relative(entity.path, from: documentsPath);
        byToken.putIfAbsent(token, () => []).add(relative);
      }
    }

    return SandboxHashIndex(byToken);
  }

  /// The relative path holding [contentHash]'s bytes, or null if the sandbox
  /// does not have them.
  ///
  /// A full-hash filename is trusted outright. A `hash8` match is trusted when
  /// it is the only one — 8 hex digits over one user's library is not a
  /// collision risk worth a multi-megabyte re-hash. When two or more files
  /// share a `hash8`, the ambiguity is real and each candidate is verified by
  /// full hash before it is trusted.
  Future<String?> resolve(
    final String contentHash, {
    required final String documentsPath,
    required final AssetHashService hasher,
  }) async {
    final full = contentHash.toLowerCase();
    final exact = _byToken[full];
    if (exact != null && exact.isNotEmpty) return exact.first;

    final short = full.length > 8 ? full.substring(0, 8) : full;
    final candidates = _byToken[short];
    if (candidates == null || candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    for (final relative in candidates) {
      final absolute = p.join(documentsPath, relative);
      if (await hasher.verifyHash(absolute, contentHash)) return relative;
    }
    return null;
  }
}
