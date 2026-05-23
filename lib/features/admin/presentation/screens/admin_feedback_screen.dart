import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _feedbacks = [];
  bool _loading = true;
  String _filter = 'all'; // all | pending | reviewed | resolved
  RealtimeChannel? _channel;

  static const _statusColors = {
    'pending':  AppTheme.warningColor,
    'reviewed': AppTheme.infoColor,
    'resolved': AppTheme.successColor,
  };

  static const _statusIcons = {
    'pending':  Icons.hourglass_empty_rounded,
    'reviewed': Icons.remove_red_eye_outlined,
    'resolved': Icons.check_circle_outline_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _loading = true);
    try {
      // Build filter first (PostgrestFilterBuilder), then order (PostgrestTransformBuilder)
      var q = _supabase
          .from('feedbacks')
          .select('*, user_profiles(full_name, email, phone)');

      final data = _filter == 'all'
          ? await q.order('created_at', ascending: false)
          : await q.eq('status', _filter).order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _feedbacks = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading feedback: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _subscribeRealtime() {
    _channel = _supabase
        .channel('admin-feedbacks')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'feedbacks',
          callback: (_) => _loadFeedbacks(),
        )
        .subscribe();
  }


  Future<void> _showDetailDialog(Map<String, dynamic> fb) async {
    final notesCtrl = TextEditingController(text: fb['admin_notes'] ?? '');
    String status = fb['status'] ?? 'pending';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      _StarRating(rating: (fb['rating'] as int? ?? 0)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fb['category'] ?? 'General',
                              style: const TextStyle(
                                color: AppTheme.primaryLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _formatDate(fb['created_at']),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white38),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // User info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            color: Colors.white38, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${(fb['user_profiles'] as Map?)?['full_name'] ?? 'Unknown'}'
                            ' • ${(fb['user_profiles'] as Map?)?['email'] ?? ''}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Message
                  Text('Message',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.darkBorder),
                    ),
                    child: Text(
                      fb['message'] ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status
                  Text('Status',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['pending', 'reviewed', 'resolved'].map((s) {
                      final isSelected = status == s;
                      final col = _statusColors[s]!;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setLocal(() => status = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? col.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected ? col : Colors.white24),
                            ),
                            child: Text(
                              s[0].toUpperCase() + s.substring(1),
                              style: TextStyle(
                                color: isSelected ? col : Colors.white38,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Admin notes
                  Text('Admin Notes',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add internal notes...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: AppTheme.darkSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppTheme.darkBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppTheme.darkBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryLight, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Save
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final updated = await _supabase.from('feedbacks').update({
                            'status': status,
                            'admin_notes': notesCtrl.text.trim(),
                            'updated_at': DateTime.now().toIso8601String(),
                          }).eq('id', fb['id']).select();

                          if (updated.isEmpty) {
                            throw Exception('RLS policy blocked the update or row not found.');
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadFeedbacks();
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Error saving: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> get _filtered => _filter == 'all'
      ? _feedbacks
      : _feedbacks.where((f) => f['status'] == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final pending = _feedbacks.where((f) => f['status'] == 'pending').length;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text('User Feedback',
                style: TextStyle(fontWeight: FontWeight.w700)),
            if (pending > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pending new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadFeedbacks,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in [
                    ('all', 'All', Icons.list_rounded),
                    ('pending', 'Pending', Icons.hourglass_empty_rounded),
                    ('reviewed', 'Reviewed', Icons.remove_red_eye_outlined),
                    ('resolved', 'Resolved', Icons.check_circle_outline_rounded),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _filter = f.$1);
                          _loadFeedbacks();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _filter == f.$1
                                ? AppTheme.primaryLight.withValues(alpha: 0.15)
                                : AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _filter == f.$1
                                  ? AppTheme.primaryLight
                                  : AppTheme.darkBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(f.$3,
                                  size: 14,
                                  color: _filter == f.$1
                                      ? AppTheme.primaryLight
                                      : Colors.white38),
                              const SizedBox(width: 6),
                              Text(
                                f.$2,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _filter == f.$1
                                      ? AppTheme.primaryLight
                                      : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryLight))
          : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.feedback_outlined,
                          size: 56, color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 12),
                      Text(
                        'No ${_filter == 'all' ? '' : '$_filter '}feedback yet',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final fb = _filtered[i];
                    final status = fb['status'] as String? ?? 'pending';
                    final statusColor = _statusColors[status] ?? Colors.white38;
                    final statusIcon = _statusIcons[status] ?? Icons.circle;
                    final profile = fb['user_profiles'] as Map?;

                    return GestureDetector(
                      onTap: () => _showDetailDialog(fb),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: status == 'pending'
                                ? AppTheme.warningColor.withValues(alpha: 0.3)
                                : AppTheme.darkBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _StarRating(
                                    rating: (fb['rating'] as int? ?? 0)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon,
                                          size: 11, color: statusColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        status[0].toUpperCase() +
                                            status.substring(1),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(fb['created_at'] as String?),
                                  style: const TextStyle(
                                      color: Colors.white24, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    color: Colors.white38, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  profile?['full_name'] ?? 'Unknown User',
                                  style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    fb['category'] ?? 'General',
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fb['message'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ).animate(delay: Duration(milliseconds: 30 * i))
                          .fadeIn()
                          .slideY(begin: 0.04, end: 0),
                    );
                  },
                ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: i < rating ? AppTheme.warningColor : Colors.white24,
        );
      }),
    );
  }
}
