import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_saoji/core/theme/app_theme.dart';

class BarcodeScannerModal extends StatefulWidget {
  final String title;
  const BarcodeScannerModal({super.key, this.title = 'Scan Barcode'});

  @override
  State<BarcodeScannerModal> createState() => _BarcodeScannerModalState();

  static Future<String?> show(BuildContext context, {String title = 'Scan Barcode'}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BarcodeScannerModal(title: title),
    );
  }
}

class _BarcodeScannerModalState extends State<BarcodeScannerModal> with SingleTickerProviderStateMixin {
  late AnimationController _scannerAnimCtrl;
  final _manualCodeCtrl = TextEditingController();
  bool _isManualInput = false;
  bool _isFlashOn = false;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.all],
  );

  final List<Map<String, String>> _mockBarcodes = [
    {'name': 'Basmati Rice 1kg', 'code': '8901234567890'},
    {'name': 'Wai Wai Noodles', 'code': '9770123456789'},
    {'name': 'Coca Cola 250ml', 'code': '5449000000096'},
    {'name': 'Amul Butter 100g', 'code': '8901262010016'},
    {'name': 'Dettol Soap 75g', 'code': '8901396323126'},
  ];

  @override
  void initState() {
    super.initState();
    _scannerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerAnimCtrl.dispose();
    _manualCodeCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onCodeScanned(String code) {
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 520 + bottomInset,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (!_isManualInput)
                    IconButton(
                      tooltip: 'Toggle Flashlight',
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isFlashOn ? AppTheme.primaryColor : Colors.grey,
                      ),
                      onPressed: () {
                        _scannerController.toggleTorch();
                        setState(() => _isFlashOn = !_isFlashOn);
                      },
                    ),
                  IconButton(
                    tooltip: _isManualInput ? 'Camera Scanner' : 'Keyboard Entry',
                    icon: Icon(_isManualInput ? Icons.qr_code_scanner : Icons.keyboard, color: AppTheme.primaryColor),
                    onPressed: () => setState(() => _isManualInput = !_isManualInput),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _isManualInput
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.keyboard_outlined, size: 64, color: AppTheme.primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        'Enter Barcode Manually',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _manualCodeCtrl,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'e.g. 8901234567890',
                          prefixIcon: const Icon(Icons.edit_road),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward, color: AppTheme.primaryColor),
                            onPressed: () {
                              final text = _manualCodeCtrl.text.trim();
                              if (text.isNotEmpty) {
                                _onCodeScanned(text);
                              }
                            },
                          ),
                        ),
                        onSubmitted: (val) {
                          final text = val.trim();
                          if (text.isNotEmpty) {
                            _onCodeScanned(text);
                          }
                        },
                      ),
                    ],
                  ).animate().fadeIn()
                : Column(
                    children: [
                      // Scanner camera view frame
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: Colors.black,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Camera stream
                                MobileScanner(
                                  controller: _scannerController,
                                  fit: BoxFit.cover,
                                  onDetect: (capture) {
                                    final List<Barcode> barcodes = capture.barcodes;
                                    debugPrint('mobile_scanner: detected ${barcodes.length} barcodes');
                                    for (final b in barcodes) {
                                      debugPrint('mobile_scanner: format = ${b.format}, value = ${b.rawValue}');
                                    }
                                    if (barcodes.isNotEmpty) {
                                      final String? code = barcodes.first.rawValue;
                                      if (code != null && code.isNotEmpty) {
                                        _onCodeScanned(code);
                                      }
                                    }
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 44),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Camera Error or Permission Denied',
                                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              error.errorDetails?.message ?? 'Please check system camera settings or grant browser camera access.',
                                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Laser Scanning Line Overlay
                                AnimatedBuilder(
                                  animation: _scannerAnimCtrl,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: 30 + (220 * _scannerAnimCtrl.value),
                                      left: 40,
                                      right: 40,
                                      child: Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorColor,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.errorColor.withValues(alpha: 0.8),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Active Scanner Box Overlay Frame
                                Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.8), width: 2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Active Camera Scanning Feed...',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Align barcode inside the green square',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select a demo product to simulate a scan:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      // Mock barcode chips
                      SizedBox(
                        height: 48,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _mockBarcodes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final b = _mockBarcodes[i];
                            return ActionChip(
                              label: Text('${b['name']} (${b['code']})'),
                              avatar: const Icon(Icons.qr_code, size: 16),
                              onPressed: () => _onCodeScanned(b['code']!),
                            );
                          },
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
          ),
        ],
      ),
    );
  }
}
