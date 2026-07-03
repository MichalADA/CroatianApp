import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../auth/data/auth_repository_impl.dart';
import '../../../languages/data/languages_repository.dart';
import '../../../languages/domain/entities/language.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  Future<void> _changeLanguage(WidgetRef ref, String code) async {
    final result = await ref.read(languagesRepositoryProvider).setMine(code);
    // Odśwież dane usera i language list.
    ref.invalidate(languagesListProvider);
    // Pobierz na nowo /auth/me, żeby selectedLanguage się zaktualizował
    // (backend zwraca zaktualizowane pole), lub uaktualnij lokalnie:
    final auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) {
      final api = ref.read(authApiProvider);
      try {
        final fresh = await api.me();
        ref.read(authControllerProvider.notifier).updateUser(fresh);
      } on Object {
        // fallback: manualnie ustaw kod
        ref
            .read(authControllerProvider.notifier)
            .updateUser(auth.user.copyWith(selectedLanguage: result.code));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(languagesListProvider);
    final auth = ref.watch(authControllerProvider);
    final currentCode =
        auth is AuthAuthenticated ? auth.user.selectedLanguage : 'hr';

    return languagesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (langs) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: langs
              .map((l) => _LangButton(
                    language: l,
                    active: l.code == currentCode,
                    onTap: l.code == currentCode
                        ? null
                        : () => _changeLanguage(ref, l.code),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({required this.language, required this.active, this.onTap});

  final Language language;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: active
          ? theme.colorScheme.surfaceContainerHighest
          : Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                language.code.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (!language.hasContent) ...[
                const SizedBox(width: 3),
                Icon(Icons.circle_outlined,
                    size: 10,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.35)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
