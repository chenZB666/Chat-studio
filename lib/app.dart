import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'services/desktop_tray_service.dart';

class LlamaChatApp extends ConsumerStatefulWidget {
  const LlamaChatApp({super.key});

  @override
  ConsumerState<LlamaChatApp> createState() => _LlamaChatAppState();
}

class _LlamaChatAppState extends ConsumerState<LlamaChatApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).load();
      ref.read(storageServiceProvider).seedBuiltInTemplates();
    });
    // Initialize system tray after runApp (platform channels need active event loop)
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DesktopTrayService.init();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mobile: No special action needed when going to/from background.
    // Dio connections stay alive, SQLite is available.
    // ChatState is preserved in memory and UI re-renders on return.
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed to foreground');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Chat Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.colorSeed),
      darkTheme: AppTheme.dark(settings.colorSeed),
      themeMode: settings.themeMode,
      home: const HomeScreen(),
    );
  }
}