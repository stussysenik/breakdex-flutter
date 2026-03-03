import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/design/theme.dart';
import 'core/navigation/app_router.dart';
import 'core/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Global error widget for production resilience
  ErrorWidget.builder = (details) => Material(
    color: Colors.transparent,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Something went wrong',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BreakdexApp(),
    ),
  );
}

class BreakdexApp extends ConsumerWidget {
  const BreakdexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSetting = ref.watch(themeSettingProvider);

    return MaterialApp.router(
      title: 'Breakdex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeSetting.themeMode,
      routerConfig: appRouter,
    );
  }
}
