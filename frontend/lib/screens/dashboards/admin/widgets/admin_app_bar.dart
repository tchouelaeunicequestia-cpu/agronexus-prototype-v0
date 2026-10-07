import 'dart:ui';
import 'package:flutter/material.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onHaltPressed;

  const AdminAppBar({
    super.key,
    required this.title,
    this.onHaltPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  void _showHaltDialog(BuildContext context) {
    if (onHaltPressed != null) {
      onHaltPressed!();
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF131B2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF93000A), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF93000A).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gpp_maybe, color: Color(0xFFFFB4AB), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Emergency Platform Halt',
                  style: TextStyle(
                    color: Color(0xFFDAE2FD),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to trigger an emergency freeze on the AgroNexus Central Cameroon mesh?',
                style: TextStyle(color: Color(0xFFBBCABF), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF060E20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF222A3D)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• 142 Escrow smart contracts will freeze', style: TextStyle(color: Color(0xFFFFB4AB), fontSize: 11)),
                    SizedBox(height: 4),
                    Text('• ESP32 edge broker ingestion paused', style: TextStyle(color: Color(0xFFFFB4AB), fontSize: 11)),
                    SizedBox(height: 4),
                    Text('• Central Cameroon mesh fail-safe engaged', style: TextStyle(color: Color(0xFFFFB4AB), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFBBCABF))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF93000A),
                foregroundColor: const Color(0xFFFFDAD6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB4AB)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'EMERGENCY PLATFORM HALT INITIATED: Central nodes locked.',
                            style: TextStyle(color: Color(0xFFFFDAD6), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Color(0xFF93000A),
                    duration: Duration(seconds: 4),
                  ),
                );
              },
              child: const Text('CONFIRM HALT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: const Color(0xFF0B1326).withValues(alpha: 0.85),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF171F33), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4EDEA3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF003824),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                'SYSTEM ADMIN (L3 ROOT)',
                                style: TextStyle(
                                  color: Color(0xFF4EDEA3),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFFDAE2FD),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _showHaltDialog(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF93000A).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF93000A).withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.gpp_maybe,
                            color: Color(0xFFFFB4AB),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'HALT',
                            style: TextStyle(
                              color: Color(0xFFFFB4AB),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
