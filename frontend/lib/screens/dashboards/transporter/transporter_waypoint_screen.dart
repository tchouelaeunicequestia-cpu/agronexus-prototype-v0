import 'package:flutter/material.dart';
import 'package:frontend/config/app_assets.dart';

import 'dart:ui';

import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_provider.dart';
import 'package:frontend/services/draft_service.dart';
import 'package:frontend/services/platform_services.dart';

class TransporterWaypointScreen extends StatefulWidget {
  final String orderId;
  final VoidCallback onWaypointUpdated;

  const TransporterWaypointScreen({
    super.key,
    required this.orderId,
    required this.onWaypointUpdated,
  });

  @override
  State<TransporterWaypointScreen> createState() =>
      _TransporterWaypointScreenState();
}

class _TransporterWaypointScreenState extends State<TransporterWaypointScreen> {
  final _noteController = TextEditingController();
  bool _isLoading = false;
  PositionData? _currentPos;

  @override
  void initState() {
    super.initState();
    _fetchCurrentGps();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentGps() async {
    try {
      final pos = await LocationServiceFactory.getService()
          .getCurrentLocation();
      if (mounted) setState(() => _currentPos = pos);
    } catch (_) {}
  }

  Future<void> _submitWaypoint() async {
    if (_currentPos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acquiring live RTK position first...')),
      );
      await _fetchCurrentGps();
      if (_currentPos == null) return;
    }

    setState(() => _isLoading = true);
    bool success = await ApiService.updateTransportWaypoint(
      orderId: widget.orderId,
      latitude: _currentPos!.latitude,
      longitude: _currentPos!.longitude,
      waypointNote: _noteController.text.trim().isEmpty
          ? 'En route waypoint check-in'
          : _noteController.text.trim(),
      token: ApiService.globalAccessToken,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Waypoint logged successfully into corridor tracking mesh.',
            ),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        widget.onWaypointUpdated();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to transmit waypoint update. Check connection.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Waypoint Check-In: ${widget.orderId}'),
        backgroundColor: Colors.black.withOpacity(0.6),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.cover,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0F382C)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Log Transit Checkpoint',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Broadcast your current RTK location coordinate and transit status update to the buyer and admin plane.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.gps_fixed,
                                color: Color(0xFF6CF8BB),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _currentPos != null
                                      ? 'Lat: ${_currentPos!.latitude.toStringAsFixed(4)}° N, Lon: ${_currentPos!.longitude.toStringAsFixed(4)}° E'
                                      : 'Acquiring satellite RTK lock...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _noteController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Waypoint Notes / Condition Check',
                            hintText: 'e.g., Passed checkpoint inspection at Bafia gate, cargo secure.',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _submitWaypoint,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Transmit Waypoint Update',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
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
          ),
        ],
      ),
    );
  }
}
