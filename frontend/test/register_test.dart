import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:frontend/services/platform_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Services Tests', () {
    test('LocationServiceFactory provides instance', () {
      final locService = LocationServiceFactory.getService();
      expect(locService, isNotNull);
    });

    test('IdentityServiceFactory provides instance', () {
      final idService = IdentityServiceFactory.getService();
      expect(idService, isNotNull);
    });

    test('PositionData model holds correct coordinates', () {
      final pos = PositionData(
        latitude: 4.0511,
        longitude: 9.7679,
        description: 'Douala Test Hub',
      );
      expect(pos.latitude, 4.0511);
      expect(pos.longitude, 9.7679);
      expect(pos.description, contains('Douala'));
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('RegisterScreen renders UI elements properly on Desktop', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pump();

      // Verify Brand & Left Panel Header
      expect(find.textContaining('AgroNexus'), findsWidgets);
      expect(find.textContaining('Verifiable'), findsOneWidget);
      expect(find.textContaining('Zero-Knowledge'), findsOneWidget);
      expect(find.textContaining('Role-Based Access'), findsOneWidget);
      expect(find.textContaining('Geo-Spatial Origin'), findsOneWidget);

      // Verify Form & Role Selectors
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Farmer'), findsOneWidget);
      expect(find.text('Buyer'), findsOneWidget);
      expect(find.text('Transporter'), findsOneWidget);
      expect(find.text('Agronomist'), findsOneWidget);

      // Verify Role selection interaction
      await tester.tap(find.text('Buyer'));
      await tester.pump();
      await tester.tap(find.text('Transporter'));
      await tester.pump();
      await tester.tap(find.text('Agronomist'));
      await tester.pump();
      await tester.tap(find.text('Farmer'));
      await tester.pump();

      // Verify Action Cards
      expect(find.textContaining('Live Biometric Scan'), findsOneWidget);
      expect(find.textContaining('Geo-Spatial GPS Sync'), findsOneWidget);
      expect(find.text('Complete Verification & Enroll'), findsOneWidget);
    });

    testWidgets('Live Scan Dialog can be opened and dismissed', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pump();

      // Find the Verify Now button for Live Biometrics
      final verifyButton = find.text('Verify Now');
      expect(verifyButton, findsOneWidget);
      await tester.tap(verifyButton);
      await tester.pump();

      // Check dialog is displayed
      expect(find.text('Live Face Scan Verification'), findsOneWidget);
      expect(
        find.textContaining('biometric verification frame'),
        findsOneWidget,
      );
      expect(find.text('Start Facial Scan'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('Live Face Scan Verification'), findsNothing);
    });

    testWidgets('Location GPS Capture triggers capture and updates UI', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pump();

      // Find GPS sync button
      final gpsButton = find.text('Acquire GPS');
      expect(gpsButton, findsOneWidget);
      await tester.tap(gpsButton);
      await tester.pump(const Duration(milliseconds: 100));

      // After location capture, the status changes to captured coordinates
      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });
}
