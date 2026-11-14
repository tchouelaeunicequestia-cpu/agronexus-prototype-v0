import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/dashboards/farmer/farmer_dashboard.dart';
import 'screens/dashboards/buyer/buyer_dashboard.dart';
import 'screens/dashboards/transporter/transporter_dashboard.dart';
import 'screens/dashboards/agronomist/agronomist_dashboard.dart';
import 'screens/dashboards/admin/admin_dashboard.dart';
import 'services/auth_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
      ],
      child: const AgroNexusApp(),
    ),
  );
}

class AgroNexusApp extends StatelessWidget {
  const AgroNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroNexus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }

          // Strict RBAC Role Guard & Sanitization
          final String role = (auth.role ?? '').toUpperCase().trim();

          switch (role) {
            case 'FARMER':
              return const FarmerDashboard();
            case 'BUYER':
              return const BuyerDashboard();
            case 'TRANSPORTER':
              return const TransporterDashboard();
            case 'AGRONOMIST':
              return const AgronomistDashboard();
            case 'ADMIN':
              return const AdminDashboard();
            default:
              // Unauthorized role injection trap -> Force Session Termination
              auth.logout();
              return const LoginScreen();
          }
        },
      ),
    );
  }
}
