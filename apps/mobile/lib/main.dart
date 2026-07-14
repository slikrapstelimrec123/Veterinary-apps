import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_gate.dart';
import 'core/auth/auth_repository.dart';
import 'core/auth/auth_state.dart' as app_auth;
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  runApp(const VetCareApp());
}

class VetCareApp extends StatefulWidget {
  const VetCareApp({super.key});

  @override
  State<VetCareApp> createState() => _VetCareAppState();
}

class _VetCareAppState extends State<VetCareApp> {
  late final app_auth.AuthState authState;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    authState = app_auth.AuthState(AuthRepository());
    authState.bootstrap();
  }

  @override
  void dispose() {
    authState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return app_auth.AuthScope(
      notifier: authState,
      child: MaterialApp(
        title: 'Lappo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('uk'), // Ukrainian
          Locale('ru'), // Russian
          Locale('en'), // English
        ],
        locale: const Locale('uk'),
        home: _showSplash
            ? SplashScreen(onDone: () => setState(() => _showSplash = false))
            : const AuthGate(),
      ),
    );
  }
}
