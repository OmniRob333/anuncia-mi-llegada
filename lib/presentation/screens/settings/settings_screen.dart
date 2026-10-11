import 'package:anuncia_mi_llegada/config/menu/settings_items.dart';
import 'package:anuncia_mi_llegada/config/preferences/preferences_service.dart';
import 'package:anuncia_mi_llegada/presentation/widgets/buttons/reset_button.dart';
import 'package:anuncia_mi_llegada/presentation/widgets/layouts/settings_screen_layout.dart';
import 'package:anuncia_mi_llegada/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  static const name = 'settings_screen';

  final String version;

  const SettingsScreen({super.key, this.version = 'Versión'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Implementación del backgroundColor
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder<bool>(
        valueListenable: isTrueDarkMode,
        builder: (context, isDark, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isDark ? null : AppTheme.backgroundColorLM,
            gradient: isDark ? AppTheme.backgroundColorDM : null,
          ),
          //-------------------------------------
          child: SettingsScreenLayout(
            settingsView: _SettingsView(version: version),
            version: '',
          ),
        ),
      ),
    );
  }
}

// ------------- Versión de la aplicación
class _ApplicationVersion extends StatelessWidget {
  final String version;
  const _ApplicationVersion({required this.version});

  @override
  Widget build(BuildContext context) {
    return Text(version, textAlign: TextAlign.center);
  }
}
// -------------

class _ResetSettingsButton extends StatelessWidget {
  const _ResetSettingsButton();

  @override
  Widget build(BuildContext context) {
    //Se reconstruye cuando cualquiera de las configuraciones cambia:
    return ListenableBuilder(
      listenable: Listenable.merge([
        PreferencesService.isTrueDarkMode,
        PreferencesService.messageBody,
        PreferencesService.willBeShowedTransportName,
        PreferencesService.willBeShowedLineNamesInMessage,
        PreferencesService.willBeShowedInstitutionsName,
        PreferencesService.whatMessagingAppYouWillUse,
      ]),
      builder: (context, _) {
        final showButton = PreferencesService.hasModifiedSettings;
        return IgnorePointer(
          ignoring: !showButton,
          child: AnimatedOpacity(
            opacity: showButton ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: const ResetButton(),
          ),
        );
      },
    );
  }
}

class _SettingsView extends StatelessWidget {
  final String version;
  const _SettingsView({required this.version});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      //+1 para el botón de restablecer configuraciones:
      itemCount: appSettingsItems.length + 1,
      itemBuilder: (BuildContext context, int index) {
        //Botón fijo debajo de la última opción (Apariencia):
        if (index == appSettingsItems.length) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(child: _ResetSettingsButton()),
              ),
              // Versión de la aplicación
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(child: _ApplicationVersion(version: version)),
              ),
            ],
          );
        }
    
        final menuItem = appSettingsItems[index];
        return _CustomListTitle(menuItem: menuItem);
      },
          );
  }
}

class _CustomListTitle extends StatefulWidget {
  const _CustomListTitle({required this.menuItem});

  final MenuItem menuItem;

  @override
  State<_CustomListTitle> createState() => _CustomListTitleState();
}

class _CustomListTitleState extends State<_CustomListTitle> {
  bool _areShowedThePreferences = false;

  Widget _withColor(Widget widget, Color fallbackColor) {
    if (widget is Text && widget.data != null) {
      final baseStyle = widget.style ?? const TextStyle();
      final effectiveColor = baseStyle.color ?? fallbackColor;
      return Text(
        widget.data!,
        style: baseStyle.copyWith(color: effectiveColor),
      );
    }
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    final theWidthOfYourScreen = MediaQuery.of(context).size.width;

    return ValueListenableBuilder<bool>(
      valueListenable: isTrueDarkMode,
      builder: (context, isDark, _) {
        final titleColor = isDark
            ? const Color.fromRGBO(204, 204, 204, 100)
            : Colors.black;
        final subtitleColor = isDark
            ? const Color.fromRGBO(151, 145, 145, 100)
            : const Color.fromRGBO(91, 79, 79, 100);

        return Column(
          children: [
            InkWell(
              onTap: () {
                if (widget.menuItem.icon is AppearanceIcon) {
                  isTrueDarkMode.value = !isTrueDarkMode.value;
                } else if (widget.menuItem.showedConfigurations != null) {
                  setState(() {
                    _areShowedThePreferences = !_areShowedThePreferences;
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 19.0,
                  vertical: 10.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 66,
                      height: 90,
                      child: widget.menuItem.icon,
                    ),
                    SizedBox(width: theWidthOfYourScreen * 0.06),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _withColor(widget.menuItem.title, titleColor),
                          _withColor(widget.menuItem.subtitle, subtitleColor),
                        ],
                      ),
                    ),
                    if (widget.menuItem.icon is! AppearanceIcon)
                      AnimatedRotation(
                        turns: _areShowedThePreferences ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child:
                  _areShowedThePreferences &&
                      widget.menuItem.showedConfigurations != null
                  ? widget.menuItem.showedConfigurations!
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
