import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_service.dart';
import '../design/colors.dart';

class Category {
  final String name;
  final int colorValue;
  final bool isDefault;

  const Category({
    required this.name,
    required this.colorValue,
    this.isDefault = false,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
    'name': name,
    'colorValue': colorValue,
    'isDefault': isDefault,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    name: json['name'] as String,
    colorValue: json['colorValue'] as int,
    isDefault: json['isDefault'] as bool? ?? false,
  );
}

/// Preset colors for the color picker
const categoryPresetColors = [
  AppColors.actionAgain,
  AppColors.accent,
  AppColors.stateMastery,
  AppColors.actionGood,
  AppColors.stateNew,
  AppColors.stateLearning,
  AppColors.actionHard,
  AppColors.darkSecondary,
];

const _defaultCategories = [
  Category(name: 'Power Moves', colorValue: 0xFFDA1E28, isDefault: true),
  Category(name: 'Footwork', colorValue: 0xFF2362A2, isDefault: true),
  Category(name: 'Freezes', colorValue: 0xFF8A3FFC, isDefault: false),
  Category(name: 'Toprock', colorValue: 0xFF42BE65, isDefault: false),
];

final categoriesProvider =
    NotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);

class CategoriesNotifier extends Notifier<List<Category>> {
  static const _key = 'categories';

  @override
  List<Category> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final json = prefs.getString(_key);
    if (json == null) return List.from(_defaultCategories);
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return List.from(_defaultCategories);
    }
  }

  Future<void> addCategory(String name, Color color) async {
    final updated = [
      ...state,
      Category(name: name, colorValue: color.toARGB32()),
    ];
    state = updated;
    await _persist(updated);
  }

  Future<void> removeCategory(String name) async {
    final updated = state.where((c) => c.name != name).toList();
    state = updated;
    await _persist(updated);
  }

  Future<void> _persist(List<Category> categories) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _key,
      jsonEncode(categories.map((c) => c.toJson()).toList()),
    );
  }
}
