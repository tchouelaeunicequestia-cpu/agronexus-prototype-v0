import 'package:flutter/material.dart';

import 'dart:ui';

import '../../services/api_service.dart';

class BuyerCheckoutModal extends StatefulWidget {
  final Map<String, dynamic> product;
  final String userId;
  final VoidCallback onSuccess;

  const BuyerCheckoutModal({
    super.key,
    required this.product,
    required this.userId,
    required this.onSuccess,
  });

  @override
  State<BuyerCheckoutModal> createState() => _BuyerCheckoutModalState();
}

class _BuyerCheckoutModalState extends State<BuyerCheckoutModal> {
  bool _isProcessing = false;
  int _orderQuantity = 1;

  void _processEscrowPayment() async {
    setState(() => _isProcessing = true);
    try {
      final double pricePerUnit = (widget.product['pricePerUnit'] ?? 0)
          .toDouble();
      final double subtotal = pricePerUnit * _orderQuantity;
      final double platformFee = subtotal * 0.05; // 5% Platform Service Fee
      final double totalAmount = subtotal + platformFee;

      await ApiService.authenticatedRequest(
        '/escrow/checkout',
        method: 'POST',
        body: {
          'productId': widget.product['id'],
          'buyerId': widget.userId,
          'quantity': _orderQuantity,
          'subtotal': subtotal,
          'platformFee': platformFee,
          'totalAmount': totalAmount,
          'paymentMethod': 'MoMo',
        },
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escrow order secured successfully.'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double pricePerUnit = (widget.product['pricePerUnit'] ?? 0)
        .toDouble();
    final int maxQuantity = widget.product['availableQuantity'] ?? 1;
    final String unitType = widget.product['unitType'] ?? 'kg';

    final double subtotal = pricePerUnit * _orderQuantity;
    final double platformFee = subtotal * 0.05;
    final double totalAmount = subtotal + platformFee;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Multi-Sig Escrow Checkout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                widget.product['title'] ?? 'Produce Item',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6CF8BB),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Quantity:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.white,
                        ),
                        onPressed: _orderQuantity > 1
                            ? () => setState(() => _orderQuantity--)
                            : null,
                      ),
                      Text(
                        '$_orderQuantity $unitType',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                        ),
                        onPressed: _orderQuantity < maxQuantity
                            ? () => setState(() => _orderQuantity++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              Divider(color: Colors.white.withValues(alpha: 0.2), height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${subtotal.toStringAsFixed(2)} XAF',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Platform Service Fee (5%)',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${platformFee.toStringAsFixed(2)} XAF',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              Divider(color: Colors.white.withValues(alpha: 0.2), height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Escrow Lock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${totalAmount.toStringAsFixed(2)} XAF',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6CF8BB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isProcessing ? null : _processEscrowPayment,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm & Lock Funds',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Funds are held in escrow until quality check signoff.',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                  textAlign: TextAlign.center,
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
