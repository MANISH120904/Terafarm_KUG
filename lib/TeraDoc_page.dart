import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/app_services.dart';

class TeradocPage extends StatefulWidget {
  const TeradocPage({super.key});

  @override
  State<TeradocPage> createState() => _TeradocPageState();
}

class _TeradocPageState extends State<TeradocPage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _diagnosis;
  String? _notice;
  bool _isLoading = false;

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _diagnosis = null;
      _notice = null;
    });
  }

  Future<void> _diagnose() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a plant photo first')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _diagnosis = null;
      _notice = null;
    });
    try {
      final result = await AppServices.ai.diagnosePlant(_imageBytes!);
      if (!mounted) return;
      setState(() {
        _diagnosis = result.text;
        _notice = result.notice ?? (result.isDemo ? 'Demo result' : null);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _diagnosis = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeraDoc — Plant Health'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload or capture a plant photo for a health check.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              if (_imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _imageBytes!,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: const Text('No image selected'),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _diagnose,
                icon: const Icon(Icons.health_and_safety),
                label: Text(_isLoading ? 'Analyzing…' : 'Diagnose plant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_notice != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    _notice!,
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
              ],
              if (_diagnosis != null) ...[
                const SizedBox(height: 16),
                Text(
                  _diagnosis!,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
