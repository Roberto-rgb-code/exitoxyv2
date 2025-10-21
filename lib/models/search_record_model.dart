import 'package:cloud_firestore/cloud_firestore.dart';

class SearchRecordModel {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String locationName;
  final DateTime timestamp;
  final Map<String, dynamic>? searchFilters;
  final List<String>? recommendedAreas;
  final Map<String, dynamic>? crimeData;
  final Map<String, dynamic>? placesData;
  final Map<String, dynamic>? streetViewData;

  SearchRecordModel({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.timestamp,
    this.searchFilters,
    this.recommendedAreas,
    this.crimeData,
    this.placesData,
    this.streetViewData,
  });

  factory SearchRecordModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return SearchRecordModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      locationName: data['locationName'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      searchFilters: data['searchFilters'],
      recommendedAreas: List<String>.from(data['recommendedAreas'] ?? []),
      crimeData: data['crimeData'],
      placesData: data['placesData'],
      streetViewData: data['streetViewData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'timestamp': Timestamp.fromDate(timestamp),
      'searchFilters': searchFilters,
      'recommendedAreas': recommendedAreas,
      'crimeData': crimeData,
      'placesData': placesData,
      'streetViewData': streetViewData,
    };
  }

  SearchRecordModel copyWith({
    String? id,
    String? userId,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? timestamp,
    Map<String, dynamic>? searchFilters,
    List<String>? recommendedAreas,
    Map<String, dynamic>? crimeData,
    Map<String, dynamic>? placesData,
    Map<String, dynamic>? streetViewData,
  }) {
    return SearchRecordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      timestamp: timestamp ?? this.timestamp,
      searchFilters: searchFilters ?? this.searchFilters,
      recommendedAreas: recommendedAreas ?? this.recommendedAreas,
      crimeData: crimeData ?? this.crimeData,
      placesData: placesData ?? this.placesData,
      streetViewData: streetViewData ?? this.streetViewData,
    );
  }

  @override
  String toString() {
    return 'SearchRecordModel(id: $id, locationName: $locationName, timestamp: $timestamp)';
  }
}
