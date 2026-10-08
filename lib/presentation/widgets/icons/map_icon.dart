import 'package:anuncia_mi_llegada/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MapIcon extends StatelessWidget {
  const MapIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isTrueDarkMode,
      builder: (context, isDark, _) {
        final assetPath = isDark
            ? 'assets/icons/map_icon_dark.png'
            : 'assets/icons/map_icon_w.png';
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
