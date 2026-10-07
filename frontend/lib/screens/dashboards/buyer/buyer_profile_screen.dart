import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/services/auth_provider.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  static const _green = Color(0xFF0F5132);
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

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
        : 'Buyer';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://img.freepik.com/premium-photo/agriculture-project-africa_943281-36244.jpg?w=2000',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF0F382C)),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white.withValues(alpha: 0.92),
                  foregroundColor: _text,
                  elevation: 0,
                  title: const Text(
                    'Profile & settings',
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
                          foregroundColor: Colors.red.shade700,
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
                      const SizedBox(height: 20),
                      _sectionTitle('Account'),
                      const SizedBox(height: 8),
                      _settingsCard(
                        children: [
                          _settingsTile(
                            icon: Icons.person_outline_rounded,
                            title: 'Personal information',
                            subtitle: 'Name, phone and email',
                            onTap: () => _showEditProfileDialog(context, user),
                          ),
                          _settingsTile(
                            icon: Icons.badge_outlined,
                            title: 'Buyer account',
                            subtitle: 'Role: ${user?.role ?? 'BUYER'}',
                            onTap: () => _showInfoDialog(
                              context,
                              'Buyer account',
                              'Account ID: ${user?.id ?? 'Unavailable'}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('Preferences'),
                      const SizedBox(height: 8),
                      _settingsCard(
                        children: [
                          _settingsTile(
                            icon: Icons.notifications_none_rounded,
                            title: 'Notifications',
                            subtitle: 'Manage marketplace updates',
                            onTap: () => _showUnavailableMessage(
                              context,
                              'Notification preferences are managed by the current account settings.',
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
                      const SizedBox(height: 20),
                      _sectionTitle('Security & support'),
                      const SizedBox(height: 8),
                      _settingsCard(
                        children: [
                          _settingsTile(
                            icon: Icons.fingerprint_rounded,
                            title: 'Biometric security',
                            subtitle: 'Protected when resuming your session',
                            onTap: () => _showInfoDialog(
                              context,
                              'Biometric security',
                              'Your AgroNexus session uses the device authentication flow when supported.',
                            ),
                          ),
                          _settingsTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & support',
                            subtitle: 'Get assistance with your account',
                            onTap: () => _showUnavailableMessage(
                              context,
                              'Support messaging is not available yet.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await auth.logout();
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade200),
                          backgroundColor: Colors.white.withValues(alpha: 0.92),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String initials, String? email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7F3E3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: _green,
            child: Text(
              initials.isEmpty ? 'B' : initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? 'Email unavailable',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFAF3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'BUYER ACCOUNT',
                    style: TextStyle(
                      color: _green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFFEFFAF3),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: _green, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(color: _text, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: _muted, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF94A3B8),
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
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
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
                          ),
                        );
                      } catch (error) {
                        setDialogState(() => saving = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
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

  void _showUnavailableMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
