import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hamro_pasal/core/services/app_lock_service.dart';
import 'package:hamro_pasal/core/theme/app_theme.dart';
import 'package:hamro_pasal/core/widgets/app_snackbar.dart';

class PinLockScreen extends StatefulWidget {
  final bool isConfirming;
  final String? initialPin;
  final Function(String pin)? onPinSuccess;
  final VoidCallback? onCancel;

  const PinLockScreen({
    super.key,
    this.isConfirming = false,
    this.initialPin,
    this.onPinSuccess,
    this.onCancel,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  bool _shake = false;

  void _onKeyPress(String val) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += val;
    });

    if (_pin.length == 4) {
      _processPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _processPin() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (widget.isConfirming) {
      if (widget.initialPin == _pin) {
        widget.onPinSuccess?.call(_pin);
      } else {
        setState(() {
          _shake = true;
          _pin = '';
        });
        if (mounted) {
          AppSnackbar.show(context, 'PINs do not match. Try again.', isError: true);
        }
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _shake = false);
      }
    } else if (widget.onPinSuccess != null) {
      // Custom handler
      widget.onPinSuccess?.call(_pin);
    } else {
      // Normal unlocking verification
      final ok = await AppLockService.verifyPin(_pin);
      if (ok) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _shake = true;
          _pin = '';
        });
        if (mounted) {
          AppSnackbar.show(context, 'Incorrect PIN code', isError: true);
        }
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _shake = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.98),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: widget.onCancel != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onCancel,
                    )
                  : const SizedBox(height: 48),
            ),
            const Spacer(),

            // Header text
            Column(
              children: [
                Icon(
                  widget.isConfirming ? Icons.lock_reset_outlined : Icons.lock_outline_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  widget.isConfirming
                      ? (widget.initialPin == null ? 'Create Secure PIN' : 'Confirm Secure PIN')
                      : 'Enter App PIN',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enter your 4-digit security PIN code.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.lightTextHint),
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final active = index < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? AppTheme.primaryColor : (isDark ? Colors.grey[800] : Colors.grey[300]),
                    border: Border.all(
                      color: active ? AppTheme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                );
              }),
            )
            .animate(target: _shake ? 1 : 0)
            .shake(duration: 400.ms, hz: 6, curve: Curves.easeInOut),

            const Spacer(),

            // Keyboard Layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  for (var row = 0; row < 3; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var col = 1; col <= 3; col++)
                            _buildKeypadButton((row * 3 + col).toString()),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 72, height: 72), // Empty space
                      _buildKeypadButton('0'),
                      _buildBackspaceButton(),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(digit),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onBackspace,
        borderRadius: BorderRadius.circular(36),
        child: const SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Icon(Icons.backspace_outlined, size: 24),
          ),
        ),
      ),
    );
  }
}
