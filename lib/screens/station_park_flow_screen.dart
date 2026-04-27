import 'package:flutter/material.dart';
import 'package:mdm_sport/data/local/app_storage.dart';
import 'package:mdm_sport/data/models/station.dart';
import 'package:mdm_sport/data/qr_payload.dart';
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/theme/app_theme.dart';
import 'package:mdm_sport/widgets/station_qr_block.dart';

/// Krok 1 parkowania: treść, slot, QR open, Dalej → kod zamknięcia.
class StationParkOpenStepScreen extends StatefulWidget {
  const StationParkOpenStepScreen({super.key, required this.station, this.initialSlot});

  final Station station;
  /// Z QR słupka (`stationId` + `slot`); opcjonalnie wstępnie ustawia pole slotu.
  final int? initialSlot;

  @override
  State<StationParkOpenStepScreen> createState() => _StationParkOpenStepScreenState();
}

class _StationParkOpenStepScreenState extends State<StationParkOpenStepScreen> {
  int _slot = 1;
  final _slotController = TextEditingController(text: '1');
  late String _opId;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSlot;
    if (s != null && s >= 1) {
      _slot = s;
      _slotController.text = '$s';
    }
    _opId = '${widget.station.id}_${DateTime.now().millisecondsSinceEpoch}';
    AppStorage.setLastBikeStationId(widget.station.id);
  }

  @override
  void dispose() {
    _slotController.dispose();
    super.dispose();
  }

  String get _openB64 {
    final json = buildStationActionPayload(
      stationId: widget.station.id,
      slot: _slot,
      action: QrStationAction.open,
      opId: _opId,
    );
    return encodePayloadAsBase64Qr(json);
  }

  void _goToClose() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StationParkCloseQrScreen(
          station: widget.station,
          slot: _slot,
          opId: _opId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkButtonBg,
        foregroundColor: AppColors.textOnDark,
        title: Text(t(AppStrings.parkOpenPageTitle)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t(AppStrings.parkOpenShort),
              style: const TextStyle(color: AppColors.textOnDark, fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 20),
            Text(
              widget.station.name,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.station.fullAddress,
              style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _slotController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textOnDark),
              decoration: AppInputStyles.darkInputDecoration(hintText: t(AppStrings.parkFlowSlotHint)),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n >= 1) {
                  setState(() => _slot = n);
                }
              },
            ),
            const SizedBox(height: 24),
            StationQrBlock(caption: t(AppStrings.parkFlowQrOpenCaption), data: _openB64),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _goToClose,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentYellowDark,
                foregroundColor: AppColors.textOnAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                t(AppStrings.parkOpenNextButton),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StationParkCloseQrScreen extends StatelessWidget {
  const StationParkCloseQrScreen({
    super.key,
    required this.station,
    required this.slot,
    required this.opId,
  });

  final Station station;
  final int slot;
  final String opId;

  String get _closeB64 {
    final json = buildStationActionPayload(
      stationId: station.id,
      slot: slot,
      action: QrStationAction.close,
      opId: opId,
    );
    return encodePayloadAsBase64Qr(json);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkButtonBg,
        foregroundColor: AppColors.textOnDark,
        title: Text(t(AppStrings.parkClosePageTitle)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              station.name,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              station.fullAddress,
              style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '${t(AppStrings.parkFlowSlotHint)}: $slot',
              style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Text(
              t(AppStrings.parkFlowCloseBeforeQr),
              style: const TextStyle(color: AppColors.textOnDark, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 20),
            StationQrBlock(caption: t(AppStrings.parkFlowQrCloseCaption), data: _closeB64),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentYellowDark,
                foregroundColor: AppColors.textOnAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                t(AppStrings.parkFlowDoneButton),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
