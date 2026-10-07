// lib/screens/dashboards/shared/handover_tracking_screen.dart
import 'package:flutter/material.dart';

import 'dart:ui';

import '../../../services/api_service.dart';
import '../../../widgets/handover_action_card.dart';

class HandoverTrackingScreen extends StatefulWidget {
  final String orderId;
  final String userRole; // 'FARMER', 'TRANSPORTER', or 'BUYER'
  final VoidCallback onStateUpdated;

  const HandoverTrackingScreen({
    super.key,
    required this.orderId,
    required this.userRole,
    required this.onStateUpdated,
  });

  @override
  State<HandoverTrackingScreen> createState() => _HandoverTrackingScreenState();
}

class _HandoverTrackingScreenState extends State<HandoverTrackingScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.userRole} Handover Signoff'),
        backgroundColor: Colors.black.withOpacity(0.6),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/abstract_background_1.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0F382C)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Multi-Party Handover Verification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ensure all telemetry and inspection states match before confirming signoff.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  HandoverActionCard(
                    orderId: widget.orderId,
                    role: widget.userRole,
                    authToken: ApiService.globalAccessToken ?? '',
                    onSuccess: () {
                      widget.onStateUpdated();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
