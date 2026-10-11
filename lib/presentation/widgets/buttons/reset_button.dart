import 'package:anuncia_mi_llegada/config/preferences/preferences_service.dart';
import 'package:anuncia_mi_llegada/theme/app_theme.dart';
import 'package:anuncia_mi_llegada/utils/platform_dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';

class ResetButton extends StatelessWidget {
  const ResetButton({super.key, this.onTap});

  final VoidCallback? onTap;

  static const _lightColor = Color(0xFFF69346);
  static const _darkColor = Color.fromRGBO(73, 46, 25, 0.925);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.87,
      child: ValueListenableBuilder<bool>(
        valueListenable: isTrueDarkMode,
        builder: (context, isDark, _) {
          return TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              begin: isDark ? _darkColor : _lightColor,
              end: isDark ? _darkColor : _lightColor,
            ),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            builder: (context, color, _) => InnerShadow(
              shadows: const [
                Shadow(
                  color: Color.fromRGBO(255, 255, 255, 40),
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Material(
                  color: color ?? _lightColor,
                  child: InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap:
                        onTap ??
                        () => showPlatformDialog(
                          context: context,
                          title: '¿Estás seguro de continuar?',
                          content:
                              'Si lo haces, tus configuraciones personalizadas se restablecerán a su valor predeterminado',
                          actions: [
                            PlatformDialogAction(text: 'Rechazar'),
                            PlatformDialogAction(
                              text: 'Continuar',
                              onPressed: () {
                                PreferencesService.resetAll();
                              },
                            ),
                          ],
                        ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      child: InnerShadow(
                        shadows: const [
                          Shadow(
                            color: Color.fromRGBO(255, 255, 255, 44),
                            blurRadius: 10,
                            offset: Offset(1, 1),
                          ),
                        ],
                        child: const Text(
                          'Restablecer \nconfiguraciones',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 83),
                            height: 1.3,
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
