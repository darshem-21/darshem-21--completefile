
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import 'package:farmmarket/services/supabase_service.dart';
import 'package:farmmarket/services/geo_service.dart';
import 'camera_capture_widget.dart';

class ProductFormModal extends StatefulWidget {
  final Map<String, dynamic>? product;
  final List<XFile>? initialImages;

  const ProductFormModal({
    super.key,
    this.product,
    this.initialImages,
  });

  @override
  State<ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends State<ProductFormModal>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;
  int _currentStep = 0;
  bool _isLoading = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _minOrderController;
  late TextEditingController _addressController;

  // Form data
  String _selectedCategory = 'Vegetables';
  String _selectedUnit = 'kg';
  String _selectedFarmingMethod = 'Organic';
  DateTime _harvestDate = DateTime.now();
  List<String> _selectedDeliveryOptions = ['pickup'];
  final List<XFile> _selectedImages = [];
  List<Uint8List> _selectedImageBytes = [];
  bool _isVisible = true;
  bool _hasAutoSaved = false;
  bool _useCurrentLocation = false;

  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Leafy Greens',
    'Root Vegetables',
    'Herbs',
    'Grains',
    'Dairy',
    'Others',
  ];

  final List<String> _units = [
    'kg',
    'g',
    'piece',
    'bunch',
    'liter',
    'dozen',
    'packet',
  ];

  final List<String> _farmingMethods = [
    'Organic',
    'Conventional',
    'Biodynamic',
    'Sustainable',
    'Hydroponic',
  ];

  final List<Map<String, dynamic>> _deliveryOptions = [
    {'id': 'pickup', 'name': 'Farm Pickup', 'icon': 'location_on'},
    {'id': 'delivery', 'name': 'Home Delivery', 'icon': 'local_shipping'},
    {'id': 'market', 'name': 'Market Drop', 'icon': 'store'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize controllers
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController();
    _minOrderController = TextEditingController(text: '1');
    _addressController = TextEditingController();

    // Load existing product data
    if (widget.product != null) {
      _loadProductData();
    }

    // Load initial images
    if (widget.initialImages != null) {
      _selectedImages.addAll(widget.initialImages!);
      // Load bytes asynchronously
      Future.microtask(_loadInitialImageBytes);
    }

    // Auto-save setup
    _setupAutoSave();
  }

  Future<void> _openCameraCapture() async {
    try {
      final result = await showModalBottomSheet<List<XFile>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const CameraCaptureWidget(),
      );
      if (result == null || result.isEmpty) return;
      // Clamp to max 5 images
      final available = 5 - _selectedImages.length;
      final toAdd = result.take(available).toList();
      final bytesList = <Uint8List>[];
      for (final x in toAdd) {
        try {
          final b = await x.readAsBytes();
          bytesList.add(b);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _selectedImages.addAll(toAdd);
        _selectedImageBytes.addAll(bytesList);
      });
    } catch (_) {
      Fluttertoast.showToast(
          msg: "Failed to open camera",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minOrderController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadProductData() {
    final product = widget.product!;
    _nameController.text = product['name'] ?? '';
    _descriptionController.text = product['description'] ?? '';
    _priceController.text = (product['price'] ?? 0.0).toString();
    _stockController.text = (product['stock'] ?? 0).toString();
    _minOrderController.text = (product['minOrderQty'] ?? 1).toString();
    _selectedCategory = product['category'] ?? 'Vegetables';
    _selectedUnit = product['unit'] ?? 'kg';
    _selectedFarmingMethod = product['farmingMethod'] ?? 'Organic';
    _harvestDate = product['harvestDate'] ?? DateTime.now();
    _selectedDeliveryOptions =
        List<String>.from(product['deliveryOptions'] ?? ['pickup']);
    _isVisible = product['isVisible'] ?? true;
    _addressController.text = product['pickup_address'] ?? product['address'] ?? '';
  }

  void _setupAutoSave() {
    // Auto-save every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && !_hasAutoSaved) {
        _autoSave();
        _setupAutoSave();
      }
    });
  }

  Future<void> _loadInitialImageBytes() async {
    try {
      final bytesList = <Uint8List>[];
      for (final x in _selectedImages) {
        try {
          final b = await x.readAsBytes();
          bytesList.add(b);
        } catch (_) {
          // ignore this image if bytes fail
        }
      }
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytesList;
      });
    } catch (_) {
      // no-op
    }
  }

  void _autoSave() {
    if (_nameController.text.isNotEmpty) {
      setState(() {
        _hasAutoSaved = true;
      });

      Fluttertoast.showToast(
          msg: "Draft saved",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          textColor: AppTheme.lightTheme.colorScheme.onTertiary);
    }
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      Fluttertoast.showToast(
          msg: "Maximum 5 images allowed",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError);
      return;
    }

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 12.w,
                  height: 0.5.h,
                  margin: EdgeInsets.only(top: 2.h, bottom: 3.h),
                  decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10))),
              ListTile(
                  leading: CustomIconWidget(iconName: 'camera_alt', size: 24),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _openCameraCapture();
                  }),
              ListTile(
                  leading:
                      CustomIconWidget(iconName: 'photo_library', size: 24),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _captureImage(ImageSource.gallery);
                  }),
              SizedBox(height: 2.h),
            ])));
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      if (!kIsWeb && source == ImageSource.camera) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) {
          Fluttertoast.showToast(
              msg: "Camera permission required",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
              textColor: AppTheme.lightTheme.colorScheme.onError);
          return;
        }
      }
      if (!kIsWeb && source == ImageSource.gallery) {
        final ok = await _ensureGalleryPermission();
        if (!ok) {
          Fluttertoast.showToast(
              msg: "Photos permission required",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
              textColor: AppTheme.lightTheme.colorScheme.onError);
          return;
        }
      }
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);

      if (image != null) {
        if (kIsWeb) {
          // On Web, skip cropping and read bytes
          final bytes = await image.readAsBytes();
          if (!mounted) return;
          setState(() {
            _selectedImages.add(image);
            _selectedImageBytes.add(bytes);
          });
        } else {
          // Directly use picked image on mobile/desktop (skip cropping to avoid plugin crash)
          final bytes = await image.readAsBytes();
          if (!mounted) return;
          setState(() {
            _selectedImages.add(image);
            _selectedImageBytes.add(bytes);
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Failed to capture image",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError);
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    try {
      // On web, browser handles permissions
      if (kIsWeb) return true;
      // Try photos permission first (iOS and Android 13+ map to READ_MEDIA_IMAGES)
      var status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      // Fallback to storage for older Android versions
      status = await Permission.storage.request();
      if (status.isGranted) return true;
      // If permanently denied, nudge user to settings
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<CroppedFile?> _cropImage(XFile imageFile) async {
    try {
      return await ImageCropper()
          .cropImage(sourcePath: imageFile.path, uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppTheme.lightTheme.colorScheme.primary,
            toolbarWidgetColor: AppTheme.lightTheme.colorScheme.onPrimary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ]),
        IOSUiSettings(
            title: 'Crop Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ]),
        WebUiSettings(
            context: context),
      ]);
    } catch (e) {
      return null;
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (index < _selectedImageBytes.length) {
        _selectedImageBytes.removeAt(index);
      }
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
      if (_selectedImageBytes.isNotEmpty && oldIndex < _selectedImageBytes.length) {
        final b = _selectedImageBytes.removeAt(oldIndex);
        if (newIndex <= _selectedImageBytes.length) {
          _selectedImageBytes.insert(newIndex, b);
        } else {
          _selectedImageBytes.add(b);
        }
      }
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _saveProduct();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _saveProduct() async {
    // Manual validation so Save works from step 3 as well
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());

    if (name.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please enter product name",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError);
      return;
    }

    if (price == null || price <= 0) {
      Fluttertoast.showToast(
          msg: "Please enter a valid price",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError);
      return;
    }

    if (stock == null || stock < 0) {
      Fluttertoast.showToast(
          msg: "Please enter a valid stock quantity",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError);
      return;
    }
    // Enforce minimum 5kg (or 5000g)
    if ((_selectedUnit == 'kg' && stock < 5) || (_selectedUnit == 'g' && stock < 5000)) {
      Fluttertoast.showToast(
          msg: "Minimum stock is 5 kg",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError);
      return;
    }
    // Enforce maximum 20000 kg (or 20000000 g)
    if ((_selectedUnit == 'kg' && stock > 20000) || (_selectedUnit == 'g' && stock > 20000000)) {
      Fluttertoast.showToast(
          msg: "Maximum stock is 20000 kg",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError);
      return;
    }
    // Liter bounds: 5..30
    if (_selectedUnit == 'liter' && (stock < 5 || stock > 30)) {
      Fluttertoast.showToast(
          msg: "Stock in liters must be between 5 and 30",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ownerId = SupabaseService.currentUserId;
      if (ownerId == null) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: "Please log in to add products",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError,
        );
        return;
      }

      // Prepare location
      double? latitude;
      double? longitude;
      final pickupAddress = _addressController.text.trim();
      try {
        if (pickupAddress.isNotEmpty) {
          final latLng = await GeoService.geocodeAddress(pickupAddress);
          if (latLng != null) {
            latitude = latLng.latitude;
            longitude = latLng.longitude;
          }
        } else if (_useCurrentLocation) {
          final pos = await GeoService.getCurrentPosition();
          latitude = pos.latitude;
          longitude = pos.longitude;
        }
      } catch (_) {
        // Non-fatal: continue without location
      }

      // Create product row first
      String productId;
      try {
        productId = await SupabaseService.createProduct(
          ownerId: ownerId,
          data: {
            'name': _nameController.text,
            'description': _descriptionController.text,
            'price': double.tryParse(_priceController.text) ?? 0.0,
            'unit': _selectedUnit,
            'stock': int.tryParse(_stockController.text) ?? 0,
            'category': _selectedCategory,
            'status': _isVisible ? 'active' : 'hidden',
            'farming_method': _selectedFarmingMethod,
            'harvest_date': _harvestDate.toIso8601String(),
            'min_order_qty': int.tryParse(_minOrderController.text) ?? 1,
            'delivery_options': _selectedDeliveryOptions,
            if (pickupAddress.isNotEmpty) 'pickup_address': pickupAddress,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          },
        );
        Fluttertoast.showToast(
          msg: "Product created",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } catch (e) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: "Failed to create product: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError,
        );
        return;
      }

      // Upload images to Storage bucket and collect URLs
      final urls = <String>[];
      try {
        for (final img in _selectedImages) {
          final fileName = img.name;
          // Use XFile.readAsBytes() on all platforms to avoid dart:io dependency
          final bytes = await img.readAsBytes();
          final url = await SupabaseService.uploadImage(
            bucket: 'product-images',
            // IMPORTANT: path must start with auth.uid() per your Storage policy
            path: '$ownerId/$productId/$fileName',
            bytes: bytes,
          );
          urls.add(url);
        }
        if (urls.isNotEmpty) {
          Fluttertoast.showToast(
            msg: "Uploaded ${urls.length} image(s)",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: "Failed to upload images: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError,
        );
        return;
      }

      // Update product with image_urls
      try {
        await SupabaseService.updateProduct(
          productId: productId,
          data: {'image_urls': urls},
        );
      } catch (e) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: "Failed to save image URLs: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          textColor: AppTheme.lightTheme.colorScheme.onError,
        );
        return;
      }

      setState(() => _isLoading = false);

      // Return minimal product data to caller (optional; streams can update UI too)
      if (mounted) {
        Navigator.pop(context, {
          'id': productId,
          'name': _nameController.text,
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'unit': _selectedUnit,
          'stock': int.tryParse(_stockController.text) ?? 0,
          'category': _selectedCategory,
          'image_urls': urls,
          if (pickupAddress.isNotEmpty) 'pickup_address': pickupAddress,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
        msg: "Failed to save product: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        textColor: AppTheme.lightTheme.colorScheme.onError,
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _harvestDate,
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 30)),
        builder: (context, child) {
          return Theme(
              data: Theme.of(context)
                  .copyWith(colorScheme: AppTheme.lightTheme.colorScheme),
              child: child!);
        });

    if (picked != null && picked != _harvestDate) {
      setState(() {
        _harvestDate = picked;
      });
    }
  }

  Widget _buildImageGallery() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Product Images',
            style: AppTheme.lightTheme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${_selectedImages.length}/5',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
      ]),
      SizedBox(height: 2.h),
      if (_selectedImages.isEmpty)
        GestureDetector(
            onTap: _pickImage,
            child: Container(
                height: 20.h,
                width: double.infinity,
                decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.5),
                        style: BorderStyle.solid)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                          iconName: 'add_a_photo',
                          size: 48,
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant),
                      SizedBox(height: 1.h),
                      Text('Add Product Photos',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme
                                      .onSurfaceVariant)),
                      Text('Tap to add images (max 5)',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme
                                      .onSurfaceVariant)),
                    ])))
      else
        ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _reorderImages,
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                // Add image button
                return GestureDetector(
                    key: ValueKey('add_image'),
                    onTap: _pickImage,
                    child: Container(
                        height: 15.h,
                        margin: EdgeInsets.only(bottom: 2.h),
                        decoration: BoxDecoration(
                            color: AppTheme
                                .lightTheme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.lightTheme.colorScheme.outline
                                    .withValues(alpha: 0.5),
                                style: BorderStyle.solid)),
                        child: Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              CustomIconWidget(
                                  iconName: 'add',
                                  size: 32,
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant),
                              SizedBox(height: 0.5.h),
                              Text('Add More',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                          color: AppTheme.lightTheme.colorScheme
                                              .onSurfaceVariant)),
                            ]))));
              }

              // Image item
              final image = _selectedImages[index];
              return Container(
                  key: ValueKey('image_$index'),
                  height: 15.h,
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.lightTheme.colorScheme.shadow
                                .withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                      ]),
                  child: Stack(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _selectedImageBytes.length > index
                            ? Image.memory(
                                _selectedImageBytes[index],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : (kIsWeb
                                ? Image.network(
                                    image.path,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                                  ))),

                    // Remove button
                    Positioned(
                        top: 1.w,
                        right: 1.w,
                        child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                                padding: EdgeInsets.all(1.w),
                                decoration: BoxDecoration(
                                    color:
                                        AppTheme.lightTheme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(20)),
                                child: CustomIconWidget(
                                    iconName: 'close',
                                    size: 16,
                                    color: AppTheme
                                        .lightTheme.colorScheme.onError)))),

                    // Main image indicator
                    if (index == 0)
                      Positioned(
                          bottom: 1.w,
                          left: 1.w,
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text('Main',
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                          color: AppTheme
                                              .lightTheme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.w600)))),

                    // Drag handle
                    Positioned(
                        top: 1.w,
                        left: 1.w,
                        child: Container(
                            padding: EdgeInsets.all(1.w),
                            decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.surface
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20)),
                            child: CustomIconWidget(
                                iconName: 'drag_handle',
                                size: 16,
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant))),
                  ]));
            }),
    ]);
  }

  Widget _buildBasicInfoForm() {
    return Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Product name
          TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g., Organic Tomatoes'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _hasAutoSaved = false;
                });
              }),
          SizedBox(height: 3.h),

          // Category dropdown
          DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              }),
          SizedBox(height: 3.h),

          // Description
          TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText:
                      'Describe your product, farming methods, quality...'),
              onChanged: (value) {
                setState(() {
                  _hasAutoSaved = false;
                });
              }),
          SizedBox(height: 3.h),

          // Price and unit
          Row(children: [
            Expanded(
                flex: 2,
                child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                        labelText: 'Price *', prefixText: '₹ '),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter price';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Enter valid price';
                      }
                      return null;
                    })),
            SizedBox(width: 4.w),
            Expanded(
                child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: _units.map((unit) {
                      return DropdownMenuItem(value: unit, child: Text(unit));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value!;
                      });
                    })),
          ]),
          SizedBox(height: 3.h),

          // Stock quantity
          TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                  labelText: 'Stock Quantity *',
                  hintText: 'Available quantity'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter stock quantity';
                }
                final stock = int.tryParse(value);
                if (stock == null || stock < 0) {
                  return 'Enter valid quantity';
                }
                // Enforce minimum 5kg equivalent
                if (_selectedUnit == 'kg' && stock < 5) {
                  return 'Minimum stock is 5 kg';
                }
                if (_selectedUnit == 'g' && stock < 5000) {
                  return 'Minimum stock is 5000 g (5 kg)';
                }
                // Enforce maximum 20000 kg equivalent
                if (_selectedUnit == 'kg' && stock > 20000) {
                  return 'Maximum stock is 20000 kg';
                }
                if (_selectedUnit == 'g' && stock > 20000000) {
                  return 'Maximum stock is 20000000 g (20000 kg)';
                }
                // Liter bounds: 5 to 30 liters
                if (_selectedUnit == 'liter') {
                  if (stock < 5) return 'Minimum stock is 5 liters';
                  if (stock > 30) return 'Maximum stock is 30 liters';
                }
                return null;
              }),
        ]));
  }

  Widget _buildAdvancedSettings() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Farming method
      Text('Farming Method',
          style: AppTheme.lightTheme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      SizedBox(height: 1.h),
      Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _farmingMethods.map((method) {
            final isSelected = _selectedFarmingMethod == method;
            return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFarmingMethod = method;
                  });
                },
                child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme
                                .lightTheme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.outline
                                    .withValues(alpha: 0.3))),
                    child: Text(method,
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                                color: isSelected
                                    ? AppTheme.lightTheme.colorScheme.onPrimary
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400))));
          }).toList()),
      SizedBox(height: 4.h),

      // Harvest date
      GestureDetector(
          onTap: _selectDate,
          child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                CustomIconWidget(
                    iconName: 'calendar_today',
                    size: 20,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
                SizedBox(width: 3.w),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Harvest Date',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme
                              .lightTheme.colorScheme.onSurfaceVariant)),
                  Text(
                      '${_harvestDate.day}/${_harvestDate.month}/${_harvestDate.year}',
                      style: AppTheme.lightTheme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                ]),
                const Spacer(),
                CustomIconWidget(
                    iconName: 'arrow_drop_down',
                    size: 24,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant),
              ]))),
      SizedBox(height: 4.h),

      // Minimum order quantity
      TextFormField(
          controller: _minOrderController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
              labelText: 'Minimum Order Quantity', hintText: '1')),
      SizedBox(height: 4.h),

      SizedBox(height: 4.h),

      // Pickup location
      Text('Pickup Location',
          style: AppTheme.lightTheme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      SizedBox(height: 1.h),
      TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
              labelText: 'Pickup Address',
              hintText: 'e.g., Farm address or landmark'),
          onChanged: (_) {
            setState(() {
              _useCurrentLocation = false;
              _hasAutoSaved = false;
            });
          }),
      SizedBox(height: 1.h),
      Row(children: [
        OutlinedButton.icon(
            onPressed: () async {
              setState(() {
                _useCurrentLocation = true;
              });
              Fluttertoast.showToast(
                msg: 'Will use current GPS when saving',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Use current location')),
        SizedBox(width: 3.w),
        if (_useCurrentLocation)
          Text('Enabled',
              style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600))
      ]),
      SizedBox(height: 4.h),
      SwitchListTile(
          title: const Text('Product Visibility'),
          subtitle: Text(
              _isVisible ? 'Visible to customers' : 'Hidden from customers',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
          value: _isVisible,
          onChanged: (value) {
            setState(() {
              _isVisible = value;
            });
          },
          contentPadding: EdgeInsets.zero),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 90.h,
        decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        child: Column(children: [
          // Handle bar
          Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.only(top: 2.h, bottom: 2.h),
              decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10))),

          // Header
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Row(children: [
                if (_currentStep > 0)
                  GestureDetector(
                      onTap: _previousStep,
                      child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20)),
                          child: CustomIconWidget(
                              iconName: 'arrow_back',
                              size: 20,
                              color:
                                  AppTheme.lightTheme.colorScheme.onSurface))),
                Expanded(
                    child: Text(
                        widget.product != null ? 'Edit Product' : 'Add Product',
                        style: AppTheme.lightTheme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center)),
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                            color: AppTheme
                                .lightTheme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20)),
                        child: CustomIconWidget(
                            iconName: 'close',
                            size: 20,
                            color: AppTheme.lightTheme.colorScheme.onSurface))),
              ])),

          // Progress indicator
          Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: Row(children: List.generate(3, (index) {
                final isActive = index <= _currentStep;
                return Expanded(
                    child: Container(
                        height: 0.5.h,
                        margin: EdgeInsets.symmetric(horizontal: 1.w),
                        decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(2))));
              }))),

          // Content
          Expanded(
              child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: _buildImageGallery()),
                    SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: _buildBasicInfoForm()),
                    SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: _buildAdvancedSettings()),
                  ])),

          // Bottom buttons
          Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  border: Border(
                      top: BorderSide(
                          color: AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.2)))),
              child: Row(children: [
                if (_currentStep > 0)
                  Expanded(
                      child: OutlinedButton(
                          onPressed: _previousStep,
                          child: const Text('Previous'))),
                if (_currentStep > 0) SizedBox(width: 4.w),
                Expanded(
                    child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextStep,
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme
                                            .lightTheme.colorScheme.onPrimary)))
                            : Text(
                                _currentStep == 2 ? 'Save Product' : 'Next'))),
              ])),
        ]));
  }
}