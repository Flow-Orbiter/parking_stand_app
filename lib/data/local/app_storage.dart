import 'package:hive_flutter/hive_flutter.dart';
import 'package:parking_stand_app/data/models/reservation.dart';

/// Klucze boxów Hive
const String _boxName = 'parking_stand_app';
const String _keyLastBikeStationId = 'lastBikeStationId';
const String _keyReservations = 'reservations';
const String _keyLanguageCode = 'languageCode';

/// Lokalna baza (offline-first): ostatnia stacja roweru, rezerwacje.
class AppStorage {
  static Box<dynamic>? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static Box<dynamic> get box {
    final b = _box;
    if (b == null) throw StateError('AppStorage not initialized. Call AppStorage.init() first.');
    return b;
  }

  // ----- Ostatnia stacja (gdzie jest rower) -----
  static String? get lastBikeStationId => box.get(_keyLastBikeStationId) as String?;
  static Future<void> setLastBikeStationId(String? stationId) => box.put(_keyLastBikeStationId, stationId);

  // ----- Rezerwacje -----
  static List<Reservation> get reservations {
    final list = box.get(_keyReservations);
    if (list is! List) return [];
    return list
        .map((e) => e is Map ? Reservation.fromMap(Map<String, dynamic>.from(e)) : null)
        .whereType<Reservation>()
        .toList();
  }

  static Future<void> addReservation(Reservation r) async {
    final list = reservations.map((e) => e.toMap()).toList();
    list.add(r.toMap());
    await box.put(_keyReservations, list);
  }

  static Future<void> removeReservation(String id) async {
    final list = reservations.where((e) => e.id != id).map((e) => e.toMap()).toList();
    await box.put(_keyReservations, list);
  }

  static Future<void> setReservations(List<Reservation> list) async {
    await box.put(_keyReservations, list.map((e) => e.toMap()).toList());
  }

  // ----- Język (PL/EN) -----
  static String get languageCode => (box.get(_keyLanguageCode) as String?) ?? 'pl';
  static Future<void> setLanguageCode(String code) => box.put(_keyLanguageCode, code == 'en' ? 'en' : 'pl');
}
