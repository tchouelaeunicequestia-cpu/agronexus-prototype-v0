import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class BuyerAgroAIScreen extends StatefulWidget {
  const BuyerAgroAIScreen({super.key});

  @override
  State<BuyerAgroAIScreen> createState() => _BuyerAgroAIScreenState();
}

class _BuyerAgroAIScreenState extends State<BuyerAgroAIScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _attachTelemetry = false;
  bool _hasImageAttached = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _sendQuery(String prompt) async {
    if (prompt.trim().isEmpty || _isLoading) return;

    final originalPrompt = prompt.trim();
    var promptText = originalPrompt;
    if (_hasImageAttached) promptText = '[Crop image] $promptText';
    if (_attachTelemetry) promptText = '[IoT telemetry] $promptText';

    setState(() {
      _messages.add({'sender': 'user', 'text': promptText});
      _isLoading = true;
      _hasImageAttached = false;
      _attachTelemetry = false;
    });
    _queryController.clear();

    try {
      final response = await ApiService.queryAiAssistant(originalPrompt);
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text':
              response['answer'] ??
              response['response'] ??
              response['message'] ??
              'Advisory retrieved successfully.',
          'status': response['status'] ?? 'APPROVED',
        });
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text':
              'Unable to reach AgroAI right now. ${error.toString().replaceFirst('Exception: ', '')}',
          'status': 'ERROR',
        });
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            child: _buildAssistantCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AgroAI Assistant',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'RAG-powered agricultural intelligence',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Clear conversation',
            onPressed: _messages.isEmpty || _isLoading
                ? null
                : () => setState(() => _messages.clear()),
            icon: const Icon(Icons.refresh_rounded),
            color: const Color(0xFF475569),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: _messages.isEmpty ? _buildWelcomeState() : _buildMessages(),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: Color(0xFF7C3AED),
                backgroundColor: Color(0xFFEDE9FE),
              ),
            ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.psychology_alt_rounded,
                color: Color(0xFF7C3AED),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask AgroAI about your next decision',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get practical guidance on produce quality, storage, sourcing, and market preparation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message['sender'] == 'user';
        final isError = message['status'] == 'ERROR';
        final isRejected = message['status'] == 'REJECTED';
        final bubbleColor = isUser
            ? const Color(0xFF0F5132)
            : isError || isRejected
            ? const Color(0xFFFFF1F2)
            : const Color(0xFFF8FAFC);

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: Border.all(
                color: isUser
                    ? Colors.transparent
                    : isError || isRejected
                    ? const Color(0xFFFDA4AF)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              message['text'] ?? '',
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : isError || isRejected
                    ? const Color(0xFF9F1239)
                    : const Color(0xFF334155),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    final hasAttachment = _attachTelemetry || _hasImageAttached;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (hasAttachment)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file_rounded,
                    size: 16,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [
                        if (_attachTelemetry) 'IoT telemetry',
                        if (_hasImageAttached) 'crop image',
                      ].join(' + '),
                      style: const TextStyle(
                        color: Color(0xFF6D28D9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() {
                      _attachTelemetry = false;
                      _hasImageAttached = false;
                    }),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    color: const Color(0xFF6D28D9),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                tooltip: 'Attach crop photo',
                onPressed: _isLoading
                    ? null
                    : () => setState(
                        () => _hasImageAttached = !_hasImageAttached,
                      ),
                icon: Icon(
                  Icons.camera_alt_rounded,
                  color: _hasImageAttached
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF64748B),
                ),
              ),
              IconButton(
                tooltip: 'Attach live IoT telemetry',
                onPressed: _isLoading
                    ? null
                    : () =>
                          setState(() => _attachTelemetry = !_attachTelemetry),
                icon: Icon(
                  Icons.sensors_rounded,
                  color: _attachTelemetry
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _queryController,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendQuery,
                  decoration: InputDecoration(
                    hintText: 'Message AgroAI...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send message',
                onPressed: _isLoading
                    ? null
                    : () => _sendQuery(_queryController.text),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
