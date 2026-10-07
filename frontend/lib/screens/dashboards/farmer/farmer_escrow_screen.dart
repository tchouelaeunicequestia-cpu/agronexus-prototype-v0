import 'package:flutter/material.dart';
import 'package:frontend/screens/dashboards/shared/handover_tracking_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/farmer_background_layer.dart';
import 'package:frontend/widgets/farmer_bottom_navigation.dart';

import 'farmer_dashboard.dart';
import 'farmer_listings_screen.dart';
import 'farmer_telemetry_screen.dart';
import 'farmer_profile_screen.dart';
import '../../../screens/produce/add_produce_screen.dart';

class FarmerEscrowScreen extends StatefulWidget {
  const FarmerEscrowScreen({super.key});

  @override
  State<FarmerEscrowScreen> createState() => _FarmerEscrowScreenState();
}

class _FarmerEscrowScreenState extends State<FarmerEscrowScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final orders = await ApiService.getFarmerEscrowOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double _amount(Map<String, dynamic> order) =>
      double.tryParse(order['totalEscrowAmount']?.toString() ?? '') ??
      (double.tryParse(order['itemCost']?.toString() ?? '') ?? 0) +
          (double.tryParse(order['transportFee']?.toString() ?? '') ?? 0) +
          (double.tryParse(order['platformServiceFee']?.toString() ?? '') ?? 0);

  String _money(double value) => '${value.toStringAsFixed(0)} XAF';

  bool _canDispatch(String status) =>
      status == 'HELD_IN_ESCROW' || status == 'READY_FOR_PICKUP';

  @override
  Widget build(BuildContext context) {
    final locked = _orders
        .where(
          (order) => {
            'PENDING',
            'TRANSPORT_QUOTE_PENDING',
            'HELD_IN_ESCROW',
            'READY_FOR_PICKUP',
            'DISPATCHED',
            'IN_TRANSIT',
            'DELIVERED',
          }.contains(order['status']),
        )
        .fold<double>(0, (sum, order) => sum + _amount(order));

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: FarmerBottomNavigation(
        selectedIndex: 3,
        onDestinationSelected: _navigateToFarmerTab,
      ),
      body: Stack(
        children: [
          const FarmerBackgroundLayer(),
          RefreshIndicator(
            onRefresh: _loadOrders,
            color: const Color(0xFF0F5132),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: const Color(0xF2FFFFFF),
                  foregroundColor: const Color(0xFF0F172A),
                  title: const Text('Escrow & handover ledger'),
                  actions: [
                    IconButton(
                      tooltip: 'Refresh ledger',
                      onPressed: _isLoading ? null : _loadOrders,
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
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 116),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _summaryCard(locked),
                      const SizedBox(height: 20),
                      const Text(
                        'Active escrow runs',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0F5132),
                            ),
                          ),
                        )
                      else if (_error != null)
                        _messageCard(_error!, _loadOrders)
                      else if (_orders.isEmpty)
                        _emptyCard()
                      else
                        ..._orders.map(_orderCard),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFarmerTab(int index) {
    if (index == 3) return;
    final Widget screen = switch (index) {
      0 => const FarmerDashboard(),
      1 => const FarmerListingsScreen(),
      2 => const AddProduceScreen(),
      4 => const FarmerTelemetryScreen(),
      5 => const FarmerProfileScreen(),
      _ => const FarmerDashboard(),
    };
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _summaryCard(double locked) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFD7F3E3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFF0F5132),
            ),
            SizedBox(width: 10),
            Text(
              'Producer payout protection',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Funds and handover stages are shown from your authenticated order ledger.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.35),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _metric('Locked value', _money(locked))),
            const SizedBox(width: 10),
            Expanded(child: _metric('Order runs', '${_orders.length}')),
          ],
        ),
      ],
    ),
  );

  Widget _metric(String label, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEFFAF3),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
      ],
    ),
  );

  Widget _orderCard(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'UNKNOWN';
    final orderCode = order['orderCode']?.toString() ?? 'Unavailable';
    final title = order['productTitle']?.toString() ?? 'Produce order';
    final canDispatch = _canDispatch(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7F3E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: Color(0xFF0F5132)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Order $orderCode',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'Escrow value: ${_money(_amount(order))}  •  Quantity: ${order['quantity'] ?? 'Unavailable'}',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (canDispatch) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HandoverTrackingScreen(
                        orderId: orderCode,
                        userRole: 'FARMER',
                        onStateUpdated: _loadOrders,
                      ),
                    ),
                  );
                  _loadOrders();
                },
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Verify and dispatch handover'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F5132),
                  side: const BorderSide(color: Color(0xFF0F5132)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEFFAF3),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.replaceAll('_', ' '),
      style: const TextStyle(
        color: Color(0xFF0F5132),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _emptyCard() => _messageCard(
    'No escrow orders have been created for your harvest yet.',
    null,
  );

  Widget _messageCard(String message, VoidCallback? retry) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD7F3E3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: Color(0xFF64748B))),
        if (retry != null) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ],
    ),
  );
}
