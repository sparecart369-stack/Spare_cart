import 'dart:convert';

import 'package:flutter/services.dart';

/// Vehicle make/model catalog sourced from Wikipedia car lists.
class VehicleCatalog {
  VehicleCatalog._(this._modelsByMake);

  static const int minVehicleYear = 1900;
  static const int maxVehicleYear = 2028;

  static List<int> get vehicleYears => List.generate(
        maxVehicleYear - minVehicleYear + 1,
        (i) => maxVehicleYear - i,
      );

  static VehicleCatalog? _instance;

  final Map<String, List<String>> _modelsByMake;
  List<String>? _makesCache;

  static VehicleCatalog get instance {
    final catalog = _instance;
    if (catalog == null) {
      throw StateError('VehicleCatalog.load() must complete before use.');
    }
    return catalog;
  }

  static bool get isLoaded => _instance != null;

  static Future<VehicleCatalog> load() async {
    if (_instance != null) return _instance!;

    final raw = await rootBundle.loadString('assets/data/vehicle_catalog.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final makesJson = json['makes'] as List<dynamic>? ?? const [];

    final modelsByMake = <String, List<String>>{};
    for (final entry in makesJson) {
      if (entry is! Map<String, dynamic>) continue;
      final name = entry['name'] as String?;
      if (name == null || name.isEmpty) continue;

      final models = (entry['models'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .where((model) => model.isNotEmpty)
          .toList(growable: false);

      modelsByMake[name] = models;
    }

    _instance = VehicleCatalog._(modelsByMake);
    return _instance!;
  }

  List<String> get makes {
    return _makesCache ??= (_modelsByMake.keys.toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())));
  }

  List<String> modelsFor(String? make) {
    if (make == null || make.isEmpty) return const [];
    return _modelsByMake[make] ?? const [];
  }

  bool hasModels(String? make) => modelsFor(make).isNotEmpty;

  /// When a make has no models in the catalog, use the make name as the model.
  String? defaultModelFor(String? make) {
    if (make == null || make.isEmpty) return null;
    return hasModels(make) ? null : make;
  }

  /// Picker labels — includes make prefix when models exist, or just the make otherwise.
  List<String> modelPickerItems(String? make) {
    if (make == null || make.isEmpty) return const [];
    final models = modelsFor(make);
    if (models.isEmpty) return [make];
    return models.map((model) => '$make $model').toList(growable: false);
  }

  /// Label shown in the model field.
  String? modelDisplayLabel({required String? make, required String? model}) {
    if (make == null || model == null) return null;
    if (!hasModels(make)) return make;
    return '$make $model';
  }

  /// Converts a picker label back to the stored model value.
  String modelValueFromPicker({required String make, required String pickerLabel}) {
    if (!hasModels(make)) return make;
    final prefix = '$make ';
    if (pickerLabel.startsWith(prefix)) {
      return pickerLabel.substring(prefix.length);
    }
    return pickerLabel;
  }

  bool hasMake(String make) => _modelsByMake.containsKey(make);
}
