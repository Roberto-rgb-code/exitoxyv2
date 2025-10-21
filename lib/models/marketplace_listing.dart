import 'package:flutter/material.dart';

class MarketplaceListing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String category;

  MarketplaceListing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.category,
  });

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    return MarketplaceListing(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      location: json['location'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'category': category,
    };
  }

  @override
  String toString() {
    return 'MarketplaceListing(id: $id, title: $title, price: $price, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketplaceListing && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
