import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/sign_in_screen.dart';
import 'features/profiles/presentation/profile_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  if (Env.isConfigured) {
    await initSupabase();
  }
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => MaterialApp(
        title: 'Kinscope',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: Env.isConfigured ? AuthGate() : const _NotConfiguredScreen(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final AuthRepository authRepository;

  AuthGate({super.key, AuthRepository? authRepository})
    : authRepository = authRepository ?? SupabaseAuthRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: authRepository.authStateChanges,
      builder: (context, snapshot) {
        final signedIn = authRepository.currentUser != null;
        return signedIn
            ? ProfileListScreen(
                authRepository: authRepository,
                autoSelectSingle: true,
              )
            : SignInScreen(authRepository: authRepository);
      },
    );
  }
}

class _NotConfiguredScreen extends StatelessWidget {
  const _NotConfiguredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kinscope')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 48),
              SizedBox(height: 16),
              Text(
                'Supabase is not configured yet.\nAdd SUPABASE_URL and SUPABASE_ANON_KEY to .env.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
