import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class BuyerTelemetryScreen extends StatefulWidget {
  const BuyerTelemetryScreen({super.key});

  @override
  State<BuyerTelemetryScreen> createState() => _BuyerTelemetryScreenState();
}

class _BuyerTelemetryScreenState extends State<BuyerTelemetryScreen> {
  final TextEditingController _nodeController = TextEditingController();
  List<Map<String, dynamic>> _readings = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nodeController.dispose();
    super.dispose();
  }

  Future<void> _loadTelemetry() async {
    final nodeId = _nodeController.text.trim();
    if (nodeId.isEmpty) {
      setState(
        () => _errorMessage = 'Enter a storage node ID to view telemetry.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final readings = await ApiService.getTelemetryNodeLogs(nodeId);
      if (!mounted) return;
      setState(() => _readings = readings);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _readings = [];
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? get _latestReading =>
      _readings.isEmpty ? null : _readings.first;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white.withValues(alpha: 0.92),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          title: const Text(
            'Telemetry',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh telemetry',
              onPressed: _isLoading || _nodeController.text.trim().isEmpty
                  ? null
                  : _loadTelemetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                'Storage telemetry',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inspect the latest readings from a linked storage node.',
                style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildNodeSearchCard(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _messageCard(
                  icon: Icons.info_outline_rounded,
                  message: _errorMessage!,
                  color: const Color(0xFFB45309),
                ),
              ],
              if (_latestReading != null) ...[
                const SizedBox(height: 20),
                _buildLatestReading(_latestReading!),
                const SizedBox(height: 20),
                const Text(
                  'Recent readings',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ..._readings.map(_buildReadingTile),
              ] else if (_errorMessage == null && !_isLoading) ...[
                const SizedBox(height: 30),
                _messageCard(
                  icon: Icons.sensors_off_rounded,
                  message: 'No node selected. Enter a node ID to load live environmental data.',
                  color: const Color(0xFF0F5132),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildNodeSearchCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _nodeController,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _loadTelemetry(),
        decoration: InputDecoration(
          labelText: 'Storage node ID',
          hintText: 'e.g. SILO-001',
          prefixIcon: const Icon(Icons.sensors_rounded),
          suffixIcon: IconButton(
            onPressed: _isLoading ? null : _loadTelemetry,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildLatestReading(Map<String, dynamic> reading) {
    final isAlert = reading['alertTriggered'] == true;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isAlert ? const Color(0xFFF59E0B) : const Color(0xFF6EE7B7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAlert ? Icons.warning_amber_rounded : Icons.verified_rounded,
                color: isAlert
                    ? const Color(0xFFB45309)
                    : const Color(0xFF047857),
              ),
              const SizedBox(width: 8),
              Text(
                isAlert ? 'Threshold alert' : 'Latest node status',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metricChip('Temperature', reading['temperature'], '°C'),
              _metricChip('Humidity', reading['humidity'], '%'),
              _metricChip('Gas level', reading['gasLevel'], ' ppm'),
            ],
          ),
          if (reading['alertMessage'] != null) ...[
            const SizedBox(height: 12),
            Text(
              reading['alertMessage'].toString(),
              style: const TextStyle(color: Color(0xFF92400E), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricChip(String label, dynamic value, String unit) {
    final displayValue = value == null ? 'Unavailable' : '$value$unit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTile(Map<String, dynamic> reading) {
    final timestamp = reading['recordedAt']?.toString();
    final isAlert = reading['alertTriggered'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          isAlert ? Icons.warning_amber_rounded : Icons.sensors_rounded,
          color: isAlert ? const Color(0xFFB45309) : const Color(0xFF0F5132),
        ),
        title: Text(
          '${reading['temperature'] ?? '—'}°C  ·  '
          '${reading['humidity'] ?? '—'}% RH',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Gas ${reading['gasLevel'] ?? '—'} ppm'
          '${timestamp == null ? '' : '  ·  $timestamp'}',
        ),
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
