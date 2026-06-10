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

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.darkCard,
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
                // Title
                const Text(
                  'Edit User',
                  style: TextStyle(
                      color: Colors.white,
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
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: SwitchListTile(
                      title: const Text('Admin Access',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: const Text('Grant admin portal access',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 11)),
                      value: isAdmin,
                      activeTrackColor:
                          AppTheme.primaryLight.withValues(alpha: 0.5),
                      activeThumbColor: AppTheme.primaryLight,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      onChanged: (val) => setStateSB(() => isAdmin = val),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons row
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
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24),
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
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.darkCard,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: const TextStyle(color: Colors.white70)),
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 420;
    final pad = isCompact ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: Text(
          'Users',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 15 : 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(pad),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users by name or email…',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.primaryLight),
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryLight),
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryLight))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No users found',
                            style: TextStyle(color: Colors.white38)))
                    : ListView.separated(
                        padding:
                            EdgeInsets.symmetric(horizontal: pad),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
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
// User Card — adapts to narrow screens
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
    final isAdmin = user['is_admin'] == true;
    String displayName =
        (user['full_name'] ?? user['email'] ?? '?').toString().trim();
    if (displayName.isEmpty) displayName = '?';

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin
              ? AppTheme.primaryLight.withValues(alpha: 0.4)
              : AppTheme.darkBorder,
        ),
      ),
      child: isCompact
          // ── Compact layout: avatar + info stacked, actions on right ─
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      AppTheme.primaryLight.withValues(alpha: 0.15),
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user['full_name'] ?? 'Unknown',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            _AdminBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user['phone'] != null &&
                          (user['phone'] as String).isNotEmpty)
                        Text(
                          user['phone'],
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    _ActionButton(
                        icon: Icons.edit_rounded,
                        color: AppTheme.primaryLight,
                        onTap: onEdit,
                        tooltip: 'Edit User'),
                    const SizedBox(height: 6),
                    _ActionButton(
                        icon: Icons.delete_rounded,
                        color: AppTheme.errorColor,
                        onTap: onDelete,
                        tooltip: 'Delete User'),
                  ],
                ),
              ],
            )
          // ── Normal layout: horizontal row ─────────────────────────
          : Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      AppTheme.primaryLight.withValues(alpha: 0.15),
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w700),
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
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            _AdminBadge(),
                          ],
                        ],
                      ),
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user['phone'] != null &&
                          (user['phone'] as String).isNotEmpty)
                        Text(
                          user['phone'],
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11),
                        ),
                    ],
                  ),
                ),
                _ActionButton(
                    icon: Icons.edit_rounded,
                    color: AppTheme.primaryLight,
                    onTap: onEdit,
                    tooltip: 'Edit User'),
                const SizedBox(width: 8),
                _ActionButton(
                    icon: Icons.delete_rounded,
                    color: AppTheme.errorColor,
                    onTap: onDelete,
                    tooltip: 'Delete User'),
              ],
            ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('ADMIN',
          style: TextStyle(
              color: AppTheme.primaryLight,
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
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: AppTheme.primaryLight, size: 18),
        filled: true,
        fillColor: AppTheme.darkSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.darkBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.darkBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primaryLight)),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Center(child: Icon(icon, color: color, size: 18)),
          ),
        ),
      ),
    );
  }
}
