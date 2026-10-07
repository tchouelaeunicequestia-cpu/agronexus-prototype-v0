import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/platform_services.dart';

class BuyerMarketplaceScreen extends StatefulWidget {
  const BuyerMarketplaceScreen({super.key});

  @override
  State<BuyerMarketplaceScreen> createState() => _BuyerMarketplaceScreenState();
}

class _BuyerMarketplaceScreenState extends State<BuyerMarketplaceScreen> {
  static const _surfaceCard = Color(0xF2FFFFFF);
  static const _primary = Color(0xFF0F5132);
  static const _muted = Color(0xFF64748B);
  static const _text = Color(0xFF0F172A);

  final _searchController = TextEditingController();
  final _categories = const [
    'All',
    'Plantains',
    'Cereals',
    'Tubers',
    'Vegetables',
    'Cocoa',
  ];
  List<Map<String, dynamic>> _products = [];
  Set<dynamic> _favorites = {};
  String _category = 'All';
  String _location = 'Bastos, Yaoundé';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMarketplace();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketplace() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    var latitude = 3.8480;
    var longitude = 11.5021;
    try {
      final position = await LocationServiceFactory.getService()
          .getCurrentLocation();
      latitude = position.latitude;
      longitude = position.longitude;
      _location = position.description;
    } catch (_) {
      // The API defaults keep discovery available when device location is unavailable.
    }
    try {
      final products = await ApiService.getNearbyProducts(
        lat: latitude,
        lon: longitude,
        radiusKm: 50,
      );
      if (!mounted) return;
      final favorites = await ApiService.getFavoriteProductIds();
      if (!mounted) return;
      setState(() {
        _products = products;
        _favorites = favorites;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(dynamic productId) async {
    if (productId == null) return;
    final wasFavorite = _favorites.contains(productId);
    final nextFavorites = {..._favorites};
    if (wasFavorite) {
      nextFavorites.remove(productId);
    } else {
      nextFavorites.add(productId);
    }
    setState(() => _favorites = nextFavorites);
    try {
      if (wasFavorite) {
        await ApiService.removeFavoriteProduct(productId);
      } else {
        await ApiService.addFavoriteProduct(productId);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (wasFavorite) {
          _favorites.add(productId);
        } else {
          _favorites.remove(productId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _products.where((product) {
      final category = product['category']?.toString().toLowerCase() ?? '';
      final title = product['title']?.toString().toLowerCase() ?? '';
      final matchesCategory =
          _category == 'All' ||
          category.contains(_category.toLowerCase().replaceAll('s', ''));
      return matchesCategory &&
          (query.isEmpty || title.contains(query) || category.contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
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
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                foregroundColor: _text,
                elevation: 0,
                titleSpacing: 16,
                title: Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: _primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Produce discovery',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Refresh marketplace',
                    onPressed: _loading ? null : _loadMarketplace,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: _loadMarketplace,
                color: _primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _buildTelemetryBanner(),
                    const SizedBox(height: 16),
                    _buildSearch(),
                    const SizedBox(height: 14),
                    _buildCategories(),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nearby harvest lots',
                          style: TextStyle(
                            color: _text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${products.length} available',
                          style: const TextStyle(color: _muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(color: _primary),
                        ),
                      )
                    else if (_error != null)
                      _buildMessage(
                        _error!,
                        Icons.error_outline_rounded,
                        Colors.orange,
                      )
                    else if (products.isEmpty)
                      _buildMessage(
                        'No produce lots match this discovery area and filter.',
                        Icons.inventory_2_outlined,
                        _muted,
                      )
                    else
                      ...products.map(_buildProductCard),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBanner() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFEFFAF3), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD7F3E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE DISCOVERY',
                style: TextStyle(
                  color: _primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Text(
            'Highland telemetry & escrow exchange',
            style: TextStyle(
              color: _text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: _muted, size: 15),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _location,
                  style: const TextStyle(color: _muted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: _text),
      decoration: InputDecoration(
        hintText: 'Search produce, category, or farm',
        hintStyle: const TextStyle(color: _muted),
        prefixIcon: const Icon(Icons.search_rounded, color: _muted),
        filled: true,
        fillColor: _surfaceCard,
        suffixIcon: IconButton(
          tooltip: 'Clear search',
          onPressed: _searchController.text.isEmpty
              ? null
              : () {
                  _searchController.clear();
                  setState(() {});
                },
          icon: const Icon(Icons.close_rounded, color: _muted),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final category = _categories[index];
          final selected = category == _category;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => setState(() => _category = category),
            selectedColor: _primary,
            backgroundColor: _surfaceCard,
            labelStyle: TextStyle(
              color: selected ? Colors.white : _text,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final id = product['id'];
    final favorite = _favorites.contains(id);
    final title = product['title']?.toString() ?? 'Produce harvest lot';
    final category = product['category']?.toString() ?? 'Produce';
    final quantity = product['availableQuantity'];
    final unit = product['unitType']?.toString() ?? 'kg';
    final price = product['pricePerUnit'];
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: _surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Favorite',
                  onPressed: () => _toggleFavorite(id),
                  icon: Icon(
                    favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: favorite ? Colors.redAccent : _muted,
                  ),
                ),
              ],
            ),
            Text(
              category,
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _detail(Icons.inventory_2_outlined, '${quantity ?? '—'} $unit'),
                const SizedBox(width: 18),
                _detail(Icons.payments_outlined, '${price ?? '—'} XAF/$unit'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: _primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Escrow lock available after checkout',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, product),
                  child: const Text('View lot'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _muted),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMessage(String message, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
