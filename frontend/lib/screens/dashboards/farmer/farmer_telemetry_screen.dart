import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/farmer_background_layer.dart';
import 'package:frontend/widgets/farmer_bottom_navigation.dart';

import 'farmer_dashboard.dart';
import 'farmer_listings_screen.dart';
import 'farmer_escrow_screen.dart';
import 'farmer_profile_screen.dart';
import '../../../screens/produce/add_produce_screen.dart';

class FarmerTelemetryScreen extends StatefulWidget {
  const FarmerTelemetryScreen({super.key});

  @override
  State<FarmerTelemetryScreen> createState() => _FarmerTelemetryScreenState();
}

class _FarmerTelemetryScreenState extends State<FarmerTelemetryScreen> {
  final _nodeController = TextEditingController();
  Map<String, dynamic> _metrics = {};
  List<Map<String, dynamic>> _readings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  @override
  void dispose() {
    _nodeController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final metrics = await ApiService.getFarmerDashboardMetrics();
      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadNodeReadings() async {
    final nodeId = _nodeController.text.trim();
    if (nodeId.isEmpty) return;
    setState(() => _errorMessage = null);
    try {
      final readings = await ApiService.getTelemetryNodeLogs(nodeId);
      if (mounted) setState(() => _readings = readings);
    } catch (error) {
      if (mounted)
        setState(
          () =>
              _errorMessage = error.toString().replaceFirst('Exception: ', ''),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    bottomNavigationBar: FarmerBottomNavigation(
      selectedIndex: 4,
      onDestinationSelected: _navigateToFarmerTab,
    ),
    body: Stack(
      children: [
        const FarmerBackgroundLayer(),
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: const Color(0xF2FFFFFF),
              foregroundColor: const Color(0xFF0F172A),
              title: const Text('Silo telemetry'),
              actions: [
                IconButton(
                  tooltip: 'Refresh metrics',
                  onPressed: _isLoading ? null : _loadMetrics,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: 'Open profile',
                  onPressed: () => _navigateToFarmerTab(5),
                  icon: const Icon(Icons.person_outline_rounded),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _siloHeader(),
                  const SizedBox(height: 18),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6CF8BB),
                      ),
                    )
                  else if (_errorMessage != null)
                    _messageCard(_errorMessage!)
                  else
                    _metricsGrid(),
                  const SizedBox(height: 20),
                  _nodeSearch(),
                  if (_readings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Recent node readings',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._readings.take(10).map(_readingCard),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  void _navigateToFarmerTab(int index) {
    if (index == 4) return;
    final Widget screen = switch (index) {
      0 => const FarmerDashboard(),
      1 => const FarmerListingsScreen(),
      2 => const AddProduceScreen(),
      3 => const FarmerEscrowScreen(),
      5 => const FarmerProfileScreen(),
      _ => const FarmerDashboard(),
    };
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _metricsGrid() => LayoutBuilder(
    builder: (context, constraints) {
      final cards = [
        _metricCard(
          'Escrow balance',
          _metrics['escrowBalance'] == null
              ? 'Unavailable'
              : '${_metrics['escrowBalance']} XAF',
          Icons.lock_rounded,
        ),
        _metricCard(
          'Active lots',
          _metrics['activeLotsCount']?.toString() ?? 'Unavailable',
          Icons.inventory_2_rounded,
        ),
        _metricCard(
          'Total yield',
          _metrics['totalYieldKg'] == null
              ? 'Unavailable'
              : '${_metrics['totalYieldKg']} kg',
          Icons.scale_rounded,
        ),
        _metricCard(
          'Silo temperature',
          _valueOrUnavailable(_metrics['siloTemp'], '°C'),
          Icons.thermostat_rounded,
        ),
        _metricCard(
          'Silo humidity',
          _valueOrUnavailable(_metrics['siloHumidity'], '%'),
          Icons.water_drop_rounded,
        ),
        _metricCard(
          'Gas level',
          _valueOrUnavailable(_metrics['siloGas'], ' ppm'),
          Icons.air_rounded,
        ),
      ];
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: cards
            .map(
              (card) =>
                  SizedBox(width: (constraints.maxWidth - 10) / 2, child: card),
            )
            .toList(),
      );
    },
  );

  String _valueOrUnavailable(dynamic value, String suffix) =>
      value == null ? 'Unavailable' : '$value$suffix';

  Widget _siloHeader() {
    final online = _metrics['telemetryAvailable'] == true;
    final nodeId = _metrics['telemetryNodeId']?.toString();
    final facility = _metrics['storageFacilityName']?.toString();
    final hasAlert = _metrics['telemetryAlert'] == true;
    final alertMessage = _metrics['telemetryAlertMessage']?.toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: online ? const Color(0xFFD7F3E3) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: online ? const Color(0xFF0F5132) : Colors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                online ? 'NODE ONLINE' : 'WAITING FOR NODE',
                style: TextStyle(
                  color: online ? const Color(0xFF0F5132) : Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Farm Storage Silos',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.warehouse_outlined,
                color: Color(0xFF0F5132),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                facility?.isNotEmpty == true
                    ? facility!
                    : 'Storage facility not identified',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
          if (nodeId?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              'Node $nodeId',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
          if (hasAlert) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alertMessage?.isNotEmpty == true
                        ? alertMessage!
                        : 'Storage conditions require attention.',
                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD7F3E3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF0F5132)),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
      ],
    ),
  );

  Widget _nodeSearch() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD7F3E3)),
    ),
    child: TextField(
      controller: _nodeController,
      style: const TextStyle(color: Color(0xFF0F172A)),
      onSubmitted: (_) => _loadNodeReadings(),
      decoration: InputDecoration(
        labelText: 'Inspect a storage node',
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        hintText: 'Enter node ID',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.sensors_rounded, color: Color(0xFF0F5132)),
        suffixIcon: IconButton(
          onPressed: _loadNodeReadings,
          icon: const Icon(
            Icons.arrow_forward_rounded,
            color: Color(0xFF0F5132),
          ),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0F5132)),
        ),
      ),
    ),
  );

  Widget _readingCard(Map<String, dynamic> reading) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFD7F3E3)),
    ),
    child: Row(
      children: [
        Icon(
          reading['alertTriggered'] == true
              ? Icons.warning_amber_rounded
              : Icons.check_circle_rounded,
          color: reading['alertTriggered'] == true
              ? Colors.amber
              : const Color(0xFF0F5132),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Temperature ${reading['temperature'] ?? '—'}°C • Humidity ${reading['humidity'] ?? '—'}%',
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _messageCard(String message) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFF64748B))),
  );
}
