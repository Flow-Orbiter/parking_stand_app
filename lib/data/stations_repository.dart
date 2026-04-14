import 'package:parking_stand_app/data/models/station.dart';

/// Lista stacji – na razie stała (później z Firebase).
/// Format payloadu QR ze słupka: {"stationId": "1"} lub {"id": "1"}.
final List<Station> kStations = [
  const Station(
    id: '1',
    name: 'Stacja #1',
    address: 'Semaforowa 130',
    city: '54-515 Wrocław',
    lat: 51.1079,
    lng: 17.0385,
  ),
  const Station(
    id: '2',
    name: 'Stacja #2',
    address: 'ul. Przykładowa 5',
    city: '54-500 Wrocław',
    lat: 51.1120,
    lng: 17.0420,
  ),
  const Station(
    id: '3',
    name: 'Stacja #3',
    address: 'Pl. Centralny 1',
    city: '54-516 Wrocław',
    lat: 51.1020,
    lng: 17.0300,
  ),
];

Station? getStationById(String id) {
  try {
    return kStations.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}

List<Station> searchStations(String query) {
  if (query.trim().isEmpty) return List.from(kStations);
  final q = query.trim().toLowerCase();
  return kStations.where((s) {
    return s.name.toLowerCase().contains(q) ||
        s.address.toLowerCase().contains(q) ||
        s.city.toLowerCase().contains(q);
  }).toList();
}
