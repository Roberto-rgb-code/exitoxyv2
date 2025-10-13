import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolygonsMethods {
  /// Recibe `data` como: [[ "lon,lat,lon,lat,..." ]]
  /// y regresa la lista de puntos en orden.
  List<LatLng> geometryData(List data) {
    final raw = data;
    final polygonCoords = <LatLng>[];

    final list = (raw[0] as String).replaceAll(" ", "").split(",");

    // El formato llega lon,lat,...; se consume desde el final
    while (list.isNotEmpty) {
      final lat = double.parse(list.removeLast());
      final lon = double.parse(list.removeLast());
      polygonCoords.add(LatLng(lat, lon));
    }
    return polygonCoords;
  }
}
