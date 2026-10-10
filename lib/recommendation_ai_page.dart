import 'package:flutter/material.dart';

import 'services/app_services.dart';

class RecommendationForm extends StatefulWidget {
  const RecommendationForm({super.key});

  @override
  State<RecommendationForm> createState() => _RecommendationFormState();
}

class _RecommendationFormState extends State<RecommendationForm> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaSizeController = TextEditingController();
  final TextEditingController _dailyTimeController = TextEditingController();

  final List<String> _spaceTypes = ['Balcony', 'Terrace', 'Garden'];
  String _selectedSpaceType = 'Balcony';

  final List<String> _timeUnits = ['hours', 'mins'];
  String _selectedTimeUnit = 'hours';

  String _result = '';
  String? _notice;
  bool _isLoading = false;

  Future<void> _getRecommendation() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your city')),
      );
      return;
    }

    final areaText = _areaSizeController.text.trim();
    final dailyText = _dailyTimeController.text.trim();
    final areaSize = int.tryParse(areaText);
    final dailyTime = int.tryParse(dailyText);

    if (areaSize == null || areaSize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid area size (whole number)')),
      );
      return;
    }
    if (dailyTime == null || dailyTime <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid daily care time (whole number)'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '';
      _notice = null;
    });

    try {
      final result = await AppServices.ai.recommendCrops(
        city: city,
        spaceType: _selectedSpaceType.toLowerCase(),
        areaSize: areaText,
        dailyTime: dailyText,
        dailyUnit: _selectedTimeUnit,
      );
      if (!mounted) return;
      setState(() {
        _result = result.text.replaceAll('*', '');
        _notice = result.notice;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result =
            'Error: Unable to fetch recommendation. Please check your input and try again.';
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
    _areaSizeController.dispose();
    _dailyTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terafarm Crop Recommendations'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Enter Your City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _areaSizeController,
                decoration: const InputDecoration(
                  labelText: 'Area Size (in square meters)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Text('Select Space Type: ', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    value: _selectedSpaceType,
                    items: _spaceTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedSpaceType = newValue!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dailyTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Daily Care Time',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    value: _selectedTimeUnit,
                    items: _timeUnits.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedTimeUnit = newValue!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _getRecommendation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  child: Text(
                    _isLoading ? 'Loading…' : 'Get My Recommendation',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_notice != null) ...[
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
                const SizedBox(height: 16),
              ],
              if (_result.isNotEmpty)
                Text(
                  _result,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                )
              else if (!_isLoading)
                const Center(
                  child: Text(
                    'Enter details and press the button to get recommendations.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
