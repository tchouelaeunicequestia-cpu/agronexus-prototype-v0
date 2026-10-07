import 'package:flutter/material.dart';
import 'package:frontend/screens/produce/add_produce_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/draft_service.dart';
import 'package:frontend/widgets/farmer_background_layer.dart';
import 'package:frontend/widgets/farmer_bottom_navigation.dart';

import 'farmer_dashboard.dart';
import 'farmer_escrow_screen.dart';
import 'farmer_telemetry_screen.dart';
import 'farmer_profile_screen.dart';

class FarmerListingsScreen extends StatefulWidget {
  const FarmerListingsScreen({super.key});

  @override
  State<FarmerListingsScreen> createState() => _FarmerListingsScreenState();
}

class _FarmerListingsScreenState extends State<FarmerListingsScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _drafts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getFarmerProducts(),
        DraftService.loadDrafts(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0];
        _drafts = results[1];
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openAddProduce() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProduceScreen()),
    );
    if (result == true || mounted) _loadListings();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredProducts = _products.where((product) {
      final matchesQuery =
          query.isEmpty ||
          product.values.any(
            (value) => value.toString().toLowerCase().contains(query),
          );
      return matchesQuery && (_filter == 'All' || _filter == 'Active');
    }).toList();
    final filteredDrafts = _drafts.where((draft) {
      final matchesQuery =
          query.isEmpty ||
          draft.values.any(
            (value) => value.toString().toLowerCase().contains(query),
          );
      return matchesQuery && (_filter == 'All' || _filter == 'Drafts');
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: FarmerBottomNavigation(
        selectedIndex: 1,
        onDestinationSelected: _navigateToFarmerTab,
      ),
      body: Stack(
        children: [
          const FarmerBackgroundLayer(),
          CustomScrollView(
            slivers: [
              _appBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 116),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _searchAndFilter(),
                    const SizedBox(height: 16),
                    _summaryCard(),
                    const SizedBox(height: 18),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            color: Color(0xFF0F5132),
                          ),
                        ),
                      )
                    else if (_errorMessage != null)
                      _messageCard(_errorMessage!)
                    else ...[
                      _sectionTitle(
                        'Published harvest lots',
                        filteredProducts.length,
                      ),
                      const SizedBox(height: 10),
                      if (filteredProducts.isEmpty)
                        _emptyCard(
                          'No active lots yet. Publish your first harvest lot.',
                        )
                      else
                        ...filteredProducts.map(_productCard),
                      if (filteredDrafts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _sectionTitle('Drafts', filteredDrafts.length),
                        const SizedBox(height: 10),
                        ...filteredDrafts.map((draft) => _draftCard(draft)),
                      ],
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToFarmerTab(int index) {
    if (index == 1) return;
    final Widget screen = switch (index) {
      0 => const FarmerDashboard(),
      2 => const AddProduceScreen(),
      3 => const FarmerEscrowScreen(),
      4 => const FarmerTelemetryScreen(),
      5 => const FarmerProfileScreen(),
      _ => const FarmerDashboard(),
    };
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _appBar() => SliverAppBar(
    pinned: true,
    backgroundColor: const Color(0xF2FFFFFF),
    foregroundColor: const Color(0xFF0F172A),
    title: const Text('My harvest lots'),
    actions: [
      IconButton(
        tooltip: 'Refresh listings',
        onPressed: _isLoading ? null : _loadListings,
        icon: const Icon(Icons.refresh_rounded),
      ),
      IconButton(
        tooltip: 'Open profile',
        onPressed: () => _navigateToFarmerTab(5),
        icon: const Icon(Icons.person_outline_rounded),
      ),
    ],
  );

  Widget _summaryCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFD7F3E3)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.inventory_2_rounded,
          color: Color(0xFF0F5132),
          size: 30,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${_products.length + _drafts.length} total items in your producer workspace',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _openAddProduce,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F5132),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _searchAndFilter() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Search batch ID, crop type, or sensor cluster',
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0F5132)),
          suffixIcon: IconButton(
            tooltip: 'Clear search',
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: const Icon(Icons.close, color: Color(0xFF64748B)),
          ),
          filled: true,
          fillColor: const Color(0xF2FFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        children: ['All', 'Active', 'Drafts']
            .map(
              (filter) => ChoiceChip(
                label: Text(filter),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
                selectedColor: const Color(0xFFEFFAF3),
                backgroundColor: const Color(0xF2FFFFFF),
                labelStyle: TextStyle(
                  color: _filter == filter
                      ? const Color(0xFF0F5132)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide.none,
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget _sectionTitle(String title, int count) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        '$count',
        style: const TextStyle(
          color: Color(0xFF0F5132),
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _productCard(Map<String, dynamic> product) => _listingCard(
    title: product['title']?.toString() ?? 'Produce lot',
    subtitle:
        '${product['availableQuantity']?.toString() ?? 'Unavailable'} ${product['unitType'] ?? ''} available',
    detail:
        '${product['pricePerUnit']?.toString() ?? 'Unavailable'} XAF / ${product['unitType'] ?? 'unit'}',
    status: 'ACTIVE',
    icon: Icons.eco_rounded,
  );

  Widget _draftCard(Map<String, dynamic> draft) => _listingCard(
    title: draft['title']?.toString() ?? 'Untitled draft',
    subtitle:
        '${draft['availableQuantity']?.toString() ?? 'Unavailable'} ${draft['unitType'] ?? ''} planned',
    detail:
        '${draft['pricePerUnit']?.toString() ?? 'Unavailable'} XAF / ${draft['unitType'] ?? 'unit'}',
    status: 'DRAFT',
    icon: Icons.edit_note_rounded,
    action: IconButton(
      tooltip: 'Delete draft',
      onPressed: () => _deleteDraft(draft['id']?.toString()),
      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54),
    ),
  );

  Future<void> _deleteDraft(String? draftId) async {
    if (draftId == null || draftId.isEmpty) return;
    await DraftService.deleteDraft(draftId);
    if (!mounted) return;
    setState(
      () => _drafts.removeWhere((draft) => draft['id']?.toString() == draftId),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Draft deleted.')));
  }

  Widget _listingCard({
    required String title,
    required String subtitle,
    required String detail,
    required String status,
    required IconData icon,
    Widget? action,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD7F3E3)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFEFFAF3),
          child: Icon(icon, color: const Color(0xFF0F5132)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              Text(
                detail,
                style: const TextStyle(
                  color: Color(0xFF0F5132),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        action ??
            Chip(
              label: Text(status),
              labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: status == 'ACTIVE'
                  ? const Color(0xFFEFFAF3)
                  : const Color(0xFFFFF7E6),
              side: BorderSide.none,
            ),
      ],
    ),
  );

  Widget _emptyCard(String message) =>
      _messageCard(message, icon: Icons.inventory_2_outlined);

  Widget _messageCard(
    String message, {
    IconData icon = Icons.error_outline_rounded,
  }) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD7F3E3)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF0F5132)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      ],
    ),
  );
}
