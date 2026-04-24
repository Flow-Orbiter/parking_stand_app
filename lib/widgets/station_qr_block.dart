import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mdm_sport/theme/app_theme.dart';

/// QR na jasnym tle do pokazania czytnikowi stacji.
class StationQrBlock extends StatelessWidget {
  const StationQrBlock({super.key, required this.caption, required this.data});

  final String caption;
  final String data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          caption,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 220,
            ),
          ),
        ),
      ],
    );
  }
}
