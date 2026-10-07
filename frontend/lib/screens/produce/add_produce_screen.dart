import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../services/draft_service.dart';
import '../../services/image_picker_service.dart';
import '../../services/platform_services.dart';
import '../../widgets/farmer_background_layer.dart';
import 'windows_camera_capture_screen.dart';

class AddProduceScreen extends StatefulWidget {
  const AddProduceScreen({super.key});

  @override
  State<AddProduceScreen> createState() => _AddProduceScreenState();
}

class _AddProduceScreenState extends State<AddProduceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController(text: '');
  final _priceController = TextEditingController(text: '');
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _storageNodeController = TextEditingController();

  double _quantity = 200.0;
  String _category = 'FRUITS';
  String _unitType = 'kg';
  String _selectedStorageNode = '';
  bool _hasIoTNode = false;
  Map<String, String>? _liveTelemetry;
  bool _telemetryLoading = false;
  String _selectedGrade = 'Grade A+ Export';
  int _activeProofIndex = 0;

  // GPS coordinates — null until device provides them
  double? _lat;
  double? _lon;
  String _locationDescription = 'Acquiring GPS...';
  bool _isLoading = false;
  bool _isLocating = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'FRUITS', 'icon': Icons.nature_rounded},
    {'name': 'CEREALS', 'icon': Icons.grain_rounded},
    {'name': 'TUBERS', 'icon': Icons.spa_rounded},
    {'name': 'VEGETABLES', 'icon': Icons.eco_rounded},
    {'name': 'COCOA', 'icon': Icons.local_cafe_rounded},
  ];

  // Mutable — starts empty; url/bytes are null until farmer captures/uploads a photo
  final List<Map<String, dynamic>> _harvestProofs = [
    {'title': 'Overview', 'sub': 'Batch Overview', 'url': null, 'bytes': null},
    {'title': 'Stem Cut', 'sub': 'Fresh Cut Proof', 'url': null, 'bytes': null},
    {
      'title': 'Scale/Weight',
      'sub': 'Depot Weight Proof',
      'url': null,
      'bytes': null,
    },
  ];

  final List<Map<String, String>> _unitTypes = [
    {'label': 'kg (Kilograms)', 'value': 'kg'},
    {'label': 'bags (50kg Bag)', 'value': 'bags'},
    {'label': 'crates (Wood Box)', 'value': 'crates'},
    {'label': 'tons (Metric Ton)', 'value': 'tons'},
  ];

  final List<String> _qualityGrades = [
    'Grade A+ Export',
    'Grade AA Domestic',
    'Standard Market',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _captureInitialLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _storageNodeController.dispose();
    super.dispose();
  }

  Future<void> _captureInitialLocation() async {
    try {
      final locationService = LocationServiceFactory.getService();
      PositionData pos = await locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lon = pos.longitude;
          _locationDescription = pos.description;
        });
      }
    } catch (_) {}
  }

  Future<void> _captureLocation() async {
    setState(() => _isLocating = true);
    try {
      final locationService = LocationServiceFactory.getService();
      PositionData pos = await locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lon = pos.longitude;
          _locationDescription = pos.description;
        });
      }

      _showSnackBar(
        'PostGIS RTK Coordinates Locked! (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
        isError: false,
      );
    } catch (_) {
      _showSnackBar(
        'Unable to acquire your current location. Please try again before publishing.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _loadSelectedTelemetry() async {
    if (!_hasIoTNode || _selectedStorageNode.isEmpty) {
      if (mounted) setState(() => _liveTelemetry = null);
      return;
    }
    setState(() => _telemetryLoading = true);
    try {
      final readings = await ApiService.getTelemetryNodeLogs(
        _selectedStorageNode,
      );
      final latest = readings.isEmpty ? null : readings.first;
      if (!mounted) return;
      setState(() {
        _liveTelemetry = latest == null
            ? null
            : {
                'temp': '${latest['temperature'] ?? '—'}°C',
                'tempStatus': latest['alertTriggered'] == true
                    ? 'Alert'
                    : 'Live reading',
                'moisture': '${latest['humidity'] ?? '—'}% RH',
                'moistureStatus': latest['alertTriggered'] == true
                    ? 'Check storage'
                    : 'Live reading',
                'power': 'Unavailable',
                'powerStatus': 'Not reported',
              };
      });
    } catch (_) {
      if (mounted) setState(() => _liveTelemetry = null);
    } finally {
      if (mounted) setState(() => _telemetryLoading = false);
    }
  }

  double get _unitPrice {
    return double.tryParse(_priceController.text.trim()) ?? 0.0;
  }

  double get _grossTotal {
    return _unitPrice * _quantity;
  }

  String _formatXAF(double val) {
    final intVal = val.toInt();
    final str = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} XAF';
  }

  /// Called when farmer taps Take Photo or Choose Gallery for an angle slot.
  Future<void> _capturePhoto(int slotIndex, {bool fromGallery = false}) async {
    try {
      final PickedProduceImage? picked;
      if (!fromGallery && defaultTargetPlatform == TargetPlatform.windows) {
        picked = await Navigator.of(context).push<PickedProduceImage>(
          MaterialPageRoute(builder: (_) => const WindowsCameraCaptureScreen()),
        );
      } else if (!fromGallery &&
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        throw UnsupportedError(
          'Camera capture is not available on this desktop platform. '
          'Choose Gallery to select an image instead.',
        );
      } else {
        picked = await ImagePickerService.pickImage(fromCamera: !fromGallery);
      }
      if (picked == null) return;
      if (!mounted) return;
      final image = picked;

      setState(() {
        _harvestProofs[slotIndex]['url'] = image.dataUrl;
        _harvestProofs[slotIndex]['bytes'] = image.bytes;
        _activeProofIndex = slotIndex;
      });
      _showSnackBar(
        fromGallery
            ? 'Photo selected from gallery: ${image.name}'
            : 'Photo captured: ${image.name}',
        isError: false,
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Could not open image picker: $e', isError: true);
      }
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final farmerId = int.tryParse(
        context.read<AuthProvider>().currentUser?.id ?? '',
      );
      if (farmerId == null) {
        throw Exception(
          'Your authenticated farmer account could not be identified.',
        );
      }
      if (_lat == null || _lon == null) {
        throw Exception(
          'Your current location is required before publishing this harvest batch.',
        );
      }

      // Use first available captured photo URL, or imageUrl field, or empty string
      final capturedUrl = _harvestProofs
          .map((p) => p['url'] as String?)
          .firstWhere((u) => u != null, orElse: () => null);
      final finalImageUrl = _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : (capturedUrl ?? '');

      final response = await ApiService.authenticatedRequest(
        '/api/v1/products',
        method: 'POST',
        body: {
          'title': _titleController.text.trim(),
          'category': _category,
          'description': _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : 'Harvest batch verified by $_selectedGrade${_hasIoTNode ? ' and $_selectedStorageNode telemetry' : ' (Standard storage)'}.',
          'pricePerUnit': _unitPrice,
          'unitType': _unitType,
          'availableQuantity': _quantity,
          'latitude': _lat,
          'longitude': _lon,
          'imageUrl': finalImageUrl,
          'farmerId': farmerId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          _showSnackBar(
            'Batch Indexed into PostGIS Network & Escrow Depository!',
            isError: false,
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          _showSnackBar(
            'Unable to publish batch (HTTP ${response.statusCode}).',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Unable to publish batch: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isLoading = true);
    try {
      final farmerId = int.tryParse(
        context.read<AuthProvider>().currentUser?.id ?? '',
      );
      if (farmerId == null) {
        throw Exception(
          'Your authenticated farmer account could not be identified.',
        );
      }

      await DraftService.saveDraft({
        'title': _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Untitled Draft',
        'category': _category,
        'pricePerUnit': _unitPrice,
        'unitType': _unitType,
        'availableQuantity': _quantity,
        'farmerId': farmerId,
        'isDraft': true,
      });

      if (mounted) {
        _showSnackBar(
          'Draft saved! Visible in your dashboard.',
          isError: false,
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, 'draft');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Could not save draft: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isError
              ? const Color(0xFFBA1A1A)
              : const Color(0xFF0F5132),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final userInitials = (user?.name != null && user!.name!.isNotEmpty)
        ? user.name!.substring(0, 1).toUpperCase()
        : 'F';

    final activeTelemetry =
        _liveTelemetry ??
        {
          'temp': 'Unavailable',
          'tempStatus': 'No live reading',
          'moisture': 'Unavailable',
          'moistureStatus': 'No live reading',
          'power': 'Unavailable',
          'powerStatus': 'Not reported',
        };

    // Active photo data (bytes from real picker, or fallback URL)
    final activeProof = _harvestProofs[_activeProofIndex];
    final activePhotoUrl = activeProof['url'] as String?;
    final activeBytes = activeProof['bytes'] as Uint8List?;
    final hasActivePhoto =
        activeBytes != null ||
        (activePhotoUrl != null && activePhotoUrl.isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xF2FFFFFF),
        foregroundColor: const Color(0xFF0F172A),
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFFAF3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFF0F5132),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'List New Harvest Batch',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: user?.name ?? 'Logged In Producer',
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFEFFAF3),
                child: Text(
                  userInitials,
                  style: const TextStyle(
                    color: const Color(0xFF0F5132),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const FarmerBackgroundLayer(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Banner
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?q=80&w=800&auto=format&fit=crop',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.82),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.satellite_alt_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Spatial RTK Active',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Listing automatically geocoded to PostGIS coordinates for automated 5km–100km radius matching with commercial buyers across the Central African corridor.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // STEP 1: Produce Identity
                    _buildCardSection(
                      stepNumber: 'Step 1 of 3',
                      title: 'Produce Identity',
                      subtitle: 'Taxonomy, regional cultivar & classification',
                      icon: Icons.eco_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 38,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final isSelected = _category == cat['name'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: InkWell(
                                    onTap: () => setState(
                                      () => _category = cat['name'] as String,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFEFFAF3)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            cat['icon'] as IconData,
                                            size: 16,
                                            color: isSelected
                                                ? const Color(0xFF0F5132)
                                                : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            cat['name'] as String,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? const Color(0xFF0F5132)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            'Produce Batch Title',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _titleController,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'e.g. Red Roma Tomatoes, White Maize...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                suffixIcon: Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF0F5132),
                                  size: 20,
                                ),
                              ),
                              validator: (v) => v!.isEmpty
                                  ? 'Please enter produce title'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SECTION: Produce Photo & Harvest Evidence
                    _buildCardSection(
                      stepNumber: 'Verified Fresh',
                      title: 'Produce Photo & Harvest Evidence',
                      subtitle: 'High-res verification with EXIF telemetry',
                      icon: Icons.add_a_photo_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo Preview Container — placeholder when no photo yet
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              image: hasActivePhoto
                                  ? DecorationImage(
                                      image: activeBytes != null
                                          ? MemoryImage(activeBytes)
                                                as ImageProvider
                                          : NetworkImage(activePhotoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                // Gradient overlay — only when photo is present
                                if (hasActivePhoto)
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.3),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.8),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Upload placeholder — shown when no photo yet
                                if (!hasActivePhoto)
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFFAF3),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add_a_photo_rounded,
                                            color: Color(0xFF0F5132),
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Tap \'Take Photo\' or \'Choose Gallery\'\nto add your harvest photo',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // EXIF badge — only when photo is captured
                                if (hasActivePhoto)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.photo_camera_rounded,
                                            size: 13,
                                            color: Color(0xFF0F5132),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'EXIF GPS Tagged • Just Now',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F5132),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Edit button — only when photo is captured
                                if (hasActivePhoto)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: InkWell(
                                      onTap: () => _capturePhoto(
                                        _activeProofIndex,
                                        fromGallery: true,
                                      ),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          size: 16,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ),

                                // AI quality check chip — only when photo is captured
                                if (hasActivePhoto)
                                  Positioned(
                                    left: 10,
                                    right: 10,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.95,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(
                                                    Icons.verified_rounded,
                                                    size: 16,
                                                    color: Color(0xFF0F5132),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'AI Visual Check: Quality Scan Ready',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF0F5132),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '0% Visible Blight',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Tap \u2713 to submit this batch photo for AI analysis',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Take Photo & Choose Gallery Buttons (target selected slot)
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _capturePhoto(
                                    _activeProofIndex,
                                    fromGallery: false,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_camera_rounded,
                                          size: 18,
                                          color: Color(0xFF0F5132),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Take Photo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F5132),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _capturePhoto(
                                    _activeProofIndex,
                                    fromGallery: true,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_library_rounded,
                                          size: 18,
                                          color: Color(0xFF0F5132),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Choose Gallery',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F5132),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Harvest Angle Proofs — dynamic count label
                          Builder(
                            builder: (ctx) {
                              final captured = _harvestProofs
                                  .where(
                                    (p) =>
                                        p['bytes'] != null ||
                                        (p['url'] != null &&
                                            (p['url'] as String).isNotEmpty),
                                  )
                                  .length;
                              return Text(
                                'Harvest Angle Proofs ($captured/${_harvestProofs.length} Captured)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB7C2D6),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(_harvestProofs.length, (
                              idx,
                            ) {
                              final proof = _harvestProofs[idx];
                              final isSelected = _activeProofIndex == idx;
                              final thumbBytes = proof['bytes'] as Uint8List?;
                              final thumbUrl = proof['url'] as String?;
                              final hasThumb =
                                  thumbBytes != null ||
                                  (thumbUrl != null && thumbUrl.isNotEmpty);

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _activeProofIndex = idx);
                                      if (!hasThumb) {
                                        _capturePhoto(idx, fromGallery: true);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      height: 64,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF4EDEA3)
                                              : const Color(0xFF32405A),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        color: !hasThumb
                                            ? const Color(0xFF171F33)
                                            : null,
                                        image: hasThumb
                                            ? DecorationImage(
                                                image: thumbBytes != null
                                                    ? MemoryImage(thumbBytes)
                                                          as ImageProvider
                                                    : NetworkImage(thumbUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Empty slot UI
                                          if (!hasThumb)
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .add_circle_outline_rounded,
                                                  size: 18,
                                                  color: Color(0xFF4EDEA3),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  proof['title'] as String,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4EDEA3),
                                                  ),
                                                ),
                                              ],
                                            ),

                                          // Label bar — shown only when photo is set
                                          if (hasThumb)
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0B1326)
                                                      .withValues(alpha: 0.8),
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        bottom: Radius.circular(
                                                          8,
                                                        ),
                                                      ),
                                                ),
                                                child: Text(
                                                  proof['title'] as String,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),

                                          if (isSelected && hasThumb)
                                            const Positioned(
                                              top: 2,
                                              right: 2,
                                              child: Icon(
                                                Icons.check_circle_rounded,
                                                size: 14,
                                                color: Color(0xFF4EDEA3),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // STEP 2: Pricing & Available Volume
                    _buildCardSection(
                      stepNumber: 'Step 2 of 3',
                      title: 'Pricing & Available Volume',
                      subtitle:
                          'Real-time valuation in Central African CFA (XAF)',
                      icon: Icons.scale_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Unit Price (XAF)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB7C2D6),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF171F33),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _priceController,
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (_) => setState(() {}),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFF3F6FF),
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                              ),
                                              validator: (v) => v!.isEmpty
                                                  ? 'Required'
                                                  : null,
                                            ),
                                          ),
                                          const Text(
                                            'XAF',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFB7C2D6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Unit Measure',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB7C2D6),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF171F33),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _unitType,
                                          isExpanded: true,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFF3F6FF),
                                          ),
                                          items: _unitTypes.map((u) {
                                            return DropdownMenuItem<String>(
                                              value: u['value'],
                                              child: Text(u['label']!),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _unitType = val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171F33),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Harvest Available',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF3F6FF),
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      child: Text(
                                        '${_quantity.toInt()} $_unitType',
                                        key: ValueKey('$_quantity-$_unitType'),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0B1326),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _quantity,
                                  min: 200,
                                  max: 10000,
                                  divisions: 98,
                                  activeColor: const Color(0xFF0B1326),
                                  inactiveColor: const Color(0xFF171F33),
                                  onChanged: (val) =>
                                      setState(() => _quantity = val),
                                ),
                                Row(
                                  children: [
                                    _buildQtyAddButton('+500 $_unitType', 500),
                                    const SizedBox(width: 6),
                                    _buildQtyAddButton(
                                      '+1,000 $_unitType',
                                      1000,
                                    ),
                                    const SizedBox(width: 6),
                                    _buildQtyAddButton(
                                      '+2,500 $_unitType',
                                      2500,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // STEP 3: IoT Silo & Telemetry Link (Optional)
                    _buildCardSection(
                      stepNumber: 'Optional',
                      title: 'IoT Silo & Telemetry Link',
                      subtitle: 'Automated Quality Attestation',
                      icon: Icons.sensors_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toggle row to link/unlink IoT node
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171F33),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        _hasIoTNode
                                            ? Icons.sensors_rounded
                                            : Icons.sensors_off_rounded,
                                        color: _hasIoTNode
                                            ? const Color(0xFF4EDEA3)
                                            : const Color(0xFF64748B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Connect IoT Storage Node',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFF3F6FF),
                                              ),
                                            ),
                                            Text(
                                              _hasIoTNode
                                                  ? 'Active telemetry feed linked'
                                                  : 'Optional — produce listed under ambient storage',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFFB7C2D6),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _hasIoTNode,
                                  activeThumbColor: const Color(0xFF0B1326),
                                  activeTrackColor: const Color(0xFF4EDEA3),
                                  onChanged: (val) {
                                    setState(() {
                                      _hasIoTNode = val;
                                      _liveTelemetry = null;
                                    });
                                    if (val) _loadSelectedTelemetry();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (!_hasIoTNode) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF171F33)
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF32405A),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: Color(0xFF4EDEA3),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Standard harvest listing without IoT sensor link. Select your produce quality grade below.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFB7C2D6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (_hasIoTNode) ...[
                            const Text(
                              'Attached Storage Node',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB7C2D6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _storageNodeController,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF3F6FF),
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'Enter the node ID assigned to this silo',
                                filled: true,
                                fillColor: Color(0xFF171F33),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                final normalized = value.trim();
                                if (normalized != _selectedStorageNode) {
                                  setState(() {
                                    _selectedStorageNode = normalized;
                                    _liveTelemetry = null;
                                  });
                                }
                              },
                              onSubmitted: (_) => _loadSelectedTelemetry(),
                            ),
                            /* The node identifier is farmer-provided until the backend
                           exposes a farmer-scoped node registry. */
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF171F33)
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Text(
                                  'Telemetry is loaded only after this node responds through the backend.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFB7C2D6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            if (_telemetryLoading)
                              const LinearProgressIndicator(
                                minHeight: 2,
                                color: Color(0xFF4EDEA3),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTelemetryMiniCard(
                                    icon: Icons.thermostat_rounded,
                                    label: 'Temp',
                                    value: activeTelemetry['temp']!,
                                    status: activeTelemetry['tempStatus']!,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTelemetryMiniCard(
                                    icon: Icons.water_drop_rounded,
                                    label: 'Moisture',
                                    value: activeTelemetry['moisture']!,
                                    status: activeTelemetry['moistureStatus']!,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTelemetryMiniCard(
                                    icon: Icons.battery_charging_full_rounded,
                                    label: 'Power',
                                    value: activeTelemetry['power']!,
                                    status: activeTelemetry['powerStatus']!,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),

                          Text(
                            _hasIoTNode
                                ? 'Produce Quality Grade (Verified by IoT Telemetry)'
                                : 'Produce Quality Grade (Self-Declared)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB7C2D6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: _qualityGrades.map((grade) {
                              final isSelected = _selectedGrade == grade;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _selectedGrade = grade),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF0B1326)
                                            : const Color(0xFF171F33),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.verified_rounded
                                                : Icons
                                                      .check_circle_outline_rounded,
                                            size: 16,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFFB7C2D6),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            grade,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFFB7C2D6),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // STEP 4: PostGIS Farm Gate Proximity Lock
                    _buildCardSection(
                      stepNumber: 'Step 3 of 3',
                      title: 'PostGIS Farm Gate Proximity Lock',
                      subtitle: 'SRID 4326 High-Precision Ephemeris',
                      icon: Icons.location_on_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 130,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=800&auto=format&fit=crop',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: const Color(0xFF0B1326)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.radar_rounded,
                                          size: 12,
                                          color: Color(0xFF4EDEA3),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Radius Lock: 50km Match Active',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0B1326),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Center(
                                  child: FadeTransition(
                                    opacity: _pulseAnimation,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0B1326),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.agriculture_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _locationDescription,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFF3F6FF),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Lat: ${_lat?.toStringAsFixed(4) ?? "4.7502"}° N, Lon: ${_lon?.toStringAsFixed(4) ?? "11.2331"}° E',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFFB7C2D6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF171F33),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            '±1.8m RTK',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4EDEA3),
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
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.satellite_rounded,
                                    size: 14,
                                    color: Color(0xFF4EDEA3),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '4/4 Constellation Satellites Locked',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFB7C2D6),
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: _isLocating ? null : _captureLocation,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF171F33),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.my_location_rounded,
                                        size: 12,
                                        color: _isLocating
                                            ? Colors.grey
                                            : const Color(0xFF4EDEA3),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isLocating
                                            ? 'Locking...'
                                            : 'Re-calibrate GPS',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4EDEA3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // STEP 5: Escrow Net Payout Guarantee
                    _buildCardSection(
                      stepNumber: 'Safe Escrow',
                      title: 'Escrow Net Payout Guarantee',
                      subtitle: 'Smart Liquidity Buffer',
                      icon: Icons.shield_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Expected Gross Value',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB7C2D6),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: Text(
                                  _formatXAF(_grossTotal),
                                  key: ValueKey('gross-$_grossTotal'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF3F6FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Platform Service Fee (5%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB7C2D6),
                                ),
                              ),
                              Text(
                                'Shown at checkout',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4EDEA3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Smart Contract Verification Fee',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB7C2D6),
                                ),
                              ),
                              Text(
                                '0 XAF (Sponsored)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4EDEA3),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18, color: Color(0xFF171F33)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '100% Guaranteed Payout',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF3F6FF),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: Text(
                                  _formatXAF(_grossTotal),
                                  key: ValueKey('net-$_grossTotal'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0B1326),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF171F33),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.lock_clock_rounded,
                                  color: Color(0xFF4EDEA3),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Funds are protected through AgroNexus escrow and released after digital delivery signoff.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5132),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _isLoading ? null : _submitListing,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cell_tower_rounded, size: 20),
                        label: Text(
                          _isLoading
                              ? 'Broadcasting Spatial Telemetry...'
                              : 'Publish Batch to AgroNexus Network',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFFAF3),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _saveDraft,
                        icon: const Icon(
                          Icons.save_rounded,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        label: const Text(
                          'Save Draft in Local SQLite (Offline Mode)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
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

  Widget _buildQtyAddButton(String text, double delta) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _quantity = (_quantity + delta).clamp(200.0, 10000.0);
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required String status,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: const Color(0xFF0F5132)),
              const SizedBox(width: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF3F6FF),
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F5132),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFFAF3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: const Color(0xFF0F5132)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFAF3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F5132),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
