import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/providers/settings_providers.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/theme/app_theme.dart';

/// Root widget for the GemAI application.
///
/// Reads theme mode and onboarding state from Riverpod providers
/// and routes the user to either the [WelcomeScreen] or [HomeScreen].
class GemAIApp extends ConsumerWidget {
  const GemAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final onboardingComplete = ref.watch(onboardingProvider);

    return MaterialApp(
      title: 'GemAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: onboardingComplete
          ? const HomeScreen()
          : const WelcomeScreen(),
    );
  }
}
