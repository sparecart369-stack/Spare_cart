import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:spare_kart/core/constants/app_assets.dart';

class PartSubcategory {
  const PartSubcategory({
    required this.id,
    required this.name,
    required this.group,
    this.image,
  });

  final String id;
  final String name;
  final String group;
  final String? image;
}

class PartCategoryCatalog {
  const PartCategoryCatalog({
    required this.id,
    required this.name,
    required this.subcategories,
  });

  final String id;
  final String name;
  final List<PartSubcategory> subcategories;

  List<String> get groups {
    final seen = <String>{};
    final result = <String>[];
    for (final sub in subcategories) {
      if (seen.add(sub.group)) result.add(sub.group);
    }
    return result;
  }

  List<PartSubcategory> subcategoriesForGroup(String group) =>
      subcategories.where((sub) => sub.group == group).toList(growable: false);

  PartSubcategory? subcategoryById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final sub in subcategories) {
      if (sub.id == id) return sub;
    }
    return null;
  }

  PartSubcategory? subcategoryByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final sub in subcategories) {
      if (sub.name == name) return sub;
    }
    return null;
  }
}

/// Hierarchical parts taxonomy for filters and sell listings.
class PartsCatalog {
  PartsCatalog._(this._categoriesByName, this._categoriesById);

  static PartsCatalog? _instance;

  final Map<String, PartCategoryCatalog> _categoriesByName;
  final Map<String, PartCategoryCatalog> _categoriesById;

  static PartsCatalog get instance {
    final catalog = _instance;
    if (catalog == null) {
      throw StateError('PartsCatalog.load() must complete before use.');
    }
    return catalog;
  }

  static bool get isLoaded => _instance != null;

  static Future<PartsCatalog> load() async {
    if (_instance != null) return _instance!;

    final raw = await rootBundle.loadString('assets/data/parts_catalog.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final categoriesJson = json['categories'] as List<dynamic>? ?? const [];

    final byName = <String, PartCategoryCatalog>{};
    final byId = <String, PartCategoryCatalog>{};

    for (final entry in categoriesJson) {
      if (entry is! Map<String, dynamic>) continue;
      final id = entry['id'] as String?;
      final name = entry['name'] as String?;
      if (id == null || name == null) continue;

      final subsJson = entry['subcategories'] as List<dynamic>? ?? const [];
      final subcategories = <PartSubcategory>[];
      for (final subEntry in subsJson) {
        if (subEntry is! Map<String, dynamic>) continue;
        final subId = subEntry['id'] as String?;
        final subName = subEntry['name'] as String?;
        final group = subEntry['group'] as String?;
        if (subId == null || subName == null || group == null) continue;
        subcategories.add(
          PartSubcategory(
            id: subId,
            name: subName,
            group: group,
            image: subEntry['image'] as String?,
          ),
        );
      }

      final category = PartCategoryCatalog(
        id: id,
        name: name,
        subcategories: subcategories,
      );
      byName[name] = category;
      byId[id] = category;
    }

    _instance = PartsCatalog._(byName, byId);
    return _instance!;
  }

  List<String> get categoryNames => _categoriesByName.keys.toList(growable: false);

  PartCategoryCatalog? categoryForName(String? name) =>
      name == null ? null : _categoriesByName[name];

  PartCategoryCatalog? categoryForId(String? id) => id == null ? null : _categoriesById[id];

  List<PartSubcategory> subcategoriesForCategory(String? categoryName) =>
      categoryForName(categoryName)?.subcategories ?? const [];

  String? subcategoryImageFor({
    required String? categoryName,
    required String? subcategoryId,
  }) {
    final category = categoryForName(categoryName);
    return category?.subcategoryById(subcategoryId)?.image;
  }

  /// Uses explicit catalog image first, then `assets/sub/{categoryId}/{subcategoryId}.png`.
  String resolveSubcategoryImage({
    required PartCategoryCatalog category,
    required PartSubcategory subcategory,
  }) {
    final explicit = subcategory.image;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return AppAssets.subcategoryImagePath(
      categoryId: category.id,
      subcategoryId: subcategory.id,
    );
  }
}
