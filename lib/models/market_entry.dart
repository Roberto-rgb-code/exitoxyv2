import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarketEntry {
  final String name;
  final String firm;
  final String activity;
  final String? postalCode;
  final LatLng position;

  MarketEntry({
    required this.name,
    required this.firm,
    required this.activity,
    required this.position,
    this.postalCode,
  });
}
