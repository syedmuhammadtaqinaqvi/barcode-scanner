import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'result_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  late final BarcodeScanner _barcodeScanner;
  List<BarcodeFormat> _selectedFormats = [
    BarcodeFormat.qrCode,
    BarcodeFormat.aztec,
    BarcodeFormat.dataMatrix,
    BarcodeFormat.pdf417,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.codabar,
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.itf,
    BarcodeFormat.upca,
    BarcodeFormat.upce,
  ];
  bool _isFlashOn = false;
  bool _isProcessing = false;
  String? _lastScannedCode;
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize barcode scanner with selected formats
    _barcodeScanner = BarcodeScanner(formats: _selectedFormats);
    
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    ));
    _scanAnimationController.repeat();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showPermissionDeniedDialog();
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras[0],
          ResolutionPreset.high, // Use high resolution for better QR detection
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
        );

        await _controller!.initialize();
        _controller!.startImageStream(_processCameraImage);
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  int _frameCount = 0;
  
  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    
    // Process every 3rd frame to improve performance
    _frameCount++;
    if (_frameCount % 3 != 0) return;
    
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final barcodes = await _barcodeScanner.processImage(inputImage);
        if (barcodes.isNotEmpty && mounted) {
          final barcode = barcodes.first;
          final scannedValue = barcode.rawValue ?? barcode.displayValue;
          
          if (scannedValue != null && scannedValue != _lastScannedCode) {
            _lastScannedCode = scannedValue;
            HapticFeedback.mediumImpact();
            
            await _controller?.stopImageStream();
            
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ResultScreen(
                    barcode: barcode,
                    scannedValue: scannedValue,
                  ),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[0];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // Handle multi-plane images properly
    if (image.planes.isEmpty) return null;
    
    late Uint8List bytes;
    late int bytesPerRow;
    
    if (Platform.isAndroid) {
      // Android typically uses NV21 format with Y and UV planes
      if (image.planes.length == 1) {
        // Single plane - use as is
        bytes = image.planes[0].bytes;
        bytesPerRow = image.planes[0].bytesPerRow;
      } else {
        // Multi-plane - combine Y and UV planes
        final yPlane = image.planes[0];
        final uvPlane = image.planes[1];
        
        final yBytes = yPlane.bytes;
        final uvBytes = uvPlane.bytes;
        
        // For NV21, we need Y plane followed by interleaved UV
        bytes = Uint8List(yBytes.length + uvBytes.length);
        bytes.setRange(0, yBytes.length, yBytes);
        bytes.setRange(yBytes.length, bytes.length, uvBytes);
        
        bytesPerRow = yPlane.bytesPerRow;
      }
    } else {
      // iOS typically uses BGRA8888 with a single plane
      final plane = image.planes.first;
      bytes = plane.bytes;
      bytesPerRow = plane.bytesPerRow;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      ),
    );
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void _toggleFlash() async {
    if (_controller != null) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Camera Permission Required',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This app needs camera permission to scan barcodes. Please enable camera access in your device settings.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _barcodeScanner.close();
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Initializing Camera...',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Overlay with scanning area
          Positioned.fill(
            child: Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: Colors.white,
                  borderRadius: 20,
                  borderLength: 30,
                  borderWidth: 4,
                  cutOutSize: MediaQuery.of(context).size.width * 0.8,
                ),
              ),
            ),
          ),

          // Scanning Animation
          Positioned.fill(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.8,
                child: AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ScannerLinePainter(_scanAnimation.value),
                    );
                  },
                ),
              ),
            ),
          ),

          // Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      'Scan QR Code',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _toggleFlash,
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.center_focus_strong,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Align QR code within the frame',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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

class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path outerPath = Path()..addRect(rect);
    Path innerPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, outerPath, innerPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final cutOutWidth = cutOutSize + borderOffset;
    final cutOutHeight = cutOutSize + borderOffset;

    final cutOutRect = Rect.fromLTWH(
      rect.center.dx - cutOutWidth / 2,
      rect.center.dy - cutOutHeight / 2,
      cutOutWidth,
      cutOutHeight,
    );

    final outerRRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );
    final innerRRect = RRect.fromRectAndRadius(
      cutOutRect,
      Radius.circular(borderRadius),
    );
    final outerPath = Path()..addRRect(outerRRect);
    final innerPath = Path()..addRRect(innerRRect);
    final overlayPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );

    final overlayPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRRect(innerRRect);

    canvas.drawPath(path, overlayPaint);

    // Draw corner borders
    canvas.drawPath(
      _getCornerPath(cutOutRect.topLeft, 0),
      borderPaint,
    );
    canvas.drawPath(
      _getCornerPath(cutOutRect.topRight, 1),
      borderPaint,
    );
    canvas.drawPath(
      _getCornerPath(cutOutRect.bottomLeft, 2),
      borderPaint,
    );
    canvas.drawPath(
      _getCornerPath(cutOutRect.bottomRight, 3),
      borderPaint,
    );
  }

  Path _getCornerPath(Offset corner, int cornerIndex) {
    const adjustmentValue = 0.5;
    final path = Path();

    if (cornerIndex == 0) {
      path.moveTo(corner.dx - adjustmentValue, corner.dy + borderLength);
      path.lineTo(corner.dx - adjustmentValue, corner.dy + borderRadius);
      path.quadraticBezierTo(corner.dx - adjustmentValue, corner.dy - adjustmentValue,
          corner.dx + borderRadius, corner.dy - adjustmentValue);
      path.lineTo(corner.dx + borderLength, corner.dy - adjustmentValue);
    } else if (cornerIndex == 1) {
      path.moveTo(corner.dx + adjustmentValue, corner.dy + borderLength);
      path.lineTo(corner.dx + adjustmentValue, corner.dy + borderRadius);
      path.quadraticBezierTo(corner.dx + adjustmentValue, corner.dy - adjustmentValue,
          corner.dx - borderRadius, corner.dy - adjustmentValue);
      path.lineTo(corner.dx - borderLength, corner.dy - adjustmentValue);
    } else if (cornerIndex == 2) {
      path.moveTo(corner.dx - adjustmentValue, corner.dy - borderLength);
      path.lineTo(corner.dx - adjustmentValue, corner.dy - borderRadius);
      path.quadraticBezierTo(corner.dx - adjustmentValue, corner.dy + adjustmentValue,
          corner.dx + borderRadius, corner.dy + adjustmentValue);
      path.lineTo(corner.dx + borderLength, corner.dy + adjustmentValue);
    } else if (cornerIndex == 3) {
      path.moveTo(corner.dx + adjustmentValue, corner.dy - borderLength);
      path.lineTo(corner.dx + adjustmentValue, corner.dy - borderRadius);
      path.quadraticBezierTo(corner.dx + adjustmentValue, corner.dy + adjustmentValue,
          corner.dx - borderRadius, corner.dy + adjustmentValue);
      path.lineTo(corner.dx - borderLength, corner.dy + adjustmentValue);
    }
    return path;
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

class ScannerLinePainter extends CustomPainter {
  final double animationValue;

  ScannerLinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        Colors.red.withOpacity(0.8),
        Colors.transparent,
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, 3);
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect);

    final yPosition = size.height * animationValue;
    canvas.drawRect(
      Rect.fromLTWH(0, yPosition, size.width, 3),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
