import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/app_services.dart';
import 'widgets/state_views.dart';

class ListFarmPage extends StatefulWidget {
  const ListFarmPage({super.key});

  @override
  _ListFarmPageState createState() => _ListFarmPageState();
}

class _ListFarmPageState extends State<ListFarmPage> {
  final _formKey = GlobalKey<FormState>();

  // Farm Details
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _farmDescriptionController = TextEditingController();

  // Scale Option
  String _scaleOption = "Small Scale"; // default selection

  // Products: List of product entries
  final List<Map<String, TextEditingController>> _products = [];

  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Start with one product entry by default
    _addProductField();
  }

  // Add a new product entry (cropName, stock, price)
  void _addProductField() {
    setState(() {
      _products.add({
        'cropName': TextEditingController(),
        'stock': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  // Remove a product entry
  void _removeProductField(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  // Pick an image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      setState(() => _selectedImage = File(image.path));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
    }
  }

  // Upload image & save farm details to Firestore
  Future<void> _saveFarmDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final user = AppServices.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to list a farm')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    String imageUrl = '';
    if (_selectedImage != null) {
      try {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await AppServices.media.uploadFile(
          file: _selectedImage!,
          path: 'farm_images/$fileName.jpg',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        }
        if (mounted) setState(() => _isUploading = false);
        return;
      }
    }

    final productData = _products.map((product) => {
          'cropName': product['cropName']!.text.trim(),
          'stock in kgs': product['stock']!.text.trim(),
          'pricePerKg': product['price']!.text.trim(),
        }).toList();

    try {
      await AppServices.firestore.collection('farms').add({
        'farmName': _farmNameController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'location': _locationController.text.trim(),
        'farmDescription': _farmDescriptionController.text.trim(),
        'scale': _scaleOption,
        'products': productData,
        'imageUrl': imageUrl,
        'sellerId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm created successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving farm details: $e')),
        );
      }
    }

    if (mounted) setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (AppServices.auth.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('List a Farm'),
          backgroundColor: Colors.green,
        ),
        body: const EmptyView(
          message: 'Sign in to register your farm.',
          icon: Icons.agriculture,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('List a Farm'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Please upload a square image:", style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),

                // Image Upload Button
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text("Choose File"),
                    ),
                    SizedBox(width: 10),
                    if (_selectedImage != null)
                      Text("File Chosen", style: TextStyle(fontSize: 16, color: Colors.green)),
                  ],
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.file(_selectedImage!, height: 100),
                  ),
                SizedBox(height: 12),

                // Farm Name
                TextFormField(
                  controller: _farmNameController,
                  decoration: InputDecoration(
                    labelText: "Farm Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Please enter a farm name" : null,
                ),
                SizedBox(height: 10),

                // Contact Number
                TextFormField(
                  controller: _contactNumberController,
                  decoration: InputDecoration(
                    labelText: "Contact Number",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? "Please enter a contact number" : null,
                ),
                SizedBox(height: 10),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: "Location",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Please enter a location" : null,
                ),
                SizedBox(height: 10),

                // Farm Description
                TextFormField(
                  controller: _farmDescriptionController,
                  decoration: InputDecoration(
                    labelText: "Farm Description",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Please enter a farm description" : null,
                ),
                SizedBox(height: 12),

                // Scale Option (Small / Large)
                Text("Scale:", style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    Radio<String>(
                      value: "Small Scale",
                      groupValue: _scaleOption,
                      onChanged: (value) => setState(() => _scaleOption = value!),
                    ),
                    Text("Small Scale"),
                    SizedBox(width: 20),
                    Radio<String>(
                      value: "Large Scale",
                      groupValue: _scaleOption,
                      onChanged: (value) => setState(() => _scaleOption = value!),
                    ),
                    Text("Large Scale"),
                  ],
                ),
                SizedBox(height: 12),

                // Product Details
                Text("Product Details:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Column(
                  children: _products.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, TextEditingController> product = entry.value;
                    return _buildProductFields(product, index);
                  }).toList(),
                ),
                SizedBox(height: 10),

                // +Add Product Button
                Center(
                  child: ElevatedButton(
                    onPressed: _addProductField,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text("+Add product"),
                  ),
                ),
                SizedBox(height: 20),

                // Create Farm Button
                Center(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _saveFarmDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isUploading
                        ? CircularProgressIndicator()
                        : Text("Create a Farm"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build one product's text fields
  Widget _buildProductFields(Map<String, TextEditingController> product, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Light background for product container
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Product ${index + 1}",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),

          // Crop Name
          TextFormField(
            controller: product['cropName'],
            decoration: InputDecoration(
              labelText: "Crop Name",
              border: OutlineInputBorder(),
            ),
            validator: (value) => value!.isEmpty ? "Please enter crop name" : null,
          ),
          SizedBox(height: 10),

          // Stock
          TextFormField(
            controller: product['stock'],
            decoration: InputDecoration(
              labelText: "Stock",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? "Please enter stock" : null,
          ),
          SizedBox(height: 10),

          // Price
          TextFormField(
            controller: product['price'],
            decoration: InputDecoration(
              labelText: "Price per kg",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? "Please enter price" : null,
          ),
          SizedBox(height: 10),

          // Remove Product Button (if more than one product)
          if (_products.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _removeProductField(index),
                child: Text("Remove", style: TextStyle(color: Colors.red)),
              ),
            ),
        ],
      ),
    );
  }
}
