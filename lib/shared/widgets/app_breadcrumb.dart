import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:breakdex/core/design/layout.dart';
import 'package:breakdex/core/design/typography.dart';

/// One crumb: what it reads as, and where it goes.
@immutable
class AppCrumb {
  const AppCrumb({required this.label, required this.location});

  /// The slug as displayed — lowercase, hyphenated, id-elided.
  final String label;

  /// The absolute location this crumb addresses.
  final String location;

  @override
  bool operator ==(final Object other) =>
      other is AppCrumb &&
      other.label == label &&
      other.location == location;

  @override
  int get hashCode => Object.hash(label, location);

  @override
  String toString() => 'AppCrumb($label -> $location)';
}

/// Split an absolute location into the crumb trail it addresses.
///
/// Pure: no router, no context. `/breakdex/moves/Power%20Moves` becomes
/// `breakdex › moves › power-moves`, each crumb carrying the prefix it points
/// at. Query and fragment are dropped — a crumb addresses a page, not a state.
List<AppCrumb> breadcrumbsFor(final String path) {
  final segments = Uri.parse(path).pathSegments;
  final crumbs = <AppCrumb>[];
  final buffer = StringBuffer();
  for (final segment in segments) {
    buffer.write('/$segment');
    crumbs.add(AppCrumb(label: crumbLabel(segment), location: buffer.toString()));
  }
  return crumbs;
}

/// The displayed form of one path segment.
///
/// Slugs are the vocabulary here: lowercase, hyphens for spaces. Opaque ids
/// (uuids, long tokens) are elided in the middle — the crumb has to say *where*
/// you are, and 36 characters of uuid says nothing a reader can use.
String crumbLabel(final String segment) {
  final decoded = Uri.decodeComponent(segment)
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s_]+'), '-');
  if (decoded.length <= 16) return decoded;
  return '${decoded.substring(0, 6)}…${decoded.substring(decoded.length - 4)}';
}

/// The lexical address line, rendered above every screen title.
///
/// It answers one question the four-band frame otherwise leaves unanswered:
/// *where am I, and how did I get here.* Crumbs that resolve to a real route
/// are tappable and go there; intermediate segments that address nothing
/// (`/breakdex/move` — a prefix, not a page) render as plain text rather than
/// as a link that would bounce the user home.
///
/// Text only — no chips, no chevrons, no boxes. The trail is one line of type
/// on the same baseline on every screen, so it reads as an address, not as a
/// control panel.
class AppBreadcrumb extends StatelessWidget {
  const AppBreadcrumb({super.key, this.path});

  /// Override the location. Defaults to the router's current location; null on
  /// both counts (a widget test with no router) renders nothing.
  final String? path;

  @override
  Widget build(final BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final location = path ?? _currentLocation(router);
    if (location == null) return const SizedBox.shrink();

    final crumbs = breadcrumbsFor(location);
    if (crumbs.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final muted = AppTypography.caption.copyWith(color: colorScheme.secondary);
    final here = AppTypography.caption.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    final spans = <Widget>[Text('/', style: muted)];
    for (var i = 0; i < crumbs.length; i++) {
      final crumb = crumbs[i];
      final isLast = i == crumbs.length - 1;
      if (i > 0) {
        spans.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('/', style: muted),
          ),
        );
      }
      final label = Text(crumb.label, style: isLast ? here : muted);
      spans.add(
        isLast || !_resolves(router, crumb.location)
            ? label
            : _CrumbLink(location: crumb.location, child: label),
      );
    }

    return SizedBox(
      height: AppLayout.crumbHeight,
      // reverse: the tail — where you actually are — stays pinned in view when
      // the trail outgrows the column.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(mainAxisSize: MainAxisSize.min, children: spans),
      ),
    );
  }

  static String? _currentLocation(final GoRouter? router) {
    if (router == null) return null;
    return router.state.uri.path;
  }

  /// Whether a prefix addresses a real route. `findMatch` is the router's own
  /// answer, so this cannot drift from the route table the way a hand-kept
  /// list of "linkable" segments would.
  static bool _resolves(final GoRouter? router, final String location) {
    if (router == null) return false;
    return !router.configuration.findMatch(Uri.parse(location)).isError;
  }
}

class _CrumbLink extends StatelessWidget {
  const _CrumbLink({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    return Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => GoRouter.of(context).go(location),
          child: child,
        ),
      ),
    );
  }
}
