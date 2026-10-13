import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../models/station_point.dart';

class GeojsonRepository {
  static List<StationPoint>? _cache;

  static const double nearbyStationMaxMeters = 50;

  static const List<String> _geoJsonAssets = [
    'assets/data/ubications/ubicaciones_metro.geojson',
    'assets/data/ubications/ubicaciones_metrobus.geojson',
    'assets/data/ubications/ubicaciones_trolebus.geojson',
    'assets/data/ubications/ubicaciones_cablebus.geojson',
    'assets/data/ubications/ubicaciones_tren_ligero.geojson',
  ];

  static const Distance _distance = Distance();

  static Future<List<StationPoint>> loadAllStations() async {
    if (_cache != null) return _cache!;

    final stations = <StationPoint> [];
    for (final asset in _geoJsonAssets) {
      final raw = await rootBundle.loadString(asset);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final features = decoded['features'] as List? ?? const [];

      for (final feature in features) {
        if (feature is! Map<String, dynamic>) continue;
        stations.add(StationPoint.fromGeoJsonFeature(feature));
      }
    }

    _cache = stations;
    return stations;
  }

  static Future<String?> nearestStationNameWithin({
    required double latitude,
    required double longitude,
    required double maxMeters,
  }) async {
    final stations = await loadAllStations() ;
    final origin = LatLng(latitude, longitude);

    String? nearestName;
    var minDistance = double.infinity;

    for (final station in stations) {
      final distance = _distance.as (
        LengthUnit.Meter,
        origin,
        LatLng(station.latitude, station.longitude),
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestName = station.name;
      }
    }

    if (minDistance <= maxMeters) return nearestName;
    return null;
  }
}
