import 'package:flutter/material.dart';

import 'package:frontend/services/api_service.dart';

class BuyerEscrowScreen extends StatefulWidget {
  const BuyerEscrowScreen({super.key});

  @override
  State<BuyerEscrowScreen> createState() => _BuyerEscrowScreenState();
}

class _BuyerEscrowScreenState extends State<BuyerEscrowScreen> {
  static const _green = Color(0xFF0F5132);
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

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
      final orders = await ApiService.getBuyerQuoteOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  double _number(Map<String, dynamic> order, String key) {
    return double.tryParse(order[key]?.toString() ?? '') ?? 0;
  }

  String _formatAmount(double amount) {
    return '${amount.toStringAsFixed(0)} XAF';
  }

  @override
  Widget build(BuildContext context) {
    final lockedTotal = _orders.fold<double>(
      0,
      (total, order) =>
          total +
          _number(order, 'itemCost') +
          _number(order, 'transportFee') +
          _number(order, 'platformServiceFee'),
    );

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: _green,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            foregroundColor: _text,
            elevation: 0,
            title: const Text(
              'Escrow',
              style: TextStyle(color: _text, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh escrow orders',
                onPressed: _isLoading ? null : _loadOrders,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildIntroCard(lockedTotal),
                const SizedBox(height: 20),
                const Text(
                  'Pending escrow orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (_error != null)
                  _buildMessageCard(
                    icon: Icons.cloud_off_rounded,
                    title: 'Unable to load escrow orders',
                    message: _error!,
                    actionLabel: 'Try again',
                    onAction: _loadOrders,
                  )
                else if (_orders.isEmpty)
                  _buildMessageCard(
                    icon: Icons.lock_open_rounded,
                    title: 'No pending escrow orders',
                    message: 'Orders created from the Market tab will appear here while they are awaiting payment or transport confirmation.',
                  )
                else
                  ..._orders.map(_buildOrderCard),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(double lockedTotal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7F3E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Protected payments',
                  style: TextStyle(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your payment stays protected until the order milestones are completed.',
            style: TextStyle(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryMetric(
                  'Pending orders',
                  _orders.length.toString(),
                  Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetric(
                  'Escrow value',
                  _formatAmount(lockedTotal),
                  Icons.lock_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _green, size: 19),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _text,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final amount =
        _number(order, 'itemCost') +
        _number(order, 'transportFee') +
        _number(order, 'platformServiceFee');
    final status = order['status']?.toString() ?? 'PENDING';
    final title = order['productTitle']?.toString() ?? 'Produce order';
    final code = order['orderCode']?.toString() ?? 'Unavailable';
    final quantity = order['quantity']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: _green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _statusChip(status),
            ],
          ),
          const Divider(height: 24),
          _detailRow('Order code', code),
          _detailRow('Quantity', quantity),
          _detailRow('Protected amount', _formatAmount(amount), isTotal: true),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? _green : _text,
              fontWeight: FontWeight.w700,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Color(0xFF92400E),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    Future<void> Function()? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: _green, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _text,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }
}
