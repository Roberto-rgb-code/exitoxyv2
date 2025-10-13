import "package:flutter/material.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";

/// Estado global ligero para compartir entre pantallas.
/// Lo usan CompetitionPage y DemographyPage.
class AppState extends ChangeNotifier {
  String? _postalCode;
  LatLng? _lastPoint;
  String? _activity;

  String? get postalCode => _postalCode;
  LatLng? get lastPoint => _lastPoint;
  String? get activity => _activity;

  void setPostalCode(String? cp) {
    _postalCode = cp;
    notifyListeners();
  }

  void setLastPoint(LatLng? p) {
    _lastPoint = p;
    notifyListeners();
  }

  void setActivity(String? a) {
    _activity = a;
    notifyListeners();
  }

  void clear() {
    _postalCode = null;
    _lastPoint = null;
    _activity = null;
    notifyListeners();
  }
}