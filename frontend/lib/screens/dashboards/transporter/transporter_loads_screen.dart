import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'dart:ui';

class TransporterLoadsScreen extends StatefulWidget {
  const TransporterLoadsScreen({super.key});

  @override
  State<TransporterLoadsScreen> createState() => _TransporterLoadsScreenState();
}

class _TransporterLoadsScreenState extends State<TransporterLoadsScreen> {
  static const _surface = Color(0xFF0b1326);
  static const _surfaceContainer = Color(0xFF171f33);
  static const _surfaceContainerHigh = Color(0xFF222a3d);
  static const _surfaceContainerLow = Color(0xFF131b2e);
  static const _primary = Color(0xFF4edea3);
  static const _tertiary = Color(0xFFffb95f);
  static const _secondary = Color(0xFF45dfa4);
  static const _onSurface = Color(0xFFdae2fd);
  static const _onSurfaceVariant = Color(0xFFbbcabf);

  int _selectedFilter = 0;
  bool _isLoading = true;
  List<dynamic> _quoteRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchQuoteRequests();
  }

  Future<void> _fetchQuoteRequests() async {
    try {
      final orders = await ApiService.getTransportQuoteRequests();
      if (mounted) {
        setState(() {
          _quoteRequests = orders;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quoteRequests = [];
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(user),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _primary))
        : RefreshIndicator(
            onRefresh: _fetchQuoteRequests,
            color: _primary,
            backgroundColor: _surfaceContainerHigh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTelemetryRibbon(user),
                  const SizedBox(height: 24),
                  _buildSearchAndCorridor(),
                  const SizedBox(height: 16),
                  _buildCategoryFilters(),
                  const SizedBox(height: 24),
                  ..._quoteRequests.map((load) => _buildLoadCard(load)).toList(),
                  const SizedBox(height: 16),
                  _buildDailyLedger(),
                  const SizedBox(height: 32),
                ],
              ),
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
                    'Loads',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _onSurface),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    user?.name ?? 'UNIT-740X',
                    style: const TextStyle(fontSize: 11, color: _onSurfaceVariant, fontFamily: 'Inter'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('•', style: TextStyle(fontSize: 10, color: Colors.white30)),
                  ),
                  const Text(
                    '42T SEMI',
                    style: TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.w600),
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
              Text('ONLINE', style: TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _buildTelemetryRibbon(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainer.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.rv_hookup, color: _primary, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'Jean-Paul Mbarga', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _onSurface)),
                          const Text('Unit #TR-408 • 12T Actros Reefer', style: TextStyle(fontSize: 11, color: _onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: _primary, size: 6),
                        SizedBox(width: 4),
                        Text('INGEST READY', style: TextStyle(color: _primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _surfaceContainerLow.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payload Free', style: TextStyle(fontSize: 11, color: _onSurfaceVariant)),
                              Text('70.8%', style: TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text.rich(
                            TextSpan(
                              text: '8,500 ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _onSurface),
                              children: [
                                TextSpan(text: '/ 12,000 kg', style: TextStyle(fontSize: 11, color: _onSurfaceVariant, fontWeight: FontWeight.normal)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: 0.292,
                            backgroundColor: const Color(0xFF2d3449),
                            valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
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
                        color: _surfaceContainerLow.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Reefer Diesel', style: TextStyle(fontSize: 11, color: _onSurfaceVariant)),
                              Text('Est. 410km', style: TextStyle(fontSize: 11, color: _tertiary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.local_gas_station, color: _tertiary, size: 16),
                              SizedBox(width: 4),
                              Text.rich(
                                TextSpan(
                                  text: '74% ',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _onSurface),
                                  children: [
                                    TextSpan(text: 'Tank', style: TextStyle(fontSize: 11, color: _onSurfaceVariant, fontWeight: FontWeight.normal)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: 0.74,
                            backgroundColor: const Color(0xFF2d3449),
                            valueColor: const AlwaysStoppedAnimation<Color>(_tertiary),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndCorridor() {
    return Column(
      children: [
        TextField(
          style: const TextStyle(color: _onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search load origin, destination, cargo...',
            hintStyle: TextStyle(color: _onSurfaceVariant.withOpacity(0.6), fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: _onSurfaceVariant),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune, color: _onSurfaceVariant, size: 18),
            ),
            filled: true,
            fillColor: _surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _surfaceContainerLow.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.alt_route, color: _secondary, size: 18),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACTIVE AXIS CORRIDOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _onSurfaceVariant, letterSpacing: 0.5)),
                    Text('RN4: Bafia ➔ Yaoundé ➔ Douala Port', style: TextStyle(fontSize: 12, color: _onSurface, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: _primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      children: [
                        Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    final filters = [
      {'label': 'All Loads', 'icon': null, 'count': '12', 'color': _primary},
      {'label': 'Reefer Cold-Chain', 'icon': Icons.ac_unit, 'count': '5', 'color': _primary},
      {'label': 'Bulk Dry', 'icon': Icons.grain, 'count': '4', 'color': _onSurface},
      {'label': 'Urgent (<2h)', 'icon': Icons.bolt, 'count': '3', 'color': _tertiary},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final filter = filters[index];
          final isActive = _selectedFilter == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = index),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? _primary : _surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isActive ? [BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 12)] : [],
                ),
                child: Row(
                  children: [
                    if (filter['icon'] != null) ...[
                      Icon(filter['icon'] as IconData, size: 16, color: isActive ? const Color(0xFF003824) : filter['color'] as Color),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      filter['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF003824) : _onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF003824).withOpacity(0.2) : const Color(0xFF060e20),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        filter['count'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? const Color(0xFF003824) : filter['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadCard(dynamic load) {
    bool isColdChain = load['type'].toString().contains('Cold');
    bool isExport = load['type'].toString().contains('Export');
    Color accentColor = isExport ? _tertiary : _primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(isColdChain ? Icons.ac_unit : (isExport ? Icons.anchor : Icons.local_shipping), size: 14, color: accentColor),
                        const SizedBox(width: 4),
                        Text(load['type'], style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2d3449),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(load['priority'], style: const TextStyle(color: _onSurfaceVariant, fontSize: 10)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      text: load['price'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: _tertiary, letterSpacing: -0.5),
                      children: const [
                        TextSpan(text: ' FCFA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Color(0xFFffb95f))),
                      ],
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.lock_clock, size: 12, color: _primary),
                      SizedBox(width: 4),
                      Text('Escrow Instant MoMo', style: TextStyle(fontSize: 10, color: Colors.white60)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/abstract_background_1.jpg',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(load['title'] ?? 'Product', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _onSurface)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.verified, size: 14, color: _primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${load['seller']}',
                            style: const TextStyle(fontSize: 12, color: _onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: accentColor),
                        const SizedBox(width: 4),
                        Text(load['pickup'] ?? '', style: TextStyle(fontSize: 11, color: accentColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 10, color: _primary),
                        const SizedBox(width: 8),
                        Text(load['origin'] ?? '', style: const TextStyle(fontSize: 12, color: _onSurface)),
                      ],
                    ),
                    const Text('Gate', style: TextStyle(fontSize: 11, color: _onSurfaceVariant)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                  child: Row(
                    children: [
                      Container(width: 2, height: 16, color: const Color(0xFF3c4a42).withOpacity(0.6)),
                      const SizedBox(width: 12),
                      Text(load['distance'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 10, color: Color(0xFF00bd85)),
                        const SizedBox(width: 8),
                        Text(load['destination'] ?? '', style: const TextStyle(fontSize: 12, color: _onSurface)),
                      ],
                    ),
                    const Text('Depot', style: TextStyle(fontSize: 11, color: _onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map, color: _onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Accepting Freight Contract...'),
                        backgroundColor: _primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: const Color(0xFF003824),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Accept Freight Contract', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLedger() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF060e20).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, color: _primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TODAY'S EARNINGS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _onSurfaceVariant, letterSpacing: 0.5)),
                  Text.rich(
                    TextSpan(
                      text: '148,500 ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _onSurface),
                      children: [
                        TextSpan(text: 'FCFA', style: TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.normal)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('COMPLETED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _onSurfaceVariant, letterSpacing: 0.5)),
                  Text.rich(
                    TextSpan(
                      text: '2 Hauls ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _onSurface),
                      children: [
                        TextSpan(text: '(184 km)', style: TextStyle(fontSize: 11, color: _onSurfaceVariant, fontWeight: FontWeight.normal)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_forward, size: 16, color: _onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
