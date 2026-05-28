/// Supabase project URL and anon key — pass at build/run time:
/// flutter run -d chrome \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=your-anon-key
class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

/// Backend API base URL.
/// Override at build time: --dart-define=API_URL=https://your-deployment.onrender.com
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000', // local dev default
    // Production: 'https://arco-papers-api.onrender.com'
  );
}
