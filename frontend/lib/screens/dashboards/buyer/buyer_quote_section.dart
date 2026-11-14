// lib/screens/dashboards/buyer_quote_section.dart
import 'package:flutter/material.dart';

import 'dart:ui';

import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_provider.dart';
import 'package:frontend/services/draft_service.dart';
import 'package:frontend/services/platform_services.dart';

class BuyerQuoteSection extends StatefulWidget {
  final List<Map<String, dynamic>> quoteOrders;
  final Future<void> Function() onRefreshNeeded;

  const BuyerQuoteSection({
    super.key,
    required this.quoteOrders,
    required this.onRefreshNeeded,
  });

  @override
  State<BuyerQuoteSection> createState() => _BuyerQuoteSectionState();
}

class _BuyerQuoteSectionState extends State<BuyerQuoteSection> {
  Future<void> _approveQuote(String orderCode) async {
    try {
      await ApiService.approveTransportQuote(orderCode: orderCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote approved and funds locked in escrow.'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await widget.onRefreshNeeded();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quoteOrders.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_shipping_rounded,
                    color: Color(0xFF6CF8BB),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pending Transporter Quotes Awaiting Your Approval',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...widget.quoteOrders.map((order) {
                final double itemCost = (order['itemCost'] ?? 0).toDouble();
                final double transportFee = (order['transportFee'] ?? 0)
                    .toDouble();
                final double total = itemCost + transportFee;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order['orderCode'] ?? 'ORD-REF',
                            style: const TextStyle(
                              color: Color(0xFF6CF8BB),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${transportFee.toStringAsFixed(0)} XAF Freight',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order['productTitle'] ?? 'Produce Harvest Lot',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimated Total Escrow Lock: ${total.toStringAsFixed(0)} XAF (incl. 5% service fee)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _approveQuote(order['orderCode']),
                          child: const Text(
                            'Approve Quote & Lock Escrow Funds',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
