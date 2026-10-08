import 'package:anuncia_mi_llegada/theme/app_theme.dart';
import 'package:flutter/material.dart';

class GearIcon extends StatelessWidget {
  const GearIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isTrueDarkMode,
      builder: (context, isDark, _) {
        final assetPath = isDark
            ? 'assets/icons/config_icons/gear_dark.png'
            : 'assets/icons/config_icons/gear_white.png';
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Image(
            key: ValueKey<String>(assetPath),
            image: AssetImage(assetPath),
            width: 80,
            height: 80,
          ),
        );
      },
    );
  }
}