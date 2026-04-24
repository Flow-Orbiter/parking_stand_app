import 'package:flutter/material.dart';
import 'package:mdm_sport/data/local/app_storage.dart';
import 'package:mdm_sport/data/models/station.dart';
import 'package:mdm_sport/data/qr_payload.dart';
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/theme/app_theme.dart';
import 'package:mdm_sport/widgets/station_qr_block.dart';

/// Odbiór: QR open, opcjonalnie ekran z kodem close; „Gotowe” czyści „rower na stacji” w pamięci lokalnej.
class StationPickupScreen extends StatefulWidget {
  const StationPickupScreen({super.key, required this.station, this.initialSlot});

  final Station station;
  final int? initialSlot;

  @override
  State<StationPickupScreen> createState() => _StationPickupScreenState();
}

class _StationPickupScreenState extends State<StationPickupScreen> {
  int _slot = 1;
  late final TextEditingController _slotController;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSlot;
    if (s != null && s >= 1) {
      _slot = s;
      _slotController = TextEditingController(text: '$s');
    } else {
      _slotController = TextEditingController(text: '1');
    }
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
    );
    return encodePayloadAsBase64Qr(json);
  }

  void _onDone() {
    AppStorage.setLastBikeStationId(null);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goToCloseQr() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StationPickupCloseQrScreen(
          station: widget.station,
          slot: _slot,
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
        title: Text(t(AppStrings.pickupTitle)),
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
              t(AppStrings.pickupIntro),
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
              decoration: AppInputStyles.darkInputDecoration(hintText: t(AppStrings.pickupFlowSlotHint)),
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n >= 1) {
                  setState(() => _slot = n);
                }
              },
            ),
            const SizedBox(height: 24),
            StationQrBlock(caption: t(AppStrings.pickupOpenCaption), data: _openB64),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _goToCloseQr,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentYellowDark,
                foregroundColor: AppColors.textOnAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                t(AppStrings.pickupLockNowButton),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _onDone,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textOnDark,
                side: const BorderSide(color: AppColors.textPlaceholder),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                t(AppStrings.pickupFlowDoneButton),
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

/// Opcjonalne natychmiastowe zamknięcie rygla po odbiorze (ten sam payload `close` co przy parkowaniu).
class StationPickupCloseQrScreen extends StatelessWidget {
  const StationPickupCloseQrScreen({
    super.key,
    required this.station,
    required this.slot,
  });

  final Station station;
  final int slot;

  String get _closeB64 {
    final json = buildStationActionPayload(
      stationId: station.id,
      slot: slot,
      action: QrStationAction.close,
    );
    return encodePayloadAsBase64Qr(json);
  }

  void _onDone(BuildContext context) {
    AppStorage.setLastBikeStationId(null);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkButtonBg,
        foregroundColor: AppColors.textOnDark,
        title: Text(t(AppStrings.pickupClosePageTitle)),
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
              '${t(AppStrings.pickupFlowSlotHint)}: $slot',
              style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Text(
              t(AppStrings.pickupCloseBeforeQr),
              style: const TextStyle(color: AppColors.textOnDark, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 20),
            StationQrBlock(caption: t(AppStrings.pickupCloseCaption), data: _closeB64),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => _onDone(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentYellowDark,
                foregroundColor: AppColors.textOnAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                t(AppStrings.pickupFlowDoneButton),
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
