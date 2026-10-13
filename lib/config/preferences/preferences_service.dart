import 'package:anuncia_mi_llegada/data/models/history_items.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _preferences;
  static bool _initialized = false;

  //Valores canónicos de la app de mensajería usada para enviar el mensaje.
  //Son el identificador que se persiste, por lo que un cambio en el texto
  //visible obliga a registrar el valor anterior en _legacyMessagingAppValues.
  static const String messagingAppSms = "SMS";
  static const String messagingAppWhatsApp = "WhatsApp";
  static const String messagingAppAny = "Cualquier app de mensajería";

  //Único lugar donde se declara qué opciones existen.
  static const List<String> messagingAppOptions = [
    messagingAppSms,
    messagingAppWhatsApp,
    messagingAppAny,
  ];

  //Traducción de valores guardados por versiones anteriores de la app a su
  //valor canónico actual. "Otros" se renombró a "Cualquier app de mensajería".
  static const Map<String, String> _legacyMessagingAppValues = {
    "Otros": messagingAppAny,
  };

  //Configuraciones predeterminadas:
  static const bool defaultIsTrueDarkMode = false;
  static const String defaultMessageBody = "Ya estoy en";
  static const bool defaultWillBeShowedTransportName = true;
  static const bool defaultWillBeShowedLineNamesInMessage = true;
  static const bool defaultWillBeShowedInstitutionsName = true;
  static const String defaultWhatMessagingAppYouWillUse = messagingAppSms;
  static const bool defaultDetectNearbyStation = true;

  //------- ValueNotifiers: -------
  static final isTrueDarkMode = ValueNotifier<bool>(defaultIsTrueDarkMode);
  static final messageBody = ValueNotifier<String>(defaultMessageBody);

  static final willBeShowedTransportName = ValueNotifier<bool>(
    defaultWillBeShowedTransportName,
  );

  static final willBeShowedLineNamesInMessage = ValueNotifier<bool>(
    defaultWillBeShowedLineNamesInMessage,
  );

  static final willBeShowedInstitutionsName = ValueNotifier<bool>(
    defaultWillBeShowedInstitutionsName,
  );

  static final detectNearbyStation = 
    ValueNotifier<bool>(defaultDetectNearbyStation);

  static final whatMessagingAppYouWillUse = ValueNotifier<String>(
    defaultWhatMessagingAppYouWillUse,
  );

  static final historyList = ValueNotifier<List<HistoryItems>>([]);

  //--------------------------------

  // ------- hasModifiedSettings: Indica si alguna configuración difiere de su valor de fábrica. -------
  static bool get hasModifiedSettings =>

      isTrueDarkMode.value != defaultIsTrueDarkMode ||

      messageBody.value != defaultMessageBody ||

      willBeShowedTransportName.value != defaultWillBeShowedTransportName ||

      willBeShowedLineNamesInMessage.value !=
          defaultWillBeShowedLineNamesInMessage ||

      willBeShowedInstitutionsName.value !=
          defaultWillBeShowedInstitutionsName ||

      detectNearbyStation.value != defaultDetectNearbyStation ||

      whatMessagingAppYouWillUse.value != defaultWhatMessagingAppYouWillUse;

  ///Normaliza un valor de app de mensajería guardado o seleccionado.
  ///Aplica la traducción de valores antiguos y, si el resultado no está
  ///entre las [messagingAppOptions] vigentes, cae al valor predeterminado
  ///para que la app nunca quede con una preferencia desconocida.
  static String resolveMessagingApp(String? value) {
    if (value == null) return defaultWhatMessagingAppYouWillUse;
    final migrated = _legacyMessagingAppValues[value] ?? value;
    return messagingAppOptions.contains(migrated)
        ? migrated
        : defaultWhatMessagingAppYouWillUse;
  }

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _preferences = await SharedPreferences.getInstance();

    // Lectura de las preferencias
    isTrueDarkMode.value =
        _preferences.getBool('isTrueDarkMode') ?? defaultIsTrueDarkMode;
    messageBody.value =
        _preferences.getString('messageBody') ?? defaultMessageBody;

    willBeShowedTransportName.value =
        _preferences.getBool('willBeShowedTransportName') ??
        defaultWillBeShowedTransportName;

    willBeShowedLineNamesInMessage.value =
        _preferences.getBool('willBeShowedLineNamesInMessage') ??
        defaultWillBeShowedLineNamesInMessage;

    willBeShowedInstitutionsName.value =
        _preferences.getBool('willBeShowedInstitutionsName') ??
        defaultWillBeShowedInstitutionsName;

    detectNearbyStation.value =
        _preferences.getBool('detectNearbyStation') ??
        defaultDetectNearbyStation;

    isTrueDarkMode.addListener(() {
      _preferences.setBool('isTrueDarkMode', isTrueDarkMode.value);
    });

    //Migración: el valor guardado puede venir de una versión anterior de la
    //app (p. ej. "Otros", renombrado a "Cualquier app de mensajería"). Se
    //normaliza al valor vigente y se persiste, de modo que la corrección se
    //escribe una sola vez y el usuario conserva su preferencia.
    final storedMessagingApp =
        _preferences.getString('whatMessagingAppYouWillUse');
    final messagingApp = resolveMessagingApp(storedMessagingApp);
    whatMessagingAppYouWillUse.value = messagingApp;
    if (messagingApp != storedMessagingApp) {
      await _preferences.setString('whatMessagingAppYouWillUse', messagingApp);
    }

    //Lectura del historial (misma key con la que se guarda y se borra)
    //Limpieza: la key antigua 'app_records' (de una versión previa del modelo)
    //ya no se usa; se elimina para que no vuelva a restaurar un historial obsoleto.
    final savedRecords = _preferences.getStringList('app_history') ?? [];
    historyList.value = savedRecords
        .map((item) => HistoryItems.fromJson(item))
        .toList();
    if (_preferences.containsKey('app_records')) {
      await _preferences.remove('app_records');
    }
    //------------
  }

  // Escritura de las preferencias
  static Future<void> setYourCustomMessage(String value) async {
    messageBody.value = value;
    await _preferences.setString('messageBody', value);
  }

  static Future<void> showTransportName(bool value) async {
    willBeShowedTransportName.value = value;
    await _preferences.setBool('willBeShowedTransportName', value);
  }

  static Future<void> showLineNamesInMessage(bool value) async {
    willBeShowedLineNamesInMessage.value = value;
    await _preferences.setBool('willBeShowedLineNamesInMessage', value);
  }

  static Future<void> showInstitutionsName(bool value) async {
    willBeShowedInstitutionsName.value = value;
    await _preferences.setBool('willBeShowedInstitutionsName', value);
  }

  static Future<void> setDefaultMessagingApp(String value) async {
    final resolved = resolveMessagingApp(value);
    whatMessagingAppYouWillUse.value = resolved;
    await _preferences.setString('whatMessagingAppYouWillUse', resolved);
  }

  static Future<void> setDetectNearbyStation(bool value) async {
    detectNearbyStation.value = value;
    await _preferences.setBool('detectNearbyStation', value);
  }

  //Guardar los nuevos mensajes al RecordItems
  static Future<void> saveToHistoryItems(HistoryItems newItem) async {
    final updateList = [newItem, ...historyList.value];
    historyList.value = updateList;

    final stringList = updateList.map((item) => item.toJson()).toList();
    await _preferences.setStringList('app_history', stringList);
  }

  //Borrar el historial
  static Future<void> deleteHistory() async {
    historyList.value = [];
    await _preferences.remove('app_history');
  }

  //Borrar un elemento del historial
  static Future<void> deleteHistoryItem(String id) async {
    final updateList = historyList.value
        .where((item) => item.id != id)
        .toList();
    historyList.value = updateList;

    final stringList = updateList.map((item) => item.toJson()).toList();
    await _preferences.setStringList('app_history', stringList);
  }


  // Restablecimiento de todas las configuraciones a su estado original
  static Future<void> resetAll() async {
    isTrueDarkMode.value = defaultIsTrueDarkMode;

    messageBody.value = defaultMessageBody;

    willBeShowedTransportName.value = defaultWillBeShowedTransportName;

    willBeShowedLineNamesInMessage.value =
        defaultWillBeShowedLineNamesInMessage;

    willBeShowedInstitutionsName.value = defaultWillBeShowedInstitutionsName;

    whatMessagingAppYouWillUse.value = defaultWhatMessagingAppYouWillUse;

    detectNearbyStation.value = defaultDetectNearbyStation;

    await _preferences.setBool('isTrueDarkMode', defaultIsTrueDarkMode);
    await _preferences.setString('messageBody', defaultMessageBody);
    await _preferences.setBool(
      'willBeShowedTransportName',
      defaultWillBeShowedTransportName,
    );
    await _preferences.setBool(
      'willBeShowedLineNamesInMessage',
      defaultWillBeShowedLineNamesInMessage,
    );
    await _preferences.setBool(
      'willBeShowedInstitutionsName',
      defaultWillBeShowedInstitutionsName,
    );
    await _preferences.setString(
      'whatMessagingAppYouWillUse',
      defaultWhatMessagingAppYouWillUse,
    );

    await _preferences.setBool(
      'detectNearbyStation',
      defaultDetectNearbyStation,
    );

  }
}
