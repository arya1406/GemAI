import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'data/datasources/ai/local_gemma_data_source.dart';
import 'presentation/providers/chat_providers.dart';
import 'presentation/providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LocalGemmaDataSource? preloadedDataSource;

  // FlutterGemma is only supported on Android/iOS — skip on desktop.
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    try {
      await FlutterGemma.initialize();

      // Pre-install the bundled Ultra-Light model from app assets.
      // This copies the .task file from the APK/IPA into the device's
      // data directory. Subsequent launches are a fast no-op.
      final ds = LocalGemmaDataSource(
        variant: GemmaModelVariant.ultraLight,
      );
      final installed = await ds.installFromAsset();
      if (installed) {
        final loaded = await ds.loadModel();
        if (loaded) preloadedDataSource = ds;
      }
    } catch (e) {
      debugPrint('FlutterGemma init skipped: $e');
    }
  }

  final database = AppDatabase();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (preloadedDataSource != null)
          preloadedGemmaProvider.overrideWithValue(preloadedDataSource),
      ],
      child: const GemAIApp(),
    ),
  );
}
