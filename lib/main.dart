import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:spare_kart/app.dart';
import 'package:spare_kart/core/config/env_config.dart';
import 'package:spare_kart/data/india_locations.dart';
import 'package:spare_kart/data/vehicle_catalog.dart';
import 'package:spare_kart/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void _configureImagePicker() {
  final implementation = ImagePickerPlatform.instance;
  if (implementation is ImagePickerAndroid) {
    implementation.useAndroidPhotoPicker = true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureImagePicker();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    publishableKey: EnvConfig.supabaseAnonKey,
  );

  await Future.wait([
    VehicleCatalog.load(),
    IndiaLocations.load(),
  ]);

  runApp(const SpareKartApp());
}
