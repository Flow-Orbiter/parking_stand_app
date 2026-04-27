import 'package:flutter/foundation.dart';
import 'package:mdm_sport/data/models/station.dart';
import 'package:mdm_sport/data/local/app_storage.dart';

/// Zmiana wartości = [kStations] została zaktualizowana (cache, Firestore, nasłuch na żywo).
/// [MapScreen] i inne widoki mają nasłuchiwać i wywoływać setState.
final ValueNotifier<int> stationsDataRevision = ValueNotifier<int>(0);

void _notifyStationsChanged() {
  stationsDataRevision.value++;
}

/// Lista stacji z Cloud Firestore (i z lokalnego cache po udanym syncu).
/// Brak wbudowanych „testowych” punktów — do momentu syncu mapa może być bez markerów.
/// Format payloadu QR ze słupka: {"stationId": "1"} lub {"id": "1"}.
List<Station> _stations = [];

/// Id stacji jak w QR / Firestore — bez zbędnych spacji na brzegach.
String normalizeStationId(String id) => id.trim();

List<Station> get kStations => List<Station>.unmodifiable(_stations);

/// Ustawia listę stacji w pamięci. Pusta lista czyści mapę i (opcjonalnie) Hive.
/// [persistToHive]: `false` przy starcie z już wczytanego cache — unikamy zbędnego zapisu.
Future<void> setStations(List<Station> stations, {bool persistToHive = true}) async {
  if (stations.isEmpty) {
    _stations = [];
    _notifyStationsChanged();
    if (persistToHive) {
      await AppStorage.setCachedStations([]);
    }
    return;
  }
  final byId = <String, Station>{};
  for (final s in stations) {
    byId[s.id] = s;
  }
  _stations = byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  _notifyStationsChanged();
  if (persistToHive) {
    await AppStorage.setCachedStations(_stations.map((e) => e.toMap()).toList());
  }
}

/// Jedna stacja po odczycie z Firestore przy skanie QR (nie nadpisuje całej listy z syncu).
/// Zapisuje też Hive ([AppStorage.cachedStations]), żeby stacja była dostępna offline po restarcie.
Future<void> upsertStation(Station station) async {
  final key = normalizeStationId(station.id);
  final list = List<Station>.from(_stations);
  final i = list.indexWhere((s) => normalizeStationId(s.id) == key);
  if (i >= 0) {
    list[i] = station;
  } else {
    list.add(station);
  }
  list.sort((a, b) => a.id.compareTo(b.id));
  _stations = list;
  _notifyStationsChanged();
  await AppStorage.setCachedStations(_stations.map((e) => e.toMap()).toList());
}

Future<void> initializeStationsFromCache() async {
  final cached = AppStorage.cachedStations;
  if (cached.isEmpty) return;
  final parsed = cached
      .map((e) {
        try {
          return Station.fromMap(e);
        } catch (_) {
          return null;
        }
      })
      .whereType<Station>()
      .toList();
  if (parsed.isNotEmpty) {
    await setStations(parsed, persistToHive: false);
  }
}

Station? getStationById(String id) {
  final key = normalizeStationId(id);
  if (key.isEmpty) return null;
  try {
    return _stations.firstWhere((s) => normalizeStationId(s.id) == key);
  } catch (_) {
    return null;
  }
}

List<Station> searchStations(String query) {
  if (query.trim().isEmpty) return List.from(_stations);
  final q = query.trim().toLowerCase();
  return _stations.where((s) {
    return s.name.toLowerCase().contains(q) ||
        s.address.toLowerCase().contains(q) ||
        s.city.toLowerCase().contains(q);
  }).toList();
}
