import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with TickerProviderStateMixin {
  String _expression = '';
  String _result = '0';
  final List<String> _history = [];
  bool _justEvaluated = false;
  late AnimationController _resultAnimCtrl;
  late Animation<double> _resultScaleAnim;

  @override
  void initState() {
    super.initState();
    _resultAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _resultScaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _resultAnimCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _resultAnimCtrl.dispose();
    super.dispose();
  }

  void _onButton(String label) {
    HapticFeedback.lightImpact();
    setState(() {
      if (label == 'C') {
        _expression = '';
        _result = '0';
        _justEvaluated = false;
      } else if (label == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          if (_expression.isEmpty) _result = '0';
        }
        _justEvaluated = false;
      } else if (label == '=') {
        _evaluate();
      } else if (label == '%') {
        _applyPercent();
      } else if (label == '+/-') {
        _toggleSign();
      } else {
        if (_justEvaluated &&
            !_isOperator(label) &&
            label != '.' &&
            label != '(') {
          _expression = '';
        }
        _justEvaluated = false;
        _expression += label;
        _liveEval();
      }
    });
  }

  bool _isOperator(String s) =>
      s == '+' || s == '-' || s == '×' || s == '÷';

  void _liveEval() {
    try {
      final val = _evalExpr(_expression);
      _result = _formatNum(val);
    } catch (_) {}
  }

  void _evaluate() {
    if (_expression.isEmpty) return;
    try {
      final val = _evalExpr(_expression);
      final res = _formatNum(val);
      _history.insert(0, '$_expression = $res');
      if (_history.length > 20) _history.removeLast();
      _result = res;
      _expression = '';
      _justEvaluated = true;
      _resultAnimCtrl.forward().then((_) => _resultAnimCtrl.reverse());
    } catch (_) {
      _result = 'Error';
    }
  }

  void _applyPercent() {
    if (_expression.isEmpty) return;
    try {
      final val = _evalExpr(_expression) / 100;
      _expression = _formatNum(val);
      _result = _expression;
    } catch (_) {}
  }

  void _toggleSign() {
    if (_expression.isEmpty) return;
    try {
      final val = _evalExpr(_expression) * -1;
      _expression = _formatNum(val);
      _result = _expression;
    } catch (_) {}
  }

  String _formatNum(double val) {
    if (val == val.truncateToDouble() && val.abs() < 1e15) {
      return val.toInt().toString();
    }
    String s = val.toStringAsFixed(8);
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  double _evalExpr(String expr) {
    final sanitized = expr.replaceAll('×', '*').replaceAll('÷', '/');
    return _Parser(sanitized).parse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : const Color(0xFF0A1628);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'Calculator',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white70),
              tooltip: 'History',
              onPressed: _showHistory,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Display ──────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Expression
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _expression.isEmpty ? '' : _expression,
                      key: ValueKey(_expression),
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Result
                  AnimatedBuilder(
                    animation: _resultScaleAnim,
                    builder: (_, child) => Transform.scale(
                      scale: _resultScaleAnim.value,
                      child: child,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _result,
                        style: TextStyle(
                          fontSize: 64,
                          color: _result == 'Error'
                              ? AppTheme.errorColor
                              : Colors.white,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Divider ──────────────────────────────────────────
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),

          // ── Keypad ───────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _Keypad(onButton: _onButton),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Calculation History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _history.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.white.withValues(alpha: 0.08),
                height: 1,
              ),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _history[i],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy_rounded,
                          color: Colors.white38, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _history[i]));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  setState(() => _history.clear());
                  Navigator.pop(context);
                },
                child: const Text(
                  'Clear History',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Keypad ────────────────────────────────────────────────────
class _Keypad extends StatelessWidget {
  final void Function(String) onButton;
  const _Keypad({required this.onButton});

  static const _layout = [
    ['C', '+/-', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '-'],
    ['1', '2', '3', '+'],
    ['(', '0', '.', '='],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _layout.map((row) {
        return Expanded(
          child: Row(
            children: row.map((label) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: _CalcButton(
                    label: label,
                    onTap: () => onButton(label),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _CalcButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _CalcButton({required this.label, required this.onTap});

  @override
  State<_CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<_CalcButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bg {
    final l = widget.label;
    if (l == '=') return AppTheme.primaryColor;
    if (l == 'C' || l == '+/-' || l == '%') {
      return Colors.white.withValues(alpha: 0.15);
    }
    if (l == '÷' || l == '×' || l == '-' || l == '+') {
      return AppTheme.primaryColor.withValues(alpha: 0.25);
    }
    return Colors.white.withValues(alpha: 0.08);
  }

  Color get _fg {
    final l = widget.label;
    if (l == '=') return Colors.white;
    if (l == '÷' || l == '×' || l == '-' || l == '+') {
      return AppTheme.primaryLight;
    }
    if (l == 'C' || l == '+/-' || l == '%') {
      return Colors.white.withValues(alpha: 0.9);
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(16),
            border: widget.label == '='
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: widget.label == '='
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.label == '⌫' ? 22 : 24,
                color: _fg,
                fontWeight: widget.label == '='
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Simple Recursive Descent Parser ──────────────────────────
class _Parser {
  final String input;
  int _pos = 0;
  _Parser(this.input);

  double parse() {
    final result = _expr();
    if (_pos < input.length) throw const FormatException('Unexpected character');
    return result;
  }

  double _expr() {
    double val = _term();
    while (_pos < input.length) {
      final ch = input[_pos];
      if (ch == '+') {
        _pos++;
        val += _term();
      } else if (ch == '-') {
        _pos++;
        val -= _term();
      } else {
        break;
      }
    }
    return val;
  }

  double _term() {
    double val = _factor();
    while (_pos < input.length) {
      final ch = input[_pos];
      if (ch == '*') {
        _pos++;
        val *= _factor();
      } else if (ch == '/') {
        _pos++;
        final d = _factor();
        if (d == 0) throw Exception('Division by zero');
        val /= d;
      } else {
        break;
      }
    }
    return val;
  }

  double _factor() {
    _skipWs();
    if (_pos < input.length && input[_pos] == '(') {
      _pos++; // consume '('
      final val = _expr();
      if (_pos < input.length && input[_pos] == ')') _pos++;
      return val;
    }
    if (_pos < input.length && input[_pos] == '-') {
      _pos++;
      return -_factor();
    }
    return _number();
  }

  double _number() {
    _skipWs();
    final start = _pos;
    while (_pos < input.length &&
        (input[_pos] == '.' || RegExp(r'\d').hasMatch(input[_pos]))) {
      _pos++;
    }
    if (_pos == start) throw FormatException('Expected number at pos $_pos');
    return double.parse(input.substring(start, _pos));
  }

  void _skipWs() {
    while (_pos < input.length && input[_pos] == ' ') {
      _pos++;
    }
  }
}
