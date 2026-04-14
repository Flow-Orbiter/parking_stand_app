import 'dart:math' as math;
import 'package:parking_stand_app/data/models/station.dart';

/// Proximity w metrach (ze skilla)
const double kProximityMeters = 50.0;

/// Odległość w metrach (Haversine) między (lat1, lng1) a (lat2, lng2).
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0; // Ziemia w m
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double _toRad(double deg) => deg * math.pi / 180;

/// Pierwsza stacja w promieniu [meters] od (lat, lng), lub null.
Station? nearestStationWithin(double lat, double lng, List<Station> stations, [double meters = kProximityMeters]) {
  for (final s in stations) {
    if (distanceMeters(lat, lng, s.lat, s.lng) <= meters) return s;
  }
  return null;
}
