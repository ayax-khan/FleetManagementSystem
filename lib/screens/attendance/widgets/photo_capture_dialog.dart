import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
// import 'package:camera/camera.dart'; // Uncomment when camera package is added
// import 'package:path_provider/path_provider.dart';

class PhotoCaptureDialog extends StatefulWidget {
  final String driverName;
  final String attendanceType; // 'check_in' or 'check_out'
  final Function(String photoPath) onPhotoCapture;

  const PhotoCaptureDialog({
    super.key,
    required this.driverName,
    required this.attendanceType,
    required this.onPhotoCapture,
  });

  @override
  State<PhotoCaptureDialog> createState() => _PhotoCaptureDialogState();
}

class _PhotoCaptureDialogState extends State<PhotoCaptureDialog> {
  // CameraController? _cameraController; // Uncomment when camera package is added
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _capturedPhotoPath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    // _cameraController?.dispose(); // Uncomment when camera package is added
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // TODO: Uncomment and implement when camera package is added
      /*
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first, // Use front camera for attendance
          ResolutionPreset.medium,
        );
        
        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
      */
      
      // For now, simulate camera initialization
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // TODO: Implement actual photo capture
      /*
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final image = await _cameraController!.takePicture();
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/attendance_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await image.saveTo(imagePath);
        
        setState(() {
          _capturedPhotoPath = imagePath;
          _isCapturing = false;
        });
      }
      */

      // For now, simulate photo capture
      await Future.delayed(const Duration(seconds: 1));
      final mockPhotoPath = '/mock/path/attendance_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      setState(() {
        _capturedPhotoPath = mockPhotoPath;
        _isCapturing = false;
      });

      // Provide haptic feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo capture failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildCameraView()),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF4CAF50),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.camera_alt, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.attendanceType == 'check_in' ? 'Check In' : 'Check Out'} Photo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.driverName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    if (_capturedPhotoPath != null) {
      return _buildPhotoPreview();
    }

    return _buildCameraPreview();
  }

  Widget _buildCameraPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // TODO: Replace with actual camera preview
            /*
            if (_cameraController != null && _cameraController!.value.isInitialized)
              AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              )
            else
            */
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Camera Preview\n(Demo Mode)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Capture guidelines overlay
            Positioned.fill(
              child: CustomPaint(
                painter: FaceGuidePainter(),
              ),
            ),
            
            // Instructions overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Position your face within the oval guide',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // TODO: Show actual captured image
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey.shade100,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Photo Captured Successfully!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Retake button
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    _capturedPhotoPath = null;
                  });
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.refresh, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cancel Button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          
          // Capture/Confirm Button
          if (_capturedPhotoPath == null)
            FloatingActionButton.large(
              onPressed: _isCapturing ? null : _capturePhoto,
              backgroundColor: const Color(0xFF4CAF50),
              child: _isCapturing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.white, size: 32),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                widget.onPhotoCapture(_capturedPhotoPath!);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirm Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for face guide overlay
class FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    // Draw oval guide
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2, height: radius * 2.5),
      paint,
    );

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final cornerSize = 20.0;
    
    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - radius, center.dy - radius * 1.25 + cornerSize)
        ..lineTo(center.dx - radius, center.dy - radius * 1.25)
        ..lineTo(center.dx - radius + cornerSize, center.dy - radius * 1.25),
      cornerPaint,
    );
    
    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + radius - cornerSize, center.dy - radius * 1.25)
        ..lineTo(center.dx + radius, center.dy - radius * 1.25)
        ..lineTo(center.dx + radius, center.dy - radius * 1.25 + cornerSize),
      cornerPaint,
    );
    
    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - radius, center.dy + radius * 1.25 - cornerSize)
        ..lineTo(center.dx - radius, center.dy + radius * 1.25)
        ..lineTo(center.dx - radius + cornerSize, center.dy + radius * 1.25),
      cornerPaint,
    );
    
    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + radius - cornerSize, center.dy + radius * 1.25)
        ..lineTo(center.dx + radius, center.dy + radius * 1.25)
        ..lineTo(center.dx + radius, center.dy + radius * 1.25 - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}