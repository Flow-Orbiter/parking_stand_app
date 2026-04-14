import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model stacji parkingowej. Format payloadu QR ze słupka: JSON z "stationId" (lub "id").
class Station {
  const Station({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final double lat;
  final double lng;

  LatLng get position => LatLng(lat, lng);

  String get fullAddress => '$address, $city';

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'lat': lat,
        'lng': lng,
      };

  factory Station.fromMap(Map<String, dynamic> map) => Station(
        id: map['id'] as String,
        name: map['name'] as String,
        address: map['address'] as String,
        city: map['city'] as String,
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
      );
}
