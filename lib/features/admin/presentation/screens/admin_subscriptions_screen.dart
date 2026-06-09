import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> {
  final _db = Supabase.instance.client;
  bool _loading = true;
  int _activeTabIndex = 0; // 0: Overview, 1: Payments, 2: Users, 3: Features

  // Cache keys
  static const String _kAdminOverviewCacheKey = 'cached_admin_overview';
  static const String _kAdminSubsCacheKey = 'cached_admin_subs';
  static const String _kAdminPaymentsCacheKey = 'cached_admin_payments';

  // State Lists
  List<Map<String, dynamic>> _subs = [];
  List<Map<String, dynamic>> _paymentRequests = [];
  List<Map<String, dynamic>> _businessesList = [];
  
  // Overview data variables
  int _totalSubscribers = 0;
  int _activePlansCount = 0;
  int _expiredPlansCount = 0;
  double _totalRevenue = 0.0;
  Map<String, int> _planDistribution = {'basic': 0, 'gold': 0, 'diamond': 0};

  // Filter variables
  String _paymentPlanFilter = 'all'; // all, gold, diamond
  String _userStatusFilter = 'all'; // all, active, suspended, expired
  String _userSearchQuery = '';
  final _searchController = TextEditingController();

  // Feature control variables
  String _selectedPlanCode = 'basic'; // basic, gold, diamond
  int _maxStaffCtrl = 0;
  int _maxBizCtrl = 1;
  List<Map<String, dynamic>> _planPermissions = [];

  // Database list of plans
  final List<String> _planCodes = ['basic', 'gold', 'diamond'];


  @override
  void initState() {
    super.initState();
    _loadAllFromCache();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Overview Cache
      final overviewStr = prefs.getString(_kAdminOverviewCacheKey);
      if (overviewStr != null) {
        final data = jsonDecode(overviewStr) as Map<String, dynamic>;
        setState(() {
          _totalSubscribers = data['totalSubscribers'] ?? 0;
          _activePlansCount = data['activePlansCount'] ?? 0;
          _expiredPlansCount = data['expiredPlansCount'] ?? 0;
          _totalRevenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
          _planDistribution = Map<String, int>.from(data['planDistribution'] ?? {});
        });
      }

      // Load Subs Cache
      final subsStr = prefs.getString(_kAdminSubsCacheKey);
      if (subsStr != null) {
        setState(() {
          _subs = (jsonDecode(subsStr) as List).cast<Map<String, dynamic>>();
        });
      }

      // Load Payments Cache
      final paymentsStr = prefs.getString(_kAdminPaymentsCacheKey);
      if (paymentsStr != null) {
        setState(() {
          _paymentRequests = (jsonDecode(paymentsStr) as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveAllToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final overviewData = {
        'totalSubscribers': _totalSubscribers,
        'activePlansCount': _activePlansCount,
        'expiredPlansCount': _expiredPlansCount,
        'totalRevenue': _totalRevenue,
        'planDistribution': _planDistribution,
      };
      
      await prefs.setString(_kAdminOverviewCacheKey, jsonEncode(overviewData));
      await prefs.setString(_kAdminSubsCacheKey, jsonEncode(_subs));
      await prefs.setString(_kAdminPaymentsCacheKey, jsonEncode(_paymentRequests));
    } catch (_) {}
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      // 1. Fetch user subscriptions & profiles
      final subsRes = await _db
          .from('user_subscriptions')
          .select('user_id, plan_code, start_date, expiry_date, status, payment_status, approved_by, approved_at, user_profiles:user_profiles!user_subscriptions_user_id_fkey(id, full_name, email, phone)')
          .order('updated_at', ascending: false);

      final List<Map<String, dynamic>> subsData = (subsRes as List).map((e) {
        final map = e as Map<String, dynamic>;
        final profile = map['user_profiles'];
        if (profile is List && profile.isNotEmpty) {
          map['user'] = profile[0];
        } else if (profile is Map) {
          map['user'] = profile;
        }
        return map;
      }).toList();

      // 2. Fetch businesses list to link in memory
      final bizRes = await _db.from('businesses').select('id, name, owner_id');
      final List<Map<String, dynamic>> businessesData = (bizRes as List).cast<Map<String, dynamic>>();

      // 3. Fetch payment requests
      final paymentsRes = await _db
          .from('payment_requests')
          .select('id, user_id, plan_code, amount, screenshot_url, status, rejection_reason, created_at, user_profiles(id, full_name, email, phone)')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> paymentsData = (paymentsRes as List).map((e) {
        final map = e as Map<String, dynamic>;
        final profile = map['user_profiles'];
        if (profile is List && profile.isNotEmpty) {
          map['user'] = profile[0];
        } else if (profile is Map) {
          map['user'] = profile;
        }
        return map;
      }).toList();

      // 4. Calculate dashboard metrics
      _totalSubscribers = subsData.length;
      _activePlansCount = subsData.where((s) {
        final statusActive = s['status'] == 'active';
        final expiry = s['expiry_date'];
        if (!statusActive) return false;
        if (expiry == null) return true;
        return DateTime.parse(expiry).isAfter(DateTime.now());
      }).length;
      
      _expiredPlansCount = subsData.where((s) {
        final expiry = s['expiry_date'];
        if (s['status'] == 'expired') return true;
        if (expiry == null) return false;
        return DateTime.parse(expiry).isBefore(DateTime.now());
      }).length;

      // Revenue: sum of amount from approved payment requests
      _totalRevenue = paymentsData
          .where((p) => p['status'] == 'approved')
          .fold<double>(0.0, (sum, p) => sum + (double.tryParse(p['amount'].toString()) ?? 0.0));

      // Plan distribution counts
      int basicC = 0, goldC = 0, diamondC = 0;
      for (var sub in subsData) {
        final code = sub['plan_code'] as String? ?? 'basic';
        if (code == 'basic') basicC++;
        if (code == 'gold') goldC++;
        if (code == 'diamond') diamondC++;
      }

      setState(() {
        _subs = subsData;
        _paymentRequests = paymentsData;
        _businessesList = businessesData;
        _planDistribution = {'basic': basicC, 'gold': goldC, 'diamond': diamondC};
        _loading = false;
      });

      // Save updated data to cache
      await _saveAllToCache();
      
      if (_activeTabIndex == 3) {
        await _fetchFeatureControlData();
      }
    } catch (e) {
      debugPrint('Error fetching subscription data: $e');
      setState(() => _loading = false);
      // If offline or query fails, load cached data and alert user
      await _loadAllFromCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ── Feature Control Data Loading ─────────────────────────────────
  
  Future<void> _fetchFeatureControlData() async {
    try {
      final permsList = (await _db.from('feature_permissions').select().eq('plan_code', _selectedPlanCode) as List).cast<Map<String, dynamic>>();
      final staffLimitMap = await _db.from('staff_limits').select().eq('plan_code', _selectedPlanCode).maybeSingle();
      final bizLimitMap = await _db.from('business_limits').select().eq('plan_code', _selectedPlanCode).maybeSingle();


      setState(() {
        _planPermissions = permsList;
        _maxStaffCtrl = staffLimitMap?['max_staff'] as int? ?? 0;
        _maxBizCtrl = bizLimitMap?['max_businesses'] as int? ?? 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load features: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _saveFeatureControl() async {
    setState(() => _loading = true);
    try {
      // 1. Upsert staff limit
      await _db.from('staff_limits').upsert({
        'plan_code': _selectedPlanCode,
        'max_staff': _maxStaffCtrl,
      }, onConflict: 'plan_code');

      // 2. Upsert business limit
      await _db.from('business_limits').upsert({
        'plan_code': _selectedPlanCode,
        'max_businesses': _maxBizCtrl,
      }, onConflict: 'plan_code');

      // 3. Upsert feature permissions
      for (var perm in _planPermissions) {
        await _db.from('feature_permissions').upsert({
          'plan_code': _selectedPlanCode,
          'feature_name': perm['feature_name'],
          'is_allowed': perm['is_allowed'],
        }, onConflict: 'plan_code, feature_name');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully updated settings for ${_selectedPlanCode.toUpperCase()}!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
      await _fetchData();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  // ── Approval / Rejection flow ─────────────────────────────────────

  Future<void> _approvePayment(Map<String, dynamic> req) async {
    try {
      final userId = req['user_id'];
      final planCode = req['plan_code'];
      final reqId = req['id'];
      final adminId = _db.auth.currentUser?.id;
      final expiryDate = DateTime.now().add(const Duration(days: 365));

      // 1. Update user_subscriptions
      await _db.from('user_subscriptions').upsert({
        'user_id': userId,
        'plan_code': planCode,
        'status': 'active',
        'payment_status': 'completed',
        'start_date': DateTime.now().toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'approved_by': adminId,
        'approved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      // 2. Mark payment request as approved
      await _db.from('payment_requests').update({
        'status': 'approved',
      }).eq('id', reqId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment approved! Notification triggered to user device.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _rejectPayment(Map<String, dynamic> req) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Payment Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Provide a reason for rejection:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. screenshot is blur / payment not received.',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: AppTheme.darkSurface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.darkBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.errorColor)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final reason = reasonCtrl.text.trim();
      if (reason.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rejection reason is required'), backgroundColor: AppTheme.errorColor),
          );
        }
        return;
      }

      try {
        await _db.from('payment_requests').update({
          'status': 'rejected',
          'rejection_reason': reason,
        }).eq('id', req['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment request rejected. User notified.'), backgroundColor: AppTheme.errorColor),
          );
          _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rejection failed: $e'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  // ── Manage User Subscription Modal ────────────────────────────────

  void _showManageSubscriptionDialog(Map<String, dynamic> sub) {
    String currentPlan = sub['plan_code'] ?? 'basic';
    String currentStatus = sub['status'] ?? 'active';
    DateTime? currentExpiry = sub['expiry_date'] != null ? DateTime.parse(sub['expiry_date']) : null;
    
    final daysCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Manage User Subscription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Selection
                const Text('Upgrade / Downgrade Plan:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: AppTheme.darkCard,
                      value: currentPlan,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      items: _planCodes.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.toUpperCase()),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => currentPlan = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status Selection
                const Text('Subscription Status:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: AppTheme.darkCard,
                      value: currentStatus,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      items: ['active', 'suspended', 'expired'].map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.toUpperCase()),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => currentStatus = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Expiry Date Selection
                Text(
                  'Expiry Date: ${currentExpiry != null ? DateFormat('dd MMM yyyy').format(currentExpiry!) : "Lifetime (Basic)"}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: currentExpiry ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null) {
                            setDialogState(() => currentExpiry = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_month, size: 14),
                        label: const Text('Pick Date', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkSurface,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: daysCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: '+ Days (e.g. 30)',
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 11),
                          filled: true,
                          fillColor: AppTheme.darkSurface,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (val) {
                          final d = int.tryParse(val) ?? 0;
                          if (d > 0) {
                            final base = currentExpiry ?? DateTime.now();
                            setDialogState(() => currentExpiry = base.add(Duration(days: d)));
                            daysCtrl.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _loading = true);
                try {
                  final userId = sub['user_id'];
                  await _db.from('user_subscriptions').upsert({
                    'user_id': userId,
                    'plan_code': currentPlan,
                    'status': currentStatus,
                    'expiry_date': currentExpiry?.toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  }, onConflict: 'user_id');

                  _fetchData();
                } catch (e) {
                  setState(() => _loading = true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update subscription: $e'), backgroundColor: AppTheme.errorColor),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showScreenshotDialog(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        final screenH = MediaQuery.sizeOf(context).height;
        return Dialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: screenH * 0.88,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, color: AppTheme.primaryLight, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Payment Proof Receipt',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 22),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 20),

                  // ── Image (fills available space) ────────
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ColoredBox(
                        color: Colors.black45,
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 6.0,
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            headers: const {'Cache-Control': 'no-cache'},
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              final pct = progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null;
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      value: pct,
                                      color: AppTheme.primaryLight,
                                      strokeWidth: 2.5,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      pct != null
                                          ? 'Loading ${(pct * 100).toStringAsFixed(0)}%'
                                          : 'Loading image…',
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.image_not_supported_outlined,
                                        color: AppTheme.errorColor, size: 56),
                                    SizedBox(height: 14),
                                    Text(
                                      'Unable to Preview Image',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'CORS or private storage settings may block\nin-app preview. Tap "Open in New Tab" below.',
                                      style: TextStyle(color: Colors.white54, fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Footer actions ────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pinch/scroll to zoom  •  Drag to pan',
                        style: TextStyle(
                            color: Colors.white30, fontSize: 10, fontStyle: FontStyle.italic),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close',
                                style: TextStyle(color: Colors.white60)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Could not launch receipt URL.')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.open_in_new_rounded, size: 14),
                            label: const Text('Open in New Tab',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryLight,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Filters & Search Handlers ─────────────────────────────────────

  List<Map<String, dynamic>> get _filteredPayments {
    if (_paymentPlanFilter == 'all') return _paymentRequests;
    return _paymentRequests.where((p) => p['plan_code'] == _paymentPlanFilter).toList();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    List<Map<String, dynamic>> list = _subs;
    
    // Status Filter
    if (_userStatusFilter != 'all') {
      list = list.where((s) {
        if (_userStatusFilter == 'active') {
          final isAct = s['status'] == 'active';
          final expiry = s['expiry_date'];
          if (!isAct) return false;
          if (expiry == null) return true;
          return DateTime.parse(expiry).isAfter(DateTime.now());
        }
        if (_userStatusFilter == 'expired') {
          final expiry = s['expiry_date'];
          if (s['status'] == 'expired') return true;
          if (expiry == null) return false;
          return DateTime.parse(expiry).isBefore(DateTime.now());
        }
        return s['status'] == _userStatusFilter;
      }).toList();
    }

    // Search Query (name, email, phone)
    if (_userSearchQuery.isNotEmpty) {
      final q = _userSearchQuery.toLowerCase();
      list = list.where((s) {
        final u = s['user'] as Map<String, dynamic>? ?? {};
        final name = (u['full_name'] as String? ?? '').toLowerCase();
        final email = (u['email'] as String? ?? '').toLowerCase();
        final phone = (u['phone'] as String? ?? '').toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q);
      }).toList();
    }

    return list;
  }

  Color _getPlanColor(String planCode) {
    switch (planCode.toLowerCase()) {
      case 'gold':
        return AppTheme.warningColor;
      case 'diamond':
        return AppTheme.primaryLight;
      default:
        return Colors.white54;
    }
  }

  // ── Main UI Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final showLabels = screenWidth >= 360;
    final showUnselected = screenWidth >= 480;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: const Text('Admin Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchData,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeTabIndex,
        onTap: (index) {
          setState(() {
            _activeTabIndex = index;
          });
          if (index == 3) {
            _fetchFeatureControlData();
          }
        },
        backgroundColor: AppTheme.darkSurface,
        selectedItemColor: AppTheme.primaryLight,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: showLabels,
        showUnselectedLabels: showLabels && showUnselected,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_rounded), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.supervised_user_circle_rounded), label: 'Subscribers'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_rounded), label: 'Features'),
        ],
      ),
      body: _loading && _subs.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildActiveTab(),
            ),
    );
  }

  Widget _buildActiveTab() {
    switch (_activeTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildPaymentsTab();
      case 2:
        return _buildUsersTab();
      case 3:
        return _buildFeaturesTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── 1. Overview Dashboard Tab ────────────────────────────────────

  Widget _buildOverviewTab() {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Metrics Grid
          GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            childAspectRatio: isDesktop ? 1.5 : 1.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildMetricCard('Total Subscribers', '$_totalSubscribers', Icons.people_rounded, const Color(0xFF3B82F6)),
              _buildMetricCard('Active Plans', '$_activePlansCount', Icons.check_circle_rounded, AppTheme.successColor),
              _buildMetricCard('Expired Plans', '$_expiredPlansCount', Icons.cancel_rounded, AppTheme.errorColor),
              _buildMetricCard('Revenue Summary', 'Rs. ${_totalRevenue.toInt()}', Icons.monetization_on_rounded, AppTheme.accentColor),
            ],
          ),
          const SizedBox(height: 24),

          // Plan Distribution Chart Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan Distribution',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 20),
                _buildDistributionBar('Basic Free Plan', _planDistribution['basic'] ?? 0, _totalSubscribers, Colors.grey),
                const SizedBox(height: 14),
                _buildDistributionBar('Gold Premium Plan', _planDistribution['gold'] ?? 0, _totalSubscribers, AppTheme.warningColor),
                const SizedBox(height: 14),
                _buildDistributionBar('Diamond Enterprise Plan', _planDistribution['diamond'] ?? 0, _totalSubscribers, AppTheme.primaryLight),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildDistributionBar(String title, int count, int total, Color color) {
    final double pct = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('$count (${(pct * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // ── 2. Payment Verification Panel Tab ────────────────────────────

  Widget _buildPaymentsTab() {
    return Column(
      children: [
        // Plan filters for payments
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Text('Filter Plan: ', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(width: 8),
              ...['all', 'gold', 'diamond'].map((code) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(code.toUpperCase()),
                  selected: _paymentPlanFilter == code,
                  onSelected: (_) => setState(() => _paymentPlanFilter = code),
                  selectedColor: AppTheme.primaryLight,
                  backgroundColor: AppTheme.darkSurface,
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  side: BorderSide(color: _paymentPlanFilter == code ? AppTheme.primaryLight : AppTheme.darkBorder),
                ),
              )),
            ],
          ),
        ),

        // List
        Expanded(
          child: _filteredPayments.isEmpty
              ? const Center(child: Text('No pending payment requests', style: TextStyle(color: Colors.white38)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredPayments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final req = _filteredPayments[i];
                    final user = req['user'] as Map<String, dynamic>? ?? {};
                    final userName = user['full_name'] ?? 'Unknown';
                    final phone = user['phone'] ?? 'No Phone';
                    final plan = (req['plan_code'] as String).toUpperCase();
                    final amount = req['amount'] ?? 0;
                    final date = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(req['created_at'] as String).toLocal());
                    final status = req['status'] as String? ?? 'pending';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(phone, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                    const SizedBox(height: 8),
                                    Text('Requested: $plan', style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Amount: Rs. ${amount.toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text('Submitted: $date', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                  ],
                                ),
                              ),
                              if (req['screenshot_url'] != null)
                                GestureDetector(
                                  onTap: () => _showScreenshotDialog(req['screenshot_url']),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24, width: 1.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            req['screenshot_url'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Colors.white.withValues(alpha: 0.05),
                                              child: const Center(
                                                child: Icon(Icons.image_not_supported_outlined, color: AppTheme.primaryLight, size: 24),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          if (status == 'pending') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _approvePayment(req),
                                    icon: const Icon(Icons.check_circle_outline, size: 16),
                                    label: const Text('Approve Upgrade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.successColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _rejectPayment(req),
                                    icon: const Icon(Icons.cancel_outlined, size: 16),
                                    label: const Text('Reject Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.errorColor,
                                      side: const BorderSide(color: AppTheme.errorColor),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: status == 'approved' ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.errorColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(status == 'approved' ? Icons.check_circle : Icons.error, color: status == 'approved' ? AppTheme.successColor : AppTheme.errorColor, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    status == 'approved' ? 'APPROVED' : 'REJECTED: ${req['rejection_reason'] ?? ""}',
                                    style: TextStyle(
                                      color: status == 'approved' ? AppTheme.successColor : AppTheme.errorColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn();
                  },
                ),
        ),
      ],
    );
  }

  // ── 3. User Subscription Management Tab ──────────────────────────

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search & Filters Box
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search input
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search subscriber name or phone...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: AppTheme.darkSurface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryLight),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _userSearchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Status Choice Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Status: ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(width: 6),
                    ...['all', 'active', 'suspended', 'expired'].map((st) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(st.toUpperCase()),
                        selected: _userStatusFilter == st,
                        onSelected: (_) => setState(() => _userStatusFilter = st),
                        selectedColor: AppTheme.primaryLight,
                        backgroundColor: AppTheme.darkSurface,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                        side: BorderSide(color: _userStatusFilter == st ? AppTheme.primaryLight : AppTheme.darkBorder),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _filteredUsers.isEmpty
              ? const Center(child: Text('No matching subscribers found', style: TextStyle(color: Colors.white38)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final sub = _filteredUsers[i];
                    final user = sub['user'] as Map<String, dynamic>? ?? {};
                    final userName = user['full_name'] ?? 'Unknown User';
                    final phone = user['phone'] ?? 'No Phone';
                    final plan = (sub['plan_code'] as String? ?? 'basic').toUpperCase();
                    final status = sub['status'] as String? ?? 'active';
                    
                    final expiryStr = sub['expiry_date'] != null
                        ? DateFormat('dd MMM yyyy').format(DateTime.parse(sub['expiry_date']))
                        : 'Lifetime';

                    // Get business profiles belonging to this user
                    final userBizs = _businessesList
                        .where((b) => b['owner_id']?.toString() == sub['user_id']?.toString())
                        .map((b) => b['name']?.toString() ?? 'Unnamed')
                        .toList();

                    Color statusColor = const Color(0xFF10B981);
                    if (status == 'suspended') statusColor = const Color(0xFFEF4444);
                    if (status == 'expired') statusColor = Colors.grey;

                    final planColor = _getPlanColor(sub['plan_code'] as String? ?? 'basic');

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          Text('Phone: $phone', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Plan: $plan', style: TextStyle(color: planColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('Expires: $expiryStr', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                          if (userBizs.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white10),
                            const Text('LINKED BUSINESSES:', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(userBizs.join(', '), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showManageSubscriptionDialog(sub),
                              icon: const Icon(Icons.settings_suggest, size: 14),
                              label: const Text('Manage & Change Plan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryLight,
                                side: const BorderSide(color: AppTheme.primaryLight),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn();
                  },
                ),
        ),
      ],
    );
  }

  // ── 4. Feature Control Tab ───────────────────────────────────────

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Plan to Customize:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),

          // Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: AppTheme.darkCard,
                value: _selectedPlanCode,
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                items: _planCodes.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.toUpperCase()),
                )).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPlanCode = val;
                    });
                    _fetchFeatureControlData();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Plan limits card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plan Parameter Limits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Max Staff Accounts:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.white38),
                          onPressed: () {
                            if (_maxStaffCtrl > 0) setState(() => _maxStaffCtrl--);
                          },
                        ),
                        Text('$_maxStaffCtrl', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryLight),
                          onPressed: () => setState(() => _maxStaffCtrl++),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Max Business Profiles:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.white38),
                          onPressed: () {
                            if (_maxBizCtrl > 1) setState(() => _maxBizCtrl--);
                          },
                        ),
                        Text('$_maxBizCtrl', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryLight),
                          onPressed: () => setState(() => _maxBizCtrl++),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Permissions switches lists
          const Text('Feature Flag Permissions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),

          _planPermissions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No flags setup for this plan.', style: TextStyle(color: Colors.white38))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _planPermissions.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                  itemBuilder: (context, idx) {
                    final perm = _planPermissions[idx];
                    final bool isAllowed = perm['is_allowed'] as bool? ?? false;
                    final name = perm['feature_name'] as String? ?? 'Unknown Feature';

                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        name.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      value: isAllowed,
                      activeThumbColor: AppTheme.primaryLight,
                      onChanged: (val) {
                        setState(() {
                          _planPermissions[idx]['is_allowed'] = val;
                        });
                      },
                    );
                  },
                ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveFeatureControl,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Plan Flags & Limits', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ).animate().fadeIn();
  }
}
