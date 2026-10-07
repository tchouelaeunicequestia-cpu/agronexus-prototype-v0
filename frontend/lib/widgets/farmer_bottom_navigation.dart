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
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          border: const Border(top: BorderSide(color: Color(0xFFD7F3E3))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            _item(0, Icons.dashboard_outlined, 'Dashboard'),
            _item(1, Icons.inventory_2_outlined, 'Batches'),
            Expanded(
              child: InkWell(
                onTap: () => onDestinationSelected(2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669)
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 1),
                    _label('List Crop', selectedIndex == 2),
                  ],
                ),
              ),
            ),
            _item(3, Icons.verified_user_outlined, 'Escrow'),
            _item(4, Icons.sensors_outlined, 'IoT Silos'),
            _item(5, Icons.person_outline_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, String label) {
    final selected = selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onDestinationSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF0F5132)
                  : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(height: 3),
            _label(label, selected),
          ],
        ),
      ),
    );
  }

  Widget _label(String label, bool selected) => Text(
    label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: selected ? const Color(0xFF0F5132) : const Color(0xFF64748B),
      fontSize: 9,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    ),
  );
}
