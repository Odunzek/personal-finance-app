import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/env.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';

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
    return MaterialApp(
      title: 'Finance App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const _StatusScreen(),
    );
  }
}

class _StatusScreen extends StatelessWidget {
  const _StatusScreen();

  @override
  Widget build(BuildContext context) {
    final configured = Env.isConfigured;
    return Scaffold(
      appBar: AppBar(title: const Text('Finance App')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                configured ? Icons.check_circle : Icons.warning_amber,
                color: configured ? Colors.green : Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                configured
                    ? 'Supabase is configured and initialized.'
                    : 'Supabase is not configured yet.\nAdd SUPABASE_URL and SUPABASE_ANON_KEY to .env.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
