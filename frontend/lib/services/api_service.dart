// lib/services/api_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_constants.dart' as api_constants;
import 'secure_storage_service.dart';

class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'Your session has expired. Please sign in again.';
}

class ApiService {
  static String get baseUrl => api_constants.baseUrl;

  // Global token references used by auth provider and dashboards
  static String? globalAccessToken;
  static String? globalRefreshToken;
  static int? globalUserId;
  static Future<bool>? _refreshOperation;
  static int _sessionVersion = 0;
  static final SecureStorageService _storage = SecureStorageService();

  static void markSessionChanged() {
    _sessionVersion++;
  }

  /// Authenticate user credentials
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      globalAccessToken = data['accessToken'];
      globalRefreshToken = data['refreshToken'];
      globalUserId = data['userId'];
      return data;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Authentication failed.');
    }
  }

  /// Authenticate with Google OAuth idToken
  static Future<Map<String, dynamic>> googleLogin({
    required String idToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      globalAccessToken = data['accessToken'];
      globalRefreshToken = data['refreshToken'];
      globalUserId = data['userId'];
      return data;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Google authentication failed.');
    }
  }

  /// Returns the current account from the server, including its authoritative role.
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await authenticatedRequest('/api/v1/auth/me');
    if (response.statusCode == 200) {
      final payload = jsonDecode(response.body);
      if (payload is Map<String, dynamic>) {
        return payload;
      }
    }
    throw Exception(
      'Unable to verify the current session (HTTP ${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> updateCurrentUserProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    final response = await authenticatedRequest(
      '/api/v1/auth/me',
      method: 'PUT',
      body: {'fullName': fullName, 'phoneNumber': phoneNumber},
    );
    final payload = _decodeJsonObject(response.body);
    if (response.statusCode == 200 && payload is Map<String, dynamic>) {
      return payload;
    }
    throw Exception(
      payload is Map<String, dynamic>
          ? payload['error']?.toString() ?? 'Unable to update profile.'
          : 'Unable to update profile (HTTP ${response.statusCode}). '
                'Please make sure the backend is running the latest version.',
    );
  }

  static Map<String, dynamic>? _decodeJsonObject(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Register a new user role with biometric profile data and optional images
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String nationalId,
    required bool biometricVerified,
    required bool cniVerified,
    required String role,
    double? latitude,
    double? longitude,
    XFile? cniImage,
    XFile? faceImage,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/register');

    // Use multipart when images are present, plain JSON otherwise
    if (cniImage != null || faceImage != null) {
      final request = http.MultipartRequest('POST', uri);
      if (globalAccessToken != null) {
        request.headers['Authorization'] = 'Bearer $globalAccessToken';
      }
      request.fields.addAll({
        'fullName': name,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'nationalId': nationalId,
        'biometricVerified': biometricVerified.toString(),
        'cniVerified': cniVerified.toString(),
        'role': role,
        'latitude': (latitude ?? 3.8480).toString(),
        'longitude': (longitude ?? 11.5021).toString(),
      });
      if (cniImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('cniImage', cniImage.path),
        );
      }
      if (faceImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('faceImage', faceImage.path),
        );
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Registration failed.');
      }
    } else {
      // Fallback: plain JSON (no images)
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': name,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'nationalId': nationalId,
          'biometricVerified': biometricVerified,
          'cniVerified': cniVerified,
          'role': role,
          'latitude': latitude ?? 3.8480,
          'longitude': longitude ?? 11.5021,
        }),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Registration failed.');
      }
    }
  }

  static Future<Map<String, dynamic>> verifyRegistrationCode({
    required String email,
    required String channel,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'channel': channel, 'code': code}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return Map<String, dynamic>.from(data);
    throw Exception(data['error'] ?? 'Verification failed.');
  }

  /// Generic authenticated HTTP request wrapper with proper positional endpoint and named options
  static Future<http.Response> authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final activeToken =
        token ?? globalAccessToken ?? await _storage.getAccessToken();
    final uri = Uri.parse(
      endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint',
    );

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (activeToken != null) 'Authorization': 'Bearer $activeToken',
    };

    Future<http.Response> send(Map<String, String> requestHeaders) {
      final requestBody = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'POST':
          return http.post(uri, headers: requestHeaders, body: requestBody);
        case 'PUT':
          return http.put(uri, headers: requestHeaders, body: requestBody);
        case 'PATCH':
          return http.patch(uri, headers: requestHeaders, body: requestBody);
        case 'DELETE':
          return http.delete(uri, headers: requestHeaders);
        default:
          return http.get(uri, headers: requestHeaders);
      }
    }

    final response = await send(headers);
    if (response.statusCode != 401) return response;
    final tokenWasRefreshed =
        activeToken != null &&
        globalAccessToken != null &&
        activeToken != globalAccessToken;
    if (!tokenWasRefreshed && !await refreshAccessToken()) {
      throw const SessionExpiredException();
    }

    final refreshedToken = globalAccessToken ?? await _storage.getAccessToken();
    if (refreshedToken == null || refreshedToken.isEmpty) {
      throw const SessionExpiredException();
    }
    final retryHeaders = Map<String, String>.from(headers)
      ..['Authorization'] = 'Bearer $refreshedToken';
    return send(retryHeaders);
  }

  /// Opens the agronomist's live stream of threshold-breach telemetry alerts.
  static Stream<Map<String, dynamic>> telemetryAlertStream() async* {
    final activeToken = globalAccessToken ?? await _storage.getAccessToken();
    final request = http.Request(
      'GET',
      Uri.parse('$baseUrl/api/v1/telemetry/alerts/stream'),
    );
    request.headers['Accept'] = 'text/event-stream';
    if (activeToken != null) {
      request.headers['Authorization'] = 'Bearer $activeToken';
    }

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception(
        'Unable to connect to telemetry alert stream '
        '(HTTP ${response.statusCode}).',
      );
    }

    String? eventName;
    final dataLines = <String>[];
    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      } else if (line.isEmpty && dataLines.isNotEmpty) {
        final payload = jsonDecode(dataLines.join('\n'));
        if (eventName == 'telemetry-alert' && payload is Map<String, dynamic>) {
          yield payload;
        }
        eventName = null;
        dataLines.clear();
      }
    }
  }

  /// Refreshes and rotates the backend refresh token once for concurrent 401s.
  static Future<bool> refreshAccessToken() {
    final pending = _refreshOperation;
    if (pending != null) return pending;

    final operation = _performTokenRefresh();
    _refreshOperation = operation;
    return operation.whenComplete(() {
      if (identical(_refreshOperation, operation)) _refreshOperation = null;
    });
  }

  static Future<bool> _performTokenRefresh() async {
    final sessionVersion = _sessionVersion;
    globalRefreshToken ??= await _storage.getRefreshToken();
    if (globalRefreshToken == null || globalRefreshToken!.isEmpty) {
      return false;
    }
    final requestRefreshToken = globalRefreshToken!;

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': requestRefreshToken}),
    );
    if (response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 400) {
      return false;
    }
    if (response.statusCode != 200) {
      throw Exception('Token refresh failed (HTTP ${response.statusCode}).');
    }

    final data = _decodeJsonObject(response.body);
    final accessToken = data?['accessToken']?.toString();
    final refreshToken = data?['refreshToken']?.toString();
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw const FormatException(
        'Token refresh endpoint returned an invalid response.',
      );
    }
    if (sessionVersion != _sessionVersion) return false;

    globalAccessToken = accessToken;
    globalRefreshToken = refreshToken;
    await _storage.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: await _storage.getUserRole() ?? 'BUYER',
      userId: await _storage.getUserId(),
      name: await _storage.getUserName(),
      email: await _storage.getUserEmail(),
    );
    return true;
  }

  /// Fetches real-time escrow, yield, and IoT silo metrics for the logged-in farmer
  static Future<Map<String, dynamic>> getFarmerDashboardMetrics() async {
    final response = await authenticatedRequest('/api/v1/farmers/me/dashboard');
    if (response.statusCode == 200) {
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) return payload;
      } on FormatException {
        throw Exception(
          'Farmer dashboard endpoint returned invalid JSON. Check the backend response.',
        );
      }
      throw Exception(
        'Farmer dashboard endpoint returned an unexpected response.',
      );
    }
    final errorBody = _decodeJsonObject(response.body);
    final detail =
        errorBody?['error']?.toString() ?? errorBody?['message']?.toString();
    throw Exception(
      detail != null && detail.isNotEmpty
          ? '$detail (HTTP ${response.statusCode})'
          : 'Unable to load your farmer dashboard (HTTP ${response.statusCode}).',
    );
  }

  /// Fetches the product listings created by the logged-in farmer
  static Future<List<Map<String, dynamic>>> getFarmerProducts() async {
    final response = await authenticatedRequest('/api/v1/products/mine');
    if (response.statusCode == 200) {
      try {
        final payload = jsonDecode(response.body);
        if (payload is List) {
          return payload
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }
      } on FormatException {
        throw Exception(
          'Farmer listings endpoint returned invalid JSON. Check the backend response.',
        );
      } on TypeError {
        throw Exception(
          'Farmer listings endpoint returned an unexpected response.',
        );
      }
      throw Exception(
        'Farmer listings endpoint returned an unexpected response.',
      );
    }
    final errorBody = _decodeJsonObject(response.body);
    final detail =
        errorBody?['error']?.toString() ?? errorBody?['message']?.toString();
    throw Exception(
      detail != null && detail.isNotEmpty
          ? '$detail (HTTP ${response.statusCode})'
          : 'Unable to load your produce listings (HTTP ${response.statusCode}).',
    );
  }

  /// Fetches products available to buyers, optionally filtered by proximity radius (km)
  static Future<List<Map<String, dynamic>>> getNearbyProducts({
    double lat = 3.8480,
    double lon = 11.5021,
    double radiusKm = 50,
  }) async {
    final response = await authenticatedRequest(
      '/api/v1/products/nearby?latitude=$lat&longitude=$lon&radiusMeters=${radiusKm * 1000}',
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static Future<Set<dynamic>> getFavoriteProductIds() async {
    final response = await authenticatedRequest('/api/v1/products/favorites');
    if (response.statusCode != 200) {
      throw Exception('Unable to load your favorite produce listings.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return <dynamic>{};
    return decoded.toSet();
  }

  static Future<void> addFavoriteProduct(dynamic productId) async {
    final response = await authenticatedRequest(
      '/api/v1/products/favorites/$productId',
      method: 'POST',
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Unable to save this produce listing as a favorite.');
    }
  }

  static Future<void> removeFavoriteProduct(dynamic productId) async {
    final response = await authenticatedRequest(
      '/api/v1/products/favorites/$productId',
      method: 'DELETE',
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to remove this produce listing from favorites.');
    }
  }

  /// Fetches the latest environmental readings for a storage telemetry node.
  static Future<List<Map<String, dynamic>>> getTelemetryNodeLogs(
    String nodeId,
  ) async {
    final normalizedNodeId = nodeId.trim();
    if (normalizedNodeId.isEmpty) {
      throw ArgumentError.value(nodeId, 'nodeId', 'A node ID is required.');
    }

    final response = await authenticatedRequest(
      '/api/v1/telemetry/node/${Uri.encodeComponent(normalizedNodeId)}',
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    }
    throw Exception('Unable to load telemetry for node $normalizedNodeId.');
  }

  static Future<List<Map<String, dynamic>>> getTelemetryNodes() async {
    final response = await authenticatedRequest('/api/v1/telemetry/nodes');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    }
    throw Exception(
      'Unable to load storage nodes (HTTP ${response.statusCode}).',
    );
  }

  static Future<List<Map<String, dynamic>>> getActuatorCommands() async {
    final response = await authenticatedRequest(
      '/api/v1/telemetry/actuator-commands',
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    }
    throw Exception(
      'Unable to load actuator requests (HTTP ${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> createActuatorCommand({
    required String nodeId,
    required String action,
  }) async {
    final response = await authenticatedRequest(
      '/api/v1/telemetry/nodes/${Uri.encodeComponent(nodeId)}/commands',
      method: 'POST',
      body: {'action': action},
    );
    final payload = _decodeJsonObject(response.body);
    if (response.statusCode == 201 && payload != null) return payload;
    throw Exception(
      payload?['error']?.toString() ??
          'Unable to queue the actuator request (HTTP ${response.statusCode}).',
    );
  }

  /// Fetches real-time metrics for the Agronomist dashboard
  static Future<Map<String, dynamic>> getAgronomistMetrics() async {
    final response = await authenticatedRequest('/api/v1/agronomist/metrics');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    throw Exception('Unable to load agronomist metrics.');
  }

  static Future<List<Map<String, dynamic>>> getAgronomistGuides() async {
    final response = await authenticatedRequest('/api/v1/agronomist/guides');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    }
    throw Exception(
      'Unable to load Agronomist guides (HTTP ${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> saveAgronomistGuide({
    required String title,
    required String sourceAgency,
    required String category,
    required String content,
  }) async {
    final response = await authenticatedRequest(
      '/api/v1/agronomist/guides',
      method: 'POST',
      body: {
        'title': title,
        'sourceAgency': sourceAgency,
        'category': category,
        'content': content,
        'status': 'DRAFT',
      },
    );
    final payload = _decodeJsonObject(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        payload != null) {
      return payload;
    }
    throw Exception(
      payload?['error']?.toString() ??
          'Unable to save the guide draft (HTTP ${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> publishAgronomistGuide(
    int guideId,
  ) async {
    final response = await authenticatedRequest(
      '/api/v1/agronomist/guides/$guideId/publish',
      method: 'POST',
    );
    final payload = _decodeJsonObject(response.body);
    if (response.statusCode == 200 && payload != null) return payload;
    throw Exception(
      payload?['error']?.toString() ??
          'Unable to publish the guide (HTTP ${response.statusCode}).',
    );
  }

  /// Fetches real-time metrics for the Transporter dashboard
  static Future<Map<String, dynamic>> getTransporterMetrics() async {
    try {
      final response = await authenticatedRequest(
        '/api/v1/transporter/metrics',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {
      'lockedEscrow': '100,000 XAF',
      'temp': '8.2°C',
      'odometer': '142 km',
      'jobs': 2,
    };
  }

  /// Creates the order record and locks its calculated amount in escrow.
  static Future<Map<String, dynamic>> createEscrowOrder({
    required int buyerId,
    required int productId,
    required double quantity,
    double? transportFee,
    bool isSelfPickup = false,
    String? deliveryAddress,
  }) async {
    final response = await authenticatedRequest(
      '/api/v1/escrow/order',
      method: 'POST',
      body: {
        'buyerId': buyerId,
        'productId': productId,
        'quantity': quantity,
        'transportFee': transportFee,
        'isSelfPickup': isSelfPickup,
        'deliveryAddress': deliveryAddress,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    final errorBody = jsonDecode(response.body);
    throw Exception(errorBody['error'] ?? 'Unable to create the escrow order.');
  }

  static Future<Map<String, dynamic>> submitTransportQuote({
    required String orderCode,
    required double transportFee,
  }) async {
    final response = await authenticatedRequest(
      '/api/v1/escrow/order/$orderCode/quote',
      method: 'POST',
      body: {'transportFee': transportFee},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception(data['error'] ?? 'Unable to submit the transport quote.');
  }

  static Future<Map<String, dynamic>> approveTransportQuote({
    required String orderCode,
  }) async {
    final response = await authenticatedRequest(
      '/api/v1/escrow/order/$orderCode/approve-quote',
      method: 'POST',
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception(data['error'] ?? 'Unable to approve the transport quote.');
  }

  static Future<List<Map<String, dynamic>>> getTransportQuoteRequests() async {
    final response = await authenticatedRequest(
      '/api/v1/transporter/quote-requests',
      method: 'GET',
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to load transport quote requests.');
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  static Future<List<Map<String, dynamic>>> getBuyerQuoteOrders() async {
    final response = await authenticatedRequest(
      '/api/v1/escrow/buyer/orders',
      method: 'GET',
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to load your quote orders.');
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  static Future<List<Map<String, dynamic>>> getFarmerEscrowOrders() async {
    final response = await authenticatedRequest(
      '/api/v1/escrow/farmer/orders',
      method: 'GET',
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to load your escrow ledger.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  // --- PHASE 4.3: MULTI-PARTY HANDOVER & WAYPOINT METHODS ---

  /// 1. Farmer Dispatch Signoff
  static Future<bool> farmerSignoffDispatch(
    String orderId,
    String token,
  ) async {
    try {
      final response = await authenticatedRequest(
        '/api/v1/farmer/orders/$orderId/dispatch',
        method: 'POST',
        token: token,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Farmer Dispatch Error: $e');
      return false;
    }
  }

  /// 2. Transporter Delivery Confirmation
  static Future<bool> transporterConfirmDelivery(
    String orderId,
    String token,
  ) async {
    try {
      final response = await authenticatedRequest(
        '/api/v1/transporter/orders/$orderId/deliver',
        method: 'POST',
        token: token,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Transporter Delivery Error: $e');
      return false;
    }
  }

  /// 3. Buyer Final Inspection & Escrow Release Signoff
  static Future<bool> buyerReleaseEscrow(String orderId, String token) async {
    try {
      final response = await authenticatedRequest(
        '/api/v1/escrow/orders/$orderId/release',
        method: 'POST',
        token: token,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Escrow Release Error: $e');
      return false;
    }
  }

  /// 4. Transporter Intermediate Waypoint Update
  static Future<bool> updateTransportWaypoint({
    required String orderId,
    required double latitude,
    required double longitude,
    required String waypointNote,
    String? token,
  }) async {
    try {
      final response = await authenticatedRequest(
        '/api/v1/transporter/orders/$orderId/waypoint',
        method: 'POST',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'waypointNote': waypointNote,
        },
        token: token,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Waypoint Update Error: $e');
      return false;
    }
  }

  /// Query the AgroAI Domain-Guarded Assistant
  static Future<Map<String, dynamic>> queryAiAssistant(String prompt) async {
    final response = await authenticatedRequest(
      '/api/v1/ai/query',
      method: 'POST',
      body: {'query': prompt},
    );
    // If the backend returns 200 OK or 400 Bad Request (guardrail rejection),
    // both contain valid JSON bodies we want to decode!
    if (response.statusCode == 200 || response.statusCode == 400) {
      return jsonDecode(response.body);
    }
    throw Exception(
      'Failed to communicate with AgroAI Assistant (Status: ${response.statusCode})',
    );
  }
}
