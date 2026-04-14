import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:parking_stand_app/data/local/app_storage.dart';
import 'package:parking_stand_app/l10n/translations.dart';
import 'package:parking_stand_app/data/models/reservation.dart';
import 'package:parking_stand_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveReservationsScreen extends StatefulWidget {
  const ActiveReservationsScreen({super.key});

  @override
  State<ActiveReservationsScreen> createState() => _ActiveReservationsScreenState();
}

class _ActiveReservationsScreenState extends State<ActiveReservationsScreen> {
  List<Reservation> get _reservations => AppStorage.reservations;

  Future<void> _navigateToStation(Reservation r) async {
    final address = '${r.stationAddress}, ${r.stationCity}';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _endReservation(Reservation r) async {
    await AppStorage.removeReservation(r.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE8E8E8),
                  const Color(0xFFF0F0F0),
                  const Color(0xFFE0E0E0),
                ],
              ),
            ),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text(
                    t(AppStrings.reservationsTitle),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                Expanded(
                  child: _reservations.isEmpty
                      ? Center(
                          child: Text(
                            t(AppStrings.reservationsEmpty),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _reservations.length,
                          itemBuilder: (context, index) {
                            return _ReservationCard(
                              reservation: _reservations[index],
                              onNavigate: _navigateToStation,
                              onEnd: _endReservation,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.onNavigate,
    required this.onEnd,
  });

  final Reservation reservation;
  final void Function(Reservation) onNavigate;
  final void Function(Reservation) onEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stacja #${reservation.stationId}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reservation.stationAddress}, ${reservation.stationCity}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.reservationSlotGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${reservation.slotNumber}',
                    style: const TextStyle(
                      color: AppColors.surfaceWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TimeColumn(label: t(AppStrings.reservationsStart), value: reservation.startTimeFormatted),
                _TimeColumn(label: t(AppStrings.reservationsDuration), value: reservation.durationFormatted),
                _TimeColumn(label: t(AppStrings.reservationsEnd), value: reservation.endTimeFormatted),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onNavigate(reservation),
                    icon: const Icon(Icons.send, size: 18, color: AppColors.textPrimary),
                    label: Text(
                      t(AppStrings.reservationsNavigate),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surfaceWhite,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onEnd(reservation),
                    icon: const Icon(Icons.stop_circle_outlined, size: 18, color: AppColors.textPrimary),
                    label: Text(
                      t(AppStrings.reservationsEndButton),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surfaceWhite,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
