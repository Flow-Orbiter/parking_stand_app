import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mdm_sport/data/models/station.dart';
import 'package:mdm_sport/data/stations_repository.dart';

/// Synchronizacja listy stacji z **Cloud Firestore** (kolekcje dokumentów).
///
/// Oczekiwana kolekcja (pierwsza, która zwróci dane): `stations`, potem `Stations`.
/// Pola dokumentu: `id` / `stationId` (opcjonalne — wtedy używany jest ID dokumentu),
/// `name`, `address`, `city`, oraz `lat`/`lng` lub `GeoPoint` w `location` / `position` / `geo`.
///
/// Dokument bez współrzędnych nie trafia na listę z syncu (mapa), ale może zostać
/// wczytany przy skanie QR ([resolveStationForQrScan]) z tymczasową pozycją — uzupełnij `lat`/`lng` w bazie.
const double _placeholderStationLat = 51.1079;
const double _placeholderStationLng = 17.0385;

class StationsSyncService {
  StationsSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<String> _candidateCollections = [
    'stations',
    'Stations',
  ];

  /// Pola pod zapytania `where` w [resolveStationForQrScan] (różne konwencje nazw w dokumentach).
  static const List<String> _resolveIdQueryFields = [
    'stationId',
    'id',
    'station_id',
  ];

  /// Ostatnio użyta kolekcja (dla nasłuchu [snapshots]).
  static String _activeCollection = 'stations';

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSub;

  static String _listeningCollection = '';

  /// Jednorazowy odczyt + podpięcie nasłuchu zmian.
  Future<void> syncStationsFromFirestore() async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {}
    try {
      const fetchOpts = GetOptions(source: Source.server);
      for (final name in _candidateCollections) {
        try {
          final snap = await _firestore.collection(name).get(fetchOpts);
          if (snap.docs.isEmpty) {
            if (kDebugMode) {
              debugPrint('StationsSyncService: Firestore collection "$name" is empty.');
            }
            continue;
          }
          final parsed = _stationsFromQuerySnapshot(snap);
          if (parsed.isEmpty) {
            if (kDebugMode) {
              final sample = snap.docs.first.data();
              debugPrint(
                'StationsSyncService: Firestore "$name" — 0 stations parsed '
                '(${snap.docs.length} docs). Przykładowy dokument "${snap.docs.first.id}" '
                '— pola: ${sample.keys.toList()}. Oczekiwane m.in.: lat/lng, latitude/longitude, '
                'GeoPoint w location, lub coordinates [lng,lat].',
              );
            }
            continue;
          }
          await setStations(parsed);
          _activeCollection = name;
          if (kDebugMode) {
            debugPrint(
              'StationsSyncService: synced ${parsed.length} stations from Firestore/$name',
            );
          }
          return;
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('StationsSyncService: Firestore read "$name" failed: $e\n$st');
          }
        }
      }
      if (kDebugMode) {
        debugPrint(
          'StationsSyncService: brak stacji z Firestore (kolekcje: ${_candidateCollections.join(", ")}).',
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('StationsSyncService sync failed: $e\n$st');
      }
    } finally {
      startLiveStationsSync();
    }
  }

  /// Zgodność wsteczna — wywołania w [main] / [MapScreen].
  Future<void> syncStationsFromRealtimeDatabase() => syncStationsFromFirestore();

  /// Gdy [getStationById] nie znajdzie stacji (np. inne `documentId` niż `stationId` w QR,
  /// lub dokument bez `lat`/`lng` odfiltrowany przy syncu), jednorazowy odczyt z Firestore.
  Future<Station?> resolveStationForQrScan(String rawStationId) async {
    final id = normalizeStationId(rawStationId);
    if (id.isEmpty) return null;
    final cached = getStationById(id);
    if (cached != null) return cached;
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {}
    const opts = GetOptions(source: Source.serverAndCache);
    for (final collName in _candidateCollections) {
      final coll = _firestore.collection(collName);
      try {
        final byPath = await coll.doc(id).get(opts);
        final fromPath = _stationFromDocumentSnapshot(
          byPath,
          allowPlaceholderCoordinates: true,
        );
        if (fromPath != null) {
          await upsertStation(fromPath);
          return fromPath;
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            'StationsSyncService resolveStationForQrScan: doc get "$collName/$id" failed: $e\n$st',
          );
        }
      }
      for (final field in _resolveIdQueryFields) {
        QuerySnapshot<Map<String, dynamic>> q;
        try {
          q = await coll.where(field, isEqualTo: id).limit(1).get(opts);
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint(
              'StationsSyncService resolveStationForQrScan: $collName where $field=="$id": $e\n$st',
            );
          }
          continue;
        }
        if (q.docs.isEmpty) continue;
        final s = _stationFromDocumentSnapshot(
          q.docs.first,
          allowPlaceholderCoordinates: true,
        );
        if (s != null) {
          await upsertStation(s);
          return s;
        }
      }
    }
    if (kDebugMode) {
      debugPrint(
        'StationsSyncService resolveStationForQrScan: no station for id="$id" '
        '(tried collections: ${_candidateCollections.join(", ")})',
      );
    }
    return null;
  }

  Future<void> _applyLiveStationsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    final parsed = _stationsFromQuerySnapshot(snap);
    await setStations(parsed);
    if (kDebugMode) {
      debugPrint(
        'StationsSyncService: Firestore live update, ${parsed.length} stations',
      );
    }
  }

  /// Nasłuch zmian w aktywnej kolekcji stacji.
  void startLiveStationsSync() {
    final name = _activeCollection;
    if (_firestoreSub != null && _listeningCollection == name) {
      return;
    }
    _firestoreSub?.cancel();
    _firestoreSub = null;
    _listeningCollection = '';
    try {
      _firestoreSub = _firestore.collection(name).snapshots().listen(
        (snap) {
          unawaited(_applyLiveStationsSnapshot(snap));
        },
        onError: (Object e, StackTrace st) {
          if (kDebugMode) {
            debugPrint('StationsSyncService Firestore listener: $e\n$st');
          }
        },
      );
      _listeningCollection = name;
      if (kDebugMode) {
        debugPrint('StationsSyncService: Firestore listener on "$name"');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('StationsSyncService startLiveStationsSync: $e\n$st');
      }
    }
  }

  List<Station> _stationsFromQuerySnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final out = <Station>[];
    for (final doc in snap.docs) {
      final s = _stationFromFirestoreDoc(doc);
      if (s != null) out.add(s);
    }
    return out;
  }

  Station? _stationFromFirestoreDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final map = _stringKeyedMap(data);
    return _stationFromRaw(
      map,
      fallbackId: doc.id,
      allowPlaceholderCoordinates: false,
    );
  }

  Station? _stationFromDocumentSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap, {
    required bool allowPlaceholderCoordinates,
  }) {
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    final map = _stringKeyedMap(data);
    return _stationFromRaw(
      map,
      fallbackId: snap.id,
      allowPlaceholderCoordinates: allowPlaceholderCoordinates,
    );
  }

  Map<String, dynamic> _stringKeyedMap(Map<String, dynamic> data) {
    return Map<String, dynamic>.from(
      data.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  Station? _stationFromRaw(
    Map<String, dynamic> map, {
    required String fallbackId,
    required bool allowPlaceholderCoordinates,
  }) {
    try {
      final id = _str(map['id']) ??
          _str(map['stationId']) ??
          _str(map['station_id']) ??
          fallbackId;
      final name = _str(map['name']) ?? _str(map['title']) ?? 'Stacja #$id';
      final address = _str(map['address']) ??
          _str(map['street']) ??
          (map['location'] is String ? _str(map['location']) : null) ??
          '-';
      final city = _str(map['city']) ?? _str(map['town']) ?? _str(map['postalCity']) ?? '-';
      final latLng = _extractLatLng(map);
      var lat = latLng.$1;
      var lng = latLng.$2;
      if (lat == null || lng == null) {
        if (!allowPlaceholderCoordinates) return null;
        lat = _placeholderStationLat;
        lng = _placeholderStationLng;
      }
      return Station(
        id: id,
        name: name,
        address: address,
        city: city,
        lat: lat,
        lng: lng,
      );
    } catch (_) {
      return null;
    }
  }

  (double?, double?) _extractLatLng(Map<String, dynamic> map) {
    double? lat = _latFromValue(map['lat']) ??
        _latFromValue(map['latitude']) ??
        _latFromValue(map['Lat']) ??
        _latFromValue(map['Latitude']);
    double? lng = _lngFromValue(map['lng']) ??
        _lngFromValue(map['lon']) ??
        _lngFromValue(map['longitude']) ??
        _lngFromValue(map['Longitude']) ??
        _lngFromValue(map['Lng']);
    if (lat != null && lng != null) return (lat, lng);

    // Dowolne pole typu GeoPoint (np. zagnieżdżone pod niestandardową nazwą).
    for (final v in map.values) {
      if (v is GeoPoint) return (v.latitude, v.longitude);
    }

    for (final key in [
      'location',
      'position',
      'geo',
      'gps',
      'coords',
      'coord',
      'coordinates_point',
      'geopoint',
    ]) {
      final v = map[key];
      if (v is GeoPoint) return (v.latitude, v.longitude);
      if (v is Map) {
        final pair = _latLngFromMapLoose(
          Map<String, dynamic>.from(
            v.map((k, val) => MapEntry(k.toString(), val)),
          ),
        );
        if (pair.$1 != null && pair.$2 != null) return pair;
      }
    }

    final coord = map['coordinates'];
    if (coord is List && coord.length >= 2) {
      lng = _toDouble(coord[0]);
      lat = _toDouble(coord[1]);
      if (lat != null && lng != null) return (lat, lng);
    }

    // Para [lat, lng] lub [lng, lat] w jednym polu (lista).
    for (final key in ['ll', 'latlng', 'lat_lng', 'geo']) {
      final v = map[key];
      if (v is List && v.length >= 2) {
        final a = _toDouble(v[0]);
        final b = _toDouble(v[1]);
        if (a != null && b != null) {
          if (a.abs() <= 90 && b.abs() <= 180) return (a, b);
          if (b.abs() <= 90 && a.abs() <= 180) return (b, a);
        }
      }
    }

    // Ostatnia szansa: dopasuj klucze case-insensitive (np. "Latitude" tylko w mapie).
    return _latLngFromMapLoose(map);
  }

  (double?, double?) _latLngFromMapLoose(Map<String, dynamic> m) {
    double? lat;
    double? lng;
    for (final e in m.entries) {
      final k = e.key.toLowerCase();
      final v = e.value;
      if (k == 'lat' || k == 'latitude') lat = _toDouble(v) ?? lat;
      if (k == 'lng' || k == 'lon' || k == 'longitude') lng = _toDouble(v) ?? lng;
    }
    if (lat != null && lng != null) return (lat, lng);
    return (null, null);
  }

  double? _latFromValue(Object? v) => _toDouble(v);
  double? _lngFromValue(Object? v) => _toDouble(v);

  double? _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final t = v.trim().replaceAll(',', '.');
      return double.tryParse(t);
    }
    return null;
  }

  String? _str(Object? v) {
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }
}
