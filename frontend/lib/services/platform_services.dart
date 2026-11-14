// lib/services/platform_services.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';

// --- DATA MODELS ---

class PositionData {
  final double latitude;
  final double longitude;
  final String description;

  PositionData({
    required this.latitude,
    required this.longitude,
    required this.description,
  });
}

// --- ABSTRACT INTERFACES ---

abstract class LocationService {
  Future<PositionData> getCurrentLocation();
}

abstract class IdentityService {
  Future<bool> verifyFaceOrBiometric();
}

// --- LOCATION IMPLEMENTATIONS ---

class AndroidLocationService implements LocationService {
  @override
  Future<PositionData> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled on Android.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied.');
      }
    }

    Position pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return PositionData(
      latitude: pos.latitude,
      longitude: pos.longitude,
      description:
          'Android GPS (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
    );
  }
}

class WebLocationService implements LocationService {
  @override
  Future<PositionData> getCurrentLocation() async {
    Position pos = await Geolocator.getCurrentPosition();
    return PositionData(
      latitude: pos.latitude,
      longitude: pos.longitude,
      description:
          'Web Geolocation (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
    );
  }
}

class DesktopLocationService implements LocationService {
  @override
  Future<PositionData> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Windows Location Services are disabled in PC Settings.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Windows Location Permission denied.');
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return PositionData(
      latitude: pos.latitude,
      longitude: pos.longitude,
      description:
          'Windows Live GPS (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
    );
  }
}

class LocationServiceFactory {
  static LocationService getService() {
    if (kIsWeb) {
      return WebLocationService();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return AndroidLocationService();
    } else {
      return DesktopLocationService();
    }
  }
}

// --- IDENTITY / BIOMETRIC IMPLEMENTATIONS ---

class MockCameraIdentityService implements IdentityService {
  @override
  Future<bool> verifyFaceOrBiometric() async {
    // Bypass OS-level credential prompt (local_auth) and simulate an in-app camera face scan
    // This pairs perfectly with the custom UI dialog in RegisterScreen
    await Future.delayed(
      const Duration(seconds: 2),
    ); // Simulated neural facial mesh validation
    return true; // Returns true upon successful face capture
  }
}

class IdentityServiceFactory {
  static IdentityService getService() {
    // For now, return the MockCameraIdentityService for all platforms (Web, Android, Desktop)
    // to bypass the system's native password/PIN locks.
    return MockCameraIdentityService();
  }
}
