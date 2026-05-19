import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _subs = [];
  bool _loading = true;
  String _filter = 'all';
  RealtimeChannel? _realtimeChannel;

  static const _statusFilters = ['all', 'trial_active', 'active', 'trial_expired', 'expired'];

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _realtimeChannel = _db
        .channel('admin_subscriptions_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'subscriptions',
          callback: (payload) {
            // Re-fetch full data with joined business info on any change
            if (mounted) _fetchSubscriptions();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchSubscriptions() async {
    setState(() => _loading = true);
    try {
      // 1. Fetch subscriptions and businesses
      final res = await _db
          .from('subscriptions')
          .select(
              'id, business_id, status, trial_start_date, trial_end_date, subscription_start_date, subscription_end_date, is_trial_used, businesses(id, name, owner_id)')
          .order('created_at', ascending: false);
          
      final List<Map<String, dynamic>> subsData = (res as List).cast<Map<String, dynamic>>();
      
      // 2. Extract owner IDs
      final Set<String> ownerIds = {};
      for (var sub in subsData) {
        final bizData = sub['businesses'];
        if (bizData is List && bizData.isNotEmpty && bizData[0] != null) {
          final ownerId = bizData[0]['owner_id'];
          if (ownerId != null) ownerIds.add(ownerId.toString());
        } else if (bizData is Map && bizData['owner_id'] != null) {
          ownerIds.add(bizData['owner_id'].toString());
        }
      }
      
      // 3. Fetch user profiles for these owners
      Map<String, Map<String, dynamic>> userProfiles = {};
      if (ownerIds.isNotEmpty) {
        final profilesRes = await _db
            .from('user_profiles')
            .select('id, full_name, email, phone')
            .inFilter('id', ownerIds.toList());
            
        for (var p in (profilesRes as List)) {
          userProfiles[p['id'].toString()] = p as Map<String, dynamic>;
        }
      }
      
      // 4. Merge data
      for (var sub in subsData) {
        final bizData = sub['businesses'];
        Map<String, dynamic>? biz;
        if (bizData is List && bizData.isNotEmpty && bizData[0] != null) {
          biz = bizData[0] as Map<String, dynamic>;
        } else if (bizData is Map) {
          biz = bizData as Map<String, dynamic>;
        }
        
        if (biz != null && biz['owner_id'] != null) {
          final owner = userProfiles[biz['owner_id'].toString()];
          if (owner != null) {
            // Overwrite business name/email/phone with user_profile data if needed
            // Or just store it inside the business object for the UI to use
            biz['owner_name'] = owner['full_name'];
            biz['email'] = owner['email'];
            biz['phone'] = owner['phone'];
          }
        }
      }

      setState(() {
        _subs = subsData;
        _loading = false;
      });
    } catch (e, stack) {
      setState(() => _loading = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Debug Error'),
            content: SingleChildScrollView(child: Text('Error: $e\n\nStack: $stack', style: const TextStyle(fontSize: 12))),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _subs;
    return _subs.where((s) => s['status'] == _filter).toList();
  }

  Future<void> _extendSubscription(Map<String, dynamic> sub) async {
    final days = await _showExtendDialog();
    if (days == null || days <= 0) return;

    try {
      final now = DateTime.now();
      final currentEnd = sub['subscription_end_date'] != null
          ? DateTime.parse(sub['subscription_end_date'])
          : now;
      final baseDate = currentEnd.isAfter(now) ? currentEnd : now;
      final newEnd = baseDate.add(Duration(days: days));

      await _db.from('subscriptions').update({
        'status': 'active',
        'subscription_start_date':
            sub['subscription_start_date'] ?? now.toIso8601String(),
        'subscription_end_date': newEnd.toIso8601String(),
      }).eq('id', sub['id']);

      await _fetchSubscriptions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription extended by $days days until ${DateFormat('dd MMM yyyy').format(newEnd)}'),
            backgroundColor: const Color(0xFF10B981),
          ),
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

  Future<void> _extendTrial(Map<String, dynamic> sub) async {
    final days = await _showExtendDialog(title: 'Extend Trial');
    if (days == null || days <= 0) return;

    try {
      final now = DateTime.now();
      final currentEnd = sub['trial_end_date'] != null
          ? DateTime.parse(sub['trial_end_date'])
          : now;
      final baseDate = currentEnd.isAfter(now) ? currentEnd : now;
      final newEnd = baseDate.add(Duration(days: days));

      await _db.from('subscriptions').update({
        'status': 'trial_active',
        'trial_end_date': newEnd.toIso8601String(),
      }).eq('id', sub['id']);

      await _fetchSubscriptions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trial extended by $days days until ${DateFormat('dd MMM yyyy').format(newEnd)}'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
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



  Future<void> _deleteSubscription(String subId) async {
    try {
      await _db.from('subscriptions').delete().eq('id', subId);
      await _fetchSubscriptions();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription deleted'), backgroundColor: Color(0xFFEF4444)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
    }
  }

  Future<int?> _showExtendDialog({String title = 'Extend Subscription'}) async {
    final ctrl = TextEditingController(text: '30');
    return await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131929),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter number of days to extend:',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. 30',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                suffixText: 'days',
                suffixStyle: const TextStyle(color: Color(0xFFF59E0B)),
                filled: true,
                fillColor: const Color(0xFF0A0F1E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFF59E0B))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text) ?? 0),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
            child: const Text('Extend', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070C18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1525),
        elevation: 0,
        title: const Text('Subscriptions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: _fetchSubscriptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _statusFilters.map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.replaceAll('_', ' ').toUpperCase()),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: const Color(0xFFF59E0B),
                    backgroundColor: const Color(0xFF0E1525),
                    labelStyle: TextStyle(
                      color: selected ? Colors.black : Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFFF59E0B)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No subscriptions found',
                            style: TextStyle(color: Colors.white38)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final sub = _filtered[i];
                          return _SubRow(
                            sub: sub,
                            onExtend: () => _extendSubscription(sub),
                            onExtendTrial: () => _extendTrial(sub),
                            onDelete: () => _deleteSubscription(sub['id']),
                          ).animate().fadeIn(delay: (i * 30).ms);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SubRow extends StatelessWidget {
  final Map<String, dynamic> sub;
  final VoidCallback onExtend;
  final VoidCallback onExtendTrial;
  final VoidCallback onDelete;

  const _SubRow({
    required this.sub, 
    required this.onExtend, 
    required this.onExtendTrial,
    required this.onDelete,
  });

  Color _statusColor(String status) {
    return switch (status) {
      'trial_active' => const Color(0xFFF59E0B),
      'active' => const Color(0xFF10B981),
      'trial_expired' => const Color(0xFFEF4444),
      'expired' => const Color(0xFF6B7280),
      _ => const Color(0xFF6B7280),
    };
  }

  String _formatDate(String? dt) {
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy').format(DateTime.parse(dt).toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final status = sub['status'] ?? 'none';
    final color = _statusColor(status);
    final isTrial = status.contains('trial');
    
    // In PostgREST, embedded relations can be a Map or List. Safe extract:
    final bizData = sub['businesses'];
    Map<String, dynamic> biz = {};
    if (bizData is List && bizData.isNotEmpty && bizData[0] != null) {
      biz = bizData[0] as Map<String, dynamic>;
    } else if (bizData is Map) {
      biz = bizData as Map<String, dynamic>;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      biz['name']?.toString() ?? 'Unknown Business',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    if (biz['owner_name'] != null && biz['owner_name'].toString().isNotEmpty)
                      Text('Owner: ${biz['owner_name']}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    if (biz['email'] != null && biz['email'].toString().isNotEmpty)
                      Text(biz['email'].toString(),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                    if (biz['phone'] != null && biz['phone'].toString().isNotEmpty)
                      Text(biz['phone'].toString(),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Dates
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (sub['trial_start_date'] != null)
                _InfoChip(label: 'Trial Start', value: _formatDate(sub['trial_start_date'])),
              if (sub['trial_end_date'] != null)
                _InfoChip(label: 'Trial End', value: _formatDate(sub['trial_end_date'])),
              if (sub['subscription_start_date'] != null)
                _InfoChip(label: 'Sub Start', value: _formatDate(sub['subscription_start_date'])),
              if (sub['subscription_end_date'] != null)
                _InfoChip(label: 'Sub End', value: _formatDate(sub['subscription_end_date'])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: OutlinedButton.icon(
                  onPressed: onExtend,
                  icon: const Icon(Icons.card_membership_rounded, size: 14),
                  label: const Text('Extend Sub', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981), width: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isTrial)
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: onExtendTrial,
                    icon: const Icon(Icons.hourglass_top_rounded, size: 14),
                    label: const Text('Extend Trial', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B), width: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                onPressed: onDelete,
                tooltip: 'Delete Subscription',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
