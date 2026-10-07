import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_provider.dart';
import 'package:frontend/services/platform_services.dart';

import 'buyer_quote_section.dart';
import 'buyer_escrow_screen.dart';
import 'buyer_telemetry_screen.dart';
import 'buyer_agroai_screen.dart';
import 'buyer_profile_screen.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard>
    with SingleTickerProviderStateMixin {
  List<dynamic> _backendProducts = [];
  bool _isLoading = false;
  double _searchRadiusKm = 50.0;
  double _userLat = 3.8480;
  double _userLon = 11.5021;
  String _locationDescription = 'Yaoundé, Centre Region, Cameroon';
  String _selectedCategory = 'All';
  String _searchQuery = '';
  List<Map<String, dynamic>> _quoteOrders = [];
  int _activeNavIndex =
      0; // 0: Home, 1: Market, 2: Escrow, 3: Telemetry, 4: AgroAI, 5: Profile

  final TextEditingController _searchController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<double> _radiusOptions = [5, 15, 25, 50, 100];
  final List<Map<String, dynamic>> _categoryItems = [
    {
      'name': 'All Lots',
      'value': 'All',
      'icon': Icons.apps_rounded,
      'color': const Color(0xFF0F172A),
    },
    {
      'name': 'Plantains',
      'value': 'PLANTAINS',
      'icon': Icons.eco_rounded,
      'color': const Color(0xFF059669),
    },
    {
      'name': 'Cereals',
      'value': 'CEREALS',
      'icon': Icons.grass_rounded,
      'color': const Color(0xFFD97706),
    },
    {
      'name': 'Tubers',
      'value': 'TUBERS',
      'icon': Icons.set_meal_rounded,
      'color': const Color(0xFFB45309),
    },
    {
      'name': 'Vegetables',
      'value': 'VEGETABLES',
      'icon': Icons.local_florist_rounded,
      'color': const Color(0xFFEF4444),
    },
    {
      'name': 'Cocoa & Coffee',
      'value': 'COCOA',
      'icon': Icons.coffee_rounded,
      'color': const Color(0xFF78350F),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadUserLocationAndProduce();
    _loadQuoteOrders();
  }

  Future<void> _loadQuoteOrders() async {
    try {
      final orders = await ApiService.getBuyerQuoteOrders();
      if (mounted) setState(() => _quoteOrders = orders);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocationAndProduce() async {
    try {
      final locationService = LocationServiceFactory.getService();
      PositionData pos = await locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLon = pos.longitude;
          _locationDescription = pos.description;
        });
      }
    } catch (_) {}
    await _fetchNearbyProduce();
  }

  Future<void> _fetchNearbyProduce() async {
    setState(() => _isLoading = true);
    try {
      final radiusMeters = _searchRadiusKm * 1000;
      final endpoint =
          '/products/nearby?latitude=$_userLat&longitude=$_userLon&radiusMeters=$radiusMeters';

      final response = await ApiService.authenticatedRequest(
        endpoint,
        method: 'GET',
      );

      if (response.statusCode == 200) {
        List<dynamic> fetched = jsonDecode(response.body);
        setState(() {
          _backendProducts = fetched;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _displayLots {
    List<Map<String, dynamic>> combined = [];

    for (var p in _backendProducts) {
      combined.add({
        'id': p['id'] ?? 0,
        'title': p['title'] ?? 'Produce Harvest Lot',
        'scientificName': p['description'] ?? 'Verified Farm Lot',
        'farmerName': p['farmer'] != null
            ? p['farmer']['fullName'] ?? 'Verified Farmer'
            : 'Farmer #${p['farmerId'] ?? 1}',
        'locationAxis': 'PostGIS Geopositional',
        'category': (p['category'] ?? 'PLANTAINS').toString().toUpperCase(),
        'pricePerUnit': (p['pricePerUnit'] ?? 450).toInt(),
        'unitType': p['unitType'] ?? 'kg',
        'availableQuantity': (p['availableQuantity'] ?? 1000.0).toDouble(),
        'inventoryPercent': p['inventoryPercent'],
        'distanceKm': p['distanceKm'],
        'gradeBadge': p['gradeBadge'],
        'telemetryInfo': p['telemetryInfo'],
        'timeAgo': p['timeAgo'],
        'spec1': 'Direct Farm Pickup',
        'spec2': 'Escrow Lock Ready',
        'imageUrl': p['imageUrl'] ?? 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?q=80&w=800&auto=format&fit=crop',
      });
    }

    if (_selectedCategory != 'All') {
      combined = combined.where((item) {
        final cat = (item['category'] ?? '').toString().toUpperCase();
        return cat == _selectedCategory ||
            (_selectedCategory == 'PLANTAINS' && cat.contains('PLANT')) ||
            (_selectedCategory == 'COCOA' &&
                (cat.contains('COCOA') || cat.contains('COFFEE')));
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      combined = combined.where((item) {
        return item['title'].toString().toLowerCase().contains(q) ||
            item['farmerName'].toString().toLowerCase().contains(q) ||
            item['category'].toString().toLowerCase().contains(q);
      }).toList();
    }

    return combined;
  }

  void _openEscrowCheckoutModal(Map<String, dynamic> item) {
    final double price = (item['pricePerUnit'] ?? 0).toDouble();
    final double availableQuantity = (item['availableQuantity'] ?? 0)
        .toDouble();
    double quantity = availableQuantity > 0 ? 1 : 0;
    bool isSelfPickup = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final double? transportFee = isSelfPickup ? 0 : null;
          final double platformServiceFee = price * quantity * 0.05;
          final double? totalDepository = isSelfPickup
              ? price * quantity + platformServiceFee
              : null;

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFAF3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD7F3E3)),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF0F5132),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Escrow Depository Order Lock',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Transparent 5% platform service fee',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildModalCostRow(
                        'Produce Harvest Lot',
                        item['title'],
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      _buildModalCostRow(
                        'Producer / Cooperative',
                        item['farmerName'],
                      ),
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                      _buildModalCostRow(
                        'Item Cost',
                        '${(price * quantity).toStringAsFixed(0)} XAF',
                      ),
                      const SizedBox(height: 8),
                      _buildModalCostRow(
                        'Freight Dispatch Fee',
                        isSelfPickup ? '0 XAF' : 'Pending transporter quote',
                      ),
                      const SizedBox(height: 8),
                      _buildModalCostRow(
                        'Platform Service Fee (5%)',
                        '${platformServiceFee.toStringAsFixed(0)} XAF',
                      ),
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                      _buildModalCostRow(
                        'Total Escrow Locked',
                        totalDepository == null
                            ? 'Pending quote approval'
                            : '${totalDepository.toStringAsFixed(0)} XAF',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: quantity > 1
                          ? () => setModalState(() => quantity -= 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${quantity.toInt()} ${item['unitType']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: quantity < availableQuantity
                          ? () => setModalState(() => quantity += 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Buyer self-pickup'),
                  subtitle: Text(
                    isSelfPickup
                        ? 'No transport fee'
                        : 'Delivery to $_locationDescription',
                  ),
                  value: isSelfPickup,
                  onChanged: (value) =>
                      setModalState(() => isSelfPickup = value),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Color(0xFF0F5132),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Delivery orders remain pending until a transporter quote is approved.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5132),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: quantity <= 0
                            ? null
                            : () => _createEscrowOrder(
                                item,
                                quantity: quantity,
                                transportFee: transportFee,
                                isSelfPickup: isSelfPickup,
                                deliveryAddress: _locationDescription,
                              ),
                        icon: const Icon(Icons.verified_user_rounded, size: 18),
                        label: const Text(
                          'Create Order',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createEscrowOrder(
    Map<String, dynamic> item, {
    required double quantity,
    required double? transportFee,
    required bool isSelfPickup,
    required String deliveryAddress,
  }) async {
    final buyerId = ApiService.globalUserId;
    final productId = item['id'];
    if (buyerId == null || productId is! num) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify this buyer or produce listing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await ApiService.createEscrowOrder(
        buyerId: buyerId,
        productId: productId.toInt(),
        quantity: quantity,
        transportFee: transportFee,
        isSelfPickup: isSelfPickup,
        deliveryAddress: deliveryAddress,
      );
      if (!mounted) return;

      final order = response['order'] as Map<String, dynamic>;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order['orderCode']} locked in escrow.'),
          backgroundColor: const Color(0xFF0F5132),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      await _loadQuoteOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to lock order: ${e.toString().replaceAll("Exception: ", "")}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildModalCostRow(
    String label,
    String value, {
    bool isBold = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal || isBold ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal || isBold ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? const Color(0xFF0F5132) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeOverview(String displayName, String initials) {
    final activeOrders = _quoteOrders.length;
    final availableLots = _displayLots.length;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          backgroundColor: Colors.white.withValues(alpha: 0.92),
          elevation: 0,
          toolbarHeight: 64,
          title: Row(
            children: [
              Semantics(
                button: true,
                label: 'Open buyer profile',
                child: Tooltip(
                  message: 'Open profile',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => setState(() => _activeNavIndex = 5),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFEFFAF3),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF0F5132),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome back, $displayName',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Buyer overview',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                'Your sourcing dashboard',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Review activity and jump into the marketplace when you are ready.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewMetric(
                      Icons.receipt_long_rounded,
                      'Active orders',
                      '$activeOrders',
                      const Color(0xFF0F5132),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOverviewMetric(
                      Icons.inventory_2_rounded,
                      'Nearby lots',
                      '$availableLots',
                      const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildOverviewPanel(
                icon: Icons.location_on_outlined,
                title: 'Sourcing location',
                value: _locationDescription,
                detail: 'Used to find produce near you',
              ),
              const SizedBox(height: 12),
              _buildOverviewPanel(
                icon: Icons.shield_outlined,
                title: 'Escrow protection',
                value: 'Available for every order',
                detail: 'Funds stay protected until delivery is confirmed',
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _activeNavIndex = 1),
                  icon: const Icon(Icons.storefront_rounded),
                  label: const Text('Open marketplace'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5132),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick access',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewAction(
                      Icons.verified_user_rounded,
                      'Escrow',
                      2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildOverviewAction(
                      Icons.sensors_rounded,
                      'Telemetry',
                      3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildOverviewAction(
                      Icons.psychology_rounded,
                      'AgroAI',
                      4,
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewMetric(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildOverviewPanel({
    required IconData icon,
    required String title,
    required String value,
    required String detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFAF3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0F5132)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewAction(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => setState(() => _activeNavIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0F5132)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final displayName = user?.name ?? 'Buyer';
    final initials = displayName.trim().isEmpty
        ? 'B'
        : displayName.trim().substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://img.freepik.com/premium-photo/agriculture-project-africa_943281-36244.jpg?w=2000',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0F382C)),
            ),
          ),
          SafeArea(
            top: false,
            child: Stack(
              children: [
                IndexedStack(
                  index: _activeNavIndex,
                  children: [
                    // Index 0: Home
                    _buildHomeOverview(displayName, initials),
                    // Index 1: Market
                    CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          floating: true,
                          pinned: true,
                          backgroundColor: Colors.white.withValues(alpha: 0.92),
                          elevation: 0,
                          toolbarHeight: 64,
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(1),
                            child: Container(
                              color: const Color(0xFFE2E8F0),
                              height: 1,
                            ),
                          ),
                          title: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  image: const DecorationImage(
                                    image: AssetImage(
                                      'assets/images/agronexus.jpg',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFD7F3E3),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'AgroNexus',
                                        style: TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFFAF3),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFD7F3E3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            FadeTransition(
                                              opacity: _pulseAnimation,
                                              child: Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF10B981),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Buyer',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F5132),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    'Institutional Wholesale Portal',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          actions: [
                            Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Color(0xFF475569),
                                      size: 20,
                                    ),
                                    onPressed: () {},
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 10,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 14.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () =>
                                    setState(() => _activeNavIndex = 5),
                                child: Semantics(
                                  button: true,
                                  label: 'Open buyer profile',
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF0F5132)
                                            .withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFF0F5132),
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SliverToBoxAdapter(
                          child: BuyerQuoteSection(
                            quoteOrders: _quoteOrders,
                            onRefreshNeeded: _loadQuoteOrders,
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFFAF3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFD7F3E3),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.explore_rounded,
                                        color: Color(0xFF0F5132),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Sourcing Farm GPS Coordinates',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _locationDescription,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          FadeTransition(
                                            opacity: _pulseAnimation,
                                            child: Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            '±3.8m Precision',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFFAF3),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.radar_rounded,
                                                size: 18,
                                                color: Color(0xFF0F5132),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Sourcing Radius Filter',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
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
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.tune_rounded,
                                                size: 12,
                                                color: Color(0xFF0F5132),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'PostGIS ST_DWithin',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF475569),
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: _radiusOptions.map((dist) {
                                          final isSelected =
                                              _searchRadiusKm == dist;
                                          return Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(
                                                  () => _searchRadiusKm = dist,
                                                );
                                                _fetchNearbyProduce();
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFF0F5132)
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow: isSelected
                                                      ? [
                                                          BoxShadow(
                                                            color:
                                                                const Color(
                                                                  0xFF0F5132,
                                                                ).withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                          ),
                                                        ]
                                                      : [],
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '${dist.toInt()} km',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF475569,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Perimeter: Within ${_searchRadiusKm.toInt()} km zone',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFFAF3),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF1B8A53),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_displayLots.length} verified harvest lots',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F5132),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (val) =>
                                            setState(() => _searchQuery = val),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF0F172A),
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Search crops, cooperatives, lot ID...',
                                          hintStyle: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                            color: Color(0xFF94A3B8),
                                            size: 20,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.filter_list_rounded,
                                        color: Color(0xFF475569),
                                        size: 20,
                                      ),
                                      onPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 36,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _categoryItems.length,
                                  itemBuilder: (context, index) {
                                    final cat = _categoryItems[index];
                                    final isSelected =
                                        _selectedCategory == cat['value'];

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(
                                            () => _selectedCategory =
                                                cat['value'],
                                          );
                                          _fetchNearbyProduce();
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF0F172A)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF0F172A)
                                                  : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              if (cat['value'] != 'All')
                                                Icon(
                                                  cat['icon'],
                                                  size: 15,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : cat['color'],
                                                ),
                                              if (cat['value'] != 'All')
                                                const SizedBox(width: 6),
                                              Text(
                                                cat['name'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : const Color(0xFF334155),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Real-Time Available Lots',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'PostGIS geosorted by buyer proximity',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.swap_vert_rounded,
                                          size: 15,
                                          color: Color(0xFF0F5132),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Nearest First',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _isLoading
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(40.0),
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF0F5132),
                                        ),
                                      ),
                                    )
                                  : _displayLots.isEmpty
                                  ? Container(
                                      padding: const EdgeInsets.all(40),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'No active produce lots match your current filters.',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _displayLots.length,
                                      itemBuilder: (context, index) {
                                        final item = _displayLots[index];
                                        return _buildHarvestCard(item);
                                      },
                                    ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    // Index 2: Escrow
                    const BuyerEscrowScreen(),
                    // Index 3: Telemetry
                    const BuyerTelemetryScreen(),
                    // Index 4: AgroAI
                    const BuyerAgroAIScreen(),
                    // Index 5: Profile
                    const BuyerProfileScreen(),
                  ],
                ),
                if (_activeNavIndex == 1)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 72,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1E293B)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              FadeTransition(
                                opacity: _pulseAnimation,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF34D399),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'LIVE GEOSPATIAL FILTER',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF94A3B8),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    'Centre Region • ${_searchRadiusKm.toInt()}km radius',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 14,
                                      color: Color(0xFFE2E8F0),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Filter',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFE2E8F0),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F5132),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.map_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Map View',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      border: const Border(
                        top: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
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
                        _buildNavItem(0, Icons.home_rounded, 'Home'),
                        _buildNavItem(1, Icons.storefront_rounded, 'Market'),
                        _buildNavItem(2, Icons.verified_user_rounded, 'Escrow'),
                        _buildNavItem(3, Icons.sensors_rounded, 'Telemetry'),
                        _buildNavItem(4, Icons.psychology_rounded, 'AgroAI'),
                        _buildNavItem(5, Icons.person_rounded, 'Profile'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _activeNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeNavIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEFFAF3) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive
                  ? const Color(0xFF0F5132)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? const Color(0xFF0F5132)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestCard(Map<String, dynamic> item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(19),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(
                        item['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 13,
                            color: Color(0xFF34D399),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['distanceKm'] == null
                                ? 'Distance unavailable'
                                : '${item['distanceKm']} km away',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: Color(0xFF0F5132),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item['gradeBadge']?.toString() ??
                                'Verification pending',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                FadeTransition(
                                  opacity: _pulseAnimation,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34D399),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item['telemetryInfo']?.toString() ??
                                        'Telemetry unavailable',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item['timeAgo']?.toString() ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (item['scientificName'] != null)
                                Text(
                                  '(${item['scientificName']})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    item['farmerName'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '•',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['locationAxis'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: Color(0xFF0F5132),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${item['pricePerUnit']}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F5132),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'XAF/${item['unitType']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item['availableQuantity'].toInt()} ${item['unitType']} left',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ((item['inventoryPercent'] as num?) ?? 0.0)
                            .toDouble()
                            .clamp(0.0, 1.0)
                            .toDouble(),
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: const Color(0xFF1B8A53),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_shipping_outlined,
                                  size: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item['spec1']?.toString() ??
                                        'Pickup details unavailable',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item['spec2']?.toString() ??
                                        'Escrow details unavailable',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5132),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _openEscrowCheckoutModal(item),
                        icon: const Icon(Icons.verified_user_rounded, size: 18),
                        label: const Text(
                          'Order via Escrow',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
