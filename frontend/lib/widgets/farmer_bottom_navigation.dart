import 'package:flutter/material.dart';

class FarmerBottomNavigation extends StatelessWidget {
  const FarmerBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(0, Icons.dashboard_rounded, 'Dashboard'),
            _item(1, Icons.inventory_2_rounded, 'Batches'),
            _item(2, Icons.add_rounded, 'List Crop'),
            _item(3, Icons.verified_user_rounded, 'Escrow'),
            _item(4, Icons.sensors_rounded, 'IoT Silos'),
            _item(5, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, String label) {
    final selected = selectedIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFEFFAF3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? const Color(0xFF0F5132)
                      : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              _label(label, selected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String label, bool selected) => Text(
    label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: selected ? const Color(0xFF0F5132) : const Color(0xFF64748B),
      fontSize: 10,
      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
    ),
  );
}
