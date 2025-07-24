import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:ui';
import 'dart:typed_data';

class TextRecognitionScreen extends StatefulWidget {
  const TextRecognitionScreen({Key? key}) : super(key: key);

  @override
  State<TextRecognitionScreen> createState() => _TextRecognitionScreenState();
}

class _TextRecognitionScreenState extends State<TextRecognitionScreen> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  
  final TextRecognizer _textRecognizer = TextRecognizer();
  List<TextElement> _recognizedTexts = [];
  String _statusText = 'Searching for text...';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
        );
        
        await _controller!.initialize();
        
        setState(() {
          _isInitialized = true;
        });
        
        // Start image stream for text recognition
        _controller!.startImageStream(_processImage);
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _processImage(CameraImage image) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage != null) {
        final recognizedText = await _textRecognizer.processImage(inputImage);
        
        if (mounted) {
          setState(() {
            _recognizedTexts = recognizedText.blocks
                .expand((block) => block.lines)
                .expand((line) => line.elements)
                .toList();
            
            if (_recognizedTexts.isNotEmpty) {
              _statusText = 'Text detected: ${_recognizedTexts.length} elements';
            } else {
              _statusText = 'Searching for text...';
            }
          });
        }
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Device orientation mapping
  final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _convertCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras.first;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Recognition'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isInitialized
          ? Stack(
              children: [
                // Camera preview
                CameraPreview(_controller!),
                
                // Text overlay
                CustomPaint(
                  painter: TextOverlayPainter(_recognizedTexts, _controller!),
                  size: Size.infinite,
                ),
                
                // Status bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                // Recognized text list
                if (_recognizedTexts.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recognized Text:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _recognizedTexts.length,
                              itemBuilder: (context, index) {
                                final text = _recognizedTexts[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    text.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }
}

class TextOverlayPainter extends CustomPainter {
  final List<TextElement> texts;
  final CameraController controller;

  TextOverlayPainter(this.texts, this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final text in texts) {
      final rect = _scaleRect(text.boundingBox, size);
      canvas.drawRect(rect, paint);
    }
  }

  Rect _scaleRect(Rect rect, Size size) {
    final double scaleX = size.width / controller.value.previewSize!.height;
    final double scaleY = size.height / controller.value.previewSize!.width;

    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
