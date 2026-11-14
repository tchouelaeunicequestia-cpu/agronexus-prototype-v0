import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/config/app_assets.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_provider.dart';
import 'agronomist_advisory_screen.dart';
import 'agronomist_ai_sandbox_screen.dart';
import 'agronomist_components.dart';
import 'agronomist_guide_publisher_screen.dart';
import 'agronomist_profile_screen.dart';
import 'agronomist_silo_screen.dart';

class AgronomistDashboard extends StatefulWidget {
  const AgronomistDashboard({super.key});

  @override
  State<AgronomistDashboard> createState() => _AgronomistDashboardState();
}

class _AgronomistDashboardState extends State<AgronomistDashboard> {
  static const _backgroundImage = AppAssets.cover;

  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};
  List<Map<String, dynamic>> _nodes = [];
  String? _metricsError;
  String? _nodesError;
  Map<String, dynamic>? _liveAlert;
  Timer? _overviewPollingTimer;
  String? _lastAlertKey;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadOverview();
    _overviewPollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_isLoading) _loadOverview(showNewAlerts: true);
    });
  }

  @override
  void dispose() {
    _overviewPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOverview({bool showNewAlerts = false}) async {
    setState(() => _isLoading = true);
    Map<String, dynamic>? metrics;
    List<Map<String, dynamic>>? nodes;
    String? metricsError;
    String? nodesError;

    try {
      metrics = await ApiService.getAgronomistMetrics();
    } on SessionExpiredException {
      await context.read<AuthProvider>().logout();
      return;
    } catch (error) {
      metricsError = agronomistErrorMessage(error);
    }

    try {
      nodes = await ApiService.getTelemetryNodes();
    } on SessionExpiredException {
      await context.read<AuthProvider>().logout();
      return;
    } catch (error) {
      nodesError = agronomistErrorMessage(error);
    }

    if (!mounted) return;
    Map<String, dynamic>? latestAlert;
    if (nodes != null) {
      final alerts =
          nodes.where((node) => node['isAlertTriggered'] == true).toList()
            ..sort(
              (first, second) =>
                  _recordedAt(second).compareTo(_recordedAt(first)),
            );
      if (alerts.isNotEmpty) latestAlert = alerts.first;
    }
    final latestAlertKey = latestAlert == null
        ? null
        : '${latestAlert['id'] ?? latestAlert['nodeId']}-'
              '${latestAlert['recordedAt'] ?? ''}';
    final shouldNotify =
        showNewAlerts && latestAlert != null && latestAlertKey != _lastAlertKey;
    if (nodes != null) _lastAlertKey = latestAlertKey;

    setState(() {
      if (metrics != null) _metrics = metrics;
      if (nodes != null) _nodes = nodes;
      if (nodes != null) _liveAlert = latestAlert;
      _metricsError = metricsError;
      _nodesError = nodesError;
      _isLoading = false;
    });
    if (shouldNotify) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Telemetry alert from ${latestAlert['nodeId'] ?? 'a storage node'}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF8F2828),
        ),
      );
    }
  }

  static DateTime _recordedAt(Map<String, dynamic> reading) =>
      DateTime.tryParse(reading['recordedAt']?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final name = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : 'Agronomist';

    final screens = [
      AgronomistAdvisoryScreen(
        metrics: _metrics,
        nodes: _nodes,
        liveAlert: _liveAlert,
        isLoading: _isLoading,
        metricsError: _metricsError,
        nodesError: _nodesError,
        onRefresh: _loadOverview,
        onOpenSilos: () => setState(() => _selectedIndex = 1),
        onOpenGuides: () => setState(() => _selectedIndex = 2),
      ),
      AgronomistSiloScreen(nodes: _nodes),
      const AgronomistGuidePublisherScreen(),
      const AgronomistAiSandboxScreen(),
      const AgronomistProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _backgroundImage,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF16362B)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xD90B1320),
                    const Color(0xC40B1320),
                    const Color(0xEB0B1320),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(name, user?.role ?? 'AGRONOMIST'),
                Expanded(
                  child: IndexedStack(index: _selectedIndex, children: screens),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildHeader(String name, String role) => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xEE101A29),
          border: Border(
            bottom: BorderSide(
              color: AgronomistPalette.border.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AgronomistPalette.primary.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: AgronomistPalette.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AgroNexus',
                    style: TextStyle(
                      color: AgronomistPalette.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$name · ${role.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AgronomistPalette.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(
                Icons.logout_rounded,
                color: AgronomistPalette.muted,
                size: 21,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildNavigationBar() => NavigationBar(
    height: 68,
    selectedIndex: _selectedIndex,
    onDestinationSelected: (index) => setState(() => _selectedIndex = index),
    backgroundColor: const Color(0xF2111925),
    indicatorColor: AgronomistPalette.primary.withValues(alpha: 0.14),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.space_dashboard_outlined),
        selectedIcon: Icon(Icons.space_dashboard_rounded),
        label: 'Advisory',
      ),
      NavigationDestination(
        icon: Icon(Icons.sensors_outlined),
        selectedIcon: Icon(Icons.sensors_rounded),
        label: 'Silos',
      ),
      NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book_rounded),
        label: 'Guides',
      ),
      NavigationDestination(
        icon: Icon(Icons.psychology_alt_outlined),
        selectedIcon: Icon(Icons.psychology_alt_rounded),
        label: 'AgroAI',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ],
  );
}
