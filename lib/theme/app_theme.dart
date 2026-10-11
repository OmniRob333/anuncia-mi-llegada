import 'package:anuncia_mi_llegada/config/preferences/preferences_service.dart';
import 'package:flutter/material.dart';

final ValueNotifier<bool> isTrueDarkMode = PreferencesService.isTrueDarkMode;

class AppTheme {
  
  //------ Font del Metro ------
  static const TextStyle metroStyle = TextStyle(
    fontFamily: 'METRO-DF',
    fontSize: 22,
    height: 1.4,
    letterSpacing: 1,
    color: Color(0xFFF69346),
  );

//------ Nunito Family  ------
  static const TextStyle nunitoFamily = TextStyle( 
  height: 1.3,
  fontFamily: 'Nunito',
  fontSize: 19,
  letterSpacing: 0,
  fontWeight: FontWeight.w800,
);

  //------ Nunito Family para subtítulos ------
  static const TextStyle nunitoFamilySubtitle = TextStyle( 
  height: 1.3,
  fontFamily: 'Nunito',
  fontSize: 13,
  letterSpacing: 0,
  fontWeight: FontWeight.w700,
);

  static const TextStyle nunitoFamilyCustomButton = TextStyle(
    color: Color.fromRGBO(255, 255, 255, 83),
    height: 1.3,
    fontFamily: 'Nunito',
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  //---- Selector Widget ----

  //Contenedor naranja (LM = Modo Claro, DM = Modo Oscuro)
  static const LinearGradient colorsOfOrangeContianerLM = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.fromRGBO(245, 146, 69, 88),
      Color.fromRGBO(246, 147, 70, 100),
    ],
  );

  static const LinearGradient colorsOfOrangeContainerDM = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.fromRGBO(199, 113, 70, 100),
      Color.fromRGBO(255, 111, 0, 100),
    ],
  );

  //Contenedor de vidrio (LM = Modo Claro, DM = Modo Oscuro)
  static const LinearGradient colorOfGlassContainerLM = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.fromRGBO(249, 217, 191, 100),
      Color.fromRGBO(249, 215, 173, 100),
    ],
  );

  static const Color colorOfGlassContainerDM = Color.fromRGBO(
    174,
    159,
    147,
    19,
  );
  //--------

  // --- Background Color ---
  //Modo Claro
  static const Color backgroundColorLM = Colors.white;

  //Modo Oscuro
  static const LinearGradient backgroundColorDM = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomRight,
    colors: [Color.fromRGBO(0, 0, 0, 75), Color.fromRGBO(64, 28, 0, 75)],
  );
  //--------

  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundColorLM,
    colorSchemeSeed: Color(0xFFF26400),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color.fromRGBO(91, 79, 79, 100)),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    colorSchemeSeed: Color(0xFFF26400),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color.fromRGBO(204, 204, 204, 100)),
    ),
  );
}
