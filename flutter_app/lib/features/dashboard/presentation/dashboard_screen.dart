import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/auth_state.dart';

/// Placeholder — pełna implementacja w Kroku 4.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final username = auth is AuthAuthenticated ? auth.user.username : '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Palace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            tooltip: 'Wyloguj',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Witaj, $username', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(
                'Dashboard będzie tutaj w kroku 4.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
