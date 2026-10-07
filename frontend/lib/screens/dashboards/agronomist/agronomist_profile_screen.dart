import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_provider.dart';
import 'agronomist_components.dart';

class AgronomistProfileScreen extends StatefulWidget {
  const AgronomistProfileScreen({super.key});

  @override
  State<AgronomistProfileScreen> createState() =>
      _AgronomistProfileScreenState();
}

class _AgronomistProfileScreenState extends State<AgronomistProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final name = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : 'Agronomist';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const AgronomistPageHeading(
          eyebrow: 'Account',
          title: 'Profile & settings',
          description:
              'Manage your Agronomist account and personal information.',
        ),
        const SizedBox(height: 18),
        AgronomistPanel(
          child: Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: AgronomistPalette.primary,
                child: Text(
                  initials.isEmpty ? 'A' : initials,
                  style: const TextStyle(
                    color: Color(0xFF06311F),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AgronomistPalette.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'Email unavailable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AgronomistPalette.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _roleBadge(user?.role ?? 'AGRONOMIST'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const AgronomistSectionTitle('Account'),
        const SizedBox(height: 9),
        _settingsPanel([
          _settingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal information',
            subtitle: 'Name, phone number, and email',
            onTap: () => _showEditProfileDialog(user),
          ),
          _settingsTile(
            icon: Icons.badge_outlined,
            title: 'Agronomist account',
            subtitle: 'Role: ${user?.role ?? 'AGRONOMIST'}',
            onTap: () => _showInformation(
              'Account details',
              'Account ID: ${user?.id ?? 'Unavailable'}',
            ),
          ),
        ]),
        const SizedBox(height: 20),
        const AgronomistSectionTitle('Preferences'),
        const SizedBox(height: 9),
        _settingsPanel([
          _settingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Live sensor alert stream',
            onTap: () => _showInformation(
              'Telemetry notifications',
              'Critical alerts are shown in the Advisory tab while the backend telemetry stream is connected.',
            ),
          ),
          _settingsTile(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: 'English',
            onTap: () => _showMessage(
              'Additional language preferences are not available yet.',
            ),
          ),
        ]),
        const SizedBox(height: 20),
        const AgronomistSectionTitle('Security & support'),
        const SizedBox(height: 9),
        _settingsPanel([
          _settingsTile(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric security',
            subtitle: 'Device authentication when resuming your session',
            onTap: () => _showInformation(
              'Biometric security',
              'Your AgroNexus session uses the device authentication flow when supported.',
            ),
          ),
          _settingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & support',
            subtitle: 'Get assistance with your account',
            onTap: () =>
                _showMessage('Support messaging is not available yet.'),
          ),
        ]),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () => auth.logout(),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFA6A0),
            side: const BorderSide(color: Color(0xFF8B4545)),
            backgroundColor: AgronomistPalette.surface.withValues(alpha: 0.92),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }

  Widget _settingsPanel(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: AgronomistPalette.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AgronomistPalette.border.withValues(alpha: 0.6),
      ),
    ),
    child: Column(children: children),
  );

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => ListTile(
    onTap: onTap,
    leading: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AgronomistPalette.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: AgronomistPalette.primary, size: 21),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: AgronomistPalette.text,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: AgronomistPalette.muted, fontSize: 11),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: AgronomistPalette.muted,
    ),
  );

  Widget _roleBadge(String role) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AgronomistPalette.primary.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      '$role ACCOUNT',
      style: const TextStyle(
        color: AgronomistPalette.primary,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    ),
  );

  Future<void> _showEditProfileDialog(UserProfile? user) async {
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Personal information'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your full name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user?.email ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      helperText: 'Email cannot be changed',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your phone number'
                        : null,
                  ),
                ],
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
                      setDialogState(() => _isSaving = true);
                      try {
                        await context
                            .read<AuthProvider>()
                            .updateCurrentUserProfile(
                              fullName: _nameController.text.trim(),
                              phoneNumber: _phoneController.text.trim(),
                            );
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully.'),
                          ),
                        );
                      } catch (error) {
                        setDialogState(() => _isSaving = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(agronomistErrorMessage(error)),
                          ),
                        );
                      } finally {
                        if (mounted) setDialogState(() => _isSaving = false);
                      }
                    },
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInformation(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
