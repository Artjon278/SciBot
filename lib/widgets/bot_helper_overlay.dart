import 'package:flutter/material.dart';

/// Overlay wrapper - bot helper functionality has been disabled
class BotHelperOverlay extends StatelessWidget {
  final String currentScreen;
  final Widget child;

  const BotHelperOverlay({
    super.key,
    required this.currentScreen,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Bot helper overlay disabled - show only the main content
    return child;
  }
}
