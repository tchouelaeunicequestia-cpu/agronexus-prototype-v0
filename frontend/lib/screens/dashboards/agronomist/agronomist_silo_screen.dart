import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import 'agronomist_components.dart';

class AgronomistSiloScreen extends StatefulWidget {
  const AgronomistSiloScreen({required this.nodes, super.key});

  final List<Map<String, dynamic>> nodes;

  @override
  State<AgronomistSiloScreen> createState() => _AgronomistSiloScreenState();
}

class _AgronomistSiloScreenState extends State<AgronomistSiloScreen> {
  final _nodeIdController = TextEditingController();
  String? _selectedNodeId;
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _commands = [];
  bool _isLoadingLogs = false;
  bool _isLoadingCommands = true;
  bool _isSubmittingCommand = false;
  String? _logsError;
  String? _commandsError;

  @override
  void initState() {
    super.initState();
    _loadCommands();
  }

  @override
  void didUpdateWidget(covariant AgronomistSiloScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedNodeId == null && widget.nodes.isNotEmpty) {
      final nodeId = widget.nodes.first['nodeId']?.toString();
      if (nodeId != null && nodeId.isNotEmpty) {
        _selectedNodeId = nodeId;
        _nodeIdController.text = nodeId;
        _loadNodeLogs(nodeId);
      }
    }
  }

  @override
  void dispose() {
    _nodeIdController.dispose();
    super.dispose();
  }

  Future<void> _selectNode(String nodeId) async {
    _nodeIdController.text = nodeId;
    setState(() => _selectedNodeId = nodeId);
    await _loadNodeLogs(nodeId);
  }

  Future<void> _loadNodeLogs([String? requestedNodeId]) async {
    final nodeId = (requestedNodeId ?? _nodeIdController.text).trim();
    if (nodeId.isEmpty) {
      setState(() {
        _logs = [];
        _logsError = 'Enter a node ID or select a discovered node.';
      });
      return;
    }

    setState(() {
      _selectedNodeId = nodeId;
      _isLoadingLogs = true;
      _logsError = null;
    });
    try {
      final logs = await ApiService.getTelemetryNodeLogs(nodeId);
      if (!mounted) return;
      setState(() => _logs = logs);
    } catch (error) {
      if (!mounted) return;
      setState(() => _logsError = agronomistErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoadingLogs = false);
    }
  }

  Future<void> _loadCommands() async {
    setState(() {
      _isLoadingCommands = true;
      _commandsError = null;
    });
    try {
      final commands = await ApiService.getActuatorCommands();
      if (!mounted) return;
      setState(() => _commands = commands);
    } catch (error) {
      if (!mounted) return;
      setState(() => _commandsError = agronomistErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoadingCommands = false);
    }
  }

  Future<void> _queueCommand(String action) async {
    final nodeId = _selectedNodeId;
    if (nodeId == null || nodeId.isEmpty || _isSubmittingCommand) return;

    final actionLabel = action == 'AERATION_START'
        ? 'request aeration'
        : 'request UV decontamination';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Queue equipment request?'),
        content: Text(
          'This will save a $actionLabel for node $nodeId. '
          'No equipment will be switched on from this app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmittingCommand = true);
    try {
      await ApiService.createActuatorCommand(nodeId: nodeId, action: action);
      await _loadCommands();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request saved as pending. The equipment was not switched.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(agronomistErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isSubmittingCommand = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async {
      await Future.wait([
        _loadCommands(),
        if (_selectedNodeId != null) _loadNodeLogs(_selectedNodeId),
      ]);
    },
    color: AgronomistPalette.primary,
    backgroundColor: AgronomistPalette.surface,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const AgronomistPageHeading(
          eyebrow: 'Storage telemetry',
          title: 'Silo monitoring',
          description: 'Inspect sensor readings and queue equipment requests for a selected storage node.',
        ),
        const SizedBox(height: 18),
        if (widget.nodes.isNotEmpty) ...[
          const AgronomistSectionTitle('Discovered nodes'),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.nodes
                .map((node) => node['nodeId']?.toString())
                .whereType<String>()
                .where((id) => id.isNotEmpty)
                .map(
                  (id) => ChoiceChip(
                    label: Text(id),
                    selected: _selectedNodeId == id,
                    onSelected: (_) => _selectNode(id),
                    selectedColor: AgronomistPalette.primary.withValues(
                      alpha: 0.22,
                    ),
                    backgroundColor: AgronomistPalette.surfaceRaised,
                    labelStyle: const TextStyle(
                      color: AgronomistPalette.text,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _selectedNodeId == id
                          ? AgronomistPalette.primary
                          : AgronomistPalette.border,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        AgronomistPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AgronomistSectionTitle('Find a node'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nodeIdController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _loadNodeLogs(),
                      style: const TextStyle(color: AgronomistPalette.text),
                      decoration: InputDecoration(
                        hintText: 'Enter a real telemetry node ID',
                        hintStyle: const TextStyle(
                          color: AgronomistPalette.muted,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AgronomistPalette.surfaceRaised,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Load node readings',
                    onPressed: _isLoadingLogs ? null : _loadNodeLogs,
                    style: IconButton.styleFrom(
                      backgroundColor: AgronomistPalette.primary,
                      foregroundColor: const Color(0xFF06311F),
                    ),
                    icon: _isLoadingLogs
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_logsError != null)
          _NoticePanel(
            icon: Icons.error_outline_rounded,
            color: AgronomistPalette.error,
            message: _logsError!,
          )
        else if (_selectedNodeId == null)
          const _NoticePanel(
            icon: Icons.sensors_rounded,
            color: AgronomistPalette.muted,
            message: 'No telemetry node has been discovered yet. Enter a node ID to check whether the backend has readings for it.',
          )
        else if (!_isLoadingLogs && _logs.isEmpty)
          _NoticePanel(
            icon: Icons.sensors_off_rounded,
            color: AgronomistPalette.warning,
            message: 'No readings are available for $_selectedNodeId.',
          )
        else if (_logs.isNotEmpty) ...[
          _latestReading(_logs.first),
          const SizedBox(height: 18),
          const AgronomistSectionTitle('Recent telemetry'),
          const SizedBox(height: 8),
          ..._logs.map(_readingCard),
          const SizedBox(height: 18),
          _equipmentControls(),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: AgronomistSectionTitle('Saved equipment requests'),
            ),
            IconButton(
              tooltip: 'Refresh requests',
              onPressed: _loadCommands,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AgronomistPalette.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const _NoticePanel(
          icon: Icons.info_outline_rounded,
          color: AgronomistPalette.warning,
          message: 'Requests are stored for future device integration. They do not operate equipment yet.',
        ),
        if (_commandsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _NoticePanel(
              icon: Icons.error_outline_rounded,
              color: AgronomistPalette.error,
              message: _commandsError!,
            ),
          )
        else if (_isLoadingCommands)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AgronomistPalette.primary,
              ),
            ),
          )
        else if (_commands.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: _NoticePanel(
              icon: Icons.inbox_outlined,
              color: AgronomistPalette.muted,
              message: 'No equipment requests have been saved.',
            ),
          )
        else
          ..._commands.map(_commandCard),
      ],
    ),
  );

  Widget _latestReading(Map<String, dynamic> reading) {
    final alert = reading['isAlertTriggered'] == true;
    return AgronomistPanel(
      backgroundColor: alert
          ? const Color(0xFF382126)
          : AgronomistPalette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reading['storageFacilityName']?.toString() ??
                      reading['nodeId']?.toString() ??
                      _selectedNodeId!,
                  style: const TextStyle(
                    color: AgronomistPalette.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (alert)
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AgronomistPalette.error,
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Latest reading · ${agronomistTimestamp(reading['recordedAt'])}',
            style: const TextStyle(
              color: AgronomistPalette.muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _readingMetric(
                'Temperature',
                _formatReading(reading['temperature'], '°C'),
                Icons.thermostat_rounded,
              ),
              _readingMetric(
                'Humidity',
                _formatReading(reading['humidity'], '%'),
                Icons.water_drop_outlined,
              ),
              _readingMetric(
                'Gas level',
                reading['gasLevel']?.toString() ?? '—',
                Icons.air_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _readingMetric(String label, String value, IconData icon) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AgronomistPalette.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AgronomistPalette.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AgronomistPalette.muted, fontSize: 10),
        ),
      ],
    ),
  );

  Widget _readingCard(Map<String, dynamic> reading) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: AgronomistPanel(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      backgroundColor: AgronomistPalette.surfaceRaised,
      child: Row(
        children: [
          Icon(
            reading['isAlertTriggered'] == true
                ? Icons.warning_amber_rounded
                : Icons.monitor_heart_outlined,
            color: reading['isAlertTriggered'] == true
                ? AgronomistPalette.warning
                : AgronomistPalette.primary,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_formatReading(reading['temperature'], '°C')} · '
              '${_formatReading(reading['humidity'], '%')} RH · '
              'Gas ${reading['gasLevel']?.toString() ?? '—'}',
              style: const TextStyle(
                color: AgronomistPalette.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            agronomistTimestamp(reading['recordedAt']),
            style: const TextStyle(color: AgronomistPalette.muted, fontSize: 9),
          ),
        ],
      ),
    ),
  );

  Widget _equipmentControls() => AgronomistPanel(
    backgroundColor: AgronomistPalette.surfaceRaised,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AgronomistSectionTitle('Equipment requests'),
        const SizedBox(height: 6),
        const Text(
          'Save a pending request for a future hardware adapter. '
          'Neither action will switch equipment now.',
          style: TextStyle(
            color: AgronomistPalette.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isSubmittingCommand
                    ? null
                    : () => _queueCommand('AERATION_START'),
                style: FilledButton.styleFrom(
                  backgroundColor: AgronomistPalette.primary,
                  foregroundColor: const Color(0xFF07321F),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.air_rounded, size: 18),
                label: const Text('Queue aeration'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmittingCommand
                    ? null
                    : () => _queueCommand('UV_DECONTAMINATION'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AgronomistPalette.text,
                  side: const BorderSide(color: AgronomistPalette.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.wb_twilight_rounded, size: 18),
                label: const Text('Queue UV'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _commandCard(Map<String, dynamic> command) {
    final action = command['action']?.toString() ?? 'Equipment request';
    final isAeration = action == 'AERATION_START';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AgronomistPanel(
        padding: const EdgeInsets.all(13),
        backgroundColor: AgronomistPalette.surfaceRaised,
        child: Row(
          children: [
            Icon(
              isAeration ? Icons.air_rounded : Icons.wb_twilight_rounded,
              color: AgronomistPalette.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isAeration ? 'Aeration' : 'UV'} · '
                    '${command['nodeId'] ?? 'Node unavailable'}',
                    style: const TextStyle(
                      color: AgronomistPalette.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${command['status'] ?? 'PENDING_DEVICE'} · '
                    '${agronomistTimestamp(command['createdAt'])}',
                    style: const TextStyle(
                      color: AgronomistPalette.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatReading(Object? value, String unit) {
    if (value is num) return '${value.toStringAsFixed(1)}$unit';
    if (value == null) return '—';
    return '$value$unit';
  }
}

class _NoticePanel extends StatelessWidget {
  const _NoticePanel({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) => AgronomistPanel(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AgronomistPalette.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
