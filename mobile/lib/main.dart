import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/services/fcm_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Run app UI immediately so screen never stays white
  runApp(
    const ProviderScope(
      child: MailNexaApp(),
    ),
  );

  // Initialize Firebase in background safely
  _initFirebaseAsync();
}

Future<void> _initFirebaseAsync() async {
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
      await FcmService.initialize();
    }
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
}

class MailNexaApp extends ConsumerWidget {
  const MailNexaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.read(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'MailNexa',
      debugShowCheckedModeBanner: false,

      // Routing
      routerConfig: router,

      // Theming
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Localization
      supportedLocales: const [Locale('en', 'US')],
    );
  }
}

/// Provider for theme mode (light/dark toggle)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
