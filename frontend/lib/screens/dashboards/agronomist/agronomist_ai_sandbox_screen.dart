import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import 'agronomist_components.dart';

class AgronomistAiSandboxScreen extends StatefulWidget {
  const AgronomistAiSandboxScreen({super.key});

  @override
  State<AgronomistAiSandboxScreen> createState() =>
      _AgronomistAiSandboxScreenState();
}

class _AgronomistAiSandboxScreenState extends State<AgronomistAiSandboxScreen> {
  final _queryController = TextEditingController();
  Map<String, dynamic>? _response;
  String? _error;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _submitQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isSubmitting) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _error = null;
      _response = null;
    });
    try {
      final response = await ApiService.queryAiAssistant(query);
      if (mounted) setState(() => _response = response);
    } catch (error) {
      if (mounted) setState(() => _error = agronomistErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
    children: [
      const AgronomistPageHeading(
        eyebrow: 'Knowledge governance',
        title: 'Grounded RAG query sandbox',
        description: 'Test agricultural questions against published Agronomist guides. Responses are limited to retrieved backend sources.',
      ),
      const SizedBox(height: 18),
      const AgronomistPanel(
        backgroundColor: AgronomistPalette.surfaceRaised,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_rounded, color: AgronomistPalette.primary),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agricultural domain guardrails',
                    style: TextStyle(
                      color: AgronomistPalette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Out-of-domain questions are rejected. Relevant published guide text and its source are returned; no vector search or generative model is configured.',
                    style: TextStyle(
                      color: AgronomistPalette.muted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      AgronomistPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: AgronomistPalette.primary,
                  size: 19,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Query published agronomy guidance',
                    style: TextStyle(
                      color: AgronomistPalette.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _queryController,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                color: AgronomistPalette.text,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Ask an agricultural question that matches a published guide…',
                hintStyle: const TextStyle(
                  color: AgronomistPalette.muted,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: AgronomistPalette.surfaceRaised,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitQuery,
                style: FilledButton.styleFrom(
                  backgroundColor: AgronomistPalette.primary,
                  foregroundColor: const Color(0xFF06311F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF06311F),
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(_isSubmitting ? 'Searching sources…' : 'Run query'),
              ),
            ),
          ],
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 14),
        _resultPanel(
          title: 'Query failed',
          body: _error!,
          icon: Icons.error_outline_rounded,
          accent: AgronomistPalette.error,
        ),
      ],
      if (_response != null) ...[
        const SizedBox(height: 14),
        _buildResponse(_response!),
      ],
    ],
  );

  Widget _buildResponse(Map<String, dynamic> response) {
    final status = response['status']?.toString() ?? 'UNKNOWN';
    final citation = response['citation']?.toString();
    final answer = response['answer']?.toString() ?? 'No response content.';
    final groundingMode = response['groundingMode']?.toString();
    final isApproved = status.toUpperCase() == 'APPROVED';
    final isRejected = status.toUpperCase() == 'REJECTED';
    final accent = isApproved
        ? AgronomistPalette.primary
        : AgronomistPalette.warning;

    return AgronomistPanel(
      backgroundColor: isRejected
          ? const Color(0xFF382126)
          : AgronomistPalette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isApproved
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: isRejected ? AgronomistPalette.error : accent,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Backend query result',
                  style: TextStyle(
                    color: AgronomistPalette.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            answer,
            style: const TextStyle(
              color: AgronomistPalette.text,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          if (citation != null && citation.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: AgronomistPalette.border, height: 1),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AgronomistPalette.primary,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    citation,
                    style: const TextStyle(
                      color: AgronomistPalette.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (groundingMode != null && groundingMode.isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              'Retrieval: $groundingMode',
              style: const TextStyle(
                color: AgronomistPalette.muted,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultPanel({
    required String title,
    required String body,
    required IconData icon,
    required Color accent,
  }) => AgronomistPanel(
    backgroundColor: const Color(0xFF382126),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AgronomistPalette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: AgronomistPalette.muted,
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
