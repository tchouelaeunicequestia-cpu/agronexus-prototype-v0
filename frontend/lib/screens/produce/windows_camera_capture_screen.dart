import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../services/image_picker_model.dart';

class WindowsCameraCaptureScreen extends StatefulWidget {
  const WindowsCameraCaptureScreen({super.key});

  @override
  State<WindowsCameraCaptureScreen> createState() =>
      _WindowsCameraCaptureScreenState();
}

class _WindowsCameraCaptureScreenState
    extends State<WindowsCameraCaptureScreen> {
  CameraController? _controller;
  String? _error;
  bool _loading = true;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera was found on this device.');
      }

      final camera = cameras.firstWhere(
        (description) => description.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _loading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to start the camera: $error';
        });
      }
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final image = PickedProduceImage(
        bytes: Uint8List.fromList(bytes),
        dataUrl: 'data:image/jpeg;base64,${base64Encode(bytes)}',
        name: file.name,
      );
      if (mounted) Navigator.of(context).pop(image);
    } catch (error) {
      if (mounted) {
        setState(() {
          _capturing = false;
          _error = 'Unable to capture a photo: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Capture Harvest Photo'),
        backgroundColor: const Color(0xF2FFFFFF),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SafeArea(
        child: Center(
          child: _loading
              ? const CircularProgressIndicator(color: Color(0xFF0F5132))
              : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.no_photography_outlined,
                        color: Color(0xFF0F5132),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to List Crop'),
                      ),
                    ],
                  ),
                )
              : controller == null || !controller.value.isInitialized
              ? const Text(
                  'Camera preview is unavailable.',
                  style: TextStyle(color: Color(0xFF0F172A)),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: CameraPreview(controller),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: FilledButton.icon(
                        onPressed: _capturing ? null : _takePicture,
                        icon: _capturing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded),
                        label: Text(
                          _capturing ? 'Capturing...' : 'Capture Photo',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5132),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
