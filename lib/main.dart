import 'package:flutter/material.dart';
import 'package:spare_kart/app.dart';
import 'package:spare_kart/core/config/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  runApp(const SpareKartApp());
}
