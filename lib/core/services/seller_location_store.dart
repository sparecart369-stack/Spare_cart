import 'package:shared_preferences/shared_preferences.dart';

class SellerLocation {
  const SellerLocation({required this.state, required this.district});

  final String state;
  final String district;

  bool get isComplete => state.isNotEmpty && district.isNotEmpty;
}

class SellerLocationStore {
  SellerLocationStore({this._prefs});

  final SharedPreferences? _prefs;

  static const _stateKey = 'seller_location_state';
  static const _districtKey = 'seller_location_district';

  Future<SharedPreferences> get _preferences async =>
      _prefs ?? await SharedPreferences.getInstance();

  Future<SellerLocation?> load() async {
    final prefs = await _preferences;
    final state = prefs.getString(_stateKey);
    final district = prefs.getString(_districtKey);
    if (state == null || district == null || state.isEmpty || district.isEmpty) {
      return null;
    }
    return SellerLocation(state: state, district: district);
  }

  Future<void> save({required String state, required String district}) async {
    final prefs = await _preferences;
    await prefs.setString(_stateKey, state);
    await prefs.setString(_districtKey, district);
  }
}
