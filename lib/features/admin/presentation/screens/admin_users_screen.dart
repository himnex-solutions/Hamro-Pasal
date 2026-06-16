import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final res = await _db
          .from('user_profiles')
          .select('id, email, full_name, phone, created_at, is_admin')
          .order('created_at', ascending: false);
      setState(() {
        _users = (res as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users.where((u) {
      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await _showConfirmDialog(
      'Delete User',
      'Are you sure you want to delete ${user['full_name'] ?? user['email']}? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppTheme.errorColor,
    );
    if (!confirm) return;
    try {
      await _db.from('user_profiles').delete().eq('id', user['id']);
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User deleted'),
              backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    bool isAdmin = user['is_admin'] == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit User',
                  style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
                const SizedBox(height: 20),
                _DialogField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline),
                const SizedBox(height: 12),
                _DialogField(
                    controller: phoneCtrl,
                    label: 'Phone',
                    icon: Icons.phone_outlined),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setStateSB) => Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder),
                    ),
                    child: SwitchListTile(
                      title: Text('Admin Access',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.lightTextPrimary,
                              fontSize: 14)),
                      subtitle: Text('Grant admin portal access',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : AppTheme.lightTextSecondary,
                              fontSize: 11)),
                      value: isAdmin,
                      activeTrackColor:
                          (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                              .withValues(alpha: 0.5),
                      activeThumbColor:
                          isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      onChanged: (val) => setStateSB(() => isAdmin = val),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                        ),
                        child: const Text('Save',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white54
                              : AppTheme.lightTextSecondary,
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : AppTheme.lightBorder),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != true) return;
    try {
      await _db.from('user_profiles').update({
        'full_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'is_admin': isAdmin,
      }).eq('id', user['id']);
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User updated'),
              backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(
    String title,
    String message, {
    String confirmLabel = 'Confirm',
    Color confirmColor = AppTheme.errorColor,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(title,
                style: TextStyle(
                    color:
                        isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : AppTheme.lightTextSecondary)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(confirmLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white54
                              : AppTheme.lightTextSecondary,
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : AppTheme.lightBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 420;
    final pad = isCompact ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        elevation: 0,
        title: Text(
          'Users',
          style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 15 : 17),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: isDark ? Colors.white54 : AppTheme.lightTextSecondary),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(pad),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary),
              decoration: InputDecoration(
                hintText: 'Search users by name or email…',
                hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppTheme.lightTextHint),
                prefixIcon: Icon(Icons.search,
                    color: isDark
                        ? AppTheme.primaryLight
                        : AppTheme.primaryColor),
                filled: true,
                fillColor:
                    isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor),
                ),
              ),
            ),
          ),

          // ── User list ──────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                        color: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primaryColor))
                : _filtered.isEmpty
                    ? Center(
                        child: Text('No users found',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : AppTheme.lightTextHint)))
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final u = _filtered[i];
                          return _UserCard(
                            user: u,
                            isCompact: isCompact,
                            onEdit: () => _editUser(u),
                            onDelete: () => _deleteUser(u),
                          ).animate().fadeIn(delay: (i * 30).ms);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Card
// ─────────────────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isCompact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.isCompact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = user['is_admin'] == true;
    String displayName =
        (user['full_name'] ?? user['email'] ?? '?').toString().trim();
    if (displayName.isEmpty) displayName = '?';

    final primaryAccentColor =
        isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin
              ? primaryAccentColor.withValues(alpha: 0.4)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User info row ────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryAccentColor.withValues(alpha: 0.15),
                child: Text(
                  displayName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: primaryAccentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user['full_name'] ?? 'Unknown',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.lightTextPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          _AdminBadge(),
                        ],
                      ],
                    ),
                    Text(
                      user['email'] ?? '',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppTheme.lightTextSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user['phone'] != null &&
                        (user['phone'] as String).isNotEmpty)
                      Text(
                        user['phone'],
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : AppTheme.lightTextHint,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Action buttons — always side by side ─────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text(
                    'Edit',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryAccentColor,
                    side: BorderSide(
                        color: primaryAccentColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor:
                        primaryAccentColor.withValues(alpha: 0.06),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded, size: 14),
                  label: const Text(
                    'Delete',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: BorderSide(
                        color: AppTheme.errorColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor:
                        AppTheme.errorColor.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Badge
// ─────────────────────────────────────────────────────────────────────────────

class _AdminBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccentColor =
        isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: primaryAccentColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('ADMIN',
          style: TextStyle(
              color: primaryAccentColor,
              fontSize: 9,
              fontWeight: FontWeight.w800)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _DialogField(
      {required this.controller, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      style: TextStyle(
          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.lightTextSecondary),
        prefixIcon: Icon(icon,
            color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
            size: 18),
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color:
                    isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color:
                    isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: isDark
                    ? AppTheme.primaryLight
                    : AppTheme.primaryColor)),
      ),
    );
  }
}
