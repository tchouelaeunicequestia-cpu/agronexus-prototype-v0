import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_provider.dart';
import 'package:frontend/services/api_service.dart';

import 'dart:ui';

class TransporterTripLiveScreen extends StatefulWidget {
  const TransporterTripLiveScreen({super.key});

  @override
  State<TransporterTripLiveScreen> createState() =>
      _TransporterTripLiveScreenState();
}

class _TransporterTripLiveScreenState extends State<TransporterTripLiveScreen> {
  static const _surface = Color(0xFF0b1326);
  static const _surfaceContainer = Color(0xFF171f33);
  static const _surfaceContainerHigh = Color(0xFF222a3d);
  static const _surfaceContainerLow = Color(0xFF131b2e);
  static const _primary = Color(0xFF4edea3);
  static const _tertiary = Color(0xFFffb95f);
  static const _secondary = Color(0xFF45dfa4);
  static const _onSurface = Color(0xFFdae2fd);
  static const _onSurfaceVariant = Color(0xFFbbcabf);
  static const _error = Color(0xFFffb4ab);
  static const _errorContainer = Color(0xFF93000a);

  bool _isLoading = true;
  Map<String, dynamic>? _activeTrip;

  @override
  void initState() {
    super.initState();
    _fetchActiveTrip();
  }

  Future<void> _fetchActiveTrip() async {
    try {
      final res = await ApiService.authenticatedRequest(
        '/api/v1/transporter/active-trip',
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['hasActiveTrip'] == true) {
          if (mounted)
            setState(() {
              _activeTrip = data;
              _isLoading = false;
            });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(user),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _activeTrip == null
          ? const Center(
              child: Text(
                'No Active Trip Assigned',
                style: TextStyle(color: _onSurfaceVariant, fontSize: 16),
              ),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMissionHeader(),
                  const SizedBox(height: 16),
                  _buildVectorRouteMap(),
                  const SizedBox(height: 16),
                  _buildTelematicsHUD(),
                  const SizedBox(height: 16),
                  _buildThermalLogGraph(),
                  const SizedBox(height: 16),
                  _buildCargoManifest(),
                  const SizedBox(height: 16),
                  _buildActionControls(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(dynamic user) {
    return AppBar(
      backgroundColor: const Color(0xFF060e20).withOpacity(0.85),
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: _primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF003824), size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Trip Live',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    user?.name ?? 'UNIT-740X',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '•',
                      style: TextStyle(fontSize: 10, color: Colors.white30),
                    ),
                  ),
                  const Text(
                    '42T SEMI',
                    style: TextStyle(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _surfaceContainerHigh.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: _primary, size: 8),
              SizedBox(width: 4),
              Text(
                'ONLINE',
                style: TextStyle(
                  color: _primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: _onSurfaceVariant),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMissionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '#${_activeTrip?['id'] ?? 'TRIP-PENDING'}',
                    style: const TextStyle(
                      color: _onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.circle,
                      size: 4,
                      color: Color(0xFF2d3449),
                    ),
                  ),
                  const Text(
                    'CORRIDOR RN4',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.15),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: _primary, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'IN TRANSIT (LIVE)',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.navigation, color: _primary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '${_activeTrip?['origin'] ?? 'Origin'} ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _onSurface,
                    ),
                    children: [
                      const TextSpan(
                        text: '➔ ',
                        style: TextStyle(color: _onSurfaceVariant),
                      ),
                      TextSpan(
                        text: _activeTrip?['destination'] ?? 'Destination',
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text.rich(
            TextSpan(
              text: '118 km total • ',
              style: TextStyle(fontSize: 12, color: _onSurfaceVariant),
              children: [
                TextSpan(
                  text: '52 km elapsed',
                  style: TextStyle(
                    color: _onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(text: ' • 66 km remaining'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.441,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, _secondary],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '44% COMPLETED',
                style: TextStyle(
                  color: _primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.timer, color: _tertiary, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'ETA: 1h 20m (14:45)',
                    style: TextStyle(color: _onSurface, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVectorRouteMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 176,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF060e20).withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _surfaceContainerHigh.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: _primary, size: 6),
                              SizedBox(width: 6),
                              Text(
                                'GPS LOCK: ±1.8m',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _surfaceContainerHigh.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.satellite_alt,
                                color: _primary,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'GEO-CORRIDOR OK',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(child: CustomPaint(painter: _RoutePainter())),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _surfaceContainerHigh.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'RN4 KM-52',
                            style: TextStyle(
                              fontSize: 11,
                              color: _primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Monatele Overpass',
                            style: TextStyle(
                              fontSize: 10,
                              color: _onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _surfaceContainerHigh.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'NEXT: ',
                            style: TextStyle(
                              fontSize: 11,
                              color: _onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Ndumbi Node (8 km)',
                            style: TextStyle(
                              fontSize: 11,
                              color: _tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineNode(
              icon: Icons.check,
              iconColor: _primary,
              iconBg: _primary.withOpacity(0.2),
              title: 'Bafia Farm Gate',
              subtitle: 'Dispatch Departure',
              trailingText: '07:30 Passed',
              trailingColor: _primary,
            ),
            const SizedBox(height: 10),
            _buildTimelineNode(
              icon: Icons.scale,
              iconColor: _primary,
              iconBg: _primary.withOpacity(0.2),
              title: 'Obala Weighbridge',
              subtitle: 'Gross Load: 11,840 kg',
              trailingText: '08:52 Cleared',
              trailingColor: _primary,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _tertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildTimelineNode(
                icon: Icons.sensors,
                iconColor: _tertiary,
                iconBg: _tertiary.withOpacity(0.2),
                title: 'Ndumbi Telemetry Node',
                subtitle: 'Corridor Handshake Ping',
                trailingText: 'In 8 km',
                trailingColor: _tertiary,
                trailingBold: true,
              ),
            ),
            const SizedBox(height: 10),
            _buildTimelineNode(
              icon: Icons.warehouse,
              iconColor: _onSurfaceVariant,
              iconBg: _surfaceContainerHigh,
              title: 'Bastos Wholesale Depot',
              subtitle: 'Escrow Release Terminal',
              trailingText: 'ETA 14:45',
              trailingColor: _onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineNode({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String trailingText,
    required Color trailingColor,
    bool trailingBold = false,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: iconColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          trailingText,
          style: TextStyle(
            fontSize: 11,
            color: trailingColor,
            fontWeight: trailingBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildTelematicsHUD() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle & IoT Telematics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _onSurface,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.circle, size: 6, color: _primary),
                  SizedBox(width: 4),
                  Text(
                    'STREAM LIVE',
                    style: TextStyle(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGaugeCard(
                  icon: Icons.ac_unit,
                  iconColor: _primary,
                  topTrailing: const Icon(
                    Icons.circle,
                    size: 6,
                    color: _primary,
                  ),
                  valueText: '4.3',
                  unitText: '°C',
                  unitColor: _primary,
                  subtitle: 'Reefer Box',
                  statusBg: _primary.withOpacity(0.1),
                  statusText: 'NOMINAL',
                  statusColor: _primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGaugeCard(
                  icon: Icons.speed,
                  iconColor: _secondary,
                  topTrailing: const Text(
                    'RN4',
                    style: TextStyle(
                      fontSize: 10,
                      color: _onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  valueText: '64',
                  unitText: 'km/h',
                  unitColor: _secondary,
                  subtitle: 'Ground Speed',
                  statusBg: _surfaceContainer,
                  statusText: 'MAX: 70',
                  statusColor: _onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGaugeCard(
                  icon: Icons.cell_tower,
                  iconColor: _primary,
                  topTrailing: const Icon(
                    Icons.battery_full,
                    size: 15,
                    color: _primary,
                  ),
                  valueText: '98',
                  unitText: '%',
                  unitColor: _primary,
                  subtitle: 'Telemetry Sync',
                  statusBg: _surfaceContainerHigh,
                  statusText: 'NB-IoT HIGH',
                  statusColor: _onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeCard({
    required IconData icon,
    required Color iconColor,
    required Widget topTrailing,
    required String valueText,
    required String unitText,
    required Color unitColor,
    required String subtitle,
    required Color statusBg,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 18),
              topTrailing,
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: valueText,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: _onSurface,
                letterSpacing: -1,
              ),
              children: [
                TextSpan(
                  text: unitText,
                  style: TextStyle(fontSize: 16, color: unitColor),
                ),
              ],
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: _onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermalLogGraph() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.thermostat, color: _primary, size: 20),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continuous Thermal Envelope',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _onSurface,
                          ),
                        ),
                        Text(
                          'Last 4 Hours Log • Interval: 30s',
                          style: TextStyle(
                            fontSize: 11,
                            color: _onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Target: 3.5° - 5.0°C',
                      style: TextStyle(
                        fontSize: 11,
                        color: _primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Zero Breaches',
                      style: TextStyle(
                        fontSize: 11,
                        color: _onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 112,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://via.placeholder.com/320x90/131b2e/4edea3?text=Thermal+Graph+Mockup',
                  ), // Placeholder for SVG curve
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 18,
                    right: 4,
                    child: Text(
                      '5.0°C MAX',
                      style: TextStyle(
                        fontSize: 8,
                        color: _error.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 4,
                    child: Text(
                      '3.5°C MIN',
                      style: TextStyle(
                        fontSize: 8,
                        color: _error.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '08:00',
                          style: TextStyle(
                            fontSize: 10,
                            color: _onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '09:00',
                          style: TextStyle(
                            fontSize: 10,
                            color: _onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '10:00',
                          style: TextStyle(
                            fontSize: 10,
                            color: _onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '11:00',
                          style: TextStyle(
                            fontSize: 10,
                            color: _onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '11:30 (NOW)',
                          style: TextStyle(
                            fontSize: 10,
                            color: _primary,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildCargoManifest() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2, color: _secondary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Cargo & Escrow',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _onSurface,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _tertiary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, size: 13, color: _tertiary),
                      SizedBox(width: 4),
                      Text(
                        '185,000 XAF',
                        style: TextStyle(
                          fontSize: 11,
                          color: _tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lot #PL-88',
                              style: TextStyle(
                                fontSize: 11,
                                color: _onSurfaceVariant,
                              ),
                            ),
                            Icon(Icons.eco, size: 15, color: _primary),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '300 kg',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _onSurface,
                          ),
                        ),
                        Text(
                          'Grade-A Plantains',
                          style: TextStyle(
                            fontSize: 12,
                            color: _onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lot #AV-12',
                              style: TextStyle(
                                fontSize: 11,
                                color: _onSurfaceVariant,
                              ),
                            ),
                            Icon(Icons.spa, size: 15, color: _primary),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '450 kg',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _onSurface,
                          ),
                        ),
                        Text(
                          'Hass Avocados',
                          style: TextStyle(
                            fontSize: 12,
                            color: _onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF060e20).withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: _primary, size: 20),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Depository Lock',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _onSurface,
                            ),
                          ),
                          Text(
                            'Auto-release at Bastos weigh-in',
                            style: TextStyle(
                              fontSize: 11,
                              color: _onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'SECURED',
                    style: TextStyle(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Checkpoint Reported'),
                        backgroundColor: _primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.flag, size: 20, color: _secondary),
                  label: const Text(
                    'Log Checkpoint',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _surfaceContainerHigh,
                    foregroundColor: _onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Manifest Verified'),
                        backgroundColor: _primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment, size: 20, color: _primary),
                  label: const Text(
                    'Live Manifest',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _surfaceContainerHigh,
                    foregroundColor: _onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Escalation Alert Transmitted to Yaoundé Ops',
                    ),
                    backgroundColor: _errorContainer,
                  ),
                );
              },
              icon: const Icon(Icons.crisis_alert, size: 20, color: _error),
              label: const Text(
                'EMERGENCY SOS / COLD-CHAIN BREACH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _errorContainer.withOpacity(0.4),
                foregroundColor: _error,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.1);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.4,
      size.width * 0.4,
      size.height * 0.55,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.7,
      size.width * 0.9,
      size.height * 0.85,
    );

    final shader = const LinearGradient(
      colors: [
        Color(0xFF4edea3),
        Color(0xFF45dfa4),
        Color(0xFF86948a),
        Color(0xFF3c4a42),
      ],
      stops: [0.0, 0.44, 0.48, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    paint.shader = shader;
    canvas.drawPath(path, paint);

    final fillPaint = Paint()..style = PaintingStyle.fill;

    // Passed nodes
    fillPaint.color = const Color(0xFF4edea3);
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.1),
      4.5,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.42),
      4.5,
      fillPaint,
    );

    // Live marker
    fillPaint.color = const Color(0xFF4edea3).withOpacity(0.3);
    canvas.drawCircle(
      Offset(size.width * 0.44, size.height * 0.6),
      14,
      fillPaint,
    );
    fillPaint.color = const Color(0xFF6ffbbe);
    canvas.drawCircle(
      Offset(size.width * 0.44, size.height * 0.6),
      6,
      fillPaint,
    );
    fillPaint.color = const Color(0xFF003824);
    canvas.drawCircle(
      Offset(size.width * 0.44, size.height * 0.6),
      2.5,
      fillPaint,
    );

    // Approaching nodes
    fillPaint.color = const Color(0xFFffb95f);
    canvas.drawCircle(
      Offset(size.width * 0.61, size.height * 0.69),
      4,
      fillPaint,
    );
    fillPaint.color = const Color(0xFF86948a);
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.85),
      5,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
