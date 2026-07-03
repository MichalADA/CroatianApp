import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/errors/failure.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/data/auth_repository_impl.dart';
import '../../auth/data/models/auth_dtos.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _saving = false;

  Future<void> _persistTheme(ThemeMode mode) async {
    await ref.read(themeControllerProvider.notifier).setMode(mode);
    // Zsynchronizuj z backendem (best effort — nie blokuje UI jeśli padnie).
    setState(() => _saving = true);
    try {
      final api = ref.read(authApiProvider);
      final updated = await api.updateSettings(
        SettingsUpdateRequest(theme: mode == ThemeMode.dark ? 'dark' : 'light'),
      );
      ref.read(authControllerProvider.notifier).updateUser(updated);
    } on Object {
      // ignore — offline też ok
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final mode = ref.watch(themeControllerProvider);

    final user = auth is AuthAuthenticated ? auth.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) ...[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(user.username),
                subtitle: Text(user.email),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text('Motyw',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 2)),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Ciemny')),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Jasny')),
            ],
            selected: {mode == ThemeMode.system ? ThemeMode.dark : mode},
            onSelectionChanged: _saving ? null : (s) => _persistTheme(s.first),
          ),
          const SizedBox(height: 32),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Wyloguj'),
              onTap: () async {
                try {
                  await ref.read(authControllerProvider.notifier).logout();
                } on Failure catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Memory Palace · v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
          ),
        ],
      ),
    );
  }
}
