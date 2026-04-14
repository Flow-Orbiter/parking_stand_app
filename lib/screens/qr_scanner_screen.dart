import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:parking_stand_app/data/local/app_storage.dart';
import 'package:parking_stand_app/l10n/translations.dart';
import 'package:parking_stand_app/data/qr_payload.dart';
import 'package:parking_stand_app/data/stations_repository.dart';
import 'package:parking_stand_app/theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    final stationId = parseStationIdFromQr(raw);
    if (stationId == null) return;
    final station = getStationById(stationId);
    if (station == null) return;
    _scanned = true;
    _controller.stop();
    AppStorage.setLastBikeStationId(stationId);
    if (mounted) Navigator.of(context).pop();
  }

  void _openManualEntry() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ManualStationDialog(),
    );
    if (result == null || !mounted) return;
    final station = getStationById(result);
    if (station != null) {
      AppStorage.setLastBikeStationId(result);
      if (mounted) Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(AppStrings.qrStationNotFound).replaceFirst('%s', result))),
      );
    }
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
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Material(
                    color: AppColors.darkSecondaryBg,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _openManualEntry,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit_note, color: AppColors.textOnDark, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              t(AppStrings.qrEnterManually),
                              style: const TextStyle(
                                color: AppColors.textOnDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _ManualStationDialog extends StatefulWidget {
  const _ManualStationDialog();

  @override
  State<_ManualStationDialog> createState() => _ManualStationDialogState();
}

class _ManualStationDialogState extends State<_ManualStationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkSecondaryBg,
      title: Text(
        t(AppStrings.qrEnterStationNumber),
        style: const TextStyle(color: AppColors.textOnDark),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: AppColors.textOnDark),
        decoration: const InputDecoration(
          hintText: 'np. 1',
          hintStyle: TextStyle(color: AppColors.textPlaceholder),
        ),
        onSubmitted: (v) {
          final id = v.trim();
          if (id.isNotEmpty) Navigator.of(context).pop(id);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t(AppStrings.qrCancel), style: const TextStyle(color: AppColors.textOnDark)),
        ),
        FilledButton(
          onPressed: () {
            final id = _controller.text.trim();
            if (id.isNotEmpty) Navigator.of(context).pop(id);
          },
          child: Text(t(AppStrings.qrOk)),
        ),
      ],
    );
  }
}
