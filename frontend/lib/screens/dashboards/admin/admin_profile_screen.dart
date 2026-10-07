import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/services/auth_provider.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  static const _primary = Color(0xFF4edea3);
  static const _surface = Color(0xFF141F36);
  static const _text = Colors.white;
  static const _muted = Color(0xFF8B9BB4);

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

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
        : 'Admin Operator';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: const Color(0xFF0b1326),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0b1326).withValues(alpha: 0.92),
            foregroundColor: _text,
            elevation: 0,
            title: const Text(
              'Profile & Settings',
              style: TextStyle(color: _text, fontWeight: FontWeight.bold),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextButton.icon(
                  onPressed: () async {
                    await auth.logout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Logout'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFB4AB),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileHeader(name, initials, user?.email),
                const SizedBox(height: 24),
                _sectionTitle('System Account'),
                const SizedBox(height: 12),
                _settingsCard(
                  children: [
                    _settingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Personal information',
                      subtitle: 'Name, phone and email',
                      onTap: () => _showEditProfileDialog(context, user),
                    ),
                    _settingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Clearance Level',
                      subtitle: 'Role: ${user?.role ?? 'ADMIN'}',
                      onTap: () => _showInfoDialog(
                        context,
                        'Clearance Level',
                        'Account ID: ${user?.id ?? 'Unavailable'}\n\nSuper-admin access granted to monitor and control AgroNexus global operations.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('Preferences'),
                const SizedBox(height: 12),
                _settingsCard(
                  children: [
                    _settingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Alert Subscriptions',
                      subtitle: 'Manage system incident alerts',
                      onTap: () => _showUnavailableMessage(
                        context,
                        'Alert preferences are managed globally by the system configuration.',
                      ),
                    ),
                    _settingsTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () => _showUnavailableMessage(
                        context,
                        'Additional language options are not available yet.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle('Security & Audit'),
                const SizedBox(height: 12),
                _settingsCard(
                  children: [
                    _settingsTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometric Security',
                      subtitle: 'Protected when resuming your session',
                      onTap: () => _showInfoDialog(
                        context,
                        'Biometric Security',
                        'Your AgroNexus session uses the device authentication flow when supported.',
                      ),
                    ),
                    _settingsTile(
                      icon: Icons.history_rounded,
                      title: 'Audit Logs',
                      subtitle: 'View recent administrative actions',
                      onTap: () => _showUnavailableMessage(
                        context,
                        'Audit logs are currently viewable only via raw database queries.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFB4AB),
                    side: const BorderSide(color: Color(0xFF93000A)),
                    backgroundColor: const Color(0xFF410002).withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String initials, String? email) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: _surface,
                  child: Text(
                    initials.isEmpty ? 'A' : initials,
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email ?? 'Email unavailable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primary.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user, size: 12, color: _primary),
                          SizedBox(width: 4),
                          Text(
                            'SUPER ADMIN',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: _muted,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Icon(icon, color: _primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    UserProfile? user,
  ) async {
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
    final formKey = GlobalKey<FormState>();
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _surface,
          title: const Text('Personal information', style: TextStyle(color: _text)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: _text),
                    decoration: InputDecoration(
                      labelText: 'Full name',
                      labelStyle: const TextStyle(color: _muted),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _muted)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _primary)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your full name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user?.email ?? '',
                    readOnly: true,
                    style: const TextStyle(color: _muted),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      helperText: 'Email cannot be changed',
                      labelStyle: const TextStyle(color: _muted),
                      helperStyle: const TextStyle(color: _muted),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _muted)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _primary)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: _text),
                    decoration: InputDecoration(
                      labelText: 'Phone number',
                      labelStyle: const TextStyle(color: _muted),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _muted)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _primary)),
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
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: _muted)),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
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
                            backgroundColor: _primary,
                          ),
                        );
                      } catch (error) {
                        setDialogState(() => saving = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error.toString()),
                            backgroundColor: const Color(0xFFFFB4AB),
                          ),
                        );
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.black),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: Text(title, style: const TextStyle(color: _text)),
        content: Text(message, style: const TextStyle(color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: _primary)),
          ),
        ],
      ),
    );
  }

  void _showUnavailableMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: _text)),
      backgroundColor: _surface,
    ));
  }
}
