import 'dart:async';
import 'package:anuncia_mi_llegada/config/connectivity/connectivity_service.dart';
import 'package:anuncia_mi_llegada/config/mapbox_geocoding.dart';
import 'package:anuncia_mi_llegada/config/preferences/preferences_service.dart';
import 'package:anuncia_mi_llegada/data/models/history_items.dart';
import 'package:anuncia_mi_llegada/data/repositories/geojson_repository.dart';
import 'package:anuncia_mi_llegada/presentation/screens/selectors/custom_location/map_screen.dart';
//import 'package:anuncia_mi_llegada/presentation/widgets/dialogs/gps_loading_dialog.dart';
import 'package:anuncia_mi_llegada/theme/app_theme.dart';
import 'package:anuncia_mi_llegada/utils/send_message_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MenuItem {
  final Widget title;
  final Widget icon;
  final Widget widget;
  final Future<void> Function(BuildContext context)? onTap;
  final bool requiresNetwork;

  MenuItem({
    required this.title,
    required this.icon,
    required this.widget,
    this.onTap,
    this.requiresNetwork = false,
  });
}

final appCustomLocationItems = <MenuItem>[
  //------ Ubicación manual ------
  MenuItem(
    title: Column(
      children: [
        const SizedBox(height: 40),
        Text("UBICACIÓN \nMANUAL", style: AppTheme.metroStyle),
      ],
    ),
    icon: SvgPicture.asset(
      'assets/icons/custom_location_icons/ubicacion_manual.svg',
    ),
    widget: ManualLocationText(),
  ),

  MenuItem(
    title: Text("UBICAR EN EL \nMAPA", style: AppTheme.metroStyle),
    icon: SvgPicture.asset(
      'assets/icons/custom_location_icons/uso_del_mapa.svg',
    ),
    onTap: _openMapAndSend,
    widget: SizedBox(height: 0),
    requiresNetwork: true,
  ),

  MenuItem(
    title: Text("USAR UBICACIÓN ACTUAL", style: AppTheme.metroStyle),
    icon: SvgPicture.asset(
      'assets/icons/custom_location_icons/ubicacion_actual.svg',
    ),
    onTap: _getCurrentLocationAndSend,
    widget: SizedBox(height: 0),
    requiresNetwork: true,
  ),
];

Future<void> _sendLocation(
  BuildContext context,
  String locationText,
  String type,
) async {
  if (locationText.trim().isEmpty) return;

  final messageBody = PreferencesService.messageBody.value;
  final sendedMessage = "$messageBody ${locationText.trim()}";
  final result = await SendMessageHelper.sendMessage(sendedMessage);

  if (result == SendMessageResult.succes) {
    final newHistoryItem = HistoryItems(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: "UBI.PERSONALIZADA",
      stationName: locationText.trim(),
      transportAndLineName: 'Tipo: $type',
      messageTime: DateTime.now(),
    );
    await PreferencesService.saveToHistoryItems(newHistoryItem);
    return;
  }

  /* if (context.mounted) {
    await SendMessageHelper.showSendMessageError(context, result);
  } */
}

//Feature 3: resuelve el texto del mensaje, priorizando la estación cercana.
Future<(String location, String type)> _resolveLocationText({
  required double lat,
  required double lng,
  required String defaultType,
}) async {
  if (PreferencesService.detectNearbyStation.value) {
    final nearest = await GeojsonRepository.nearestStationNameWithin(
      latitude: lat,
      longitude: lng,
      maxMeters: GeojsonRepository.nearbyStationMaxMeters,
    );
    if (nearest != null && nearest.trim().isNotEmpty) {
      return (nearest, 'Estación cercana');
    }
  }

  var locationText = '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  final address = await reverseGeocode(lat, lng);
  if (address.isNotEmpty) {
    locationText = address;
  }
  return (locationText, defaultType);
}

Future<void> _openMapAndSend(BuildContext context) async {
  final selectedPoint = await Navigator.of(
    context,
  ).push<LatLng>(MaterialPageRoute(builder: (_) => const MapScreen()));
  if (selectedPoint == null) return;

  final (locationText, type) = await _resolveLocationText(
    lat: selectedPoint.latitude,
    lng: selectedPoint.longitude,
    defaultType: 'Buscada en el mapa',
  );

  await _sendLocation(context, locationText, type);
}

Future<void> _getCurrentLocationAndSend(BuildContext context) async {
  try {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El servicio de ubicación está desactivado'),
          ),
        );
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) return;

    //Feature 5: modal de carga con cancelación.
  /*  final cancelled = ValueNotifier<bool>(false);
    unawaited(showGpsLoadingDialog(context, cancelled: cancelled)); */

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint("Parece que hubo un error con tu ubicación actual :( : $e");
      position = null;
    }

    //Si el usuario canceló, se aborta sin geocodificar ni enviar.
    // if (cancelled.value) return;

    //Cierra el modal de carga (si sigue abierto).
    if (context.mounted) Navigator.of(context).pop();

    if (position == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener tu ubicación actual'),
          ),
        );
      }
      return;
    }

    final (locationText, type) = await _resolveLocationText(
      lat: position.latitude,
      lng: position.longitude,
      defaultType: 'Ubicación actual',
    );

    await _sendLocation(context, locationText, type);
  } catch (e) {
    debugPrint("Parece que hubo un error con tu ubicación actual :( : $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener tu ubicación actual')),
      );
    }
  }
}

class ManualLocationText extends StatefulWidget {
  const ManualLocationText({super.key});

  @override
  State<ManualLocationText> createState() => _ManualLocationTextState();
}

class _ManualLocationTextState extends State<ManualLocationText> {
  final TextEditingController _manualUbicationController =
      TextEditingController();

  @override
  void dispose() {
    _manualUbicationController.dispose();
    super.dispose();
  }

  Future<void> _categorizingLocation(String locationText, String type) {
    if (locationText.trim().isEmpty) return Future.value();
    return _sendLocation(context, locationText, type);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5),
        ValueListenableBuilder<String>(
          valueListenable: PreferencesService.messageBody,
          builder: (context, messageBody, _) {
            return SizedBox(
              height: 45,
              child: TextField(
                controller: _manualUbicationController,
                style: AppTheme.nunitoFamilySubtitle,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) =>
                    _categorizingLocation(value, 'Ubicación manual'),
                decoration: InputDecoration(
                  prefixText: '$messageBody ',
                  prefixStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  hintStyle: const TextStyle(color: Colors.white30),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF69346)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFFB6A3A3),
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFFB6A3A3),
                    ),
                    onPressed: () => _categorizingLocation(
                      _manualUbicationController.text,
                      'Ubicación manual',
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
