import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mdm_sport/data/firebase/user_firestore.dart';
import 'package:mdm_sport/data/local/app_storage.dart';
import 'package:mdm_sport/l10n/translations.dart';
import 'package:mdm_sport/data/location_helper.dart';
import 'package:mdm_sport/data/models/station.dart';
import 'package:mdm_sport/data/stations_repository.dart';
import 'package:mdm_sport/data/stations_sync_service.dart';
import 'package:mdm_sport/theme/app_theme.dart';
import 'package:mdm_sport/screens/qr_scanner_screen.dart';
import 'package:mdm_sport/data/station_entry_flow.dart';
import 'package:mdm_sport/auth/auth_service.dart';
import 'package:mdm_sport/screens/help_screen.dart';
import 'package:mdm_sport/util/app_links.dart';
import 'package:mdm_sport/widgets/language_picker_chips.dart';
import 'package:url_launcher/url_launcher.dart';

const LatLng _defaultCenter = LatLng(51.1079, 17.0385);
const double _defaultZoom = 12.0;

/// Wysokość dolnej belki (padding + dwa przyciski) — pod kontrolki mapy i kartę stacji.
const double _kBottomActionBarExtent = 92.0;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _showSearchResults = false;
  Station? _selectedStation;

  List<Station> get _filteredStations =>
      _searchQuery.trim().isEmpty ? kStations : searchStations(_searchQuery);

  void _onSearchFocusChange() {
    setState(() => _showSearchResults = _searchFocusNode.hasFocus);
  }

  Set<Marker> get _markers {
    final lastId = AppStorage.lastBikeStationId;
    return _filteredStations.map((s) {
      final isBikeHere = s.id == lastId;
      return Marker(
        markerId: MarkerId(s.id),
        position: s.position,
        infoWindow: InfoWindow(title: s.name, snippet: s.fullAddress),
        icon: isBikeHere
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () {
          _mapController?.hideMarkerInfoWindow(MarkerId(s.id));
          setState(() => _selectedStation = s);
        },
      );
    }).toSet();
  }

  void _onStationsDataRevision() {
    if (mounted) setState(() {});
  }

  Future<void> _reloadStationsFromFirebase() async {
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) {
        await u.getIdToken(true);
      }
      await StationsSyncService().syncStationsFromFirestore();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('MapScreen station reload: $e\n$st');
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    stationsDataRevision.addListener(_onStationsDataRevision);
    _searchFocusNode.addListener(_onSearchFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadStationsFromFirebase());
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      UserFirestoreRepository()
          .ensureUserDocument(u)
          .catchError((Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('Firestore ensureUserDocument: $e\n$st');
        }
      });
    }
  }

  @override
  void dispose() {
    stationsDataRevision.removeListener(_onStationsDataRevision);
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onStationSelected(Station station) {
    final displayText = '${station.name}, ${station.fullAddress}';
    _searchController.text = displayText;
    _searchQuery = displayText;
    _searchFocusNode.unfocus();
    setState(() => _showSearchResults = false);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(station.position, 16),
    );
  }

  void _zoomIn() => _mapController?.animateCamera(CameraUpdate.zoomIn());
  void _zoomOut() => _mapController?.animateCamera(CameraUpdate.zoomOut());

  Future<void> _goToMyLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showGpsMessage();
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      _showGpsMessage();
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
    final nearest = nearestStationWithin(pos.latitude, pos.longitude, kStations);
    if (nearest != null && mounted) {
      AppStorage.setLastBikeStationId(nearest.id);
      setState(() {});
    }
  }

  void _showGpsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t(AppStrings.mapGpsMessage)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openQrScanner(StationEntryFlow flow) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => QrScannerScreen(flow: flow)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _navigateToStation(Station station) async {
    final address = '${station.address}, ${station.city}';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    // Pasek wyszukiwania: SafeArea + wewn. padding + ~wysokość pola (nie stałe 64 px — lepsze przy Dynamic Island).
    final searchBarBottomY = padding.top + 8 + 52 + 8;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _defaultCenter,
                      zoom: _defaultZoom,
                    ),
                    mapType: MapType.normal,
                    onMapCreated: (c) => _mapController = c,
                    onTap: (_) => setState(() => _selectedStation = null),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: true,
                    mapToolbarEnabled: false,
                    markers: _markers,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                    child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Material(
                      color: AppColors.surfaceWhite,
                      borderRadius: AppInputStyles.searchBarRadius,
                      elevation: 2,
                      shadowColor: AppColors.shadowLight,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: AppInputStyles.lightInputDecoration(
                          hintText: t(AppStrings.mapSearchHint),
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                          suffixIcon: const Icon(Icons.search, color: AppColors.textPrimary),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                  ),
                ),
              ),
              if (_showSearchResults) ...[
                Positioned(
                  top: searchBarBottomY,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _searchFocusNode.unfocus();
                      setState(() => _showSearchResults = false);
                    },
                  ),
                ),
                Positioned(
                  top: searchBarBottomY,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: AppColors.surfaceWhite,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    shadowColor: AppColors.shadowLight,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: (constraints.maxHeight * 0.45).clamp(120.0, 320.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _filteredStations.length,
                          itemBuilder: (context, index) {
                            final s = _filteredStations[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.location_on,
                                color: AppColors.textPrimary,
                                size: 24,
                              ),
                              title: Text(
                                s.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                s.fullAddress,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              onTap: () => _onStationSelected(s),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (_selectedStation != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: padding.bottom + 16 + _kBottomActionBarExtent + 12,
                  child: Material(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    shadowColor: AppColors.shadowLight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedStation!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedStation!.fullAddress,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 22),
                                onPressed: () => setState(() => _selectedStation = null),
                                color: AppColors.textSecondary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _navigateToStation(_selectedStation!),
                              icon: const Icon(Icons.directions, size: 20),
                              label: Text(t(AppStrings.reservationsNavigate)),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accentYellow,
                                foregroundColor: AppColors.textOnAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: padding.bottom + 16 + _kBottomActionBarExtent + 10,
                right: padding.right + 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 2,
                      shadowColor: AppColors.shadowLight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add, color: AppColors.textPrimary),
                            onPressed: _zoomIn,
                          ),
                          Container(height: 1, width: 24, color: AppColors.borderLight),
                          IconButton(
                            icon: const Icon(Icons.remove, color: AppColors.textPrimary),
                            onPressed: _zoomOut,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: AppColors.surfaceWhite,
                      shape: const CircleBorder(),
                      elevation: 2,
                      shadowColor: AppColors.shadowLight,
                      child: IconButton(
                        icon: const Icon(Icons.my_location, color: AppColors.textPrimary),
                        onPressed: _goToMyLocation,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: padding.left + 12,
                right: padding.right + 12,
                bottom: padding.bottom + 12,
                child: SafeArea(
                  top: false,
                  child: Material(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    elevation: 3,
                    shadowColor: AppColors.shadowLight,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _openQrScanner(StationEntryFlow.park),
                              icon: const Icon(Icons.qr_code_scanner, size: 22),
                              label: Text(t(AppStrings.mapPark)),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accentYellowDark,
                                foregroundColor: AppColors.textOnAccent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _openQrScanner(StationEntryFlow.pickup),
                              icon: const Icon(Icons.key_rounded, size: 22),
                              label: Text(t(AppStrings.mapReceive)),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.textPrimary,
                                foregroundColor: AppColors.surfaceWhite,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      drawer: _MapDrawer(
        onLogout: () async {
          try {
            await AuthService().signOut();
            if (context.mounted) Navigator.of(context).pop();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$e')),
              );
            }
          }
        },
        onOpenHelp: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
          );
        },
        onOpenPrivacy: () {
          Navigator.of(context).pop();
          if (context.mounted) {
            launchExternalUrl(context, kPrivacyPolicyUri);
          }
        },
      ),
    );
  }
}

class _MapDrawer extends StatelessWidget {
  const _MapDrawer({
    required this.onLogout,
    required this.onOpenHelp,
    required this.onOpenPrivacy,
  });

  final Future<void> Function() onLogout;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final phoneStr = user?.phoneNumber;
    final phone = (phoneStr != null && phoneStr.isNotEmpty) ? phoneStr : null;
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            decoration: const BoxDecoration(color: AppColors.accentYellow),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                t(AppStrings.mapMenu),
                style: const TextStyle(
                  color: AppColors.textOnAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              children: [
                const SizedBox(height: 4),
                Text(
                  t(AppStrings.mapDrawerProfile),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<Map<String, dynamic>?>(
                  stream: user != null
                      ? UserFirestoreRepository().userProfileDataStream(user.uid)
                      : Stream<Map<String, dynamic>?>.value(null),
                  builder: (context, snap) {
                    final d = snap.data;
                    final nameInDb = (d?['displayName'] as String?)?.trim();
                    final name = (nameInDb != null && nameInDb.isNotEmpty)
                        ? nameInDb
                        : (user?.displayName?.trim().isNotEmpty == true
                            ? user!.displayName!
                            : null);
                    String? emailOut = user?.email;
                    if (emailOut == null || emailOut.isEmpty) {
                      final c = (d?['contactEmail'] as String?)?.trim();
                      if (c != null && c.isNotEmpty) emailOut = c;
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ReadOnlyField(
                          label: t(AppStrings.mapDrawerName),
                          value: name ?? t(AppStrings.mapDrawerFieldEmpty),
                        ),
                        const SizedBox(height: 4),
                        _ReadOnlyField(
                          label: t(AppStrings.mapDrawerEmail),
                          value: (emailOut != null && emailOut.isNotEmpty)
                              ? emailOut
                              : t(AppStrings.mapDrawerFieldEmpty),
                        ),
                        const SizedBox(height: 4),
                        _ReadOnlyField(
                          label: t(AppStrings.mapDrawerPhone),
                          value: phone ?? t(AppStrings.mapDrawerFieldEmpty),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  t(AppStrings.mapDrawerLanguage),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const LanguagePickerChips(style: LanguagePickerChipsStyle.drawer),
                const SizedBox(height: 8),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textPrimary),
                  title: Text(
                    t(AppStrings.legalPrivacyPolicy),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  ),
                  onTap: onOpenPrivacy,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.help_outline, color: AppColors.textPrimary),
                  title: Text(
                    t(AppStrings.mapDrawerHelp),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  ),
                  onTap: onOpenHelp,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FilledButton.icon(
                onPressed: onLogout,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.surfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout, size: 20),
                label: Text(
                  t(AppStrings.mapDrawerLogout),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: AppInputStyles.lightInputDecoration().copyWith(
        labelText: label,
        fillColor: const Color(0xFFF2F2F2),
        enabled: false,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
