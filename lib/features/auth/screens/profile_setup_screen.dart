import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _panCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull;
    _nameCtrl = TextEditingController(text: profile?.pasalName ?? '');
    _panCtrl = TextEditingController(text: profile?.panNumber ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    _addressCtrl = TextEditingController(text: profile?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _panCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final userId = ref.read(currentUserProvider)!.id;
    final profile = UserProfile(
      id: '',
      userId: userId,
      pasalName: _nameCtrl.text.trim(),
      panNumber: _panCtrl.text.trim().isEmpty ? null : _panCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(profileProvider.notifier).saveProfile(profile);
    if (!mounted) return;
    setState(() => _loading = false);

    final err = ref.read(profileProvider).error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString()), backgroundColor: AppColors.error),
      );
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppConstants.routeSubscription);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        appBar: context.canPop() ? AppBar(title: const Text('Edit Profile')) : null,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              color: AppColors.primary, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Setup Your Shop',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: AppColors.primary)),
                                Text('Fill in your shop details to continue',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _nameCtrl,
                            label: 'Shop Name (Pasal Ko Naam) *',
                            hint: 'e.g. Shree General Store',
                            prefixIcon: Icons.store_rounded,
                            validator: (v) =>
                                v!.isEmpty ? 'Shop name is required' : null,
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            controller: _panCtrl,
                            label: 'PAN / VAT Number (Optional)',
                            hint: 'e.g. 123456789',
                            prefixIcon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            controller: _phoneCtrl,
                            label: 'Phone Number *',
                            hint: '98XXXXXXXX',
                            prefixIcon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.length < 10
                                ? 'Enter valid phone number'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            controller: _addressCtrl,
                            label: 'Address *',
                            hint: 'e.g. Kathmandu, Ward No. 5',
                            prefixIcon: Icons.location_on_outlined,
                            maxLines: 2,
                            validator: (v) =>
                                v!.isEmpty ? 'Address is required' : null,
                          ),
                          const SizedBox(height: 32),

                          AppButton(
                            label: 'Save & Continue',
                            onPressed: _saveProfile,
                            icon: Icons.arrow_forward_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
