// lib/screens/dashboards/admin/widgets/admin_user_card.dart
import 'package:flutter/material.dart';

class AdminUserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final Future<void> Function(int userId, String name, bool shouldApprove)
  onStatusChanged;

  const AdminUserCard({
    super.key,
    required this.user,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['fullName'] ?? user['name'] ?? 'Unnamed User';
    final email = user['email'] ?? 'No email';
    final role = user['role'] ?? 'FARMER';
    final isVerified = user['isVerified'] ?? false;
    final userId = user['id'] is int
        ? user['id']
        : int.tryParse(user['id'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.orange.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isVerified ? Colors.green : Colors.orange,
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isVerified
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isVerified ? 'VERIFIED' : 'PENDING VETTING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isVerified ? Colors.greenAccent : Colors.orangeAccent,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '$role • $email',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white70,
        ),
        onTap: () => _showVettingDetailsModal(
          context,
          userId,
          name,
          role,
          email,
          isVerified,
        ),
      ),
    );
  }

  void _showVettingDetailsModal(
    BuildContext context,
    int userId,
    String name,
    String role,
    String email,
    bool isVerified,
  ) {
    final phone = user['phoneNumber'] ?? user['phone'] ?? 'Not Provided';
    // Step 1 check: Reads the actual backend payload data correctly
    final nationalId = user['nationalId'] ?? 'Not Provided';
    final biometric = user['biometricVerified'] == true;
    final createdAt = user['createdAt']?.toString() ?? 'Recent';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      color: Color(0xFF6CF8BB),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Vetting Profile: $name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),

            Center(
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: biometric
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      biometric
                          ? Icons.verified_rounded
                          : Icons.pending_outlined,
                      size: 36,
                      color: biometric
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'National ID / CNI Document Scan',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      biometric
                          ? 'Biometric & Face Scan Verified Successfully'
                          : 'Biometric Scan Pending / Incomplete',
                      style: TextStyle(
                        color: biometric
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Registration Details',
              style: TextStyle(
                color: Color(0xFF6CF8BB),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            _detailRow('Full Name', name),
            _detailRow('Role', role),
            _detailRow('Email Address', email),
            _detailRow('Phone Number', phone.toString()),
            _detailRow('National ID (CNI)', nationalId.toString()),
            _detailRow(
              'Biometric Status',
              biometric ? 'Verified Hash Match' : 'Pending Scan',
            ),
            _detailRow('Registered Date', createdAt),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await onStatusChanged(userId, name, false);
                    },
                    child: const Text('De-approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16a34a),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await onStatusChanged(userId, name, true);
                    },
                    child: const Text('Approve & Notify'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
