import 'dart:ui';

import 'package:flutter/material.dart';

import 'admin_vault_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_operators_screen.dart';
import 'admin_infra_screen.dart';
import 'admin_profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminVaultScreen(),
    AdminDisputesScreen(),
    AdminOperatorsScreen(),
    AdminInfraScreen(),
    AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E).withValues(alpha: 0.92),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, -4),
              blurRadius: 24,
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFF171F33), width: 1),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: SafeArea(
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    _buildNavItem(0, Icons.account_balance, 'Vault'),
                    _buildNavItem(1, Icons.gavel, 'Disputes'),
                    _buildNavItem(2, Icons.verified_user, 'Operators'),
                    _buildNavItem(3, Icons.dns, 'Infra'),
                    _buildNavItem(4, Icons.person, 'Profile'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? const Color(0xFF4EDEA3)
                  : const Color(0xFFBBCABF),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF4EDEA3)
                    : const Color(0xFFBBCABF),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
