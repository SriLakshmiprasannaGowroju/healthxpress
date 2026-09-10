import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../core/theme/app_colors.dart';
import '../../data/production_database.dart';
import '../../models/hospital_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../widgets/real_mapbox_map.dart';
import 'hospital_detail_screen.dart';

class NearbyHospitalsMapScreen extends StatefulWidget {
  const NearbyHospitalsMapScreen({super.key});

  @override
  State<NearbyHospitalsMapScreen> createState() => _NearbyHospitalsMapScreenState();
}

class _NearbyHospitalsMapScreenState extends State<NearbyHospitalsMapScreen> {
  final GlobalKey<RealMapboxMapState> _mapKey = GlobalKey<RealMapboxMapState>();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.92);

  List<HospitalModel> _hospitals = List.from(ProductionDatabase.hospitals);
  String _selectedFilter = 'All';
  int _selectedHospitalIndex = 0;
  bool _isListView = false;

  // Real Dynamic Live GPS Coordinates (Defaults to Hyderabad, updated from device live GPS)
  double _userLat = 17.4420;
  double _userLng = 78.3880;
  String _userCityName = 'Detecting Live Location...';
  bool _isLiveGpsActive = false;

  final List<String> _filters = [
    'All',
    '🚨 24x7 Emergency',
    '🏥 Super Specialty',
    '🫀 Cardiology',
    '🦴 Orthopedics',
    '🧠 Neurology',
    '👶 Pediatrics',
    '🎗️ Oncology',
  ];

  @override
  void initState() {
    super.initState();
    _initLiveLocationAndHospitals();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapKey.currentState?.resize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initLiveLocationAndHospitals() async {
    try {
      final loc = await LocationService.getLivePosition();
      if (loc != null && mounted) {
        setState(() {
          _userLat = loc['lat'] as double? ?? 17.4420;
          _userLng = loc['lng'] as double? ?? 78.3880;
          _userCityName = '${loc['locality']}, ${loc['city']}';
          _isLiveGpsActive = true;
        });
        _mapKey.currentState?.flyTo(_userLng, _userLat, zoom: 14.5);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userCityName = 'Hyderabad, Telangana';
        });
      }
    }
    await _loadAllHospitals();
  }

  Future<void> _loadAllHospitals() async {
    try {
      // 1. Fetch real live hospitals from OSM Overpass + Mapbox POI Radar around user's live GPS
      final liveNearbyList = await ApiService.fetchLiveNearbyHospitals(
        latitude: _userLat,
        longitude: _userLng,
        cityName: _userCityName,
        limit: 40,
      );

      // 2. Fetch empaneled hospitals from backend
      final backendList = await ApiService.fetchHospitals(latitude: _userLat, longitude: _userLng);

      final combined = <HospitalModel>[];
      final seenNames = <String>{};

      // Priority 1: Add live nearby hospitals located around user's current city/area
      for (final h in liveNearbyList) {
        final key = h.name.toLowerCase().trim();
        if (!seenNames.contains(key)) {
          seenNames.add(key);
          combined.add(h);
        }
      }

      // Priority 2: Add backend hospitals with dynamic recalculated distance
      for (final h in backendList) {
        final key = h.name.toLowerCase().trim();
        if (!seenNames.contains(key)) {
          seenNames.add(key);
          final recalculatedDist = ApiService.calculateDistanceKm(_userLat, _userLng, h.latitude, h.longitude);
          combined.add(
            HospitalModel(
              id: h.id,
              name: h.name,
              logoUrl: h.logoUrl,
              bannerUrl: h.bannerUrl,
              hospitalType: h.hospitalType,
              location: h.location,
              address: h.address,
              city: h.city,
              state: h.state,
              pincode: h.pincode,
              latitude: h.latitude,
              longitude: h.longitude,
              rating: h.rating,
              reviewCount: h.reviewCount,
              distanceKm: recalculatedDist,
              doctorCount: h.doctorCount,
              specialtyCount: h.specialtyCount,
              bedCount: h.bedCount,
              departments: h.departments,
              facilities: h.facilities,
              phone: h.phone,
              emergencyPhone: h.emergencyPhone,
              email: h.email,
              website: h.website,
              description: h.description,
              workingHours: h.workingHours,
              is24x7: h.is24x7,
            ),
          );
        }
      }

      // Priority 3: Add production fallback hospitals if list is small, with dynamic recalculated distance
      if (combined.length < 5) {
        for (final h in ProductionDatabase.hospitals) {
          final key = h.name.toLowerCase().trim();
          if (!seenNames.contains(key)) {
            seenNames.add(key);
            final recalculatedDist = ApiService.calculateDistanceKm(_userLat, _userLng, h.latitude, h.longitude);
            combined.add(
              HospitalModel(
                id: h.id,
                name: h.name,
                logoUrl: h.logoUrl,
                bannerUrl: h.bannerUrl,
                hospitalType: h.hospitalType,
                location: h.location,
                address: h.address,
                city: h.city,
                state: h.state,
                pincode: h.pincode,
                latitude: h.latitude,
                longitude: h.longitude,
                rating: h.rating,
                reviewCount: h.reviewCount,
                distanceKm: recalculatedDist,
                doctorCount: h.doctorCount,
                specialtyCount: h.specialtyCount,
                bedCount: h.bedCount,
                departments: h.departments,
                facilities: h.facilities,
                phone: h.phone,
                emergencyPhone: h.emergencyPhone,
                email: h.email,
                website: h.website,
                description: h.description,
                workingHours: h.workingHours,
                is24x7: h.is24x7,
              ),
            );
          }
        }
      }

      // Sort strictly by closest proximity to user (nearest hospitals first!)
      combined.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      if (combined.isNotEmpty && mounted) {
        setState(() {
          _hospitals = combined;
          _selectedHospitalIndex = 0;
        });
      }
    } catch (_) {
      // Keep fallback
    } finally {
      _syncMarkers();
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapKey.currentState?.resize();
      });
    }
  }

  List<HospitalModel> get _filteredHospitals {
    final query = _searchController.text.trim().toLowerCase();
    return _hospitals.where((h) {
      final matchesQuery = query.isEmpty ||
          h.name.toLowerCase().contains(query) ||
          h.location.toLowerCase().contains(query) ||
          h.address.toLowerCase().contains(query) ||
          h.departments.any((d) => d.toLowerCase().contains(query)) ||
          h.services.any((s) => s.toLowerCase().contains(query));

      if (!matchesQuery) return false;

      if (_selectedFilter == 'All') return true;
      if (_selectedFilter.contains('24x7')) return h.is24x7;
      if (_selectedFilter.contains('Super Specialty')) {
        return h.hospitalType.toLowerCase().contains('super') ||
            h.hospitalType.toLowerCase().contains('quaternary') ||
            h.hospitalType.toLowerCase().contains('specialty');
      }
      if (_selectedFilter.contains('Cardiology')) {
        return h.departments.any((d) => d.toLowerCase().contains('cardio'));
      }
      if (_selectedFilter.contains('Orthopedics')) {
        return h.departments.any((d) => d.toLowerCase().contains('ortho'));
      }
      if (_selectedFilter.contains('Neurology')) {
        return h.departments.any((d) => d.toLowerCase().contains('neuro'));
      }
      if (_selectedFilter.contains('Pediatrics')) {
        return h.departments.any((d) => d.toLowerCase().contains('pediatric'));
      }
      if (_selectedFilter.contains('Oncology')) {
        return h.departments.any((d) => d.toLowerCase().contains('onco') || d.toLowerCase().contains('cancer'));
      }

      return true;
    }).toList();
  }

  List<MapboxMarkerItem> _buildMapMarkers(List<HospitalModel> list) {
    final markers = <MapboxMarkerItem>[];

    // 1. User Live GPS Pin (Pulsing Radar Beacon)
    markers.add(
      MapboxMarkerItem(
        id: 'user-live-gps',
        lng: _userLng,
        lat: _userLat,
        title: 'You are here',
        color: '#2563EB',
        width: 32,
        height: 32,
        anchor: 'center',
        iconHtml: '''
          <div style="position: relative; width: 32px; height: 32px; display: flex; align-items: center; justify-content: center;">
            <div style="position: absolute; width: 32px; height: 32px; background: rgba(37,99,235,0.28); border-radius: 50%;"></div>
            <div style="width: 14px; height: 14px; background: #2563EB; border-radius: 50%; border: 2.5px solid #FFFFFF; box-shadow: 0 0 10px rgba(37,99,235,0.9);"></div>
          </div>
        ''',
        popupHtml: '''
          <div style="padding: 6px 8px; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
            <div style="font-weight: 700; color: #1E3A8A; font-size: 13px;">📍 Your Current Location</div>
            <div style="color: #64748B; font-size: 11.5px; margin-top: 2px;">$_userCityName</div>
            <div style="color: #16A34A; font-weight: 600; font-size: 10.5px; margin-top: 4px;">• GPS Accuracy High</div>
          </div>
        ''',
      ),
    );

    // 2. Hospital Location Pin Pointer Markers
    for (int i = 0; i < list.length; i++) {
      final h = list[i];
      final isSelected = i == _selectedHospitalIndex;
      final pinColor = isSelected ? '#DC2626' : (h.is24x7 ? '#2563EB' : '#0D9488');
      final sizeW = isSelected ? 42.0 : 34.0;
      final sizeH = isSelected ? 52.0 : 42.0;

      markers.add(
        MapboxMarkerItem(
          id: 'hosp-${h.id}',
          lng: h.longitude,
          lat: h.latitude,
          title: h.name,
          color: pinColor,
          width: sizeW,
          height: sizeH,
          anchor: 'bottom',
          iconHtml: '''
            <div style="position: relative; width: ${sizeW}px; height: ${sizeH}px; cursor: pointer; display: flex; flex-direction: column; align-items: center; justify-content: center; filter: drop-shadow(0 4px 10px rgba(0,0,0,0.35)); will-change: transform;">
              <svg width="$sizeW" height="$sizeH" viewBox="0 0 38 48" fill="none" xmlns="http://www.w3.org/2000/svg">
                <!-- Pin Pointer Body -->
                <path d="M19 0C8.50659 0 0 8.50659 0 19C0 29.5 19 48 19 48C19 48 38 29.5 38 19C38 8.50659 29.4934 0 19 0Z" fill="$pinColor"/>
                <!-- Inner White Circle -->
                <circle cx="19" cy="18" r="12.5" fill="#FFFFFF"/>
                <!-- Hospital Cross in Center -->
                <rect x="16.5" y="10.5" width="5" height="15" rx="1.5" fill="$pinColor"/>
                <rect x="11.5" y="15.5" width="15" height="5" rx="1.5" fill="$pinColor"/>
              </svg>
              <!-- Mini Rating Badge on Top -->
              <div style="position: absolute; top: -5px; right: -4px; background: #FEF3C7; border: 1px solid #F59E0B; color: #92400E; font-size: 8px; font-weight: 800; padding: 1px 3px; border-radius: 6px; box-shadow: 0 1px 3px rgba(0,0,0,0.2); font-family: -apple-system, BlinkMacSystemFont, sans-serif; white-space: nowrap;">⭐ ${h.rating}</div>
            </div>
          ''',
          popupHtml: '''
            <div style="padding: 8px; font-family: -apple-system, BlinkMacSystemFont, sans-serif; min-width: 200px;">
              <div style="display: flex; align-items: center; justify-content: space-between; gap: 8px;">
                <span style="font-weight: 700; color: #0F172A; font-size: 13px;">${h.name}</span>
                <span style="background: #FEF3C7; color: #B45309; font-size: 11px; font-weight: 700; padding: 2px 6px; border-radius: 6px;">⭐ ${h.rating}</span>
              </div>
              <div style="color: #64748B; font-size: 11.5px; margin-top: 4px;">📍 ${h.location} • ${h.distanceKm} km away</div>
              <div style="display: flex; gap: 4px; margin-top: 6px;">
                <span style="background: #DCFCE7; color: #15803D; font-size: 10px; font-weight: 700; padding: 2px 6px; border-radius: 4px;">24x7 Emergency</span>
                <span style="background: #EFF6FF; color: #2563EB; font-size: 10px; font-weight: 700; padding: 2px 6px; border-radius: 4px;">${h.bedCount}+ Beds</span>
              </div>
            </div>
          ''',
        ),
      );
    }

    return markers;
  }

  void _syncMarkers() {
    final mapState = _mapKey.currentState;
    if (mapState != null) {
      mapState.clearMarkers();
      final markers = _buildMapMarkers(_filteredHospitals);
      for (final m in markers) {
        mapState.addMarker(m);
      }
    }
  }

  void _selectHospital(int index, HospitalModel h) {
    setState(() {
      _selectedHospitalIndex = index;
    });
    _mapKey.currentState?.flyTo(h.longitude, h.latitude, zoom: 15.8);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _flyToUserLocation() async {
    try {
      final loc = await LocationService.getLivePosition(forceRefresh: true);
      if (loc != null && mounted) {
        setState(() {
          _userLat = loc['lat'] as double? ?? _userLat;
          _userLng = loc['lng'] as double? ?? _userLng;
          _userCityName = '${loc['locality']}, ${loc['city']}';
          _isLiveGpsActive = true;
        });
        _mapKey.currentState?.flyTo(_userLng, _userLat, zoom: 15.5);
        _syncMarkers();
        await _loadAllHospitals();
      }
    } catch (_) {
      _mapKey.currentState?.flyTo(_userLng, _userLat, zoom: 15.5);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (kIsWeb) {
      try {
        web.window.open('tel:$cleanPhone', '_self');
      } catch (_) {}
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Connecting to: $phone', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHospitals;
    final mapMarkers = _buildMapMarkers(filtered);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 21),
                const SizedBox(width: 8),
                const Text(
                  'Nearby Hospitals',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // View Switcher (Map vs List)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() => _isListView = false);
                          Future.delayed(const Duration(milliseconds: 150), () {
                            _mapKey.currentState?.resize();
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isListView ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !_isListView
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_rounded, size: 15, color: !_isListView ? AppColors.primary : AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Map',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: !_isListView ? FontWeight.bold : FontWeight.w500,
                                  color: !_isListView ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _isListView = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isListView ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isListView
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.format_list_bulleted_rounded, size: 15, color: _isListView ? AppColors.primary : AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'List',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _isListView ? FontWeight.bold : FontWeight.w500,
                                  color: _isListView ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _isLiveGpsActive ? AppColors.success : Colors.amber.shade700,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    '$_userCityName • ${filtered.length} Hospitals Live',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Search & Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {});
                    _syncMarkers();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search hospitals, specialties, emergency...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              _syncMarkers();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedFilter = filter);
                            _syncMarkers();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Main View
          Expanded(
            child: _isListView ? _buildFullListView(filtered) : _buildMapAndCarouselView(filtered, mapMarkers),
          ),
        ],
      ),
    );
  }

  Widget _buildMapAndCarouselView(List<HospitalModel> filtered, List<MapboxMarkerItem> mapMarkers) {
    return Stack(
      children: [
        // 1. Live Mapbox GL Canvas Map (Fills entire screen)
        Positioned.fill(
          child: RealMapboxMap(
            key: _mapKey,
            initialLng: _userLng,
            initialLat: _userLat,
            initialZoom: 13.8,
            interactive: true,
            height: double.infinity,
            markers: mapMarkers,
            borderRadius: BorderRadius.zero,
          ),
        ),

        // 2. Floating Map Action Buttons (Top Right)
        Positioned(
          top: 12,
          right: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // SOS 108
              Material(
                color: AppColors.emergency,
                borderRadius: BorderRadius.circular(24),
                elevation: 4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _makePhoneCall('108'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emergency_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 5),
                        Text(
                          'SOS 108',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Locate Me
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _flyToUserLocation,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location_rounded, color: AppColors.primary, size: 15),
                        SizedBox(width: 5),
                        Text(
                          'Locate Me',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Satellite Toggle
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _mapKey.currentState?.toggleMapStyle(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _mapKey.currentState?.isSatellite == true ? Icons.streetview_rounded : Icons.satellite_alt_rounded,
                          color: const Color(0xFF0284C7),
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _mapKey.currentState?.isSatellite == true ? 'Streets' : 'Satellite',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Compact Horizontal Carousel of Hospital Cards (Reduced height: 140px, bottom: 12)
        if (filtered.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: SizedBox(
              height: 142,
              child: PageView.builder(
                controller: _pageController,
                itemCount: filtered.length,
                onPageChanged: (index) {
                  final h = filtered[index];
                  setState(() => _selectedHospitalIndex = index);
                  _mapKey.currentState?.flyTo(h.longitude, h.latitude, zoom: 15.8);
                },
                itemBuilder: (context, index) {
                  final hospital = filtered[index];
                  final isSelected = index == _selectedHospitalIndex;
                  return _buildCompactHospitalCard(hospital, index, isSelected);
                },
              ),
            ),
          )
        else
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No hospitals match your query. Try resetting the category filter.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactHospitalCard(HospitalModel hospital, int index, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.07),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: hospital)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Real Hospital Photo + Hospital Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Real Hospital Building Photo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        hospital.logoUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.network(
                          hospital.bannerUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Core Info (Flexible to prevent any overflow)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  hospital.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${hospital.rating}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hospital.location,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Badges Row (Protected against horizontal overflow)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '📍 ${hospital.distanceKm} km',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                if (hospital.is24x7)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '24×7 Emergency',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                    ),
                                  ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${hospital.bedCount}+ Beds',
                                    style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bottom Action Buttons Row
                Row(
                  children: [
                    // Call Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.phone_rounded, size: 12, color: AppColors.primary),
                      label: const Text('Call', style: TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      onPressed: () => _makePhoneCall(hospital.emergencyPhone.isNotEmpty ? hospital.emergencyPhone : hospital.phone),
                    ),
                    const SizedBox(width: 6),
                    // Center Map Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF0284C7)),
                      label: const Text('Center Map', style: TextStyle(fontSize: 10.5, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                      onPressed: () => _selectHospital(index, hospital),
                    ),
                    const Spacer(),
                    // View & Book Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View & Book', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, size: 11),
                        ],
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: hospital)),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullListView(List<HospitalModel> filtered) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital_outlined, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No hospitals found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your search keywords or category filter',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _selectedFilter = 'All');
              },
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final hospital = filtered[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: hospital)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          hospital.logoUrl,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.network(
                            hospital.bannerUrl,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 58,
                              height: 58,
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.local_hospital_rounded, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hospital.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hospital.location,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  '${hospital.rating} (${hospital.reviewCount} reviews)',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•  ${hospital.distanceKm} km',
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildPill(Icons.bed_rounded, '${hospital.bedCount}+ Beds', AppColors.primary),
                      _buildPill(Icons.medical_services_rounded, '${hospital.specialtyCount}+ Specialties', const Color(0xFF0284C7)),
                      if (hospital.is24x7)
                        _buildPill(Icons.access_time_rounded, '24x7 Emergency', AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 14, color: AppColors.primary),
                        label: const Text('Call', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        onPressed: () => _makePhoneCall(hospital.emergencyPhone.isNotEmpty ? hospital.emergencyPhone : hospital.phone),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.map_rounded, size: 14, color: Color(0xFF0284C7)),
                        label: const Text('Show on Map', style: TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setState(() => _isListView = false);
                          Future.delayed(const Duration(milliseconds: 200), () {
                            _selectHospital(index, hospital);
                          });
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Book Visit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => HospitalDetailScreen(hospital: hospital)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
