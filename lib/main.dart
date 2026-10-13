import 'package:anuncia_mi_llegada/config/connectivity/connectivity_service.dart';
import 'package:anuncia_mi_llegada/config/mapbox_config.dart';
import 'package:anuncia_mi_llegada/config/preferences/preferences_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'config/router/app_router.dart';
import 'theme/app_theme.dart';

const appVersion = 'Versión 1.2.0 (Alpha)';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureMapboxAccessToken();
  if (mapboxAccessToken.isNotEmpty) {
    MapboxOptions.setAccessToken(mapboxAccessToken);
  }
  await PreferencesService.init();
  await ConnectivityService.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const AnunciaMiLlegadaApp());
}

class AnunciaMiLlegadaApp extends StatelessWidget {
  const AnunciaMiLlegadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isTrueDarkMode,
      builder: (context, isDark, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          themeAnimationDuration: const Duration(milliseconds: 700),
          //Los menús de Cupertino (p. ej. CupertinoMenuAnchor) se dibujan en
          //el Overlay, fuera del Theme de Material: sin este CupertinoTheme
          //el panel se pintaría siempre con los colores del modo claro.
          builder: (context, child) => CupertinoTheme(
            data: CupertinoThemeData(
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
            child: child!,
          ),
          routerConfig: appRouter,
        );
      },
    );
  }
}
