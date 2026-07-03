import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthHero extends StatelessWidget {
  const AuthHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '🏛 pałac pamięci',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Memory\n',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w800,
                  fontSize: 40,
                  height: 1.05,
                  letterSpacing: -1,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: 'Palace',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w800,
                  fontSize: 40,
                  height: 1.05,
                  letterSpacing: -1,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
