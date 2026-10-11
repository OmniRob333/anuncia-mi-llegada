import 'dart:async';
import 'package:anuncia_mi_llegada/config/mapbox_config.dart';
import 'package:anuncia_mi_llegada/config/mapbox_geocoding.dart';
import 'package:anuncia_mi_llegada/presentation/widgets/shared/shared_buttons/custom_button.dart';
import 'package:anuncia_mi_llegada/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  mapbox.MapboxMap? _mapboxMap;
  late Future<LatLng> _locationFuture;

  static const LatLng _fallbackCenter = LatLng(19.4326, -99.1332);

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<MapboxPlace> _searchResults = const [];
  bool _isSearching = false;
  bool _searchFailed = false;

  @override
  void initState() {
    super.initState();
    _locationFuture = _getCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    isTrueDarkMode.removeListener(_applyMapTheme);
    super.dispose();
  }

  Future<LatLng> _getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return _fallbackCenter;
        }
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        return _fallbackCenter;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('No se pudo obtener la ubicación actual: $e');
      return _fallbackCenter;
    }
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _applyMapTheme();
    isTrueDarkMode.addListener(_applyMapTheme);
  }

  String get _styleForTheme =>
      isTrueDarkMode.value ? mapboxStyleDarkUri : mapboxStyleLightUri;

  Future<void> _applyMapTheme() async {
    final map = _mapboxMap;
    if (map == null) return;
    final uri = _styleForTheme;
    try {
      if (await map.style.getStyleURI() == uri) return;
    } catch (_) {
      // Estilo aún cargando; se aplica directamente.
    }
    await map.style.setStyleURI(uri).catchError((_) {});
  }

  Future<void> _confirmSelection() async {
    final currentCamera = await _mapboxMap?.getCameraState();
    final center = currentCamera?.center;
    final lat = (center?.coordinates.lat ?? _fallbackCenter.latitude)
        .toDouble();
    final lng = (center?.coordinates.lng ?? _fallbackCenter.longitude)
        .toDouble();
    if (!mounted) return;
    Navigator.pop(context, LatLng(lat, lng));
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = const [];
        _isSearching = false;
        _searchFailed = false;
      });
      return;
    }

    if (mapboxAccessToken.isEmpty) {
      setState(() {
        _searchResults = const [];
        _isSearching = false;
        _searchFailed = true;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isSearching = true;
        _searchFailed = false;
      });
      final results = await forwardGeocode(query, proximity: _fallbackCenter);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _searchFailed = results.isEmpty;
      });
    });
  }

  Future<void> _moveToPlace(MapboxPlace place) async {
    _searchController.clear();
    _debounce?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _searchResults = const []);

    await _mapboxMap?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(place.longitude, place.latitude),
        ),
        zoom: 16.0,
      ),
      null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<LatLng>(
            future: _locationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final center = snapshot.data ?? _fallbackCenter;
              return mapbox.MapWidget(
                viewport: mapbox.CameraViewportState(
                  center: mapbox.Point(
                    coordinates: mapbox.Position(
                      center.longitude,
                      center.latitude,
                    ),
                  ),
                  zoom: 16.0,
                ),
                styleUri: isTrueDarkMode.value
                    ? mapboxStyleDarkUri
                    : mapboxStyleLightUri,
                onMapCreated: _onMapCreated,
                onMapLoadErrorListener: (error) {
                  debugPrint(
                    'Error cargando el mapa de Mapbox '
                    '(tipo: ${error.type}, mensaje: ${error.message})',
                  );
                },
              );
            },
          ),
          const Center(
            child: Icon(Icons.location_on, color: Color(0xFFF69346), size: 50),
          ),
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isTrueDarkMode.value
                          ? Color.fromARGB(255, 27, 26, 27)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(66, 1, 1, 1),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: AppTheme.nunitoFamilySubtitle.copyWith(
                        color: isTrueDarkMode.value
                            ? Color(0xFFF69346)
                            : Color.fromRGBO(91, 79, 79, 100),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar dirección o lugar',
                        hintStyle: AppTheme.nunitoFamilySubtitle.copyWith(
                          color: const Color(0xFFF69346),
                        ),
                        prefixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.search,
                                color: Color(0xFFF69346),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 168,
              left: 78,
              right: 20,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                color: isTrueDarkMode.value 
                ? Color.fromARGB(255, 27, 26, 27)
                : Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.place,
                          color: Color(0xFFF69346),
                        ),
                        title: Text(
                          place.name,
                          style: AppTheme.nunitoFamilySubtitle.copyWith(
                            color: isTrueDarkMode.value
                                ? Color.fromARGB(255, 246, 245, 245)
                                : Color.fromRGBO(91, 79, 79, 100),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _moveToPlace(place),
                      );
                    },
                  ),
                ),
              ),
            ),
          if (_searchFailed)
            Positioned(
              top: 168,
              left: 78,
              right: 20,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        mapboxAccessToken.isEmpty
                            ? Icons.error_outline
                            : Icons.search_off,
                        color: const Color(0xFFF69346),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mapboxAccessToken.isEmpty
                              ? 'Falta configurar el token de Mapbox '
                                    '(mapbox.env)'
                              : 'No se encontraron resultados',
                          style: AppTheme.nunitoFamilySubtitle.copyWith(
                            color: const Color(0xFF4A4A4A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Align(
            alignment: AlignmentGeometry.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: CustomButton(
                forcedColor: isTrueDarkMode.value 
                ? const Color.fromARGB(255, 33, 16, 3)
                : Color(0xFFF69346),
                textOfButton: Text(
                  'Confirmar \nubicación',
                  textAlign: TextAlign.center,
                  style: AppTheme.nunitoFamilyCustomButton.copyWith(
                    fontSize: 17,
                  ),
                ),
                buttonAction: _confirmSelection,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
