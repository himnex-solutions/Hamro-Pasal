import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScreen(
      title: 'Privacy Policy',
      icon: Icons.privacy_tip_outlined,
      accentColor: AppTheme.primaryColor,
      lastUpdated: 'May 20, 2025',
      sections: [
        _LegalSection(
          heading: '1. Information We Collect',
          body:
              'We collect information that you provide directly to us when you create an account, set up your business, or use our services. This includes:\n\n'
              '• Full name and email address\n'
              '• Phone number (used as a unique identifier)\n'
              '• Business details (name, type, address, PAN number)\n'
              '• Transaction and inventory data you enter into the app\n'
              '• Device information and usage statistics (anonymised)',
        ),
        _LegalSection(
          heading: '2. How We Use Your Information',
          body:
              'We use the information we collect to:\n\n'
              '• Provide, maintain, and improve Smart Saoji\n'
              '• Process transactions and send related information\n'
              '• Send technical notices and support messages\n'
              '• Respond to comments and feedback\n'
              '• Monitor and analyse usage trends to improve user experience\n'
              '• Detect, investigate, and prevent fraudulent transactions and other illegal activities',
        ),
        _LegalSection(
          heading: '3. Data Storage & Security',
          body:
              'Your data is stored securely using Supabase (PostgreSQL) with row-level security (RLS) policies. We implement industry-standard encryption for data in transit (TLS) and at rest.\n\n'
              'Your business data is isolated from other users. Only you can access your own business information. We do not sell or rent your personal data to third parties.',
        ),
        _LegalSection(
          heading: '4. Data Sharing',
          body:
              'We do not share your personal information with third parties except:\n\n'
              '• With your consent\n'
              '• To comply with legal obligations\n'
              '• To protect the rights and safety of Smart Saoji and its users\n'
              '• With service providers who assist in our operations (e.g., cloud hosting), under strict confidentiality agreements',
        ),
        _LegalSection(
          heading: '5. Cookies & Analytics',
          body:
              'The web version of Smart Saoji may use cookies and similar tracking technologies to maintain your session and remember your preferences. We use anonymised analytics to understand usage patterns. No personally identifiable data is shared with analytics providers.',
        ),
        _LegalSection(
          heading: '6. Your Rights',
          body:
              'You have the right to:\n\n'
              '• Access the personal data we hold about you\n'
              '• Request correction of inaccurate data\n'
              '• Request deletion of your account and associated data\n'
              '• Export your business data\n\n'
              'To exercise any of these rights, please use the Send Feedback feature in the app.',
        ),
        _LegalSection(
          heading: '7. Children\'s Privacy',
          body:
              'Smart Saoji is not directed at children under 13. We do not knowingly collect personal information from children under 13. If we learn that we have collected such information, we will promptly delete it.',
        ),
        _LegalSection(
          heading: '8. Changes to This Policy',
          body:
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last Updated" date. Your continued use of the app after changes are posted constitutes your acceptance of the updated policy.',
        ),
        _LegalSection(
          heading: '9. Contact',
          body:
              'If you have any questions about this Privacy Policy, please contact us through the Send Feedback section in Settings.',
        ),
      ],
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScreen(
      title: 'Terms of Service',
      icon: Icons.description_outlined,
      accentColor: AppTheme.primaryDark,
      lastUpdated: 'May 20, 2025',
      sections: [
        _LegalSection(
          heading: '1. Acceptance of Terms',
          body:
              'By accessing or using Smart Saoji ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.',
        ),
        _LegalSection(
          heading: '2. Use of the App',
          body:
              'Smart Saoji is designed for legitimate business management purposes. You agree to:\n\n'
              '• Use the App only for lawful purposes\n'
              '• Provide accurate and complete business information\n'
              '• Keep your account credentials secure\n'
              '• Not attempt to reverse-engineer, hack, or disrupt the App\n'
              '• Not use the App to store or transmit illegal content',
        ),
        _LegalSection(
          heading: '3. Account Registration',
          body:
              'To use Smart Saoji, you must register with a valid email address and phone number. Each phone number and email may be associated with only one account. You are responsible for all activity that occurs under your account.',
        ),
        _LegalSection(
          heading: '4. Subscription & Free Trial',
          body:
              'New businesses receive a 14-day free trial with full access to all features. After the trial period, a paid subscription is required to continue using the App. Subscription fees are non-refundable unless required by applicable law.\n\n'
              'We reserve the right to modify pricing with advance notice. Your continued use after a price change constitutes acceptance.',
        ),
        _LegalSection(
          heading: '5. Data & Ownership',
          body:
              'You retain full ownership of the business data you enter into Smart Saoji. We do not claim any intellectual property rights over your data. You grant us a limited licence to store and process your data solely to provide the service.\n\n'
              'You may export your data at any time from the app settings.',
        ),
        _LegalSection(
          heading: '6. Intellectual Property',
          body:
              'The App, including its design, code, features, and branding, is the intellectual property of Himnex Solutions. You may not copy, distribute, modify, or create derivative works without our express written permission.',
        ),
        _LegalSection(
          heading: '7. Limitation of Liability',
          body:
              'To the maximum extent permitted by law, Himnex Solutions shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App.\n\n'
              'We do not guarantee that the App will be error-free or uninterrupted. Use of the App is at your own risk.',
        ),
        _LegalSection(
          heading: '8. Termination',
          body:
              'We reserve the right to suspend or terminate your account if you violate these Terms. You may cancel your account at any time from the Settings page. Upon termination, your data will be retained for 30 days before permanent deletion.',
        ),
        _LegalSection(
          heading: '9. Governing Law',
          body:
              'These Terms shall be governed by and construed in accordance with the laws of Nepal. Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts of Kathmandu, Nepal.',
        ),
        _LegalSection(
          heading: '10. Changes to Terms',
          body:
              'We may update these Terms from time to time. We will notify you of material changes via the app or email. Your continued use of the App after changes take effect constitutes acceptance of the updated Terms.',
        ),
      ],
    );
  }
}

// ── Shared Legal Screen Layout ────────────────────────────────────────────────

class _LegalScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final String lastUpdated;
  final List<_LegalSection> sections;

  const _LegalScreen({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Header banner
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Last updated: $lastUpdated',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          ),

          // Sections
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final s = sections[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 20,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.heading,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: accentColor,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.body,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.65),
                        ),
                      ],
                    ),
                  ).animate(delay: Duration(milliseconds: 40 * index))
                      .fadeIn()
                      .slideY(begin: 0.04, end: 0);
                },
                childCount: sections.length,
              ),
            ),
          ),

          // Footer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Text(
                '© ${DateTime.now().year} Smart Saoji by Himnex Solutions. All rights reserved.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  final String heading;
  final String body;
  const _LegalSection({required this.heading, required this.body});
}
