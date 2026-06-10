import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  int? _expandedIndex;

  static const _faqs = [
    (
      q: 'What is Smart Saoji?',
      a: 'Smart Saoji is an all-in-one business management and POS application designed for Nepali businesses. It helps you manage inventory, track transactions, handle parties, generate reports, and more — all from one app.',
    ),
    (
      q: 'How do I set up my business?',
      a: 'After signing up, you will be directed to the Business Setup screen. Fill in your business name, type, address, phone, and PAN number to complete the setup. Your registered phone number will be auto-filled.',
    ),
    (
      q: 'Is my data saved offline?',
      a: 'Yes! Smart Saoji supports offline mode. Your data is saved locally and synced with the cloud automatically when you have an internet connection.',
    ),
    (
      q: 'What is the free trial period?',
      a: 'All new businesses get a 14-day free trial with full access to all features. After the trial, you can subscribe to continue using the app.',
    ),
    (
      q: 'How do I add products to my inventory?',
      a: 'Go to the Inventory section from the dashboard. Tap the "+" button, fill in the product details (name, price, stock quantity, category), and save. You can also import products in bulk.',
    ),
    (
      q: 'Can I generate invoices or bills?',
      a: 'Yes. From the Transactions section, you can create sales bills, generate PDF invoices, and share them directly with customers via WhatsApp or email.',
    ),
    (
      q: 'How do I track money owed by customers?',
      a: 'Use the Parties module to manage your customers and suppliers. You can record credit/debit entries and see who owes you money at a glance.',
    ),
    (
      q: 'How do I change the app language?',
      a: 'Go to Settings → Preferences → Language. You can switch between English and Nepali (नेपाली) at any time.',
    ),
    (
      q: 'Can I use Smart Saoji on multiple devices?',
      a: 'Yes. Your data is tied to your account and synced via the cloud. Simply sign in on any device to access your business data.',
    ),
    (
      q: 'How do I contact support?',
      a: 'You can send us feedback from Settings → Support → Send Feedback. Our team will respond within 24 hours on business days.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Header banner
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF0A6070)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.help_outline_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Frequently Asked\nQuestions',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find answers to the most common questions about Smart Saoji.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          ),

          // FAQ list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final faq = _faqs[index];
                  final isExpanded = _expandedIndex == index;
                  return _FaqTile(
                    question: faq.q,
                    answer: faq.a,
                    isExpanded: isExpanded,
                    isDark: isDark,
                    onTap: () => setState(() =>
                        _expandedIndex = isExpanded ? null : index),
                  ).animate(delay: Duration(milliseconds: 40 * index))
                      .fadeIn()
                      .slideY(begin: 0.05, end: 0);
                },
                childCount: _faqs.length,
              ),
            ),
          ),

          // Footer note
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Still have questions?',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Send us your feedback and we\'ll get back to you.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool isExpanded;
  final bool isDark;
  final VoidCallback onTap;

  const _FaqTile({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isExpanded
            ? AppTheme.primaryColor.withValues(alpha: 0.06)
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? AppTheme.primaryColor.withValues(alpha: 0.4)
              : (isDark
                  ? AppTheme.darkBorder
                  : const Color(0xFFE2E8F0)),
          width: 1.5,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Q',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isExpanded ? AppTheme.primaryColor : null,
                            ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded
                            ? AppTheme.primaryColor
                            : AppTheme.lightTextHint,
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          answer,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
