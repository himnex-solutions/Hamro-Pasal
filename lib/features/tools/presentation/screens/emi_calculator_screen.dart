import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class EmiCalculatorScreen extends StatefulWidget {
  const EmiCalculatorScreen({super.key});

  @override
  State<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends State<EmiCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final _loanCtrl = TextEditingController(text: '500000');
  final _rateCtrl = TextEditingController(text: '12');
  final _tenureCtrl = TextEditingController(text: '24');
  final _formKey = GlobalKey<FormState>();

  bool _tenureInYears = false;
  late TabController _tabCtrl;

  // Results
  double _emi = 0;
  double _totalPayable = 0;
  double _totalInterest = 0;
  double _principal = 0;
  List<_EmiRow> _schedule = [];

  final _fmt = NumberFormat('#,##,##0.00', 'en_IN');
  final _fmtShort = NumberFormat('#,##,##0', 'en_IN');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _calculate();
  }

  @override
  void dispose() {
    _loanCtrl.dispose();
    _rateCtrl.dispose();
    _tenureCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final loan = double.tryParse(_loanCtrl.text.replaceAll(',', '')) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    final tenureRaw = int.tryParse(_tenureCtrl.text) ?? 0;
    final months = _tenureInYears ? tenureRaw * 12 : tenureRaw;

    if (loan <= 0 || rate <= 0 || months <= 0) {
      setState(() {
        _emi = 0;
        _totalPayable = 0;
        _totalInterest = 0;
        _schedule = [];
      });
      return;
    }

    final r = rate / 12 / 100;
    final emi = loan * r * math.pow(1 + r, months) /
        (math.pow(1 + r, months) - 1);

    double balance = loan;
    final rows = <_EmiRow>[];
    double totalInterest = 0;

    for (int i = 1; i <= months; i++) {
      final interestPart = balance * r;
      final principalPart = emi - interestPart;
      balance -= principalPart;
      totalInterest += interestPart;
      rows.add(_EmiRow(
        month: i,
        emi: emi,
        principal: principalPart,
        interest: interestPart,
        balance: balance < 0 ? 0 : balance,
      ));
    }

    setState(() {
      _emi = emi;
      _principal = loan;
      _totalInterest = totalInterest;
      _totalPayable = emi * months;
      _schedule = rows;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('EMI Calculator'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.lightTextHint,
          tabs: const [
            Tab(text: 'Calculator'),
            Tab(text: 'Schedule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildCalculatorTab(isDark),
          _buildScheduleTab(isDark),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Input Card ──────────────────────────────────
            _SectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('Loan Details', Icons.account_balance_rounded),
                  const SizedBox(height: 16),
                  _InputRow(
                    label: 'Loan Amount (NPR)',
                    hint: 'e.g. 500000',
                    controller: _loanCtrl,
                    prefix: 'रु.',
                    onChanged: (_) => _calculate(),
                  ),
                  const SizedBox(height: 14),
                  _InputRow(
                    label: 'Annual Interest Rate (%)',
                    hint: 'e.g. 12',
                    controller: _rateCtrl,
                    suffix: '%',
                    onChanged: (_) => _calculate(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _InputRow(
                          label: 'Loan Tenure',
                          hint: _tenureInYears ? 'Years' : 'Months',
                          controller: _tenureCtrl,
                          onChanged: (_) => _calculate(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Years',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.lightTextSecondary)),
                          Switch(
                            value: _tenureInYears,
                            onChanged: (v) {
                              setState(() => _tenureInYears = v);
                              _calculate();
                            },
                            activeThumbColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // ── Result Card ──────────────────────────────────
            if (_emi > 0) ...[
              _SectionCard(
                isDark: isDark,
                gradient: true,
                child: Column(
                  children: [
                    _cardTitle('Monthly EMI', Icons.payments_rounded,
                        light: true),
                    const SizedBox(height: 12),
                    Text(
                      'रु. ${_fmt.format(_emi)}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'per month',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 16),

              // ── Summary Row (responsive) ─────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 480;
                  if (isNarrow) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryTile(
                                isDark: isDark,
                                label: 'Principal',
                                value: 'रु. ${_fmtShort.format(_principal)}',
                                icon: Icons.account_balance_wallet_rounded,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryTile(
                                isDark: isDark,
                                label: 'Total Interest',
                                value: 'रु. ${_fmtShort.format(_totalInterest)}',
                                icon: Icons.trending_up_rounded,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryTile(
                                isDark: isDark,
                                label: 'Total Payable',
                                value: 'रु. ${_fmtShort.format(_totalPayable)}',
                                icon: Icons.receipt_long_rounded,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          isDark: isDark,
                          label: 'Principal',
                          value: 'रु. ${_fmtShort.format(_principal)}',
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryTile(
                          isDark: isDark,
                          label: 'Total Interest',
                          value: 'रु. ${_fmtShort.format(_totalInterest)}',
                          icon: Icons.trending_up_rounded,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryTile(
                          isDark: isDark,
                          label: 'Total Payable',
                          value: 'रु. ${_fmtShort.format(_totalPayable)}',
                          icon: Icons.receipt_long_rounded,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  );
                },
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),

              // ── Pie Visual ──────────────────────────────────
              _SectionCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle('Breakdown', Icons.pie_chart_rounded),
                    const SizedBox(height: 16),
                    _PieBreakdown(
                      principal: _principal,
                      interest: _totalInterest,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              // ── View Schedule Button ─────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _tabCtrl.animateTo(1),
                  icon: const Icon(Icons.table_rows_rounded),
                  label: const Text('View Amortization Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab(bool isDark) {
    if (_schedule.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calculate_outlined,
                size: 64, color: AppTheme.lightTextHint),
            const SizedBox(height: 12),
            const Text(
              'Fill in loan details first',
              style: TextStyle(
                  color: AppTheme.lightTextHint, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabCtrl.animateTo(0),
              child: const Text('Go to Calculator'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _headerCell('Month', flex: 1),
              _headerCell('EMI', flex: 2),
              _headerCell('Principal', flex: 2),
              _headerCell('Interest', flex: 2),
              _headerCell('Balance', flex: 2),
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        Expanded(
          child: ListView.separated(
            itemCount: _schedule.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (_, i) {
              final row = _schedule[i];
              final isEven = i % 2 == 0;
              return Container(
                color: isEven
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.grey.withValues(alpha: 0.03))
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _dataCell('${row.month}', flex: 1,
                        bold: true,
                        color: AppTheme.primaryColor),
                    _dataCell(_fmtShort.format(row.emi), flex: 2),
                    _dataCell(_fmtShort.format(row.principal),
                        flex: 2, color: AppTheme.successColor),
                    _dataCell(_fmtShort.format(row.interest),
                        flex: 2, color: AppTheme.warningColor),
                    _dataCell(
                      row.balance < 1 ? '0' : _fmtShort.format(row.balance),
                      flex: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTextHint,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.right,
        ),
      );

  Widget _dataCell(String text,
      {int flex = 1, bool bold = false, Color? color}) =>
      Expanded(
        flex: flex,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: color,
          ),
          textAlign: TextAlign.right,
        ),
      );

  Widget _cardTitle(String title, IconData icon, {bool light = false}) {
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: light ? Colors.white70 : AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: light ? Colors.white : null,
          ),
        ),
      ],
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final bool gradient;
  const _SectionCard(
      {required this.child, required this.isDark, this.gradient = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ? AppTheme.primaryGradient : null,
        color: gradient
            ? null
            : (isDark ? AppTheme.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: gradient
            ? null
            : Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        boxShadow: gradient
            ? AppTheme.glowShadow(AppTheme.primaryColor, opacity: 0.25)
            : AppTheme.cardShadow(Colors.black, opacity: 0.04),
      ),
      child: child,
    );
  }
}

class _InputRow extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? prefix;
  final String? suffix;
  final void Function(String) onChanged;

  const _InputRow({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTextSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix != null ? '$prefix  ' : null,
            suffixText: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.lightTextHint),
          ),
        ],
      ),
    );
  }
}

class _PieBreakdown extends StatelessWidget {
  final double principal;
  final double interest;
  const _PieBreakdown({required this.principal, required this.interest});

  @override
  Widget build(BuildContext context) {
    final total = principal + interest;
    final pPct = principal / total;
    final iPct = interest / total;

    return Row(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: _PiePainter(principalPct: pPct),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PieLegend(
                color: AppTheme.primaryColor,
                label: 'Principal',
                pct: pPct,
              ),
              const SizedBox(height: 10),
              _PieLegend(
                color: AppTheme.warningColor,
                label: 'Interest',
                pct: iPct,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final double principalPct;
  const _PiePainter({required this.principalPct});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 8;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 16;

    // Principal arc
    paint.color = AppTheme.primaryColor;
    canvas.drawArc(rect, -math.pi / 2,
        2 * math.pi * principalPct, false, paint);

    // Interest arc
    paint.color = AppTheme.warningColor;
    canvas.drawArc(
        rect,
        -math.pi / 2 + 2 * math.pi * principalPct,
        2 * math.pi * (1 - principalPct),
        false,
        paint);
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.principalPct != principalPct;
}

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;
  const _PieLegend(
      {required this.color, required this.label, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(
          '$label  ${(pct * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ── Data Model ─────────────────────────────────────────────────
class _EmiRow {
  final int month;
  final double emi;
  final double principal;
  final double interest;
  final double balance;
  const _EmiRow({
    required this.month,
    required this.emi,
    required this.principal,
    required this.interest,
    required this.balance,
  });
}
