import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:farmmarket/services/supabase_service.dart';
import '../../routes/app_routes.dart';
import '../farmer_product_management/widgets/product_form_modal.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Use a Future to manage the loading state of the profile data.
  late Future<Map<String, dynamic>?> _profileFuture;

  // Controllers to populate and edit existing profile data
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _upiController;
  late final TextEditingController _accountController;
  late final TextEditingController _ifscController;
  late final TextEditingController _addressController;
  // Detailed address controllers
  late final TextEditingController _houseNoController;
  late final TextEditingController _streetController;
  late final TextEditingController _areaController;
  late final TextEditingController _villageController;
  late final TextEditingController _talukController;
  late final TextEditingController _districtController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  late final TextEditingController _pincodeController;

  Uint8List? _avatarBytes;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _upiController = TextEditingController();
    _accountController = TextEditingController();
    _ifscController = TextEditingController();
    _addressController = TextEditingController();
    _houseNoController = TextEditingController();
    _streetController = TextEditingController();
    _areaController = TextEditingController();
    _villageController = TextEditingController();
    _talukController = TextEditingController();
    _districtController = TextEditingController();
    _stateController = TextEditingController();
    _countryController = TextEditingController();
    _pincodeController = TextEditingController();
    _profileFuture = _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _addressController.dispose();
    _houseNoController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _villageController.dispose();
    _talukController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  /// Fetches profile data from Supabase and populates the text controllers.
  Future<Map<String, dynamic>?> _loadProfile() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final data = await SupabaseService.getProfile(userId);
      if (data != null) {
        // Populate controllers and set avatar URL.
        _nameController.text = (data['name'] ?? '').toString();
        _phoneController.text = (data['phone'] ?? '').toString();
        _upiController.text = (data['upi_id'] ?? '').toString();
        _accountController.text = (data['account_number'] ?? '').toString();
        _ifscController.text = (data['ifsc'] ?? '').toString();
        _addressController.text = (data['address'] ?? '').toString();
        _houseNoController.text = (data['house_no'] ?? '').toString();
        _streetController.text = (data['street'] ?? '').toString();
        _areaController.text = (data['area'] ?? '').toString();
        _villageController.text = (data['village'] ?? '').toString();
        _talukController.text = (data['taluk'] ?? '').toString();
        _districtController.text = (data['district'] ?? '').toString();
        _stateController.text = (data['state'] ?? '').toString();
        _countryController.text = (data['country'] ?? '').toString();
        _pincodeController.text = (data['pincode'] ?? '').toString();
        _avatarUrl = data['avatar_url'] as String?;
      }
      return data;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
      rethrow; // Rethrow to let FutureBuilder handle the error state.
    }
  }

  /// Saves profile data and uploads a new avatar if one was picked.
  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save your profile')),
        );
      }
      return;
    }

    try {
      String? avatarUrl;
      if (_avatarBytes != null) {
        final Uint8List bytes = _avatarBytes!;
        avatarUrl = await SupabaseService.uploadImage(
          bucket: 'profile-avatars',
          path: '$userId/avatar.jpg',
          bytes: bytes,
        );
      }

      await SupabaseService.upsertProfile(userId: userId, data: {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'upi_id': _upiController.text.trim(),
        'account_number': _accountController.text.trim(),
        'ifsc': _ifscController.text.trim().toUpperCase(),
        'address': _addressController.text.trim(),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });

      // Sync the pickup address onto all products owned by this user so all users can see it.
      await SupabaseService.syncOwnerPickupAddress(userId, overwrite: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        // Refresh the profile future to update the UI with new data.
        setState(() {
          _profileFuture = _loadProfile();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  /// Handles picking an image from the camera or gallery.
  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request camera permission only when needed
      if (source == ImageSource.camera) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera permission required')),
            );
          }
          return;
        }
      }
      if (source == ImageSource.gallery) {
        final ok = await _ensureGalleryPermission();
        if (!ok) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photos permission required')),
            );
          }
          return;
        }
      }
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _avatarBytes = bytes;
          _avatarUrl = null; // Clear old URL as a new image is selected.
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to select image')),
        );
      }
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    try {
      // Try photos permission first (iOS and Android 13+ READ_MEDIA_IMAGES)
      var status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      // Fallback to storage for older Android
      status = await Permission.storage.request();
      if (status.isGranted) return true;
      // If permanently denied, direct to settings
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Profile'),
            if (SupabaseService.currentUserEmail != null)
              Text(
                SupabaseService.currentUserEmail!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        actions: [
          Builder(builder: (context) {
            const allowed = {
              'jjsmithun@gmail.com',
              'darshanks343@gmail.com',
            };
            final email = SupabaseService.currentUserEmail;
            if (email != null && allowed.contains(email)) {
              return IconButton(
                tooltip: 'Dashboard',
                icon: const Icon(Icons.dashboard_outlined),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return _buildProfileForm();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Profile image
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _avatarBytes != null
                        ? MemoryImage(_avatarBytes!) as ImageProvider<Object>?
                        : (_avatarUrl != null
                            ? NetworkImage(_avatarUrl!) as ImageProvider<Object>?
                            : null),
                    child: (_avatarBytes == null && _avatarUrl == null)
                        ? const Icon(Icons.person, size: 48, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImagePickerSheet,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _upiController,
                      decoration: const InputDecoration(labelText: 'Seller UPI ID (e.g., name@bank)'),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _accountController,
                      decoration: const InputDecoration(labelText: 'Account Number'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(18),
                      ],
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) {
                          return 'Please enter your account number';
                        }
                        if (!RegExp(r'^\d{9,18}$').hasMatch(v)) {
                          return 'Enter 9-18 digit account number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ifscController,
                      decoration: const InputDecoration(labelText: 'IFSC Code'),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (value) {
                        final v = (value ?? '').trim();
                        if (v.isEmpty) {
                          return 'Please enter IFSC code';
                        }
                        // IFSC: 11 chars, first 4 letters, 0, then 6 alnum
                        if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$', caseSensitive: false).hasMatch(v)) {
                          return 'Enter valid IFSC (e.g., HDFC0XXXXXX)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            await SupabaseService.signOut();
                            if (!mounted) return;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.login,
                              (route) => false,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Logout failed: $e')),
                            );
                          }
                        },
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // My Products section (visible only to the owner by definition)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'My Products',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const ProductFormModal(),
                            );
                            if (!mounted) return;
                            if (result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Product saved')),
                              );
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final uid = SupabaseService.currentUserId;
                        if (uid == null) {
                          return const Text('Log in to manage your products');
                        }
                        return SizedBox(
                          height: 300,
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: SupabaseService.streamProducts(ownerId: uid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }
                              final items = snapshot.data ?? const [];
                              if (items.isEmpty) {
                                return const Center(child: Text('No products yet'));
                              }
                              return ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final row = items[index];
                                  final name = (row['name'] ?? 'Product').toString();
                                  final price = (row['price'] is num)
                                      ? (row['price'] as num).toDouble()
                                      : double.tryParse('${row['price'] ?? 0}') ?? 0.0;
                                  final stock = (row['stock'] is num)
                                      ? (row['stock'] as num).toInt()
                                      : int.tryParse('${row['stock'] ?? 0}') ?? 0;
                                  final status = (row['status'] ?? 'active').toString();
                                  final soldText = (stock <= 0) ? 'Sold' : 'Not sold';
                                  final isSold = stock <= 0;
                                  return ListTile(
                                    title: Text(name),
                                    subtitle: Text('₹${price.toStringAsFixed(2)}  •  Stock: $stock  •  $soldText'),
                                    trailing: isSold
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'SOLD',
                                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: 'Delete',
                                                icon: const Icon(Icons.delete_outline),
                                                onPressed: () => _confirmDelete(row['id']?.toString() ?? ''),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Edit',
                                                icon: const Icon(Icons.edit),
                                                onPressed: () => _showEditProductDialog(row),
                                              ),
                                              IconButton(
                                                tooltip: 'Delete',
                                                icon: const Icon(Icons.delete_outline),
                                                onPressed: () => _confirmDelete(row['id']?.toString() ?? ''),
                                              ),
                                            ],
                                          ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String productId) async {
    if (productId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseService.deleteProduct(productId: productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  Future<void> _showEditProductDialog(Map<String, dynamic> row) async {
    final id = (row['id'] ?? '').toString();
    if (id.isEmpty) return;
    final nameC = TextEditingController(text: (row['name'] ?? '').toString());
    final priceC = TextEditingController(text: ((row['price'] ?? 0).toString()));
    final stockC = TextEditingController(text: ((row['stock'] ?? 0).toString()));
    String status = (row['status'] ?? 'active').toString();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceC,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              TextField(
                controller: stockC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (v) => status = v ?? status,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final price = double.tryParse(priceC.text.trim()) ?? 0.0;
              final stock = int.tryParse(stockC.text.trim()) ?? 0;
              try {
                await SupabaseService.updateProduct(
                  productId: id,
                  data: {
                    'name': nameC.text.trim(),
                    'price': price,
                    'stock': stock,
                    'status': status,
                  },
                );
                if (!mounted) return;
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}