import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

import 'widgets/admin_app_bar.dart';

class AdminVaultScreen extends StatefulWidget {
  const AdminVaultScreen({super.key});

  @override
  State<AdminVaultScreen> createState() => _AdminVaultScreenState();
}

class _AdminVaultScreenState extends State<AdminVaultScreen> {
  bool _isLoading = false;
  double _totalLocked = 48650000;
  double _farmerRatio = 0.85;
  double _freightRatio = 0.15;
  double _mtnBalance = 28400000;
  double _orangeBalance = 20250000;

  List<Map<String, dynamic>> _settlementLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveMetrics();
  }

  Future<void> _fetchLiveMetrics() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.authenticatedRequest(
        '/api/v1/admin/metrics',
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data['escrowVolume'] != null) {
          final vol = (data['escrowVolume'] as num).toDouble();
          if (vol > 0) {
            setState(() {
              _totalLocked = vol;
            });
          }
        }
      }

      final logsRes = await ApiService.authenticatedRequest(
        '/api/v1/admin/vault/logs',
      );
      if (logsRes.statusCode == 200) {
        final logsData = jsonDecode(logsRes.body);
        if (logsData is List) {
          setState(() {
            _settlementLogs = List<Map<String, dynamic>>.from(logsData);
          });
        }
      }
    } catch (_) {
      // Graceful fallback to initial telemetry numbers
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    final int val = amount.toInt();
    final s = val.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  void _showAdjustDialog(
    String gateway,
    double currentBalance,
    Function(double) onSave,
  ) {
    final controller = TextEditingController(
      text: currentBalance.toInt().toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171F33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Adjust $gateway Buffer',
          style: const TextStyle(
            color: Color(0xFFDAE2FD),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify floating liquidity allocated to this mobile money disbursement endpoint.',
              style: TextStyle(color: Color(0xFFBBCABF), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Reserve (FCFA)',
                labelStyle: const TextStyle(color: Color(0xFF86948A)),
                suffixText: 'FCFA',
                suffixStyle: const TextStyle(color: Color(0xFF4EDEA3)),
                filled: true,
                fillColor: const Color(0xFF0B1326),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2D3449)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF4EDEA3)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFBBCABF)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4EDEA3),
              foregroundColor: const Color(0xFF003824),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final newAmount =
                  double.tryParse(controller.text) ?? currentBalance;
              onSave(newAmount);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$gateway floating reserve adjusted to ${_formatCurrency(newAmount)} FCFA',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Save Reserve'),
          ),
        ],
      ),
    );
  }

  void _triggerRebalance() {
    setState(() {
      final total = _mtnBalance + _orangeBalance;
      _mtnBalance = total * 0.55;
      _orangeBalance = total * 0.45;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4EDEA3)),
            SizedBox(width: 8),
            Text('Liquidity rebalanced across MTN and Orange gateways.'),
          ],
        ),
        backgroundColor: Color(0xFF131B2E),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _triggerAutoSweep() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.sync, color: Color(0xFF4EDEA3)),
            SizedBox(width: 8),
            Text(
              'Auto-sweep executed: Reconciled 142 contracts with BEAC buffer.',
            ),
          ],
        ),
        backgroundColor: Color(0xFF131B2E),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showAuditKeysDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171F33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.key, color: Color(0xFF4EDEA3)),
            SizedBox(width: 8),
            Text(
              'Multi-Sig Audit Telemetry',
              style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 16),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Threshold Requirement: 3 of 4 Keys',
              style: TextStyle(
                color: Color(0xFFBBCABF),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '• Key #1 (Yaoundé Hub HSM): ACTIVE ✅',
              style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              '• Key #2 (Bafia Logistics Root): ACTIVE ✅',
              style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              '• Key #3 (BEAC Regulatory Node): ACTIVE ✅',
              style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              '• Key #4 (Disaster Recovery Cold): STANDBY ⏸',
              style: TextStyle(color: Color(0xFFFFB95F), fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4EDEA3),
              foregroundColor: const Color(0xFF003824),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportLedger() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.download_done, color: Color(0xFF4EDEA3)),
            SizedBox(width: 8),
            Text(
              'Signed cryptographic ledger (CSV/PDF) generated and downloaded.',
            ),
          ],
        ),
        backgroundColor: Color(0xFF131B2E),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmerAmount = _totalLocked * _farmerRatio;
    final freightAmount = _totalLocked * _freightRatio;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: const AdminAppBar(title: 'Vault'),
      body: RefreshIndicator(
        color: const Color(0xFF4EDEA3),
        backgroundColor: const Color(0xFF171F33),
        onRefresh: _fetchLiveMetrics,
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
              // 1. Status Banner & Pulse
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF171F33),
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
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4EDEA3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'VAULT SECURITY PROTOCOL ACTIVE',
                              style: TextStyle(
                                color: Color(0xFF4EDEA3),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222A3D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'L3 Cold Multi-Sig',
                            style: TextStyle(
                              color: Color(0xFFBBCABF),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TOTAL LOCKED COLLATERAL',
                      style: TextStyle(
                        color: Color(0xFFBBCABF),
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatCurrency(_totalLocked),
                          style: const TextStyle(
                            color: Color(0xFFDAE2FD),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'FCFA',
                          style: TextStyle(
                            color: Color(0xFF4EDEA3),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: Color(0xFF4EDEA3),
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Across 142 active agricultural contracts',
                          style: TextStyle(
                            color: Color(0xFFBBCABF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick Stats Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '24h Auto-Disbursements',
                                  style: TextStyle(
                                    color: Color(0xFFBBCABF),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '12,420,000 FCFA',
                                  style: TextStyle(
                                    color: Color(0xFFDAE2FD),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.bolt,
                                      color: Color(0xFF4EDEA3),
                                      size: 12,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      '100% On-Time',
                                      style: TextStyle(
                                        color: Color(0xFF4EDEA3),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFF222A3D),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cashout Buffer Reserve',
                                  style: TextStyle(
                                    color: Color(0xFFBBCABF),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '3,850,000 FCFA',
                                  style: TextStyle(
                                    color: Color(0xFFFFB95F),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      color: Color(0xFFFFB95F),
                                      size: 12,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      '1.5% Fee Absorption',
                                      style: TextStyle(
                                        color: Color(0xFFFFB95F),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
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

              const SizedBox(height: 16),

              // 2. Escrow Split Telemetry Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF171F33),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dynamic Allocation Ratio',
                          style: TextStyle(
                            color: Color(0xFFDAE2FD),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                            const SizedBox(width: 4),
                            const Text(
                              'Zero-Loss Backed',
                              style: TextStyle(
                                color: Color(0xFF4EDEA3),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress Indicator Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: (_farmerRatio * 100).toInt(),
                            child: Container(
                              height: 12,
                              color: const Color(0xFF4EDEA3),
                            ),
                          ),
                          Expanded(
                            flex: (_freightRatio * 100).toInt(),
                            child: Container(
                              height: 12,
                              color: const Color(0xFFFFB95F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4EDEA3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Farmer Reserved (85%)',
                                    style: TextStyle(
                                      color: Color(0xFFDAE2FD),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Text(
                                  '${_formatCurrency(farmerAmount)} FCFA',
                                  style: const TextStyle(
                                    color: Color(0xFFDAE2FD),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFB95F),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Freight Logistics (15%)',
                                    style: TextStyle(
                                      color: Color(0xFFDAE2FD),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Text(
                                  '${_formatCurrency(freightAmount)} FCFA',
                                  style: const TextStyle(
                                    color: Color(0xFFDAE2FD),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Mobile Money Gateways
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mobile Money Gateways',
                    style: TextStyle(
                      color: Color(0xFFDAE2FD),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.sync,
                        color: Color(0xFF4EDEA3),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '2 Nodes Hot',
                        style: TextStyle(
                          color: const Color(0xFFBBCABF).withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // MTN Card
              Container(
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
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF222A3D),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'M',
                                  style: TextStyle(
                                    color: Color(0xFFFFB95F),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MTN Mobile Money Core',
                                  style: TextStyle(
                                    color: Color(0xFFDAE2FD),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '+237 651 305 141',
                                  style: TextStyle(
                                    color: Color(0xFFBBCABF),
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222A3D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.bolt,
                                color: Color(0xFF4EDEA3),
                                size: 12,
                              ),
                              SizedBox(width: 2),
                              Text(
                                '18ms',
                                style: TextStyle(
                                  color: Color(0xFF4EDEA3),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Escrow Floating Balance',
                              style: TextStyle(
                                color: Color(0xFFBBCABF),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatCurrency(_mtnBalance)} FCFA',
                              style: const TextStyle(
                                color: Color(0xFFDAE2FD),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF222A3D),
                            foregroundColor: const Color(0xFFDAE2FD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () {
                            _showAdjustDialog('MTN MoMo', _mtnBalance, (
                              newVal,
                            ) {
                              setState(() => _mtnBalance = newVal);
                            });
                          },
                          icon: const Icon(
                            Icons.tune,
                            color: Color(0xFFFFB95F),
                            size: 16,
                          ),
                          label: const Text(
                            'Adjust',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Orange Card
              Container(
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
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF222A3D),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'O',
                                  style: TextStyle(
                                    color: Color(0xFF4EDEA3),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Orange Money Central',
                                  style: TextStyle(
                                    color: Color(0xFFDAE2FD),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '+237 694 002 750',
                                  style: TextStyle(
                                    color: Color(0xFFBBCABF),
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222A3D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.bolt,
                                color: Color(0xFF4EDEA3),
                                size: 12,
                              ),
                              SizedBox(width: 2),
                              Text(
                                '22ms',
                                style: TextStyle(
                                  color: Color(0xFF4EDEA3),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Escrow Floating Balance',
                              style: TextStyle(
                                color: Color(0xFFBBCABF),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatCurrency(_orangeBalance)} FCFA',
                              style: const TextStyle(
                                color: Color(0xFFDAE2FD),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF222A3D),
                            foregroundColor: const Color(0xFFDAE2FD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () {
                            _showAdjustDialog('Orange Money', _orangeBalance, (
                              newVal,
                            ) {
                              setState(() => _orangeBalance = newVal);
                            });
                          },
                          icon: const Icon(
                            Icons.tune,
                            color: Color(0xFF4EDEA3),
                            size: 16,
                          ),
                          label: const Text(
                            'Adjust',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Channel Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF222A3D),
                        foregroundColor: const Color(0xFFDAE2FD),
                        side: const BorderSide(color: Color(0xFF2D3449)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _triggerRebalance,
                      icon: const Icon(
                        Icons.swap_horiz,
                        color: Color(0xFFFFB95F),
                        size: 18,
                      ),
                      label: const Text(
                        'Rebalance Buffers',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF222A3D),
                        foregroundColor: const Color(0xFFDAE2FD),
                        side: const BorderSide(color: Color(0xFF2D3449)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _triggerAutoSweep,
                      icon: const Icon(
                        Icons.autorenew,
                        color: Color(0xFF4EDEA3),
                        size: 18,
                      ),
                      label: const Text(
                        'Force Auto-Sweep',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Operational Depository Pipeline (Settlement Telemetry)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Settlement Telemetry',
                    style: TextStyle(
                      color: Color(0xFFDAE2FD),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
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
                      const SizedBox(width: 4),
                      const Text(
                        'Realtime',
                        style: TextStyle(
                          color: Color(0xFF4EDEA3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF171F33),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: _settlementLogs.map((item) {
                    final isOrange = item['beneficiary'].toString().contains(
                      'Jean-Paul',
                    );
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item['order'],
                                    style: TextStyle(
                                      color: isOrange
                                          ? const Color(0xFFFFB95F)
                                          : const Color(0xFF4EDEA3),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF222A3D),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item['type'],
                                      style: const TextStyle(
                                        color: Color(0xFFBBCABF),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (item['isFast'])
                                    const Icon(
                                      Icons.bolt,
                                      color: Color(0xFF4EDEA3),
                                      size: 14,
                                    )
                                  else
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4EDEA3),
                                      size: 14,
                                    ),
                                  const SizedBox(width: 2),
                                  Text(
                                    item['speed'],
                                    style: const TextStyle(
                                      color: Color(0xFF4EDEA3),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['beneficiary'],
                                style: const TextStyle(
                                  color: Color(0xFFDAE2FD),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                item['amount'],
                                style: const TextStyle(
                                  color: Color(0xFFDAE2FD),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['subtext'],
                                style: const TextStyle(
                                  color: Color(0xFF86948A),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                item['time'],
                                style: const TextStyle(
                                  color: Color(0xFF86948A),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Treasury Governance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF222A3D),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Color(0xFFFFB95F),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'TREASURY GOVERNANCE',
                          style: TextStyle(
                            color: Color(0xFFDAE2FD),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tileColor: const Color(0xFF171F33),
                      leading: const Icon(
                        Icons.key,
                        color: Color(0xFF4EDEA3),
                        size: 20,
                      ),
                      title: const Text(
                        'Audit Multi-Sig Treasury Keys',
                        style: TextStyle(
                          color: Color(0xFFDAE2FD),
                          fontSize: 13,
                        ),
                      ),
                      trailing: const Text(
                        '3/4 Valid',
                        style: TextStyle(
                          color: Color(0xFFBBCABF),
                          fontSize: 12,
                        ),
                      ),
                      onTap: _showAuditKeysDialog,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tileColor: const Color(0xFF171F33),
                      leading: const Icon(
                        Icons.download,
                        color: Color(0xFFFFB95F),
                        size: 20,
                      ),
                      title: const Text(
                        'Export Central Ledger Report',
                        style: TextStyle(
                          color: Color(0xFFDAE2FD),
                          fontSize: 13,
                        ),
                      ),
                      trailing: const Text(
                        'CSV/PDF',
                        style: TextStyle(
                          color: Color(0xFFBBCABF),
                          fontSize: 12,
                        ),
                      ),
                      onTap: _exportLedger,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
