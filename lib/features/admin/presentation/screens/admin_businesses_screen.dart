import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminBusinessesScreen extends StatefulWidget {
  const AdminBusinessesScreen({super.key});

  @override
  State<AdminBusinessesScreen> createState() => _AdminBusinessesScreenState();
}

class _AdminBusinessesScreenState extends State<AdminBusinessesScreen> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _businesses = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchBusinesses();
  }

  Future<void> _fetchBusinesses() async {
    setState(() => _loading = true);
    try {
      final res = await _db
          .from('businesses')
          .select(
              'id, name, type, address, phone, email, pan_number, currency, created_at, owner_id')
          .order('created_at', ascending: false);
      setState(() {
        _businesses = (res as List).cast<Map<String, dynamic>>();
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
    if (_search.isEmpty) return _businesses;
    final q = _search.toLowerCase();
    return _businesses.where((b) {
      final name = (b['name'] ?? '').toString().toLowerCase();
      final email = (b['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _deleteBusiness(Map<String, dynamic> biz) async {
    final confirm = await _showConfirmDialog(
      'Delete Business',
      'Delete "${biz['name']}"? All data (transactions, inventory, etc.) will be permanently removed.',
    );
    if (!confirm) return;
    try {
      await _db.from('businesses').delete().eq('id', biz['id']);
      await _fetchBusinesses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Business deleted'),
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

  Future<void> _editBusiness(Map<String, dynamic> biz) async {
    final nameCtrl = TextEditingController(text: biz['name'] ?? '');
    final phoneCtrl = TextEditingController(text: biz['phone'] ?? '');
    final emailCtrl = TextEditingController(text: biz['email'] ?? '');
    final addressCtrl = TextEditingController(text: biz['address'] ?? '');
    final panCtrl = TextEditingController(text: biz['pan_number'] ?? '');

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
                  'Edit Business',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
                const SizedBox(height: 20),
                _DialogField(
                    controller: nameCtrl,
                    label: 'Business Name',
                    icon: Icons.store_outlined),
                const SizedBox(height: 12),
                _DialogField(
                    controller: phoneCtrl,
                    label: 'Phone',
                    icon: Icons.phone_outlined),
                const SizedBox(height: 12),
                _DialogField(
                    controller: emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined),
                const SizedBox(height: 12),
                _DialogField(
                    controller: addressCtrl,
                    label: 'Address',
                    icon: Icons.location_on_outlined),
                const SizedBox(height: 12),
                _DialogField(
                    controller: panCtrl,
                    label: 'PAN Number',
                    icon: Icons.badge_outlined),
                const SizedBox(height: 24),
                // Single-row action buttons
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
      await _db.from('businesses').update({
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'pan_number': panCtrl.text.trim(),
      }).eq('id', biz['id']);
      await _fetchBusinesses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Business updated'),
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

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.darkCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
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
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Delete',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
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
          'Businesses',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: isCompact ? 15 : 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: _fetchBusinesses,
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
                hintText: 'Search businesses…',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.primaryLight),
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.darkBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.darkBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primaryLight)),
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
                        child: Text('No businesses found',
                            style: TextStyle(color: Colors.white38)))
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: pad),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final biz = _filtered[i];
                          return _BusinessCard(
                            biz: biz,
                            isCompact: isCompact,
                            onEdit: () => _editBusiness(biz),
                            onDelete: () => _deleteBusiness(biz),
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
// Business Card — adapts to narrow screens
// ─────────────────────────────────────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  final Map<String, dynamic> biz;
  final bool isCompact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BusinessCard({
    required this.biz,
    required this.isCompact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: isCompact ? 36 : 42,
      height: isCompact ? 36 : 42,
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.store_rounded,
          color: AppTheme.accentColor, size: isCompact ? 18 : 22),
    );

    final infoSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          biz['name'] ?? 'Unknown',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 13 : 14),
          overflow: TextOverflow.ellipsis,
        ),
        if (biz['email'] != null)
          Text(
            biz['email'],
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: isCompact ? 11 : 12),
            overflow: TextOverflow.ellipsis,
          ),
        Wrap(
          spacing: 6,
          children: [
            if (biz['type'] != null)
              _Tag(label: biz['type'], color: AppTheme.primaryLight),
            _Tag(
                label: biz['currency'] ?? 'NPR',
                color: AppTheme.successColor),
          ],
        ),
      ],
    );

    final actions = isCompact
        ? Column(
            children: [
              _ActionButton(
                  icon: FontAwesomeIcons.penToSquare,
                  color: AppTheme.primaryLight,
                  onTap: onEdit,
                  tooltip: 'Edit Business'),
              const SizedBox(height: 6),
              _ActionButton(
                  icon: FontAwesomeIcons.trashCan,
                  color: AppTheme.errorColor,
                  onTap: onDelete,
                  tooltip: 'Delete Business'),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                  icon: FontAwesomeIcons.penToSquare,
                  color: AppTheme.primaryLight,
                  onTap: onEdit,
                  tooltip: 'Edit Business'),
              const SizedBox(width: 8),
              _ActionButton(
                  icon: FontAwesomeIcons.trashCan,
                  color: AppTheme.errorColor,
                  onTap: onDelete,
                  tooltip: 'Delete Business'),
            ],
          );

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget,
          SizedBox(width: isCompact ? 10 : 12),
          Expanded(child: infoSection),
          SizedBox(width: isCompact ? 8 : 12),
          actions,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

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
            child: Center(child: FaIcon(icon, color: color, size: 14)),
          ),
        ),
      ),
    );
  }
}
