import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded }

class Responsive extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  const Responsive({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 840) return ScreenSize.expanded;
    if (width >= 600) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  static bool isCompact(BuildContext context) => of(context) == ScreenSize.compact;
  static bool isMedium(BuildContext context) => of(context) == ScreenSize.medium;
  static bool isExpanded(BuildContext context) => of(context) == ScreenSize.expanded;

  static EdgeInsets safePadding(BuildContext context) {
    final data = MediaQuery.of(context);
    return EdgeInsets.only(
      left: data.padding.left,
      right: data.padding.right,
      top: data.padding.top,
      bottom: data.padding.bottom,
    );
  }

  static double navBarBottomPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom + 80;
  }

  static double bottomNavOffset(BuildContext context) {
    return MediaQuery.of(context).padding.bottom + 16;
  }

  static EdgeInsets horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 840) return const EdgeInsets.symmetric(horizontal: 24);
    if (width >= 600) return const EdgeInsets.symmetric(horizontal: 16);
    return const EdgeInsets.symmetric(horizontal: 12);
  }

  @override
  Widget build(BuildContext context) {
    final size = of(context);
    switch (size) {
      case ScreenSize.expanded:
        return expanded ?? medium ?? compact;
      case ScreenSize.medium:
        return medium ?? compact;
      case ScreenSize.compact:
        return compact;
    }
  }
}
