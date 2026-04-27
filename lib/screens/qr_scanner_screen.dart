import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/data/qr_payload.dart';
import 'package:mdm_sport/data/station_entry_flow.dart';
import 'package:mdm_sport/data/stations_repository.dart';
import 'package:mdm_sport/data/stations_sync_service.dart';
import 'package:mdm_sport/screens/station_park_flow_screen.dart';
import 'package:mdm_sport/screens/station_pickup_flow_screen.dart';
import 'package:mdm_sport/theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.flow = StationEntryFlow.park});

  final StationEntryFlow flow;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;
  bool _resolving = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _resolving) return;
    PoleQrPayload? pole;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null || raw.isEmpty) continue;
      pole = parsePoleQrPayloadFromBase64(raw);
      if (pole != null) break;
    }
    if (pole == null) return;
    if (kDebugMode) {
      debugPrint(
        'QrScannerScreen: parsed pole stationId="${pole.stationId}" slot=${pole.slot}',
      );
    }
    setState(() => _resolving = true);
    _scanned = true;
    _controller.stop();
    var station = getStationById(pole.stationId);
    station ??= await StationsSyncService().resolveStationForQrScan(pole.stationId);
    if (!mounted) return;
    setState(() => _resolving = false);
    if (station == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(AppStrings.qrStationNotInApp).replaceFirst('%s', pole.stationId))),
      );
      Navigator.of(context).pop();
      return;
    }
    final next = switch (widget.flow) {
      StationEntryFlow.park => StationParkOpenStepScreen(station: station, initialSlot: pole.slot),
      StationEntryFlow.pickup => StationPickupScreen(station: station, initialSlot: pole.slot),
    };
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => next),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
          ),
          if (_resolving)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xCC000000),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.accentYellowDark),
                      const SizedBox(height: 16),
                      Text(
                        t(AppStrings.qrResolvingStation),
                        style: const TextStyle(color: AppColors.textOnDark, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Material(
                      color: AppColors.darkButtonBg,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.chevron_left, color: AppColors.textOnDark, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.accentYellowDark, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentYellowDark.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t(AppStrings.qrScanVehicle),
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: Material(
                color: AppColors.accentYellowDark,
                shape: const CircleBorder(),
                elevation: 8,
                shadowColor: AppColors.accentYellowDark.withValues(alpha: 0.5),
                child: InkWell(
                  onTap: () => _controller.toggleTorch(),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Icon(Icons.bolt, color: AppColors.textOnAccent, size: 36),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
