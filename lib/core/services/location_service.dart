import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

enum LocationSettingsAction {
  none,
  openLocationSettings,
  openAppSettings,
}

class LocationService {
  const LocationService();

  Future<bool> isLocationServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();

  static Future<bool> openSettingsFor(LocationServiceException error) {
    switch (error.settingsAction) {
      case LocationSettingsAction.openLocationSettings:
        return Geolocator.openLocationSettings();
      case LocationSettingsAction.openAppSettings:
        return Geolocator.openAppSettings();
      case LocationSettingsAction.none:
        return Future.value(false);
    }
  }

  Future<DeviceLocation> getCurrentLocation() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Location services are turned off. Enable them in Settings to continue.',
        settingsAction: LocationSettingsAction.openLocationSettings,
      );
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location permission is required. Allow access in Settings.',
        settingsAction: LocationSettingsAction.openAppSettings,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission is permanently denied. Enable it in app Settings.',
        settingsAction: LocationSettingsAction.openAppSettings,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: _formatCoordinates(position.latitude, position.longitude),
      );
    }

    final address = _formatPlacemark(placemarks.first);
    if (address.isEmpty) {
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: _formatCoordinates(position.latitude, position.longitude),
      );
    }

    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );
  }

  String _formatPlacemark(Placemark place) {
    final parts = <String>[
      if (place.street?.trim().isNotEmpty == true) place.street!.trim(),
      if (place.subLocality?.trim().isNotEmpty == true) place.subLocality!.trim(),
      if (place.locality?.trim().isNotEmpty == true) place.locality!.trim(),
      if (place.administrativeArea?.trim().isNotEmpty == true) place.administrativeArea!.trim(),
      if (place.postalCode?.trim().isNotEmpty == true) place.postalCode!.trim(),
      if (place.country?.trim().isNotEmpty == true) place.country!.trim(),
    ];

    final seen = <String>{};
    final unique = <String>[];
    for (final part in parts) {
      final key = part.toLowerCase();
      if (seen.add(key)) unique.add(part);
    }
    return unique.join(', ');
  }

  String _formatCoordinates(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}

class LocationServiceException implements Exception {
  const LocationServiceException(
    this.message, {
    this.settingsAction = LocationSettingsAction.none,
  });

  final String message;
  final LocationSettingsAction settingsAction;

  bool get canOpenSettings => settingsAction != LocationSettingsAction.none;

  String get settingsButtonLabel => switch (settingsAction) {
        LocationSettingsAction.openLocationSettings => 'Open Location Settings',
        LocationSettingsAction.openAppSettings => 'Open App Settings',
        LocationSettingsAction.none => 'Open Settings',
      };

  @override
  String toString() => message;
}
