import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:animations/animations.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final Barcode barcode;
  final String scannedValue;

  const ResultScreen({
    super.key,
    required this.barcode,
    required this.scannedValue,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced from 1000ms
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getBarcodeTypeDisplay() {
    switch (widget.barcode.type) {
      case BarcodeType.contactInfo:
        return 'Contact Information';
      case BarcodeType.email:
        return 'Email Address';
      case BarcodeType.isbn:
        return 'ISBN';
      case BarcodeType.phone:
        return 'Phone Number';
      case BarcodeType.product:
        return 'Product';
      case BarcodeType.sms:
        return 'SMS';
      case BarcodeType.text:
        return 'Text';
      case BarcodeType.url:
        return 'Website URL';
      case BarcodeType.wifi:
        return 'WiFi Information';
      case BarcodeType.calendarEvent:
        return 'Calendar Event';
      case BarcodeType.driverLicense:
        return 'Driver License';
      default:
        return 'Unknown';
    }
  }

  String _getBarcodeFormatDisplay() {
    switch (widget.barcode.format) {
      case BarcodeFormat.qrCode:
        return 'QR Code';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      case BarcodeFormat.pdf417:
        return 'PDF417';
      case BarcodeFormat.aztec:
        return 'Aztec';
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.code39:
        return 'Code 39';
      case BarcodeFormat.code93:
        return 'Code 93';
      case BarcodeFormat.codabar:
        return 'Codabar';
      case BarcodeFormat.ean13:
        return 'EAN-13';
      case BarcodeFormat.ean8:
        return 'EAN-8';
      case BarcodeFormat.itf:
        return 'ITF';
      case BarcodeFormat.upca:
        return 'UPC-A';
      case BarcodeFormat.upce:
        return 'UPC-E';
      default:
        return 'Unknown Format';
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.scannedValue));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Scan Result',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Success Icon
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Success Message
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Successfully Scanned!',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Here are the details of your scan',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Result Card
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoCard(
                                'Format',
                                _getBarcodeFormatDisplay(),
                                Icons.qr_code_2,
                                Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              _buildInfoCard(
                                'Type',
                                _getBarcodeTypeDisplay(),
                                Icons.category,
                                Colors.purple,
                              ),
                              const SizedBox(height: 16),
                              _buildInfoCard(
                                'Content',
                                widget.scannedValue,
                                Icons.text_fields,
                                Colors.green,
                                showCopy: true,
                              ),
                              const SizedBox(height: 16),
                              // Add detailed barcode information
                              _buildDetailedBarcodeInfo(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _copyToClipboard,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6366F1),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: const Color(0xFF6366F1).withOpacity(0.2),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.copy, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Copy',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: OpenContainer(
                            transitionType: ContainerTransitionType.fadeThrough,
                            transitionDuration: const Duration(milliseconds: 500),
                            openBuilder: (context, action) => const HomeScreen(),
                            closedBuilder: (context, action) => Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: action,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.qr_code_scanner,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Scan Again',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool showCopy = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (showCopy) const Spacer(),
              if (showCopy)
                IconButton(
                  onPressed: _copyToClipboard,
                  icon: Icon(
                    Icons.copy,
                    color: color,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF1E293B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBarcodeInfo() {
    final barcode = widget.barcode;
    final List<Widget> detailWidgets = [];

    // Add corner points if available
    if (barcode.cornerPoints != null && barcode.cornerPoints!.isNotEmpty) {
      detailWidgets.add(_buildInfoCard(
        'Corner Points',
        barcode.cornerPoints!.map((p) => '(${p.x.toInt()}, ${p.y.toInt()})').join(', '),
        Icons.crop_free,
        Colors.indigo,
      ));
      detailWidgets.add(const SizedBox(height: 16));
    }

    // Add bounding box if available
    if (barcode.boundingBox != null) {
      final box = barcode.boundingBox!;
      detailWidgets.add(_buildInfoCard(
        'Bounding Box',
        'Left: ${box.left.toInt()}, Top: ${box.top.toInt()}, Right: ${box.right.toInt()}, Bottom: ${box.bottom.toInt()}',
        Icons.border_outer,
        Colors.teal,
      ));
      detailWidgets.add(const SizedBox(height: 16));
    }

    // Add additional technical details if available
    if (barcode.displayValue != null && barcode.displayValue != barcode.rawValue) {
      detailWidgets.add(_buildInfoCard(
        'Display Value',
        barcode.displayValue!,
        Icons.display_settings,
        Colors.orange,
      ));
      detailWidgets.add(const SizedBox(height: 16));
    }

    if (barcode.rawValue != null && barcode.rawValue != widget.scannedValue) {
      detailWidgets.add(_buildInfoCard(
        'Raw Value',
        barcode.rawValue!,
        Icons.code,
        Colors.deepPurple,
      ));
      detailWidgets.add(const SizedBox(height: 16));
    }

    // Note: Advanced content parsing features like WiFi, Email, Contact Info, etc.
    // are available in newer versions of Google ML Kit. The current version (0.14.1)
    // provides basic barcode detection with format and type information.
    // For advanced parsing, you might need to parse the content manually or
    // upgrade to a newer version when available.
    
    if (detailWidgets.isEmpty) {
      detailWidgets.add(_buildInfoCard(
        'Additional Info',
        'This barcode contains ${widget.scannedValue.length} characters and was detected successfully with Google ML Kit.',
        Icons.info_outline,
        Colors.blue,
      ));
    }

    return Column(children: detailWidgets);
  }
}
