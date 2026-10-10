import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/app_services.dart';
import 'widgets/app_image.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _localityController = TextEditingController();
  final TextEditingController _farmNameController = TextEditingController();
  File? _selectedImage;
  String? _imageUrl;

  bool _animate = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _animate = true);
    });
  }

  Future<void> _loadUserData() async {
    final user = AppServices.auth.currentUser;
    if (user == null) return;

    final userDoc =
        await AppServices.firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final farmQuery = await AppServices.firestore
        .collection('farms')
        .where('sellerId', isEqualTo: user.uid)
        .limit(1)
        .get();
    final farmName =
        farmQuery.docs.isNotEmpty ? farmQuery.docs.first['farmName'] : null;

    if (!mounted) return;
    setState(() {
      _usernameController.text = userData['username']?.toString() ?? '';
      _emailController.text =
          userData['email']?.toString() ?? user.email ?? '';
      _phoneController.text = userData['phone']?.toString() ?? '';
      _localityController.text = userData['locality']?.toString() ?? '';
      _farmNameController.text = farmName?.toString() ?? '';
      _imageUrl = userData['profileImage']?.toString();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = AppServices.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to save your profile')),
        );
      }
      return;
    }

    setState(() => _saving = true);

    try {
      String? imageUrl = _imageUrl;

      if (_selectedImage != null) {
        imageUrl = await AppServices.media.uploadFile(
          file: _selectedImage!,
          path: 'profile_images/${user.uid}_profile_image.jpg',
        );
      }

      await AppServices.firestore.collection('users').doc(user.uid).update({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'locality': _localityController.text.trim(),
        'profileImage': imageUrl,
      });

      final farmName = _farmNameController.text.trim();
      if (farmName.isNotEmpty) {
        final farmQuery = await AppServices.firestore
            .collection('farms')
            .where('sellerId', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (farmQuery.docs.isNotEmpty) {
          await farmQuery.docs.first.reference.update({'farmName': farmName});
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 143, 143),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 244, 143, 143),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _animatedFadeSlide(
                0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: _selectedImage != null
                            ? AppImage(
                                source: _selectedImage!.path,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : AppImage(
                                source: _imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                fallbackAsset: 'assets/sample_farm.png',
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _animatedFadeSlide(
                1,
                child: _buildEditableField('Username', _usernameController),
              ),
              _animatedFadeSlide(
                2,
                child: _buildEditableField(
                  'My email Address',
                  _emailController,
                ),
              ),
              _animatedFadeSlide(
                3,
                child: _buildEditableField('Phone number', _phoneController),
              ),
              _animatedFadeSlide(
                4,
                child: _buildEditableField('Locality', _localityController),
              ),
              _animatedFadeSlide(
                5,
                child: _buildEditableField(
                  "My Farm's name (optional)",
                  _farmNameController,
                  required: false,
                ),
              ),
              const SizedBox(height: 20),
              _animatedFadeSlide(
                6,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 16)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.edit, color: Colors.black),
          ),
          validator: required
              ? (value) =>
                    value == null || value.isEmpty
                        ? 'This field cannot be empty'
                        : null
              : null,
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _animatedFadeSlide(int index, {required Widget child}) {
    return AnimatedSlide(
      offset: _animate ? Offset.zero : const Offset(0, 0.3),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300 + (index * 100)),
        opacity: _animate ? 1 : 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: child,
        ),
      ),
    );
  }
}
