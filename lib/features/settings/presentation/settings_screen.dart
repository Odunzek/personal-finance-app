import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/profile.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../../categories/presentation/category_list_screen.dart';
import '../../profiles/presentation/profile_list_screen.dart';

class SettingsScreen extends StatelessWidget {
  final Profile profile;
  final AuthRepository authRepository;

  const SettingsScreen({
    super.key,
    required this.profile,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.users),
                title: const Text('Profiles'),
                trailing: Text(profile.displayName),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileListScreen(authRepository: authRepository),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(LucideIcons.tags),
                title: const Text('Categories'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryListScreen(profile: profile),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(LucideIcons.sun),
                title: const Text('Appearance'),
                trailing: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light},
                    onSelectionChanged: (s) => themeModeNotifier.value = s.first,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(LucideIcons.info),
                title: const Text('About'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Kinscope',
                  applicationVersion: '1.0.0',
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(LucideIcons.logOut, color: Theme.of(context).colorScheme.error),
            title: const Text('Sign out'),
            textColor: Theme.of(context).colorScheme.error,
            onTap: authRepository.signOut,
          ),
        ).animate().fadeIn(delay: 80.ms, duration: 300.ms).slideY(begin: 0.05, end: 0),
      ],
    );
  }
}
