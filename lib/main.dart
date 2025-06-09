import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scanner App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: QRScannerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool isFlashOn = false;
  bool isFrontCamera = false;
  bool isScanning = true;
  String scanResult = '';

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() {
          scanResult = barcode.rawValue!;
          isScanning = false;
        });
        _showResultDialog();
      }
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Hasil Scan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Konten:'),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    scanResult,
                    style: TextStyle(fontSize: 14, fontFamily: 'monospace'),
                  ),
                ),
                SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: Icon(Icons.copy, size: 18),
                    label: Text('Salin Konten'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetScanner();
                },
                child: Text('Scan Lagi'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: scanResult));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Salin Link!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      scanResult = '';
      isScanning = true;
    });
  }

  void _toggleFlash() async {
    await controller.toggleTorch();
    setState(() {
      isFlashOn = !isFlashOn;
    });
  }

  void _switchCamera() async {
    await controller.switchCamera();
    setState(() {
      isFrontCamera = !isFrontCamera;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'QR Code Scanner',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(controller: controller, onDetect: _onDetect),
                // Overlay frame
                Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      borderColor: Colors.blue,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 250,
                    ),
                  ),
                ),
                // Instructions
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      isScanning
                          ? 'Posisikan kode QR pada Frame'
                          : 'Kode QR Terdeteksi!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Control Panel
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Camera controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.flash_on,
                      label: 'Flash',
                      isActive: isFlashOn,
                      onPressed: _toggleFlash,
                    ),
                    _buildControlButton(
                      icon:
                          isFrontCamera
                              ? Icons.camera_front
                              : Icons.camera_rear,
                      label: 'Switch',
                      isActive: false,
                      onPressed: _switchCamera,
                    ),
                    _buildControlButton(
                      icon: Icons.refresh,
                      label: 'Reset',
                      isActive: false,
                      onPressed: _resetScanner,
                    ),
                  ],
                ),
                SizedBox(height: 15),
                // Last scan result preview
                if (scanResult.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Scan Result:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          scanResult.length > 50
                              ? '${scanResult.substring(0, 50)}...'
                              : scanResult,
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 28,
            ),
            padding: EdgeInsets.all(12),
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// Custom overlay shape
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
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(
          rect.left,
          rect.top,
          rect.left + borderRadius,
          rect.top,
        )
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final cutOutWidth = cutOutSize < width ? cutOutSize : width - borderWidth;
    final cutOutHeight =
        cutOutSize < height ? cutOutSize : height - borderWidth;

    final backgroundPaint =
        Paint()
          ..color = overlayColor
          ..style = PaintingStyle.fill;

    final boxPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      borderWidthSize - cutOutWidth / 2,
      borderHeightSize - cutOutHeight / 2,
      cutOutWidth,
      cutOutHeight,
    );

    final Paint clearPaint = Paint()..blendMode = BlendMode.clear;

    canvas
      ..saveLayer(rect, Paint())
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        clearPaint,
      )
      ..restore();

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    final path =
        Path()
          ..moveTo(cutOutRect.left + borderRadius, cutOutRect.top)
          ..lineTo(cutOutRect.left + borderLength, cutOutRect.top)
          ..moveTo(cutOutRect.right - borderLength, cutOutRect.top)
          ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)
          ..quadraticBezierTo(
            cutOutRect.right,
            cutOutRect.top,
            cutOutRect.right,
            cutOutRect.top + borderRadius,
          )
          ..lineTo(cutOutRect.right, cutOutRect.top + borderLength)
          ..moveTo(cutOutRect.right, cutOutRect.bottom - borderLength)
          ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius)
          ..quadraticBezierTo(
            cutOutRect.right,
            cutOutRect.bottom,
            cutOutRect.right - borderRadius,
            cutOutRect.bottom,
          )
          ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom)
          ..moveTo(cutOutRect.left + borderLength, cutOutRect.bottom)
          ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom)
          ..quadraticBezierTo(
            cutOutRect.left,
            cutOutRect.bottom,
            cutOutRect.left,
            cutOutRect.bottom - borderRadius,
          )
          ..lineTo(cutOutRect.left, cutOutRect.bottom - borderLength)
          ..moveTo(cutOutRect.left, cutOutRect.top + borderLength)
          ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius)
          ..quadraticBezierTo(
            cutOutRect.left,
            cutOutRect.top,
            cutOutRect.left + borderRadius,
            cutOutRect.top,
          );

    canvas.drawPath(path, borderPaint);
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
