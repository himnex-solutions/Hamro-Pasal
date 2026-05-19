import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
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
    );
    if (!confirm) return;
    try {
      // Delete from user_profiles; auth.users cascade handled by DB trigger
      await _db.from('user_profiles').delete().eq('id', user['id']);
      await _fetchUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
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
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131929),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(controller: nameCtrl, label: 'Full Name', icon: Icons.person_outline),
            const SizedBox(height: 12),
            _DialogField(controller: phoneCtrl, label: 'Phone', icon: Icons.phone_outlined),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setStateSB) {
                return SwitchListTile(
                  title: const Text('Admin Access', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Grant admin portal access', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: isAdmin,
                  activeTrackColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  activeThumbColor: const Color(0xFFF59E0B),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setStateSB(() => isAdmin = val),
                );
              }
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
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
          const SnackBar(content: Text('User updated'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF131929),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            content: Text(message, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070C18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1525),
        elevation: 0,
        title: const Text('Users', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users by name or email…',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFF59E0B)),
                filled: true,
                fillColor: const Color(0xFF0E1525),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF59E0B)),
                ),
              ),
            ),
          ),

          // Table
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No users found', style: TextStyle(color: Colors.white38)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final u = _filtered[i];
                          return _UserRow(
                            user: u,
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

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserRow({required this.user, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAdmin = user['is_admin'] == true;
    String displayName = (user['full_name'] ?? user['email'] ?? '?').toString().trim();
    if (displayName.isEmpty) displayName = '?';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin
              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            child: Text(
              displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user['full_name'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('ADMIN', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
                Text(user['email'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                if (user['phone'] != null && (user['phone'] as String).isNotEmpty)
                  Text(user['phone'], style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6), size: 20),
            onPressed: onEdit,
            tooltip: 'Edit User',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
            onPressed: onDelete,
            tooltip: 'Delete User',
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _DialogField({required this.controller, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: const Color(0xFFF59E0B), size: 18),
        filled: true,
        fillColor: const Color(0xFF0A0F1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF59E0B))),
      ),
    );
  }
}
