class StationPoint {
  final String name;
  final String system; 
  final String? line;
  final double latitude;
  final double longitude;

  const StationPoint ({
    required this.name,
    required this.system, 
    this.line, 
    required this.latitude, 
    required this.longitude
  });

  factory StationPoint.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final properties = 
      feature['properties'] as Map<String, dynamic>? ?? const {};
    final geometry = feature['geometry'] as Map<String , dynamic>? ?? const {};
    final coordinates = geometry['coordinates'] as List? ?? const [];

  return StationPoint(
      name: (properties['NOMBRE'] as String?) ?? '',
      system: (properties['SISTEMA'] as String?) ?? '',
      line: properties['LINEA'] as String?,
      latitude: coordinates.isNotEmpty
          ? (coordinates[1] as num).toDouble()
          : 0,
      longitude: coordinates.isNotEmpty
          ? (coordinates[0] as num).toDouble()
          : 0,
    );
  }
}
