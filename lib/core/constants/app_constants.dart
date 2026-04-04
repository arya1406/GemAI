/// Application-wide constant values.
class AppConstants {
  AppConstants._();

  static const String appName = 'GemAI';
  static const String databaseName = 'gem_ai.db';

  /// The privacy-first slogan displayed throughout the app.
  static const String privacySlogan =
      'AI assistant for you and you alone.\n'
      'No personal data collected. No chats collected.\n'
      'Just you and GemAI.';

  // --- SharedPreferences keys ---

  /// Key for the selected [ThemeMode] index.
  static const String keyThemeMode = 'gem_ai_theme_mode';

  /// Key for the selected Gemma model variant name.
  static const String keyModelVariant = 'gem_ai_model_variant';

  /// Key indicating whether the user has completed onboarding.
  static const String keyOnboardingComplete = 'gem_ai_onboarding_complete';

  /// Key for the online fallback toggle.
  static const String keyOnlineFallback = 'gem_ai_online_fallback';
}
