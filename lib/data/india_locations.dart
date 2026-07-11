import 'dart:convert';

import 'package:flutter/services.dart';

/// Indian states / union territories and their districts (LGD-based dataset).
class IndiaLocations {
  IndiaLocations._(this._districtsByState);

  static IndiaLocations? _instance;

  final Map<String, List<String>> _districtsByState;
  List<String>? _statesCache;

  static IndiaLocations get instance {
    final catalog = _instance;
    if (catalog == null) {
      throw StateError('IndiaLocations.load() must complete before use.');
    }
    return catalog;
  }

  static bool get isLoaded => _instance != null;

  static Future<IndiaLocations> load() async {
    if (_instance != null) return _instance!;

    final raw = await rootBundle.loadString('assets/data/india_locations.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final districtsByState = <String, List<String>>{};
    for (final entry in json.entries) {
      final districts = (entry.value as List<dynamic>? ?? const [])
          .whereType<String>()
          .where((district) => district.isNotEmpty)
          .toList(growable: false);
      districtsByState[entry.key] = districts;
    }

    _instance = IndiaLocations._(districtsByState);
    return _instance!;
  }

  List<String> get states {
    return _statesCache ??= (_districtsByState.keys.toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())));
  }

  List<String> districtsFor(String? state) {
    if (state == null || state.isEmpty) return const [];
    return _districtsByState[state] ?? const [];
  }

  bool isValidSelection({required String state, required String district}) {
    return districtsFor(state).contains(district);
  }
}
