import 'package:flutter/material.dart';

/// Wrapper który na desktopie/tablecie centruje content i ogranicza jego
/// szerokość — na telefonie zajmuje pełną szerokość (bo szerokość ekranu
/// i tak jest mniejsza od `maxWidth`).
///
/// Trzymamy jeden komponent, żeby każdy ekran robił to samo, spójnie.
class CenteredContent extends StatelessWidget {
  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = 900,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
