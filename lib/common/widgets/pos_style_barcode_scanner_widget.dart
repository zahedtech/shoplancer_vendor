import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shoplancer_vendor/util/dimensions.dart';
import 'package:shoplancer_vendor/util/styles.dart';

class PosStyleBarcodeScannerWidget extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;
  final VoidCallback? onClose;
  final double height;
  final String title;

  const PosStyleBarcodeScannerWidget({
    super.key,
    required this.onBarcodeScanned,
    this.onClose,
    this.height = 185,
    this.title = 'الماسح الضوئي نشط',
  });

  @override
  State<PosStyleBarcodeScannerWidget> createState() =>
      _PosStyleBarcodeScannerWidgetState();
}

class _PosStyleBarcodeScannerWidgetState
    extends State<PosStyleBarcodeScannerWidget> {
  late final MobileScannerController _scannerController;
  bool _isTorchOn = false;
  DateTime? _lastScannedTime;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: const [
        BarcodeFormat.ean8,
        BarcodeFormat.ean13,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.itf,
        BarcodeFormat.codabar,
        BarcodeFormat.qrCode,
      ],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    final now = DateTime.now();
    if (_lastScannedTime != null &&
        now.difference(_lastScannedTime!).inMilliseconds < 1200) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        _lastScannedTime = now;
        HapticFeedback.mediumImpact();
        widget.onBarcodeScanned(raw);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Camera Stream
            MobileScanner(
              controller: _scannerController,
              onDetect: _handleDetect,
            ),

            // Laser Animation & Viewfinder Overlay
            const _ScannerLaserOverlay(),

            // Top Scanner Header / Flash & Close Controls
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.barcode_reader,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.title.tr,
                          style: robotoMedium.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          _scannerController.toggleTorch();
                          setState(() {
                            _isTorchOn = !_isTorchOn;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isTorchOn ? Icons.flash_on : Icons.flash_off,
                            color: _isTorchOn
                                ? Colors.amber
                                : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _scannerController.switchCamera(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cameraswitch_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      if (widget.onClose != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Bottom subtle helper hint
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'وجّه الكاميرا نحو باركود المنتج للمسح المباشر'.tr,
                    style: robotoRegular.copyWith(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerLaserOverlay extends StatefulWidget {
  const _ScannerLaserOverlay();

  @override
  State<_ScannerLaserOverlay> createState() => _ScannerLaserOverlayState();
}

class _ScannerLaserOverlayState extends State<_ScannerLaserOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boxWidth = (constraints.maxWidth * 0.88).clamp(240.0, 360.0);
        final double boxHeight = (constraints.maxHeight * 0.72).clamp(100.0, 150.0);

        final double left = (constraints.maxWidth - boxWidth) / 2;
        final double top = (constraints.maxHeight - boxHeight) / 2;

        return Stack(
          children: [
            // Darkened Outer Background Mask
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.35),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Container(
                      color: Colors.black,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    width: boxWidth,
                    height: boxHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4-Corner Viewfinder Borders
            Positioned(
              left: left,
              top: top,
              width: boxWidth,
              height: boxHeight,
              child: CustomPaint(
                painter: _ScannerCornerPainter(
                  color: Theme.of(context).primaryColor,
                  strokeWidth: 3.0,
                  cornerLength: 22.0,
                ),
              ),
            ),

            // Animated Laser Beam
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final double laserY = top + (boxHeight - 4) * _animation.value;
                return Positioned(
                  left: left + 6,
                  right: left + 6,
                  top: laserY,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Theme.of(context).primaryColor.withOpacity(0.7),
                              Colors.redAccent,
                              Theme.of(context).primaryColor.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.75),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.redAccent.withOpacity(0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ScannerCornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  _ScannerCornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double r = 10.0;

    // Top-Left Corner
    final pathTL = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right Corner
    final pathTR = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left Corner
    final pathBL = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - r)
      ..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right Corner
    final pathBR = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - r, size.height)
      ..arcToPoint(
        Offset(size.width, size.height - r),
        radius: const Radius.circular(r),
      )
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
