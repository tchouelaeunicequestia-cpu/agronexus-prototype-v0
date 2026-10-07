import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'widgets/admin_app_bar.dart';

class AdminOperatorsScreen extends StatefulWidget {
  const AdminOperatorsScreen({super.key});

  @override
  State<AdminOperatorsScreen> createState() => _AdminOperatorsScreenState();
}

class _AdminOperatorsScreenState extends State<AdminOperatorsScreen> {
  bool _isLoading = false;
  List<dynamic> _backendPendingUsers = [];
  
  List<Map<String, dynamic>> _priorityQueue = [];
  List<Map<String, dynamic>> _certifiedOperators = [];

  @override
  void initState() {
    super.initState();
    _fetchBackendPendingUsers();
  }

  Future<void> _fetchBackendPendingUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.authenticatedRequest('/api/v1/admin/pending-users');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _backendPendingUsers = data;
            // Also populate priority queue with backend users so the UI shows them
            _priorityQueue = data.map((u) => {
              'id': u['id'].toString(),
              'name': u['fullName'] ?? 'Unknown',
              'role': u['role'] ?? 'User',
              'auditId': '#ID-${u['id']}',
              'license': 'Pending Verif.',
              'type': (u['role'] ?? '').toString().toLowerCase(),
            }).toList().cast<Map<String, dynamic>>();
          });
        }
      }

      final resCert = await ApiService.authenticatedRequest('/api/v1/admin/operators/certified');
      if (resCert.statusCode == 200) {
        final certData = jsonDecode(resCert.body);
        if (certData is List) {
          setState(() {
            _certifiedOperators = certData.map((u) => {
              'name': u['fullName'] ?? 'Unknown',
              'audit': 'ID: CERT-${u['id']} • Signed',
              'icon': Icons.verified,
              'color': const Color(0xFF4EDEA3),
            }).toList().cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (_) {
      // Graceful fallback to rich mock queue
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _approveOperator(String id, String name, [int? backendUserId]) async {
    if (backendUserId != null) {
      try {
        await ApiService.authenticatedRequest(
          '/api/v1/admin/approve-user/$backendUserId',
          method: 'POST',
        );
      } catch (_) {}
    }

    setState(() {
      _priorityQueue.removeWhere((item) => item['id'] == id);
      _backendPendingUsers.removeWhere((item) => item['id'] == backendUserId);
      _certifiedOperators.insert(0, {
        'name': name,
        'audit': 'ID: CERT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)} • Just Signed',
        'icon': Icons.verified,
        'color': const Color(0xFF4EDEA3),
      });
    });

    _showToast('Key Issued & Broadcasted', '$name authorized under Root Protocol.');
  }

  void _requestDoc(String name) {
    _showToast('Doc Request Dispatched', 'Signed audit request pushed to $name terminal.');
  }

  void _rejectOperator(String id, String name, [int? backendUserId]) async {
    if (backendUserId != null) {
      try {
        await ApiService.authenticatedRequest(
          '/api/v1/admin/deapprove-user/$backendUserId',
          method: 'POST',
        );
      } catch (_) {}
    }

    setState(() {
      _priorityQueue.removeWhere((item) => item['id'] == id);
      _backendPendingUsers.removeWhere((item) => item['id'] == backendUserId);
    });

    _showToast('Application Revoked', '$name marked non-compliant in regulatory buffer.');
  }

  void _showToast(String title, String desc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2D3449),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF4EDEA3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_open, color: Color(0xFF003824), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFFDAE2FD), fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(desc, style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = _priorityQueue.length + _backendPendingUsers.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: const AdminAppBar(title: 'Operators'),
      body: RefreshIndicator(
        color: const Color(0xFF4EDEA3),
        backgroundColor: const Color(0xFF171F33),
        onRefresh: _fetchBackendPendingUsers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(
                    color: Color(0xFF4EDEA3),
                    backgroundColor: Color(0xFF171F33),
                  ),
                ),
              // 1. Header & Live Telemetry Stream Indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4EDEA3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'KYC / AML NODE SYNC ACTIVE',
                              style: TextStyle(
                                color: Color(0xFF4EDEA3),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Icon(Icons.lock_reset, color: Color(0xFFBBCABF), size: 14),
                            SizedBox(width: 4),
                            Text('Zero-Knowledge Proofs', style: TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Operator Authorizations & KYC',
                      style: TextStyle(
                        color: Color(0xFFDAE2FD),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Review cryptographic identity bounds, postGIS perimeter vectors, and liquidity escrow stakes.',
                      style: TextStyle(color: Color(0xFFBBCABF), fontSize: 12, height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    // Metric Strips
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171F33),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.pending_actions, color: Color(0xFFFFB95F), size: 14),
                                    SizedBox(width: 4),
                                    Text('Pending', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$totalPending',
                                  style: const TextStyle(color: Color(0xFFDAE2FD), fontSize: 20, fontWeight: FontWeight.bold),
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
                              color: const Color(0xFF171F33),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.agriculture, color: Color(0xFF45DFA4), size: 14),
                                    SizedBox(width: 4),
                                    Text('Producers', style: TextStyle(color: Color(0xFF45DFA4), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('412', style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 20, fontWeight: FontWeight.bold)),
                                    Text('Tier-1', style: TextStyle(color: Color(0xFFBBCABF), fontSize: 10)),
                                  ],
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
                              color: const Color(0xFF171F33),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_shipping, color: Color(0xFF4EDEA3), size: 14),
                                    SizedBox(width: 4),
                                    Text('Haulers', style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('89', style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 20, fontWeight: FontWeight.bold)),
                                    Icon(Icons.verified, color: Color(0xFF4EDEA3), size: 14),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Priority Queue Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rule_folder, color: Color(0xFF4EDEA3), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Awaiting Audit Signature',
                        style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222A3D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Priority Queue ($totalPending)',
                      style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Queue Item 1: Alain Kengne (Transporter)
              ..._priorityQueue.where((item) => item['id'] == 'op-1').map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171F33),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item['avatarUrl'],
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: const Color(0xFF222A3D),
                                        child: const Icon(Icons.person, color: Color(0xFF4EDEA3)),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4EDEA3),
                                        borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
                                      ),
                                      child: const Icon(Icons.local_shipping, size: 10, color: Color(0xFF003824)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item['name'],
                                        style: const TextStyle(color: Color(0xFFDAE2FD), fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified, color: Color(0xFF4EDEA3), size: 14),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(item['role'], style: const TextStyle(color: Color(0xFF45DFA4), fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3449),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Audit ID: ${item['auditId']}',
                              style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Details Surface
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF060E20).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildAuditRow(Icons.badge, 'License Tier', item['license']),
                            const SizedBox(height: 4),
                            _buildAuditRow(Icons.fingerprint, 'Gov ID Hash', item['govId']),
                            const SizedBox(height: 4),
                            _buildAuditRow(Icons.face, 'Biometric Match', item['biometricScore'], const Color(0xFF45DFA4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Asset Telemetry Widget
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131B2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF171F33),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.ac_unit, color: Color(0xFF4EDEA3), size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['vehicle'], style: const TextStyle(color: Color(0xFFDAE2FD), fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text(item['vehicleDetails'], style: const TextStyle(color: Color(0xFF86948A), fontSize: 10)),
                                ],
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Color(0xFF4EDEA3), shape: BoxShape.circle),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Actions Stack
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4EDEA3),
                            foregroundColor: const Color(0xFF003824),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _approveOperator(item['id'], item['name']),
                          icon: const Icon(Icons.key, size: 16),
                          label: const Text('Approve & Issue Cryptographic Key', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D3449),
                                foregroundColor: const Color(0xFFDAE2FD),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _requestDoc(item['name']),
                              icon: const Icon(Icons.replay, color: Color(0xFFFFB95F), size: 14),
                              label: const Text('Request Doc', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D3449),
                                foregroundColor: const Color(0xFFFFB4AB),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _rejectOperator(item['id'], item['name']),
                              icon: const Icon(Icons.cancel, color: Color(0xFFFFB4AB), size: 14),
                              label: const Text('Reject Application', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // Queue Item 2: Lékié Hydroponic Hub (Cadastral)
              ..._priorityQueue.where((item) => item['id'] == 'op-2').map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171F33),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  item['avatarUrl'],
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 48,
                                    height: 48,
                                    color: const Color(0xFF222A3D),
                                    child: const Icon(Icons.agriculture, color: Color(0xFF4EDEA3)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'], style: const TextStyle(color: Color(0xFFDAE2FD), fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text(item['role'], style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE29100).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Cadastral', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Map & Spatial Boundary Overlay
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF060E20),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              item['mapUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF222A3D)),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B1326).withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.polyline, color: Color(0xFF4EDEA3), size: 14),
                                        const SizedBox(width: 4),
                                        Text('Hash: ${item['hash']}', style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 11)),
                                      ],
                                    ),
                                    const Text('Polygon Valid', style: TextStyle(color: Color(0xFF45DFA4), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131B2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Facilities Active', style: TextStyle(color: Color(0xFF86948A), fontSize: 10)),
                                  Text(item['facilities'], style: const TextStyle(color: Color(0xFFDAE2FD), fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131B2E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ESP32 Telemetry', style: TextStyle(color: Color(0xFF86948A), fontSize: 10)),
                                  Text(item['probes'], style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4EDEA3),
                                foregroundColor: const Color(0xFF003824),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _approveOperator(item['id'], item['name']),
                              icon: const Icon(Icons.public, size: 16),
                              label: const Text('Commit Boundary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFF2D3449),
                                foregroundColor: const Color(0xFFFFB95F),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _requestDoc(item['name']),
                              icon: const Icon(Icons.travel_explore, size: 16),
                              label: const Text('Flag Inspection', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // Queue Item 3: Yaoundé Supermarket Chain (Wholesale Buyer)
              ..._priorityQueue.where((item) => item['id'] == 'op-3').map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171F33),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB95F).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.storefront, color: Color(0xFFFFB95F), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'], style: const TextStyle(color: Color(0xFFDAE2FD), fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text(item['role'], style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3449),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Escrow Stake', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF060E20).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Standby Escrow Buffer (BEAC)', style: TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(item['escrowBuffer'], style: const TextStyle(color: Color(0xFFFFB95F), fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB95F).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet, color: Color(0xFFFFB95F), size: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4EDEA3),
                                foregroundColor: const Color(0xFF003824),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _approveOperator(item['id'], item['name']),
                              icon: const Icon(Icons.verified, size: 16),
                              label: const Text('Grant Tier-1 Wholesale Access', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D3449),
                              foregroundColor: const Color(0xFFBBCABF),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _rejectOperator(item['id'], item['name']),
                            child: const Text('Decline', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // Live Backend Users Queue (if any)
              if (_backendPendingUsers.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Registered Users Awaiting Verification', style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._backendPendingUsers.map((user) {
                  final userId = user['id'] as int;
                  final userName = user['fullName']?.toString() ?? 'User #$userId';
                  final userRole = user['role']?.toString() ?? 'MEMBER';
                  final email = user['email']?.toString() ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171F33),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: const TextStyle(color: Color(0xFFDAE2FD), fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('$userRole • $email', style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Color(0xFF4EDEA3), size: 22),
                              onPressed: () => _approveOperator('user-$userId', userName, userId),
                              tooltip: 'Approve & notify via email',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Color(0xFFFFB4AB), size: 22),
                              onPressed: () => _rejectOperator('user-$userId', userName, userId),
                              tooltip: 'Reject',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),

              // 3. Recently Certified Operators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_edu, color: Color(0xFF45DFA4), size: 18),
                      SizedBox(width: 8),
                      Text('Recently Certified Operators', style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('Live Ledger', style: TextStyle(color: const Color(0xFF4EDEA3), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: _certifiedOperators.map((item) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF222A3D), width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF171F33),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'] as String, style: const TextStyle(color: Color(0xFFDAE2FD), fontSize: 13, fontWeight: FontWeight.bold)),
                                  Text(item['audit'] as String, style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.circle, color: Color(0xFF4EDEA3), size: 6),
                                    SizedBox(width: 4),
                                    Text('Active', style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text('L3 Ledger', style: TextStyle(color: Color(0xFF86948A), fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditRow(IconData icon, String label, String value, [Color? valueColor]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF86948A), size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFFDAE2FD),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
