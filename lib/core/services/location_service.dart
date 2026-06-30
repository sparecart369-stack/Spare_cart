import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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

class LocationService {
  const LocationService();

  Future<bool> isLocationServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();

  Future<DeviceLocation> getCurrentLocation() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'Location services are turned off. Enable them in device settings.',
      );
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location permission is required to use your current pickup address.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission is permanently denied. Enable it in app settings.',
        openSettings: true,
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
      throw const LocationServiceException(
        'Could not resolve an address for your current location.',
      );
    }

    final address = _formatPlacemark(placemarks.first);
    if (address.isEmpty) {
      throw const LocationServiceException(
        'Could not resolve an address for your current location.',
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
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.message, {this.openSettings = false});

  final String message;
  final bool openSettings;

  @override
  String toString() => message;
}
