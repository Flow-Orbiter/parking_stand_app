/// Rezerwacja stanowiska – zapis lokalny (bez Firebase do czasu integracji).
class Reservation {
  const Reservation({
    required this.id,
    required this.stationId,
    required this.stationAddress,
    required this.stationCity,
    required this.slotNumber,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  final String id;
  final String stationId;
  final String stationAddress;
  final String stationCity;
  final int slotNumber;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;

  String get startTimeFormatted =>
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  String get endTimeFormatted =>
      '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  String get durationFormatted {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'stationId': stationId,
        'stationAddress': stationAddress,
        'stationCity': stationCity,
        'slotNumber': slotNumber,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationMinutes': durationMinutes,
      };

  factory Reservation.fromMap(Map<String, dynamic> map) => Reservation(
        id: map['id'] as String,
        stationId: map['stationId'] as String,
        stationAddress: map['stationAddress'] as String,
        stationCity: map['stationCity'] as String,
        slotNumber: map['slotNumber'] as int,
        startTime: DateTime.parse(map['startTime'] as String),
        endTime: DateTime.parse(map['endTime'] as String),
        durationMinutes: map['durationMinutes'] as int,
      );
}
