// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';

import '../services/api_service.dart';
import '../services/platform_services.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cniController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedRole;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLocationCaptured = false;
  bool _isFaceScanned = false;
  bool _isCniScanned = false;
  double? _lat;
  double? _lon;
  XFile? _cniImage;
  XFile? _faceImage;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnim;

  final List<Map<String, dynamic>> _roles = [
    {
      'value': 'FARMER',
      'label': 'Farmer',
      'desc': 'Producer / Yield',
      'icon': Icons.agriculture_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'value': 'BUYER',
      'label': 'Buyer',
      'desc': 'Off-taker / Wholesale',
      'icon': Icons.shopping_bag_outlined,
      'color': const Color(0xFF3B82F6),
    },
    {
      'value': 'TRANSPORTER',
      'label': 'Transporter',
      'desc': 'Fleet & Hauler',
      'icon': Icons.local_shipping_outlined,
      'color': const Color(0xFFF59E0B),
    },
    {
      'value': 'AGRONOMIST',
      'label': 'Agronomist',
      'desc': 'Soil & Auditor',
      'icon': Icons.psychology_outlined,
      'color': const Color(0xFF8B5CF6),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cniController.dispose();
    _phoneController.dispose();
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  static const int _totalSteps = 5; // Updated to include CNI document capture step

  bool get _isRoleSelected => _selectedRole != null;

  bool get _isPersonalDetailsComplete =>
      _validName(_nameController.text) == null &&
      _validCni(_cniController.text) == null &&
      _validPhone(_phoneController.text) == null &&
      _validEmail(_emailController.text) == null &&
      _validPassword(_passwordController.text) == null;

  String? _validName(String value) =>
      value.trim().length < 2 ? 'Enter your full legal name' : null;

  String? _validEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
        ? null
        : 'Enter a valid email address';
  }

  String? _validPhone(String value) {
    final phone = value.trim();
    return RegExp(r'^\+?[1-9]\d{7,14}$').hasMatch(phone)
        ? null
        : 'Use an international phone format, e.g. +237...';
  }

  String? _validCni(String value) =>
      value.trim().length < 5 ? 'Enter a valid national ID number' : null;

  String? _validPassword(String? rawValue) {
    final value = rawValue ?? '';
    if (value.length < 10) return 'Use at least 10 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Use upper, lower, and numeric characters';
    }
    return null;
  }

  int get _completedSteps {
    var completed = 0;
    if (_isRoleSelected) completed++;
    if (_isPersonalDetailsComplete) completed++;
    if (_isCniScanned) completed++;
    if (_isFaceScanned) completed++;
    if (_isLocationCaptured) completed++;
    return completed;
  }

  double get _completionProgress => _completedSteps / _totalSteps;

  String get _currentStageLabel {
    if (_completedSteps == _totalSteps) return 'All Steps Complete';
    if (!_isRoleSelected) return 'Choose Your Role';
    if (!_isCniScanned) return 'National ID Document Scan';
    if (!_isFaceScanned) return 'Biometric Verification';
    if (!_isLocationCaptured) return 'Location Capture';
    return 'Personal Details';
  }

  Future<void> _handleCniScan() async {
    XFile? capturedImage = _cniImage;
    bool scanComplete = _isCniScanned;
    String statusMessage = _isCniScanned
        ? 'National ID card photo captured & verified successfully!'
        : 'Position your physical National ID / CNI card and tap capture.';

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> performCniCapture() async {
              try {
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.camera,
                  preferredCameraDevice: CameraDevice.rear,
                  imageQuality: 85,
                );
                if (photo != null) {
                  setDialogState(() {
                    capturedImage = photo;
                    scanComplete = true;
                    statusMessage = 'National ID document captured! Review the preview below.';
                  });
                } else {
                  setDialogState(() {
                    statusMessage = 'Capture cancelled. Try again.';
                  });
                }
              } catch (e) {
                setDialogState(() {
                  scanComplete = false;
                  statusMessage = 'Camera error: ${e.toString().replaceAll("Exception: ", "")}';
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.badge_rounded,
                    color: Color(0xFF0f5132),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'National ID / CNI Photo Capture',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0f5132),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: scanComplete
                              ? const Color(0xFF16a34a)
                              : const Color(0xFF404942),
                          fontWeight: scanComplete
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 180,
                        width: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF002615),
                          border: Border.all(
                            color: scanComplete
                                ? const Color(0xFF16a34a)
                                : const Color(0xFF6cf8bb),
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: capturedImage != null
                              ? Image.file(
                                  File(capturedImage!.path),
                                  fit: BoxFit.cover,
                                  width: 280,
                                  height: 180,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.credit_card_rounded,
                                    color: Color(0xFF81c784),
                                    size: 56,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!scanComplete)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0f5132),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: performCniCapture,
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Open Camera'),
                        ),
                      if (scanComplete)
                        TextButton.icon(
                          onPressed: () async {
                            setDialogState(() {
                              scanComplete = false;
                              capturedImage = null;
                              statusMessage = 'Position your ID card and tap capture.';
                            });
                          },
                          icon: const Icon(Icons.refresh, color: Color(0xFF0f5132)),
                          label: const Text('Retake Photo',
                              style: TextStyle(color: Color(0xFF0f5132))),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0f5132),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: scanComplete
                      ? () {
                          setState(() {
                            _isCniScanned = true;
                            _cniImage = capturedImage;
                          });
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('National ID Photo Confirmed!'),
                              backgroundColor: Color(0xFF0f5132),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  child: const Text('Save CNI Photo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleBiometricScan() async {
    XFile? capturedFace = _faceImage;
    bool scanComplete = _isFaceScanned;
    String statusMessage = _isFaceScanned
        ? 'Biometric identity verified successfully!'
        : 'Position your face in frame and tap capture.';

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> performFaceCapture() async {
              try {
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.camera,
                  preferredCameraDevice: CameraDevice.front,
                  imageQuality: 85,
                );
                if (photo != null) {
                  setDialogState(() {
                    capturedFace = photo;
                    scanComplete = true;
                    statusMessage = 'Face captured! Review your photo below.';
                  });
                } else {
                  setDialogState(() {
                    statusMessage = 'Capture cancelled. Try again.';
                  });
                }
              } catch (e) {
                setDialogState(() {
                  scanComplete = false;
                  statusMessage = 'Camera error: ${e.toString().replaceAll("Exception: ", "")}';
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.face_retouching_natural_rounded,
                    color: Color(0xFF0f5132),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Live Face Scan Verification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0f5132),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: scanComplete
                              ? const Color(0xFF16a34a)
                              : const Color(0xFF404942),
                          fontWeight: scanComplete
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 180,
                        width: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF002615),
                          border: Border.all(
                            color: scanComplete
                                ? const Color(0xFF16a34a)
                                : const Color(0xFF6cf8bb),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: capturedFace != null
                              ? Image.file(
                                  File(capturedFace!.path),
                                  fit: BoxFit.cover,
                                  width: 180,
                                  height: 180,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.face_rounded,
                                    color: Color(0xFF81c784),
                                    size: 68,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!scanComplete)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0f5132),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: performFaceCapture,
                          icon: const Icon(Icons.camera_front_rounded),
                          label: const Text('Open Front Camera'),
                        ),
                      if (scanComplete)
                        TextButton.icon(
                          onPressed: () async {
                            setDialogState(() {
                              scanComplete = false;
                              capturedFace = null;
                              statusMessage = 'Position your face and tap capture.';
                            });
                          },
                          icon: const Icon(Icons.refresh, color: Color(0xFF0f5132)),
                          label: const Text('Retake Selfie',
                              style: TextStyle(color: Color(0xFF0f5132))),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0f5132),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: scanComplete
                      ? () {
                          setState(() {
                            _isFaceScanned = true;
                            _faceImage = capturedFace;
                          });
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Live Face Scan Identity Confirmed!'),
                              backgroundColor: Color(0xFF0f5132),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  child: const Text('Save Verification'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _recalibrateGps() async {
    try {
      final locService = LocationServiceFactory.getService();
      final pos = await locService.getCurrentLocation();
      setState(() {
        _lat = pos.latitude;
        _lon = pos.longitude;
        _isLocationCaptured = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS Coordinates Recalibrated Successfully!'),
            backgroundColor: Color(0xFF0f5132),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'GPS Error: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: const Color(0xFFba1a1a),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isRoleSelected) {
      _showRegistrationError('Please choose your ecosystem role first.');
      return;
    }
    if (!_isCniScanned) {
      _showRegistrationError(
        'Please capture your National ID / CNI document photo first.',
      );
      return;
    }
    if (!_isFaceScanned) {
      _showRegistrationError(
        'Please complete the Live Face Scan verification first.',
      );
      return;
    }
    if (!_isLocationCaptured || _lat == null || _lon == null) {
      _showRegistrationError(
        'Please acquire your Geo-Spatial GPS location first.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final registrationData = await ApiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        nationalId: _cniController.text.trim(),
        biometricVerified: _isFaceScanned,
        cniVerified: _isCniScanned,
        role: _selectedRole!,
        latitude: _lat,
        longitude: _lon,
        cniImage: _cniImage,
        faceImage: _faceImage,
      );
      final contactsVerified = await _verifyContactChannels();
      if (!contactsVerified) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${registrationData['message']?.toString() ?? 'Registration successful.'} '
              'Email and phone verified.',
            ),
            backgroundColor: Color(0xFF0f5132),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showRegistrationError(
          'Registration Error: ${e.toString().replaceAll("Exception: ", "")}',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRegistrationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFba1a1a),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _verifyContactChannels() async {
    final emailCodeController = TextEditingController();
    final phoneCodeController = TextEditingController();
    try {
      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Verify your contact details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter the one-time codes sent to your email and phone. Your account cannot be activated until both are verified.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Email OTP',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Phone OTP',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      await ApiService.verifyRegistrationCode(
                        email: _emailController.text.trim(),
                        channel: 'EMAIL',
                        code: emailCodeController.text.trim(),
                      );
                      await ApiService.verifyRegistrationCode(
                        email: _emailController.text.trim(),
                        channel: 'PHONE',
                        code: phoneCodeController.text.trim(),
                      );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Verify'),
                ),
              ],
            ),
          ) ??
          false;
    } finally {
      emailCodeController.dispose();
      phoneCodeController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showPanel = constraints.maxWidth >= 900;
            return Row(
              children: [
                if (showPanel) Expanded(child: _buildPremiumLeftPanel()),
                Expanded(
                  flex: showPanel ? 1 : 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildFormContent(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumLeftPanel() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAeQ1oQkkQylhbor-QfqoLQ9Yls4uOQhf9ZDXJAy_QHbCeETZN7Lg0tRwMbWbkWJe4nT1Uq9gZirqlhqZVdj8-yXG-sSpZyv3NwJkqIWaGPuWf9sYOT-RvfYbVRshioZdYZ9kxdw5kd78n_4-_DAzkAEz-eZ3R_pf5Cl6ciHJHVVYaLaX6Y5TntGzHa4_4TkOa_9GnCxXSlsmQDoomG8UwDUlQaTamHUXmnicPWGVbzKM7R6z7DXuQl',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.45),
            BlendMode.darken,
          ),
        ),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLiveBadge(),
              const SizedBox(height: 20),
              const Text(
                'Join the Verified\nAgricultural Network',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const Text(
                'Verifiable',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'One secure identity for every participant in the Central African food supply chain.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFe2e8f0),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildFeatureHighlightCard(
                icon: Icons.verified_user_outlined,
                title: 'Zero-Knowledge Identity',
                description:
                    'Verify once without exposing sensitive biometric data.',
              ),
              const SizedBox(height: 12),
              _buildFeatureHighlightCard(
                icon: Icons.hub_outlined,
                title: 'Role-Based Access Control',
                description: 'Every Farmer, Buyer, Transporter, and Agronomist gets the right access.',
              ),
              const SizedBox(height: 12),
              _buildFeatureHighlightCard(
                icon: Icons.satellite_alt_outlined,
                title: 'Geo-Spatial Origin Lock',
                description: 'Produce records tied to verified land coordinates via PostGIS.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            child: const Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 6,
              children: [
                Text(
                  'Backend: Spring Boot 3.3 · Java 21',
                  style: TextStyle(fontSize: 11, color: Color(0xFFcbd5e1)),
                ),
                Text(
                  'v4.2.0 Release',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF4ade80),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF4ade80),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Central African AgTech Mesh',
              style: TextStyle(
                color: Color(0xFF6cf8bb),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHighlightCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF22c55e).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4ade80), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFcbd5e1),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FORM CONTENT (RIGHT PANEL)
  Widget _buildFormContent() {
    final currentProgress = _completionProgress;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Enroll your verified ecosystem workspace on the AgroNexus ledger',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Centre Hub',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 7,
                            height: 7,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF0f5132),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '$_currentStageLabel · Stage $_completedSteps of $_totalSteps',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0f5132),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(currentProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0f5132),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: currentProgress,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF0f5132),
                      ),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'ECOSYSTEM ROLE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: _roles.map((role) {
                final isSelected = _selectedRole == role['value'];
                final roleColor = role['color'] as Color;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () => setState(
                        () => _selectedRole = role['value'] as String,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0f5132)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0f5132)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0f5132)
                                        .withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? roleColor.withValues(alpha: 0.15)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                role['icon'] as IconData,
                                color: isSelected
                                    ? roleColor
                                    : const Color(0xFF94A3B8),
                                size: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              role['label'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // CNI Document Card right next to/grouped with ID input flow
            _buildActionCard(
              icon: Icons.badge_rounded,
              label: 'National ID / CNI Document Scan',
              status: _isCniScanned ? 'ID Scanned ✓' : 'Pending ID Photo',
              statusOk: _isCniScanned,
              buttonText: _isCniScanned ? 'Re-capture' : 'Scan ID Card',
              onTap: _handleCniScan,
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              icon: Icons.face_retouching_natural_rounded,
              label: 'Live Biometric Scan',
              status: _isFaceScanned ? 'Verified ✓' : 'Pending Scan',
              statusOk: _isFaceScanned,
              buttonText: _isFaceScanned ? 'Re-Verify' : 'Verify Now',
              onTap: _handleBiometricScan,
            ),
            const SizedBox(height: 10),
            _buildGpsCard(),
            const SizedBox(height: 18),

            const Text(
              'PERSONAL DETAILS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            _buildField(
              controller: _nameController,
              label: 'Full Legal Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
              onChanged: (_) => setState(() {}),
              validator: (value) => _validName(value ?? ''),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _cniController,
                    label: 'National ID (CNI)',
                    hint: 'CNI number',
                    icon: Icons.badge_outlined,
                    onChanged: (_) => setState(() {}),
                    validator: (value) => _validCni(value ?? ''),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '+237...',
                    icon: Icons.phone_outlined,
                    onChanged: (_) => setState(() {}),
                    validator: (value) => _validPhone(value ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildField(
              controller: _emailController,
              label: 'Official Hub Email',
              hint: 'user@agronexus.io',
              icon: Icons.email_outlined,
              onChanged: (_) => setState(() {}),
              validator: (value) => _validEmail(value ?? ''),
            ),
            const SizedBox(height: 10),
            _buildPasswordField(onChanged: (_) => setState(() {})),
            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0f5132),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                onPressed: _isLoading ? null : _submitRegister,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Complete Verification & Enroll',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Already have an account?',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF0f5132),
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String status,
    required bool statusOk,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: statusOk ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        border: Border.all(
          color: statusOk ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusOk
                  ? const Color(0xFF0f5132)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: statusOk
                  ? const Color(0xFF6cf8bb)
                  : const Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: statusOk
                        ? const Color(0xFF065F46)
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(
                color: statusOk
                    ? const Color(0xFF0f5132)
                    : const Color(0xFFD97706),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onTap,
            child: Text(
              buttonText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusOk
                    ? const Color(0xFF0f5132)
                    : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isLocationCaptured
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFFBEB),
        border: Border.all(
          color: _isLocationCaptured
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFDE68A),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isLocationCaptured
                  ? const Color(0xFF0f5132)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: _isLocationCaptured
                  ? const Color(0xFF6cf8bb)
                  : const Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Geo-Spatial GPS Sync',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isLocationCaptured && _lat != null && _lon != null
                      ? 'Lat: ${_lat!.toStringAsFixed(5)}\u00b0, Lon: ${_lon!.toStringAsFixed(5)}\u00b0'
                      : 'Coordinates not yet acquired',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _isLocationCaptured
                        ? const Color(0xFF065F46)
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(
                color: _isLocationCaptured
                    ? const Color(0xFF0f5132)
                    : const Color(0xFFD97706),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _recalibrateGps,
            icon: Icon(
              Icons.my_location_rounded,
              size: 12,
              color: _isLocationCaptured
                  ? const Color(0xFF0f5132)
                  : const Color(0xFFB45309),
            ),
            label: Text(
              _isLocationCaptured ? 'Re-sync' : 'Acquire GPS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _isLocationCaptured
                    ? const Color(0xFF0f5132)
                    : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0f5132), width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1)),
      ),
      validator:
          validator ?? (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _buildPasswordField({void Function(String)? onChanged}) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Escrow Vault Password',
        hintText: 'Min 10 characters',
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: const Color(0xFF94A3B8),
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0f5132), width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1)),
      ),
      validator: _validPassword,
    );
  }
}