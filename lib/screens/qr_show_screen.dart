import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:parking_stand_app/data/local/app_storage.dart';
import 'package:parking_stand_app/l10n/translations.dart';
import 'package:parking_stand_app/data/models/reservation.dart';
import 'package:parking_stand_app/data/models/station.dart';
import 'package:parking_stand_app/data/stations_repository.dart';
import 'package:parking_stand_app/theme/app_theme.dart';

/// Payload QR do pokazania skanerowi stacji (bez szyfrowania w MVP).
String buildQrPayload(String stationId, int slot) {
  final map = {
    'stationId': stationId,
    'slot': slot,
    'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'deviceId': 'local', // później userId z Auth
  };
  return jsonEncode(map);
}

class QrShowScreen extends StatefulWidget {
  const QrShowScreen({super.key});

  @override
  State<QrShowScreen> createState() => _QrShowScreenState();
}

class _QrShowScreenState extends State<QrShowScreen> {
  Station? _station;
  int _slot = 1;
  String _payload = '';
  final _slotController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    final lastId = AppStorage.lastBikeStationId;
    _station = lastId != null ? getStationById(lastId) : null;
    if (_station == null && kStations.isNotEmpty) _station = kStations.first;
    _updatePayload();
  }

  @override
  void dispose() {
    _slotController.dispose();
    super.dispose();
  }

  void _updatePayload() {
    if (_station != null) {
      setState(() => _payload = buildQrPayload(_station!.id, _slot));
    }
  }

  Future<void> _addReservation() async {
    if (_station == null) return;
    final now = DateTime.now();
    final end = now.add(const Duration(hours: 2));
    final r = Reservation(
      id: '${_station!.id}_${now.millisecondsSinceEpoch}',
      stationId: _station!.id,
      stationAddress: _station!.address,
      stationCity: _station!.city,
      slotNumber: _slot,
      startTime: now,
      endTime: end,
      durationMinutes: 120,
    );
    await AppStorage.addReservation(r);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(AppStrings.qrShowReservationAdded))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkButtonBg,
        foregroundColor: AppColors.textOnDark,
        title: Text(t(AppStrings.qrShowTitle)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_station != null) ...[
              DropdownButtonFormField<Station>(
                key: ValueKey(_station?.id ?? ''),
                initialValue: _station,
                dropdownColor: AppColors.darkSecondaryBg,
                decoration: AppInputStyles.darkDropdownDecoration(hintText: t(AppStrings.qrShowStation)),
                items: kStations
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name, style: const TextStyle(color: AppColors.textOnDark))))
                    .toList(),
                onChanged: (s) {
                  if (s != null) {
                    setState(() {
                      _station = s;
                      _updatePayload();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _slotController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textOnDark),
                decoration: AppInputStyles.darkInputDecoration(hintText: t(AppStrings.qrShowSlotHint)),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n >= 1) {
                    setState(() {
                      _slot = n;
                      _updatePayload();
                    });
                  }
                },
              ),
              const SizedBox(height: 32),
              if (_payload.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: _payload,
                    version: QrVersions.auto,
                    size: 220,
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                t(AppStrings.qrShowCodeAtStation),
                style: const TextStyle(color: AppColors.textOnDark, fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _addReservation(),
                icon: const Icon(Icons.add),
                label: Text(t(AppStrings.qrShowAddReservation)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentYellowDark,
                  foregroundColor: AppColors.textOnAccent,
                ),
              ),
            ] else
              Text(t(AppStrings.qrShowNoStation), style: const TextStyle(color: AppColors.textOnDark)),
          ],
        ),
      ),
    );
  }
}
