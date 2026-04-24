import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/data/qr_payload.dart';
import 'package:mdm_sport/data/station_entry_flow.dart';
import 'package:mdm_sport/data/stations_repository.dart';
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
  DateTime? _lastInvalidSnack;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    final pole = parsePoleQrPayloadFromBase64(raw);
    if (pole == null) {
      _maybeInvalidSnack();
      return;
    }
    final station = getStationById(pole.stationId);
    if (station == null) {
      _scanned = true;
      _controller.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(AppStrings.qrStationNotInApp).replaceFirst('%s', pole.stationId))),
        );
        Navigator.of(context).pop();
      }
      return;
    }
    _scanned = true;
    _controller.stop();
    if (!mounted) return;
    final next = switch (widget.flow) {
      StationEntryFlow.park => StationParkOpenStepScreen(station: station, initialSlot: pole.slot),
      StationEntryFlow.pickup => StationPickupScreen(station: station, initialSlot: pole.slot),
    };
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => next),
    );
  }

  void _maybeInvalidSnack() {
    final now = DateTime.now();
    if (_lastInvalidSnack != null && now.difference(_lastInvalidSnack!) < const Duration(seconds: 2)) {
      return;
    }
    _lastInvalidSnack = now;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t(AppStrings.qrInvalidCode)),
        duration: const Duration(seconds: 2),
      ),
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
