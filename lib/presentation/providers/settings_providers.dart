import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/datasources/ai/local_gemma_data_source.dart';

// ---------------------------------------------------------------------------
// SharedPreferences instance provider
// ---------------------------------------------------------------------------

/// Provides the [SharedPreferences] singleton.
///
/// Must be overridden in the root [ProviderScope] after
/// `SharedPreferences.getInstance()` completes.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Override sharedPreferencesProvider in ProviderScope',
  );
});

// ---------------------------------------------------------------------------
// Theme mode
// ---------------------------------------------------------------------------

/// Manages the app-wide [ThemeMode] preference, persisted via
/// [SharedPreferences].
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final index = prefs.getInt(AppConstants.keyThemeMode) ?? 0;
    return ThemeMode.values[index.clamp(0, ThemeMode.values.length - 1)];
  }

  /// Updates the theme mode and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(AppConstants.keyThemeMode, mode.index);
    state = mode;
  }
}

/// Provides the current [ThemeMode] and its [ThemeModeNotifier].
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ---------------------------------------------------------------------------
// Model variant
// ---------------------------------------------------------------------------

/// Manages the selected [GemmaModelVariant], persisted via
/// [SharedPreferences].
class ModelVariantNotifier extends Notifier<GemmaModelVariant> {
  @override
  GemmaModelVariant build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final name = prefs.getString(AppConstants.keyModelVariant);
    if (name == null) return GemmaModelVariant.ultraLight;
    return GemmaModelVariant.values.firstWhere(
      (v) => v.name == name,
      orElse: () => GemmaModelVariant.standard,
    );
  }

  /// Updates the model variant and persists the choice.
  Future<void> setVariant(GemmaModelVariant variant) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(AppConstants.keyModelVariant, variant.name);
    state = variant;
  }
}

/// Provides the current [GemmaModelVariant] and its [ModelVariantNotifier].
final modelVariantProvider =
    NotifierProvider<ModelVariantNotifier, GemmaModelVariant>(
  ModelVariantNotifier.new,
);

// ---------------------------------------------------------------------------
// Onboarding
// ---------------------------------------------------------------------------

/// Tracks whether the user has completed the onboarding flow.
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;
  }

  /// Marks onboarding as completed.
  Future<void> complete() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(AppConstants.keyOnboardingComplete, true);
    state = true;
  }
}

/// Provides the onboarding completion state and its [OnboardingNotifier].
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

// ---------------------------------------------------------------------------
// Online fallback toggle
// ---------------------------------------------------------------------------

/// Manages whether online AI fallback is enabled.
class OnlineFallbackNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(AppConstants.keyOnlineFallback) ?? false;
  }

  /// Toggles the online fallback preference.
  Future<void> toggle() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final newValue = !state;
    await prefs.setBool(AppConstants.keyOnlineFallback, newValue);
    state = newValue;
  }
}

/// Provides the online fallback toggle and its [OnlineFallbackNotifier].
final onlineFallbackProvider =
    NotifierProvider<OnlineFallbackNotifier, bool>(OnlineFallbackNotifier.new);
