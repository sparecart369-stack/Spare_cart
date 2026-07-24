/// Supabase configuration for SpareKart production.
///
/// Override at build time with:
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
class EnvConfig {
  EnvConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hdydlfaabjtdkgmiavcq.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhkeWRsZmFhYmp0ZGtnbWlhdmNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0NDE3MDUsImV4cCI6MjA5ODAxNzcwNX0.e8HPOGoy57LKhry5MFAm_r49dr3iVCiuRP9Uhij99YU',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const cashfreeAppId = String.fromEnvironment(
    'CASHFREE_APP_ID',
    defaultValue: '1331171fd10aa7c6788a622dbce1711331',
  );

  static bool get isCashfreeConfigured => cashfreeAppId.isNotEmpty;
}
