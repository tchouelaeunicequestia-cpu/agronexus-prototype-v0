import 'package:flutter/material.dart';

import 'transporter_loads_screen.dart';
import 'transporter_trip_live_screen.dart';
import 'transporter_waybill_screen.dart';
import 'transporter_handover_screen.dart';
import 'transporter_profile_screen.dart';

class TransporterDashboard extends StatefulWidget {
  const TransporterDashboard({super.key});

  @override
  State<TransporterDashboard> createState() => _TransporterDashboardState();
}

class _TransporterDashboardState extends State<TransporterDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TransporterLoadsScreen(),
    const TransporterTripLiveScreen(),
    const TransporterWaybillScreen(),
    const TransporterHandoverScreen(),
    const TransporterProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0b1326),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF060e20).withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              offset: const Offset(0, -4),
              blurRadius: 24,
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF4edea3),
            unselectedItemColor: const Color(0xFFbbcabf),
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_shipping_outlined),
                activeIcon: Icon(Icons.local_shipping),
                label: 'Loads',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.alt_route_outlined),
                activeIcon: Icon(Icons.alt_route),
                label: 'Trip Live',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Waybill',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.verified_user_outlined),
                activeIcon: Icon(Icons.verified_user),
                label: 'Handover',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
