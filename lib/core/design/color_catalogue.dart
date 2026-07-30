import 'package:flutter/foundation.dart';

import 'package:breakdex/core/design/color_packs.dart';

/// A named group of color packs sharing a theme, season, or year.
@immutable
class ColorCollection {
  const ColorCollection({
    required this.id,
    required this.name,
    this.description,
    this.year,
    this.season,
    required this.packs,
  });

  final String id;
  final String name;

  /// Short description of what defines this collection.
  final String? description;

  /// The year this collection was curated for (e.g. 2026).
  final int? year;

  /// The season this collection evokes (e.g. "Spring", "Autumn").
  final String? season;

  /// The packs belonging to this collection, in display order.
  final List<ColorPackId> packs;
}

/// A catalogue of color pack collections.
///
/// The catalogue is the browsing and discovery layer for color packs. It
/// organises packs into named, browsable collections — grouped by season,
/// year, or theme — so the user can find the palette they want without
/// scrolling a flat list.
///
/// Multiple sources can coexist behind this interface: an in-house curated
/// set (the default), a licensed Pantone dataset (Path A), or user-created
/// collections. The pack mechanism is the same regardless of source.
abstract class ColorCatalogue {
  const ColorCatalogue();

  /// All collections in display order.
  List<ColorCollection> get collections;

  /// Look up a collection by [id].
  ColorCollection? collectionById(final String id) {
    for (final c in collections) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// The default in-house curated catalogue.
///
/// Ships with the two proven packs (`classic`, `mono`) organised into
/// display groups. When a new handpicked family is designed (6.2), it is
/// added here as a new collection.
final class InHouseCatalogue extends ColorCatalogue {
  const InHouseCatalogue();

  @override
  List<ColorCollection> get collections => [
    const ColorCollection(
      id: 'default',
      name: 'Default',
      description: 'The original Breakdex palette.',
      packs: [ColorPackId.classic],
    ),
    const ColorCollection(
      id: 'monochrome',
      name: 'Monochrome',
      description: 'A clean grayscale interface.',
      packs: [ColorPackId.mono],
    ),
  ];
}

/// Singleton access to the default catalogue.
const ColorCatalogue colorCatalogue = InHouseCatalogue();
