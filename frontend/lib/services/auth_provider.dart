// lib/services/auth_provider.dart (Updated with Biometric Lock)
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'secure_storage_service.dart';
import 'api_service.dart';

class UserProfile {
  final String? id;
  final String? name;
  final String? email;
  final String? role;
  final String? phoneNumber;
  UserProfile({this.id, this.name, this.email, this.role, this.phoneNumber});
}

class AuthProvider extends ChangeNotifier {
  final SecureStorageService _storageService = SecureStorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isAuthenticated = false;
  String? _role;
  UserProfile? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;
  UserProfile? get currentUser => _currentUser;

  Future<void> tryAutoLogin() async {
    final accessToken = await _storageService.getAccessToken();
    if (accessToken == null) {
      _isAuthenticated = false;
      notifyListeners();
      return;
    }
    ApiService.markSessionChanged();
    ApiService.globalAccessToken = accessToken;
    ApiService.globalRefreshToken = await _storageService.getRefreshToken();

    try {
      // Enforce biometric check on session restoration
      bool canCheck =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (canCheck) {
        bool didAuthenticate = await _localAuth.authenticate(
          localizedReason:
              'Verify your identity to resume your AgroNexus session.',
          biometricOnly: false,
        );
        if (!didAuthenticate) {
          await logout();
          return;
        }
      }

      _role = await _storageService.getUserRole();
      final profile = await ApiService.getCurrentUser();
      _role = profile['role']?.toString();
      final name =
          profile['fullName']?.toString() ??
          await _storageService.getUserName();
      final email =
          profile['email']?.toString() ?? await _storageService.getUserEmail();
      final id =
          profile['userId']?.toString() ?? await _storageService.getUserId();

      _isAuthenticated = true;
      ApiService.globalUserId = int.tryParse(id ?? '');
      _currentUser = UserProfile(
        id: id,
        name: name,
        email: email,
        role: _role,
        phoneNumber: profile['phoneNumber']?.toString(),
      );
      notifyListeners();
    } catch (_) {
      await logout();
    }
  }

  Future<void> login(Map<String, dynamic> authData) async {
    ApiService.markSessionChanged();
    _isAuthenticated = true;
    ApiService.globalAccessToken = authData['accessToken']?.toString();
    ApiService.globalRefreshToken = authData['refreshToken']?.toString();
    ApiService.globalUserId = int.tryParse(
      authData['userId']?.toString() ?? '',
    );
    _role = authData['role']?.toString();
    _currentUser = UserProfile(
      id: authData['userId']?.toString(),
      name: authData['fullName']?.toString() ?? authData['name']?.toString(),
      email: authData['email']?.toString(),
      role: _role,
      phoneNumber: authData['phoneNumber']?.toString(),
    );

    await _storageService.saveSession(
      accessToken: authData['accessToken']?.toString() ?? '',
      refreshToken: authData['refreshToken']?.toString() ?? '',
      role: _role ?? 'BUYER',
      userId: _currentUser?.id,
      name: _currentUser?.name,
      email: _currentUser?.email,
    );
    notifyListeners();
  }

  Future<void> updateCurrentUserProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    final profile = await ApiService.updateCurrentUserProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
    _currentUser = UserProfile(
      id: profile['userId']?.toString() ?? _currentUser?.id,
      name: profile['fullName']?.toString() ?? fullName,
      email: profile['email']?.toString() ?? _currentUser?.email,
      role: profile['role']?.toString() ?? _role,
      phoneNumber: profile['phoneNumber']?.toString() ?? phoneNumber,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    ApiService.markSessionChanged();
    _isAuthenticated = false;
    _role = null;
    _currentUser = null;
    ApiService.globalAccessToken = null;
    ApiService.globalRefreshToken = null;
    ApiService.globalUserId = null;
    await _storageService.clearSession();
    notifyListeners();
  }
}
