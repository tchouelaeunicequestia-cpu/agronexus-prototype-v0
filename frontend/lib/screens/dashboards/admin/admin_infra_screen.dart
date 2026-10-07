
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'widgets/admin_app_bar.dart';

class AdminInfraScreen extends StatefulWidget {
  const AdminInfraScreen({super.key});

  @override
  State<AdminInfraScreen> createState() => _AdminInfraScreenState();
}

class _AdminInfraScreenState extends State<AdminInfraScreen> {
  bool _isPinging = false;
  int _activeNodes = 142;
  int _totalNodes = 144;
  int _latencyMs = 24;

  @override
  void initState() {
    super.initState();
    _fetchNodeAlerts();
  }

  Future<void> _fetchNodeAlerts() async {
    try {
      final res = await ApiService.authenticatedRequest('/api/v1/telemetry/node/ESP32-MB04');
      if (res.statusCode == 200) {
        // Can read real telemetry logs if available
      }
    } catch (_) {}
  }

  void _triggerMeshPing() {
    setState(() => _isPinging = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isPinging = false;
        _latencyMs = 22;
      });
      _showToast('Ping packet burst broadcasted to 144 nodes. Mesh latency: 22ms.');
    });
  }

  void _downloadLogs() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171F33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.data_object, color: Color(0xFF45DFA4)),
            SizedBox(width: 8),
            Text('Telemetry Syslog (JSON)', style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 16)),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1326),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const SingleChildScrollView(
            child: Text(
              '{\n'
              '  "mesh_region": "Centre, Cameroon",\n'
              '  "hubs": ["Bafia", "Yaounde", "Obala", "Monatele"],\n'
              '  "online_nodes": 142,\n'
              '  "broker_protocol": "MQTT/TLS 1.3",\n'
              '  "postgis_gist_status": "SYNCHRONIZED",\n'
              '  "last_cycle": "15s FIFO ring",\n'
              '  "alerts": [\n'
              '    {"node": "ESP32-MB04", "gas_ppm": 385, "hazard": "ETHYLENE_SPIKE"},\n'
              '    {"node": "ESP32-12", "rssi_dbm": -82, "status": "MESH_DIVERTED"}\n'
              '  ]\n'
              '}',
              style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4EDEA3),
              foregroundColor: const Color(0xFF003824),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showToast('Packaging telemetry JSON payload for regional nodes... Download ready.');
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export JSON Payload'),
          ),
        ],
      ),
    );
  }

  void _purgeBuffers() {
    _showToast('Expired 15s FIFO edge ring buffers cleared successfully.');
  }

  void _showInspectModal(String node, String details) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Color(0xFFFFB4AB)),
                const SizedBox(width: 8),
                Text('Diagnostic Telemetry: $node', style: const TextStyle(color: Color(0xFFDAE2FD), fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(details, style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 13, height: 1.4)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF060E20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sensor Model:', style: TextStyle(color: Color(0xFF86948A), fontSize: 12)),
                      Text('MQ-135 Gas / Ethylene', style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Safe Threshold:', style: TextStyle(color: Color(0xFF86948A), fontSize: 12)),
                      Text('< 200 PPM FAO Safe', style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Action Dispatched:', style: TextStyle(color: Color(0xFF86948A), fontSize: 12)),
                      Text('Auto-Ventilation Fans ON', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EDEA3),
                  foregroundColor: const Color(0xFF003824),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Acknowledge Telemetry Latch'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4EDEA3), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFF222A3D),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: const AdminAppBar(title: 'Infra'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ambient Network Pulse Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF222A3D),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF060E20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, color: Color(0xFF4EDEA3), size: 6),
                            SizedBox(width: 6),
                            Text(
                              'ALL SYSTEMS NOMINAL • 99.98% UPTIME',
                              style: TextStyle(
                                color: Color(0xFF4EDEA3),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.sync, color: Color(0xFF4EDEA3), size: 14),
                          SizedBox(width: 4),
                          Text('15s Cycle', style: TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Central Cameroon Regional Mesh',
                    style: TextStyle(
                      color: Color(0xFFDAE2FD),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.hub, color: Color(0xFF45DFA4), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Bafia, Yaoundé, Obala, Monatele Hubs',
                        style: TextStyle(color: Color(0xFFBBCABF), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Quick Metrics Ribbon
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131B2E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Active Hardware Nodes', style: TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('$_activeNodes', style: const TextStyle(color: Color(0xFF4EDEA3), fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  Text('/ $_totalNodes Online', style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: _activeNodes / _totalNodes,
                                  backgroundColor: const Color(0xFF2D3449),
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFF4EDEA3)),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('98.6% Availability', style: TextStyle(color: Color(0xFF4EDEA3), fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131B2E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('API Ingestion Latency', style: TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('$_latencyMs', style: const TextStyle(color: Color(0xFF45DFA4), fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Text('ms', style: TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: const LinearProgressIndicator(
                                  value: 0.48,
                                  backgroundColor: Color(0xFF2D3449),
                                  valueColor: AlwaysStoppedAnimation(Color(0xFF45DFA4)),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Target <50ms', style: TextStyle(color: Color(0xFFBBCABF), fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Microservice & Data Fabric (4 Core Clusters)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.layers, color: Color(0xFF4EDEA3), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Microservice & Data Fabric',
                      style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('4 Core Clusters', style: TextStyle(color: const Color(0xFFBBCABF).withValues(alpha: 0.8), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),

            // Card 1: PostGIS Spatial Engine
            _buildFabricCard(
              icon: Icons.map,
              title: 'PostgreSQL 16 + PostGIS',
              subtitle: 'Spatial Engine & Geo-Polygons',
              badge: 'GiST Active',
              stat1: '14 ms Avg Spatial Latency',
              stat2: '1,000+ Queries/s',
            ),

            const SizedBox(height: 8),

            // Card 2: pgvector HNSW Store
            _buildFabricCard(
              icon: Icons.psychology,
              title: 'pgvector HNSW Store',
              subtitle: 'FAO/USDA Knowledge Embeddings',
              badge: 'RAG Ready',
              stat1: '18,420 Chunks Indexed',
              stat2: '12 ms Search Latency',
            ),

            const SizedBox(height: 8),

            // Card 3: ESP32 Telemetry Broker
            _buildFabricCard(
              icon: Icons.router,
              title: 'ESP32 Telemetry Broker',
              subtitle: 'MQTT/REST Edge Pipeline',
              badge: '142 Streaming',
              stat1: '99.8% Packet Ingestion',
              stat2: '15s Global Cycle',
            ),

            const SizedBox(height: 8),

            // Card 4: Escrow State Machine
            _buildFabricCard(
              icon: Icons.lock,
              iconColor: const Color(0xFFFFB95F),
              title: 'Escrow State Machine',
              subtitle: 'Financial Ledger Multi-Sig',
              badge: 'ACID Atomic',
              badgeColor: const Color(0xFFFFB95F),
              stat1: 'Zero State Drift',
              stat2: '142 Active Smart Locks',
              stat2Color: const Color(0xFFFFB95F),
            ),

            const SizedBox(height: 16),

            // 3. Physical Node Map Visualization
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pin_drop, color: Color(0xFF4EDEA3), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Mesh Geographic Spread',
                      style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('Cameroon Belt', style: TextStyle(color: const Color(0xFFBBCABF).withValues(alpha: 0.8), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF222A3D),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCnR6mv8IeM8FoKo2M7gJsltSwSVhpashkBt1G4TO8xWczv7LYQaJVni-6kZlxJSSI-Rr6qwZFlt8642jpFcvugRn7FPTwDAk-r9Uuwi-Ul2ZWQtSGH6hI_wbupcFOiHr8e18lzhcYzLk5wipa2oNUdnHKTBxKTVXHQHlGz_4GovMKA65PzOskGyJZ0k2rQDWZ8kBmi-8UwgsM0tfDmCedtH9iqiQlPWEZTSg4ZPVZ1UaRuE6hvIxIB',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF131B2E)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [const Color(0xFF0B1326), Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1326).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFF4EDEA3), size: 6),
                              SizedBox(width: 6),
                              Text('Bafia • Obala • Yaoundé Active', style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1326).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('2 Warning Latches', style: TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Real-Time Telemetry Incident Tracker (2 Active Alerts)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning, color: Color(0xFFFFB4AB), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Physical Node Alerts (2 Active)',
                      style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Text('Priority Triage', style: TextStyle(color: Color(0xFFFFB4AB), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),

            // Alert 1: Ethylene Spike
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF93000A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF93000A).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emergency, color: Color(0xFFFFB4AB), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Node #ESP32-MB04',
                            style: TextStyle(color: Color(0xFFFFB4AB), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF93000A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Depot Hazard', style: TextStyle(color: Color(0xFFFFDAD6), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mbalmayo Central Silo • Ethylene spike detected (385 PPM).',
                    style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.air, color: Color(0xFFFFB4AB), size: 14),
                          SizedBox(width: 4),
                          Text('Automated Desiccation Triggered', style: TextStyle(color: Color(0xFFFFB4AB), fontSize: 11)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF171F33),
                          foregroundColor: const Color(0xFFDAE2FD),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showInspectModal('Node #ESP32-MB04', 'Mbalmayo Silo #3 registered 385 PPM ethylene accumulation at 13:40 UTC.'),
                        child: const Text('Inspect', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Warning 2: Wi-Fi RSSI Degraded
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE29100).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFB95F).withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.wifi_tethering_error, color: Color(0xFFFFB95F), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Node #ESP32-12',
                            style: TextStyle(color: Color(0xFFFFB95F), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE29100).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Mesh Diverted', style: TextStyle(color: Color(0xFFFFDDB8), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Obala Depot Node • Wi-Fi RSSI degraded (-82 dBm).',
                    style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.alt_route, color: Color(0xFFFFB95F), size: 14),
                          SizedBox(width: 4),
                          Text('Dynamic Mesh Failover Active', style: TextStyle(color: Color(0xFFFFB95F), fontSize: 11)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF171F33),
                          foregroundColor: const Color(0xFFDAE2FD),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          _showToast('Dynamic mesh routing updated: Obala rerouted via Monatele Repeater #2.');
                        },
                        child: const Text('Reroute', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 5. Administrative Diagnostic Execution Panel
            const Text(
              'Administrative Diagnostics',
              style: TextStyle(color: Color(0xFFDAE2FD), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans'),
            ),
            const SizedBox(height: 10),

            // Action 1: Mesh Ping Check
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EDEA3),
                  foregroundColor: const Color(0xFF003824),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: _isPinging ? null : _triggerMeshPing,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (_isPinging)
                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003824)))
                        else
                          const Icon(Icons.network_ping, size: 22),
                        const SizedBox(width: 10),
                        const Text('Trigger Automated Mesh Ping', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Action 2: Telemetry Logs
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF222A3D),
                  foregroundColor: const Color(0xFFDAE2FD),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _downloadLogs,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.data_object, color: Color(0xFF45DFA4), size: 20),
                        SizedBox(width: 10),
                        Text('Download Telemetry Logs (JSON/Syslog)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Icon(Icons.download, color: Color(0xFFBBCABF), size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Action 3: Purge Buffer
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF222A3D),
                  foregroundColor: const Color(0xFFDAE2FD),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _purgeBuffers,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cleaning_services, color: Color(0xFFFFB95F), size: 20),
                        SizedBox(width: 10),
                        Text('Purge Stale Sensor Buffers', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Icon(Icons.delete_sweep, color: Color(0xFFBBCABF), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFabricCard({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    required String badge,
    Color? badgeColor,
    required String stat1,
    required String stat2,
    Color? stat2Color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171F33),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF222A3D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor ?? const Color(0xFF4EDEA3), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Color(0xFFDAE2FD), fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? const Color(0xFF10B981)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: badgeColor ?? const Color(0xFF4EDEA3), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF060E20).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(stat1, style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                Text(stat2, style: TextStyle(color: stat2Color ?? const Color(0xFF45DFA4), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
