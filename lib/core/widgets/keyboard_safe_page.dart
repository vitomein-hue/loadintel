import 'package:flutter/material.dart';

/// A reusable wrapper for form pages that makes them keyboard-safe on iOS.
///
/// Features:
/// - Scrollable content that adjusts when keyboard appears
/// - Tap outside inputs to dismiss keyboard
/// - Drag to dismiss keyboard
/// - Bottom padding to keep buttons above keyboard
/// - Works seamlessly on both iOS and Android
class KeyboardSafePage extends StatelessWidget {
  const KeyboardSafePage({super.key, required this.child, this.padding});

  /// The content to display (typically a Form with text fields)
  final Widget child;

  /// Optional padding around the content
  /// If null, uses default padding with bottom inset support
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Dismiss keyboard when tapping outside input fields
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        // Dismiss keyboard when dragging the page
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding:
            padding ??
            EdgeInsets.fromLTRB(
              16,
              16,
              16,
              // Add bottom padding equal to keyboard height + safe area
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
        child: child,
      ),
    );
  }
}

/// A widget that adds keyboard-aware bottom padding to fixed bottom buttons.
///
/// Use this when you have a bottomNavigationBar or fixed bottom button
/// that should appear above the keyboard.
class KeyboardAwareBottomBar extends StatelessWidget {
  const KeyboardAwareBottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: padding.add(EdgeInsets.only(bottom: bottomInset)),
        child: child,
      ),
    );
  }
}
