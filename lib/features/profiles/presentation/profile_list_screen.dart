import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/default_categories.dart';
import '../../../core/models/profile.dart';
import '../../auth/data/auth_repository.dart';
import '../../categories/data/category_repository.dart';
import '../../home/presentation/main_shell.dart';
import '../data/profile_repository.dart';
import 'profile_form_sheet.dart';

class ProfileListScreen extends StatefulWidget {
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final CategoryRepository categoryRepository;

  /// Auto-enter the profile without showing the list when there's exactly
  /// one. Only appropriate for the initial post-sign-in gate — when this
  /// screen is opened deliberately (e.g. from Settings to manage profiles),
  /// pass false so a single profile is still shown, not skipped past.
  final bool autoSelectSingle;

  ProfileListScreen({
    super.key,
    required this.authRepository,
    this.autoSelectSingle = false,
    ProfileRepository? profileRepository,
    CategoryRepository? categoryRepository,
  }) : profileRepository = profileRepository ?? SupabaseProfileRepository(),
       categoryRepository = categoryRepository ?? SupabaseCategoryRepository();

  @override
  State<ProfileListScreen> createState() => _ProfileListScreenState();
}

class _ProfileListScreenState extends State<ProfileListScreen> {
  late Future<List<Profile>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _profilesFuture = widget.profileRepository.listProfiles();
    });
  }

  Future<void> _createProfile({bool isFirstProfile = false}) async {
    final result = await showProfileFormSheet(context);
    if (result == null) return;
    final created = await widget.profileRepository.createProfile(
      displayName: result.displayName,
      currencyCode: result.currencyCode,
    );
    for (final seed in kDefaultCategorySeeds) {
      await widget.categoryRepository.createCategory(
        profileId: created.id,
        name: seed.name,
        type: seed.type,
        colorArgb: seed.colorArgb,
        iconKey: seed.iconKey,
      );
    }
    if (isFirstProfile) {
      _openProfile(created);
      return;
    }
    _reload();
  }

  Future<void> _renameProfile(Profile profile) async {
    final result = await showProfileFormSheet(
      context,
      initialName: profile.displayName,
      initialCurrency: profile.currencyCode,
    );
    if (result == null) return;
    await widget.profileRepository.renameProfile(
      profile.id,
      result.displayName,
    );
    _reload();
  }

  Future<void> _deleteProfile(Profile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text(
          'This permanently deletes "${profile.displayName}" and all of '
          'its categories and transactions. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.profileRepository.deleteProfile(profile.id);
    _reload();
  }

  void _openProfile(Profile profile) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainShell(
          profile: profile,
          authRepository: widget.authRepository,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kinscope'),
        actions: [
          IconButton(
            onPressed: widget.authRepository.signOut,
            icon: const Icon(LucideIcons.logOut),
            tooltip: 'Sign out',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createProfile,
        child: const Icon(LucideIcons.plus),
      ),
      body: FutureBuilder<List<Profile>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profiles = snapshot.data!;
          if (profiles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.userRoundPlus,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No profiles yet',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first profile to get started.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _createProfile(isFirstProfile: true),
                      child: const Text('Create profile'),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
          }
          if (profiles.length == 1 && widget.autoSelectSingle) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openProfile(profiles.first);
            });
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        LucideIcons.user,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(profile.displayName),
                    subtitle: Text(profile.currencyCode),
                    onTap: () => _openProfile(profile),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(LucideIcons.moreVertical),
                      onSelected: (value) {
                        if (value == 'rename') _renameProfile(profile);
                        if (value == 'delete') _deleteProfile(profile);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (index * 40).ms, duration: 200.ms).slideX(begin: 0.03, end: 0);
            },
          );
        },
      ),
    );
  }
}
