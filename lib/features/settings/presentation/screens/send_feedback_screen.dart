import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:smart_saoji/core/widgets/app_snackbar.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _msgCtrl = TextEditingController();
  int _rating = 0;
  String _category = 'General';
  bool _sending = false;

  static const _categories = [
    ('General', Icons.chat_bubble_outline_rounded),
    ('Bug Report', Icons.bug_report_outlined),
    ('Feature Request', Icons.lightbulb_outlined),
    ('Performance', Icons.speed_outlined),
    ('UI / Design', Icons.palette_outlined),
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      AppSnackbar.show(context, 'Please give a star rating first.',
          isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      await Supabase.instance.client.from('feedbacks').insert({
        'user_id': userId,
        'rating': _rating,
        'category': _category,
        'message': _msgCtrl.text.trim(),
        'status': 'pending',
      });
      if (!mounted) return;
      AppSnackbar.show(
        context,
        '🙏 Thank you for your feedback! We\'ll review it shortly.',
        isSuccess: true,
        duration: const Duration(seconds: 4),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(context, 'Failed to send feedback. Please try again.',
          isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
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
                    child: const Icon(Icons.feedback_outlined,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We\'d love to hear\nfrom you!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your feedback helps us improve Smart Saoji for everyone.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Star rating
                    Text('How would you rate Smart Saoji?',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = star),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: AnimatedScale(
                              scale: _rating >= star ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _rating >= star
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 42,
                                color: _rating >= star
                                    ? const Color(0xFFF59E0B)
                                    : AppTheme.lightTextHint,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_rating > 0)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            [
                              '',
                              '😞 Poor',
                              '😐 Fair',
                              '🙂 Good',
                              '😊 Very Good',
                              '🤩 Excellent!'
                            ][_rating],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ).animate().fadeIn(),
                      ),

                    const SizedBox(height: 24),

                    // Category
                    Text('Feedback Category',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _category == cat.$1;
                        return GestureDetector(
                          onTap: () => setState(() => _category = cat.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF7C3AED)
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat.$2,
                                    size: 15,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.lightTextHint),
                                const SizedBox(width: 6),
                                Text(
                                  cat.$1,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Message
                    Text('Your Message',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _msgCtrl,
                      maxLines: 5,
                      maxLength: 500,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please write your feedback';
                        }
                        if (v.trim().length < 10) {
                          return 'Please provide more detail (min 10 characters)';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Tell us what you think, what\'s working well, or what could be improved...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : const Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color(0xFF7C3AED), width: 2),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _sending ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _sending ? 'Sending...' : 'Submit Feedback',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
