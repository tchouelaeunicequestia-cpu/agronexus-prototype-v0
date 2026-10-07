import 'package:flutter/material.dart';

import 'agronomist_components.dart';

class AgronomistAdvisoryScreen extends StatelessWidget {
  const AgronomistAdvisoryScreen({
    required this.metrics,
    required this.nodes,
    required this.liveAlert,
    required this.isLoading,
    required this.metricsError,
    required this.nodesError,
    required this.onRefresh,
    required this.onOpenSilos,
    required this.onOpenGuides,
    super.key,
  });

  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> nodes;
  final Map<String, dynamic>? liveAlert;
  final bool isLoading;
  final String? metricsError;
  final String? nodesError;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenSilos;
  final VoidCallback onOpenGuides;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    color: AgronomistPalette.primary,
    backgroundColor: AgronomistPalette.surface,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        const AgronomistPageHeading(
          eyebrow: 'Agronomy operations',
          title: 'Advisory command hub',
          description: 'Review live storage telemetry, threshold alerts, and verified guidance.',
        ),
        const SizedBox(height: 18),
        if (isLoading) ...[
          const LinearProgressIndicator(
            color: AgronomistPalette.primary,
            backgroundColor: Color(0x553E5148),
          ),
          const SizedBox(height: 16),
        ],
        if (metricsError != null)
          _ErrorPanel(message: metricsError!, onRetry: onRefresh),
        if (metricsError != null) const SizedBox(height: 12),
        if (metricsError == null)
          Row(
            children: [
              Expanded(
                child: AgronomistMetricCard(
                  label: 'Threshold alerts recorded',
                  value: _metricValue(
                    metrics['triggeredAlerts'] ?? metrics['openAlerts'],
                  ),
                  icon: Icons.warning_amber_rounded,
                  accent: AgronomistPalette.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AgronomistMetricCard(
                  label: 'Reporting storage nodes',
                  value: _metricValue(
                    metrics['monitoredNodes'] ?? metrics['storageNodes'],
                  ),
                  icon: Icons.sensors_rounded,
                ),
              ),
            ],
          ),
        const SizedBox(height: 18),
        _liveAlertPanel(),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: AgronomistSectionTitle('Latest node readings'),
            ),
            TextButton(
              onPressed: onOpenSilos,
              child: const Text(
                'View silos',
                style: TextStyle(color: AgronomistPalette.primary),
              ),
            ),
          ],
        ),
        if (nodesError != null)
          _ErrorPanel(message: nodesError!, onRetry: onRefresh)
        else if (nodes.isEmpty && !isLoading)
          const AgronomistPanel(
            child: Text(
              'No sensor readings have been recorded yet. Nodes appear here after the backend receives telemetry.',
              style: TextStyle(
                color: AgronomistPalette.muted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          )
        else
          ...nodes.take(5).map(_nodeCard),
        const SizedBox(height: 20),
        AgronomistPanel(
          backgroundColor: AgronomistPalette.surfaceRaised,
          child: Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: AgronomistPalette.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Published agronomy guidance',
                      style: TextStyle(
                        color: AgronomistPalette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage sourced guides used to ground AgroAI answers.',
                      style: TextStyle(
                        color: AgronomistPalette.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Open guides',
                onPressed: onOpenGuides,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AgronomistPalette.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _liveAlertPanel() {
    final alert = liveAlert;
    final nodeId = alert?['nodeId']?.toString();
    final message = alert?['alertMessage']?.toString();

    return AgronomistPanel(
      backgroundColor: alert == null
          ? AgronomistPalette.surface
          : const Color(0xFF382126),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            alert == null ? Icons.sensors_rounded : Icons.crisis_alert_rounded,
            color: alert == null
                ? AgronomistPalette.primary
                : AgronomistPalette.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert == null ? 'Live alert stream' : 'Live threshold alert',
                  style: const TextStyle(
                    color: AgronomistPalette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert == null
                      ? 'Connected alerts will appear here when the backend emits one.'
                      : [
                          if (nodeId != null && nodeId.isNotEmpty) nodeId,
                          if (message != null && message.isNotEmpty) message,
                        ].join(' · '),
                  style: const TextStyle(
                    color: AgronomistPalette.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nodeCard(Map<String, dynamic> node) {
    final nodeId = node['nodeId']?.toString() ?? 'Unknown node';
    final alert = node['isAlertTriggered'] == true;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AgronomistPanel(
        padding: const EdgeInsets.all(14),
        backgroundColor: AgronomistPalette.surfaceRaised,
        child: Row(
          children: [
            Icon(
              alert ? Icons.warning_amber_rounded : Icons.grain_rounded,
              color: alert
                  ? AgronomistPalette.warning
                  : AgronomistPalette.primary,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node['storageFacilityName']?.toString().trim().isNotEmpty ==
                            true
                        ? node['storageFacilityName'].toString()
                        : nodeId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AgronomistPalette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temp ${_reading(node['temperature'], '°C')}  ·  '
                    'RH ${_reading(node['humidity'], '%')}  ·  '
                    'Gas ${node['gasLevel']?.toString() ?? '—'}',
                    style: const TextStyle(
                      color: AgronomistPalette.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    agronomistTimestamp(node['recordedAt']),
                    style: const TextStyle(
                      color: AgronomistPalette.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (alert)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.circle,
                  color: AgronomistPalette.error,
                  size: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _metricValue(Object? value) =>
      value == null ? '—' : value.toString();

  static String _reading(Object? value, String unit) {
    if (value is num) return '${value.toStringAsFixed(1)}$unit';
    if (value == null) return '—';
    return '$value$unit';
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => AgronomistPanel(
    backgroundColor: const Color(0xFF382126),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AgronomistPalette.error),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AgronomistPalette.text, fontSize: 12),
          ),
        ),
        IconButton(
          tooltip: 'Retry',
          onPressed: onRetry,
          icon: const Icon(
            Icons.refresh_rounded,
            color: AgronomistPalette.primary,
          ),
        ),
      ],
    ),
  );
}
