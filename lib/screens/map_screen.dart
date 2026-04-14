import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parking_stand_app/data/local/app_storage.dart';
import 'package:parking_stand_app/l10n/translations.dart';
import 'package:parking_stand_app/data/location_helper.dart';
import 'package:parking_stand_app/data/models/station.dart';
import 'package:parking_stand_app/data/stations_repository.dart';
import 'package:parking_stand_app/theme/app_theme.dart';
import 'package:parking_stand_app/screens/active_reservations_screen.dart';
import 'package:parking_stand_app/screens/qr_scanner_screen.dart';
import 'package:parking_stand_app/screens/qr_show_screen.dart';
import 'package:url_launcher/url_launcher.dart';

const LatLng _defaultCenter = LatLng(51.1079, 17.0385);
const double _defaultZoom = 12.0;

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

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
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

  Future<void> _openQrScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    setState(() {});
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
              if (AppStorage.lastBikeStationId == null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Material(
                        color: AppColors.accentYellow.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(
                            t(AppStrings.mapBikeBanner),
                            style: const TextStyle(
                              color: AppColors.textOnAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: AppStorage.lastBikeStationId == null ? 72 : 0,
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
                  top: (AppStorage.lastBikeStationId == null ? 72 : 0) + 64 + 8,
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
                  top: (AppStorage.lastBikeStationId == null ? 72 : 0) + 64 + 8,
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
                  bottom: padding.bottom + 24 + 72 + 12,
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
                bottom: padding.bottom + 24 + 72,
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
                left: padding.left + 16,
                right: padding.right + 16,
                bottom: padding.bottom + 24,
                child: SafeArea(
                  top: false,
                  child: Material(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    shadowColor: AppColors.shadowLight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Material(
                              color: AppColors.accentYellow,
                              borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                onTap: _openQrScanner,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.qr_code_scanner, color: AppColors.textOnAccent),
                                      const SizedBox(width: 8),
                                      Text(
                                        t(AppStrings.mapScan),
                                        style: const TextStyle(
                                          color: AppColors.textOnAccent,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: Material(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const QrShowScreen()),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.key, color: AppColors.textPrimary),
                                      const SizedBox(width: 6),
                                      Text(
                                        t(AppStrings.mapReceive),
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
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
                  ),
                ),
              ),
            ],
          );
        },
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.accentYellow),
              child: Text(
                t(AppStrings.mapMenu),
                style: const TextStyle(
                  color: AppColors.textOnAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: Text(t(AppStrings.mapActiveReservations)),
              onTap: () {
                Scaffold.of(context).closeDrawer();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ActiveReservationsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
