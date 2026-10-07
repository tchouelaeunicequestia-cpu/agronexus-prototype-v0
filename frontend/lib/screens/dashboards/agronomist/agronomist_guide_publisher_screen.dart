import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import 'agronomist_components.dart';

class AgronomistGuidePublisherScreen extends StatefulWidget {
  const AgronomistGuidePublisherScreen({super.key});

  @override
  State<AgronomistGuidePublisherScreen> createState() =>
      _AgronomistGuidePublisherScreenState();
}

class _AgronomistGuidePublisherScreenState
    extends State<AgronomistGuidePublisherScreen> {
  List<Map<String, dynamic>> _guides = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  Future<void> _loadGuides() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final guides = await ApiService.getAgronomistGuides();
      if (mounted) setState(() => _guides = guides);
    } catch (error) {
      if (mounted) setState(() => _error = agronomistErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createGuide({
    required String title,
    required String sourceAgency,
    required String category,
    required String content,
  }) async {
    setState(() => _isSaving = true);
    try {
      await ApiService.saveAgronomistGuide(
        title: title,
        sourceAgency: sourceAgency,
        category: category,
        content: content,
      );
      await _loadGuides();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Guide saved as a draft.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(agronomistErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _publishGuide(Map<String, dynamic> guide) async {
    final id = int.tryParse(guide['id']?.toString() ?? '');
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This guide has no valid backend ID.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ApiService.publishAgronomistGuide(id);
      await _loadGuides();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Guide published. AgroAI can retrieve it using keyword matching.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(agronomistErrorMessage(error))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showCreateGuideDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final categoryController = TextEditingController();
    final contentController = TextEditingController();
    var agency = 'FAO';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AgronomistPalette.surface,
          title: const Text(
            'New extension guide',
            style: TextStyle(color: AgronomistPalette.text),
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _formField(
                      controller: titleController,
                      label: 'Guide title',
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: agency,
                      dropdownColor: AgronomistPalette.surfaceRaised,
                      style: const TextStyle(color: AgronomistPalette.text),
                      decoration: _inputDecoration('Source agency'),
                      items: const [
                        DropdownMenuItem(value: 'FAO', child: Text('FAO')),
                        DropdownMenuItem(value: 'USDA', child: Text('USDA')),
                        DropdownMenuItem(value: 'UNECE', child: Text('UNECE')),
                      ],
                      onChanged: (value) {
                        if (value != null) setDialogState(() => agency = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _formField(
                      controller: categoryController,
                      label: 'Topic or crop category',
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    _formField(
                      controller: contentController,
                      label: 'Guidance text',
                      validator: _required,
                      maxLines: 6,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Only publish guidance you are authorized to share. '
                      'Published text becomes available to AgroAI keyword retrieval.',
                      style: TextStyle(
                        color: AgronomistPalette.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(dialogContext);
                      await _createGuide(
                        title: titleController.text.trim(),
                        sourceAgency: agency,
                        category: categoryController.text.trim(),
                        content: contentController.text.trim(),
                      );
                    },
              child: const Text('Save draft'),
            ),
          ],
        ),
      ),
    );

    titleController.dispose();
    categoryController.dispose();
    contentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publishedCount = _guides
        .where((guide) => _status(guide) == 'PUBLISHED')
        .length;
    final draftCount = _guides
        .where((guide) => _status(guide) == 'DRAFT')
        .length;

    return RefreshIndicator(
      onRefresh: _loadGuides,
      color: AgronomistPalette.primary,
      backgroundColor: AgronomistPalette.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          const AgronomistPageHeading(
            eyebrow: 'Knowledge governance',
            title: 'Extension guide publisher',
            description: 'Save source-attributed guidance and publish it for AgroAI retrieval.',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AgronomistMetricCard(
                  label: 'Published guides',
                  value: publishedCount.toString(),
                  icon: Icons.menu_book_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AgronomistMetricCard(
                  label: 'Draft guides',
                  value: draftCount.toString(),
                  icon: Icons.edit_note_rounded,
                  accent: AgronomistPalette.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const AgronomistPanel(
            backgroundColor: AgronomistPalette.surfaceRaised,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AgronomistPalette.warning,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Guides are stored in the backend database. AgroAI uses '
                    'keyword retrieval; vector embeddings are not configured.',
                    style: TextStyle(
                      color: AgronomistPalette.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isSaving ? null : _showCreateGuideDialog,
            style: FilledButton.styleFrom(
              backgroundColor: AgronomistPalette.primary,
              foregroundColor: const Color(0xFF06311F),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Create guide draft'),
          ),
          const SizedBox(height: 20),
          const AgronomistSectionTitle('Guides from the backend'),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: AgronomistPalette.primary,
                ),
              ),
            )
          else if (_error != null)
            AgronomistPanel(
              backgroundColor: const Color(0xFF382126),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: AgronomistPalette.text),
                  ),
                  TextButton.icon(
                    onPressed: _loadGuides,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_guides.isEmpty)
            const AgronomistPanel(
              child: Text(
                'No guides are saved yet. Create a draft to begin.',
                style: TextStyle(color: AgronomistPalette.muted, fontSize: 13),
              ),
            )
          else
            ..._guides.map(_guideCard),
        ],
      ),
    );
  }

  Widget _guideCard(Map<String, dynamic> guide) {
    final isPublished = _status(guide) == 'PUBLISHED';
    final content = guide['content']?.toString() ?? '';
    final preview = content.length > 220
        ? '${content.substring(0, 220)}…'
        : content;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AgronomistPanel(
        backgroundColor: AgronomistPalette.surfaceRaised,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AgronomistPalette.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    guide['title']?.toString() ?? 'Untitled guide',
                    style: const TextStyle(
                      color: AgronomistPalette.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _statusBadge(isPublished ? 'PUBLISHED' : 'DRAFT'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${guide['sourceAgency'] ?? 'Source unavailable'}'
              ' · ${guide['category'] ?? 'Uncategorized'}',
              style: const TextStyle(
                color: AgronomistPalette.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              style: const TextStyle(
                color: AgronomistPalette.muted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            if (!isPublished) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _isSaving ? null : () => _publishGuide(guide),
                  style: FilledButton.styleFrom(
                    foregroundColor: AgronomistPalette.primary,
                    backgroundColor: AgronomistPalette.primary.withValues(
                      alpha: 0.12,
                    ),
                  ),
                  icon: const Icon(Icons.publish_rounded, size: 18),
                  label: const Text('Publish'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _status(Map<String, dynamic> guide) =>
      (guide['status']?.toString() ?? 'DRAFT').toUpperCase();

  static Widget _statusBadge(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: status == 'PUBLISHED'
          ? AgronomistPalette.primary.withValues(alpha: 0.14)
          : AgronomistPalette.warning.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: status == 'PUBLISHED'
            ? AgronomistPalette.primary
            : AgronomistPalette.warning,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  static InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AgronomistPalette.muted),
    filled: true,
    fillColor: AgronomistPalette.surfaceRaised,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  static Widget _formField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(color: AgronomistPalette.text),
    decoration: _inputDecoration(label),
    validator: validator,
  );
}
