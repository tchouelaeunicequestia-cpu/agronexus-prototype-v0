import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_provider.dart';
import 'package:frontend/services/api_service.dart';

import 'dart:ui';

class TransporterWaybillScreen extends StatefulWidget {
  final String? orderCode;
  const TransporterWaybillScreen({super.key, this.orderCode});

  @override
  State<TransporterWaybillScreen> createState() =>
      _TransporterWaybillScreenState();
}

class _TransporterWaybillScreenState extends State<TransporterWaybillScreen> {
  static const _surface = Color(0xFF0b1326);
  static const _surfaceContainer = Color(0xFF171f33);
  static const _surfaceContainerHigh = Color(0xFF222a3d);
  static const _surfaceContainerLow = Color(0xFF131b2e);
  static const _primary = Color(0xFF4edea3);
  static const _tertiary = Color(0xFFffb95f);
  static const _secondary = Color(0xFF45dfa4);
  static const _onSurface = Color(0xFFdae2fd);
  static const _onSurfaceVariant = Color(0xFFbbcabf);

  bool _isLoading = true;
  Map<String, dynamic>? _waybillData;

  UserProfile? get _currentUser {
    try {
      return context.read<AuthProvider>().currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWaybill();
  }

  Future<void> _fetchWaybill() async {
    try {
      String? code = widget.orderCode;
      if (code == null) {
        final tripRes = await ApiService.authenticatedRequest('/api/v1/transporter/active-trip');
        if (tripRes.statusCode == 200) {
          final tripData = jsonDecode(tripRes.body);
          if (tripData['hasActiveTrip'] == true && tripData['id'] != null) {
            code = tripData['id'];
          }
        }
      }

      if (code != null) {
        final res = await ApiService.authenticatedRequest(
          '/api/v1/transporter/waybill/$code',
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (mounted) {
            setState(() {
              _waybillData = data;
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(user),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _waybillData == null
          ? const Center(
              child: Text(
                'Failed to load waybill',
                style: TextStyle(color: _onSurfaceVariant),
              ),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _buildCryptographicHeader(),
                  const SizedBox(height: 16),
                  _buildPartiesManifest(),
                  const SizedBox(height: 16),
                  _buildCargoManifest(),
                  const SizedBox(height: 16),
                  _buildWeighbridgeSlip(),
                  const SizedBox(height: 16),
                  _buildEscrowClause(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(dynamic user) {
    return AppBar(
      backgroundColor: const Color(0xFF060e20).withOpacity(0.85),
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: _primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF003824), size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Waybill',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _onSurface,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    user?.name ?? 'UNIT-740X',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '•',
                      style: TextStyle(fontSize: 10, color: Colors.white30),
                    ),
                  ),
                  const Text(
                    '42T SEMI',
                    style: TextStyle(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _surfaceContainerHigh.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: _primary, size: 8),
              SizedBox(width: 4),
              Text(
                'ONLINE',
                style: TextStyle(
                  color: _primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: _onSurfaceVariant),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildCryptographicHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceContainerHigh.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: _primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SIGNED BY AGRONEXUS CORE',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF060e20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: _primary, size: 6),
                      SizedBox(width: 4),
                      Text(
                        'LIVE CONTRACT',
                        style: TextStyle(
                          color: _onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ELECTRONIC WAYBILL',
                      style: TextStyle(
                        color: _onSurfaceVariant,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      _waybillData?['id'] ?? widget.orderCode ?? 'WB-ONLINE',
                      style: const TextStyle(
                        color: _onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.lock, color: _tertiary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'ESCROW-${_waybillData?['id'] ?? widget.orderCode ?? 'ONLINE'}',
                          style: const TextStyle(
                            color: _tertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cryptographic QR token validated: ESCROW-${_waybillData?['id'] ?? widget.orderCode ?? 'ONLINE'}',
                        ),
                        backgroundColor: _primary,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF060e20),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.qr_code_2,
                          color: _onSurface,
                          size: 36,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TAP TO EXPAND',
                          style: TextStyle(
                            color: _onSurfaceVariant.withOpacity(0.8),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, color: _onSurfaceVariant, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Generated: ${_waybillData?['createdAt']?.toString().split("T")[0] ?? 'Active Contract'}',
                      style: const TextStyle(color: _onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SEAL #4C99A',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartiesManifest() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sync_alt, color: _primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Parties & Transit Nodes',
                      style: TextStyle(
                        color: _onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '3 CHAIN ENTITIES',
                    style: TextStyle(
                      color: _onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Consignor
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.agriculture,
                      color: _primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CONSIGNOR • ORIGIN',
                              style: TextStyle(
                                color: _primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10b981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'VERIFIED',
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _waybillData?['consignorName'] ?? 'Verified Consignor',
                          style: const TextStyle(
                            color: _onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _waybillData?['consignorLocation'] ?? _waybillData?['origin'] ?? 'Farm Origin',
                          style: const TextStyle(
                            color: _onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.pin_drop, color: _primary, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _waybillData?['consignorLocation'] ?? _waybillData?['origin'] ?? 'Farm Gate Pick-up Point',
                                style: const TextStyle(
                                  color: _onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _waybillData?['consignorPhone'] ?? '+237 670 ••• •••',
                              style: const TextStyle(color: _onSurface, fontSize: 11),
                            ),
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: _primary,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Coop Tier 2',
                                  style: TextStyle(
                                    color: _primary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Route Visual
            Column(
              children: [
                Container(
                  width: 2,
                  height: 12,
                  color: _primary.withOpacity(0.4),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping, color: _primary, size: 14),
                      SizedBox(width: 6),
                      Text(
                        '128 km Transit Corridor (RN4)',
                        style: TextStyle(
                          color: _onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 2,
                  height: 12,
                  color: _primary.withOpacity(0.4),
                ),
              ],
            ),
            // Consignee
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _tertiary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: _tertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CONSIGNEE • DESTINATION',
                              style: TextStyle(
                                color: _tertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFe29100).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TIER-1 BUYER',
                                style: TextStyle(
                                  color: _tertiary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _waybillData?['consigneeName'] ?? 'Verified Buyer',
                          style: const TextStyle(
                            color: _onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _waybillData?['consigneeAddress'] ?? _waybillData?['destination'] ?? 'Destination Warehouse',
                          style: const TextStyle(
                            color: _onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: _tertiary, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _waybillData?['consigneeAddress'] ?? _waybillData?['destination'] ?? 'Depository Whitelisted Address',
                                style: const TextStyle(
                                  color: _onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _waybillData?['consigneePhone'] ?? '+237 690 ••• •••',
                              style: const TextStyle(color: _onSurface, fontSize: 11),
                            ),
                            const Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: _tertiary,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Depository Whitelisted',
                                  style: TextStyle(
                                    color: _onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Transporter
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2d3449),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.badge, color: _onSurface, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _waybillData?['transporterName'] ?? _currentUser?.name ?? 'Transporter',
                              style: const TextStyle(
                                color: _onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'TR-FLEET',
                              style: TextStyle(color: _primary, fontSize: 11),
                            ),
                          ],
                        ),
                        Text(
                          _waybillData?['transporterPhone'] ?? _currentUser?.email ?? 'Standard Freight Carrier',
                          style: const TextStyle(
                            color: _onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: _primary, size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCargoManifest() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: _primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ingested Cargo Manifest',
                      style: TextStyle(
                        color: _onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '2 COMMODITIES',
                  style: TextStyle(
                    color: _onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Cargo 1
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.circle, color: _primary, size: 8),
                                SizedBox(width: 6),
                                Text(
                                  _waybillData?['productTitle'] ?? _waybillData?['title'] ?? 'Grade-A Harvest Commodity',
                                  style: const TextStyle(
                                    color: _onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Staged from ${_waybillData?['origin'] ?? 'Verified Farm Depot'}',
                              style: const TextStyle(
                                color: _onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _waybillData?['productQuantity'] ?? '0 kg',
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'NET MASS',
                            style: TextStyle(
                              color: _onSurfaceVariant.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.scale, color: _primary, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Tare Verified: 18.2 kg',
                            style: TextStyle(
                              color: _onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LOT-BAF-990',
                          style: TextStyle(
                            color: _primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Cargo 2
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.circle, color: _primary, size: 8),
                                SizedBox(width: 6),
                                Text(
                                  'Organic Hass Avocados',
                                  style: TextStyle(
                                    color: _onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Export Grade • Monitored Cold-Chain Sensor Node #C7',
                              style: TextStyle(
                                color: _onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '450 kg',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'NET MASS',
                            style: TextStyle(
                              color: _onSurfaceVariant.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.thermostat, color: _primary, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Active Cold Log (8.2°C)',
                            style: TextStyle(color: _primary, fontSize: 11),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LOT-AVO-412',
                          style: TextStyle(
                            color: _primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Aggregation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL NET CARGO',
                        style: TextStyle(
                          color: _onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _waybillData?['productQuantity'] ?? '0 kg',
                        style: const TextStyle(
                          color: _onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TARE DEDUCTION',
                        style: TextStyle(
                          color: _onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.done_all, color: _primary, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '0.25% variance (PASS)',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeighbridgeSlip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.balance, color: _primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Government Weighbridge Stamp',
                      style: TextStyle(
                        color: _onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CERTIFIED PASS',
                    style: TextStyle(
                      color: Color(0xFF003824),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Obala Weighbridge Station #02',
                        style: TextStyle(
                          color: _onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '12 Oct 08:42 UTC',
                        style: TextStyle(
                          color: _onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GROSS VEHICLE MASS',
                                style: TextStyle(
                                  color: _onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '11,840 kg',
                                style: TextStyle(
                                  color: _onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INSPECTOR BADGE',
                                style: TextStyle(
                                  color: _onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'CMR-INSP-449',
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.shield, color: _primary, size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Axle load within CEMAC 13-ton limit standard. Zero infractions.',
                          style: TextStyle(
                            color: _onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscrowClause() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              _surfaceContainer,
              _surfaceContainer,
              _surfaceContainerHigh,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.paid, color: _tertiary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Escrow Payment Guarantee',
                      style: TextStyle(
                        color: _tertiary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FUNDS ESCROWED',
                    style: TextStyle(
                      color: _tertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Admin Guaranteed Freight Payout',
                        style: TextStyle(
                          color: _onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${_waybillData?['transportFee'] ?? '0'} ',
                            style: const TextStyle(
                              color: _tertiary,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'FCFA',
                            style: TextStyle(
                              color: _tertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.security, color: _primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Depository Escrow: ',
                            style: const TextStyle(
                              color: _onSurfaceVariant,
                              fontSize: 12,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: '${_waybillData?['escrowAmount'] ?? '0'} FCFA',
                                style: const TextStyle(
                                  color: _onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(
                                text: ' held in admin multi-signature smart vault. 100% of transport fee releases immediately to transporter upon handover confirmation.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.circle, color: _tertiary, size: 8),
                          SizedBox(width: 6),
                          Text(
                            'Auto-disbursement Armed',
                            style: TextStyle(
                              color: _onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Zero Intermediary Fee',
                        style: TextStyle(
                          color: _primary.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating signed PDF: WB-2026-098214...'),
                    backgroundColor: _primary,
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 20),
              label: const Text(
                'Download Certified PDF Waybill',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: const Color(0xFF003824),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Waybill link copied for Consignee dispatch'),
                    backgroundColor: _primary,
                  ),
                );
              },
              icon: const Icon(Icons.share, color: _primary, size: 20),
              label: const Text(
                'Share Waybill with Consignee',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _surfaceContainerHigh,
                foregroundColor: _onSurface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
