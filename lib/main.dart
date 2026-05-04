import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_track/app/app.dart';
import 'package:hand_track/core/theme/app_theme.dart';
import 'package:hand_track/features/settings/application/settings_providers.dart';

void main() {
  runApp(const ProviderScope(child: HandTrackApp()));
}

class HandTrackApp extends ConsumerWidget {
  const HandTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp(
      title: 'Hand Track',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLight(),
      darkTheme: AppTheme.buildDark(),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HandTrackAppShell(),
    );
  }
}
