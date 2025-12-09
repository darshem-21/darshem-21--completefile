import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CameraCaptureWidget extends StatefulWidget {
  const CameraCaptureWidget({super.key});

  @override
  State<CameraCaptureWidget> createState() => _CameraCaptureWidgetState();
}

class _CameraCaptureWidgetState extends State<CameraCaptureWidget>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  double _zoomLevel = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 8.0;
  final List<XFile> _capturedImages = [];
  late AnimationController _captureAnimation;

  @override
  void initState() {
    super.initState();
    _captureAnimation = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _captureAnimation.dispose();
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true; // Browser handles permissions

    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          _showNoCameraDialog();
        }
        return;
      }

      // Select camera (prefer back camera for mobile, front for web)
      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Apply platform-specific settings
      await _applySettings();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to initialize camera');
      }
    }
  }

  Future<void> _applySettings() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Set focus mode
      await _cameraController!.setFocusMode(FocusMode.auto);

      // Set flash mode (only for mobile)
      if (!kIsWeb) {
        try {
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (e) {
          // Flash not supported, ignore
        }
      }

      // Get zoom levels
      _minZoom = await _cameraController!.getMinZoomLevel();
      _maxZoom = await _cameraController!.getMaxZoomLevel();

      // Limit max zoom to reasonable level
      _maxZoom = _maxZoom > 8.0 ? 8.0 : _maxZoom;
    } catch (e) {
      // Settings not supported, continue without them
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Trigger capture animation
      _captureAnimation.forward().then((_) {
        _captureAnimation.reverse();
      });

      // Provide haptic feedback
      HapticFeedback.mediumImpact();

      // Capture photo
      final XFile photo = await _cameraController!.takePicture();

      setState(() {
        _capturedImages.add(photo);
      });

      Fluttertoast.showToast(
        msg: "Photo captured! (${_capturedImages.length})",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        textColor: AppTheme.lightTheme.colorScheme.onTertiary,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to capture photo",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        textColor: AppTheme.lightTheme.colorScheme.onError,
      );
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    try {
      if (kIsWeb) return true;
      var status = await Permission.photos.request();
      if (status.isGranted) return true;
      status = await Permission.storage.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _toggleFlash() async {
    if (kIsWeb ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newFlashMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      // Flash not supported
      Fluttertoast.showToast(
        msg: "Flash not supported",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
      await _cameraController!.setZoomLevel(clampedZoom);
      setState(() {
        _zoomLevel = clampedZoom;
      });
    } catch (e) {
      // Zoom not supported
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    try {
      final currentLensDirection = _cameraController!.description.lensDirection;
      final newCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection != currentLensDirection,
        orElse: () => _cameras.first,
      );

      await _cameraController!.dispose();

      _cameraController = CameraController(
        newCamera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _applySettings();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showErrorDialog('Failed to switch camera');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      if (!kIsWeb) {
        final ok = await _ensureGalleryPermission();
        if (!ok) {
          Fluttertoast.showToast(
            msg: "Photos permission required",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            textColor: AppTheme.lightTheme.colorScheme.onError,
          );
          return;
        }
      }
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _capturedImages.addAll(images);
        });

        Fluttertoast.showToast(
          msg: "${images.length} image(s) selected",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          textColor: AppTheme.lightTheme.colorScheme.onTertiary,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to pick images",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        textColor: AppTheme.lightTheme.colorScheme.onError,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
            'This app needs camera permission to capture product photos.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showNoCameraDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Camera Available'),
        content: const Text('No camera found on this device.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Initializing camera...',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: CameraPreview(_cameraController!),
        ),

        // Capture animation overlay
        AnimatedBuilder(
          animation: _captureAnimation,
          builder: (context, child) {
            return Container(
              color:
                  Colors.white.withValues(alpha: _captureAnimation.value * 0.7),
            );
          },
        ),

        // Top controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomIconWidget(
                        iconName: 'close',
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Flash button (mobile only)
                  if (!kIsWeb)
                    GestureDetector(
                      onTap: _toggleFlash,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: _isFlashOn
                              ? AppTheme.lightTheme.colorScheme.secondary
                                  .withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CustomIconWidget(
                          iconName: _isFlashOn ? 'flash_on' : 'flash_off',
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  if (!kIsWeb) SizedBox(width: 2.w),

                  // Switch camera button
                  if (_cameras.length > 1)
                    GestureDetector(
                      onTap: _switchCamera,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CustomIconWidget(
                          iconName: 'flip_camera_ios',
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Zoom slider (mobile only)
        if (!kIsWeb && _maxZoom > _minZoom)
          Positioned(
            right: 4.w,
            top: 20.h,
            bottom: 20.h,
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: _zoomLevel,
                min: _minZoom,
                max: _maxZoom,
                onChanged: _setZoom,
                activeColor: AppTheme.lightTheme.colorScheme.secondary,
                inactiveColor: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomIconWidget(
                        iconName: 'photo_library',
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Capture button
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'camera_alt',
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Captured images counter
                  GestureDetector(
                    onTap: _capturedImages.isNotEmpty
                        ? () => Navigator.pop(context, _capturedImages)
                        : null,
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: _capturedImages.isNotEmpty
                            ? AppTheme.lightTheme.colorScheme.primary
                            : Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'check',
                            size: 20,
                            color: Colors.white,
                          ),
                          if (_capturedImages.isNotEmpty) ...[
                            SizedBox(width: 1.w),
                            Text(
                              '${_capturedImages.length}',
                              style: AppTheme.lightTheme.textTheme.titleSmall
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedImagesPreview() {
    if (_capturedImages.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 12.h,
      margin: EdgeInsets.all(4.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _capturedImages.length,
        itemBuilder: (context, index) {
          final image = _capturedImages[index];
          return Container(
            width: 12.h,
            margin: EdgeInsets.only(right: 2.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: kIsWeb
                      ? Image.network(
                          image.path,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(image.path),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 1.w,
                  right: 1.w,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: EdgeInsets.all(0.5.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CustomIconWidget(
                        iconName: 'close',
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 95.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: _buildCameraPreview(),
          ),
          _buildCapturedImagesPreview(),
        ],
      ),
    );
  }
}
