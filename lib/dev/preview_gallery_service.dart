import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final previewGalleryThemeProvider = StateProvider<ThemeMode>(
  (_) => ThemeMode.light,
);
