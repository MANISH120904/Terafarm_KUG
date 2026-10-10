import 'package:flutter/material.dart';

import 'services/app_services.dart';

class PlantCarePage extends StatefulWidget {
  const PlantCarePage({super.key});

  @override
  State<PlantCarePage> createState() => _PlantCarePageState();
}

class _PlantCarePageState extends State<PlantCarePage> {
  final _cityController = TextEditingController();
  final _plantController = TextEditingController();

  String? _advice;
  String? _notice;
  bool _isLoading = false;

  Future<void> _fetchAdvice() async {
    final city = _cityController.text.trim();
    final plant = _plantController.text.trim();
    if (city.isEmpty || plant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both city and plant name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _advice = null;
      _notice = null;
    });

    try {
      final result = await AppServices.ai.plantCareAdvice(
        plant: plant,
        city: city,
      );
      if (!mounted) return;
      setState(() {
        _advice = result.text;
        _notice = result.notice;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _advice = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _plantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Care AI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Enter City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _plantController,
                decoration: const InputDecoration(
                  labelText: 'Enter Plant Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchAdvice,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Get Plant Care Advice'),
              ),
              if (_notice != null) ...[
                const SizedBox(height: 16),
                Material(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade900),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _notice!,
                            style: TextStyle(color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_advice != null) ...[
                const SizedBox(height: 20),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _advice!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
