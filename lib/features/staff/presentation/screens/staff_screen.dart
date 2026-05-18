import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hamro_pasal/core/constants/app_constants.dart';

class StaffMember {
  final String id, userId, role, email, fullName;
  final bool isActive;
  const StaffMember(
      {required this.id,
      required this.userId,
      required this.role,
      required this.email,
      required this.fullName,
      required this.isActive});

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final profile = json['user_profiles'] as Map<String, dynamic>? ?? {};
    return StaffMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      email: profile['email'] as String? ?? '',
      fullName: profile['full_name'] as String? ?? 'Unknown',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

final staffProvider =
    AsyncNotifierProvider<StaffNotifier, List<StaffMember>>(() {
  return StaffNotifier();
});

class StaffNotifier extends AsyncNotifier<List<StaffMember>> {
  @override
  Future<List<StaffMember>> build() => _fetch();

  Future<List<StaffMember>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.kSelectedBusinessId);
    if (businessId == null) return [];

    final supabase = Supabase.instance.client;

    // Step 1: fetch members (no join — avoids PostgREST FK resolution error)
    final membersRes = await supabase
        .from('business_members')
        .select('id, user_id, role, is_active')
        .eq('business_id', businessId);

    final members = (membersRes as List).cast<Map<String, dynamic>>();
    if (members.isEmpty) return [];

    // Step 2: fetch profiles for each user_id (RLS allows own profile; others
    // return null gracefully — no exception thrown)
    final staffList = <StaffMember>[];
    for (final m in members) {
      final userId = m['user_id'] as String;
      String email = '';
      String fullName = '';
      try {
        final profile = await supabase
            .from('user_profiles')
            .select('email, full_name')
            .eq('id', userId)
            .maybeSingle();
        email = profile?['email'] as String? ?? '';
        fullName = profile?['full_name'] as String? ?? '';
      } catch (_) {}

      staffList.add(StaffMember(
        id: m['id'] as String,
        userId: userId,
        role: m['role'] as String,
        email: email,
        fullName: fullName.isEmpty ? 'Staff Member' : fullName,
        isActive: m['is_active'] as bool? ?? true,
      ));
    }
    return staffList;
  }
}

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  static const _roleColors = {
    'owner': AppTheme.primaryColor,
    'admin': AppTheme.infoColor,
    'manager': AppTheme.accentColor,
    'cashier': AppTheme.successColor,
    'accountant': AppTheme.warningColor,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          IconButton(
            onPressed: () => _showInviteDialog(context),
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invite Staff',
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (staff) {
          if (staff.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_outlined,
                      size: 56, color: AppTheme.lightTextHint),
                  const SizedBox(height: 16),
                  Text('No staff members yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Invite staff to help manage your business.',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showInviteDialog(context),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Invite Staff'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: staff.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final member = staff[i];
              final roleColor =
                  _roleColors[member.role] ?? AppTheme.primaryColor;
              final initials = member.fullName
                  .split(' ')
                  .take(2)
                  .map((w) => w.isNotEmpty ? w[0] : '')
                  .join()
                  .toUpperCase();
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkBorder
                          : Colors.white,
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {},
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              roleColor,
                              roleColor.withValues(alpha: 0.7)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                            child: Text(initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16))),
                      ),
                      title: Text(member.fullName,
                          style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text(member.email,
                          style: Theme.of(context).textTheme.bodySmall),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(member.role.toUpperCase(),
                                style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: member.isActive
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                    ),
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: i * 50))
                  .fadeIn()
                  .slideX(begin: 0.05, end: 0);
            },
          );
        },
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    String role = 'cashier';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Invite Staff Member'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Email Address'),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(hintText: 'staff@example.com'),
              ),
              const SizedBox(height: 16),
              const Text('Role'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: role,
                isExpanded: true,
                items: ['admin', 'manager', 'cashier', 'accountant']
                    .map((r) => DropdownMenuItem(
                        value: r, child: Text(r.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => role = v ?? role),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                // Send invitation email via Supabase Edge Function (pending implementation)
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Invitation sent! (placeholder)'),
                      behavior: SnackBarBehavior.floating),
                );
              },
              child: const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }
}
