import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';

class AiResult {
  const AiResult({
    required this.text,
    this.isDemo = true,
    this.notice,
  });

  final String text;
  final bool isDemo;
  final String? notice;
}

abstract class AiService {
  Future<AiResult> diagnosePlant(Uint8List imageBytes);
  Future<AiResult> plantCareAdvice({
    required String plant,
    required String city,
  });
  Future<AiResult> recommendCrops({
    required String city,
    required String spaceType,
    required String areaSize,
    required String dailyTime,
    required String dailyUnit,
  });
}

class DemoAiService implements AiService {
  @override
  Future<AiResult> diagnosePlant(Uint8List imageBytes) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const AiResult(
      text: '''**Demo diagnosis — Early Blight (Alternaria)**

Likely cause: fungal leaf spots common in humid weather.

**Recommended actions**
1. Remove and discard heavily affected leaves.
2. Water at the base; avoid wetting foliage.
3. Improve airflow between plants.
4. Apply a copper-based fungicide if spots spread.
5. Mulch soil to reduce splash-back.

This is a simulated result for demo mode. No live AI call was made.''',
      isDemo: true,
      notice: 'Demo result',
    );
  }

  @override
  Future<AiResult> plantCareAdvice({
    required String plant,
    required String city,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AiResult(
      text: '''**Demo plant care for $plant in $city**

Weather (simulated): 29°C, 62% humidity, partly cloudy.

- Water lightly in the morning — soil should stay moist, not soggy.
- Provide 5–6 hours of direct sun or bright terrace light.
- Feed with compost tea every 10–14 days during active growth.
- Watch for aphids on new shoots; rinse with mild soap spray if needed.
- Harvest outer leaves / ripe fruit regularly to encourage new growth.

This is a simulated result for demo mode.''',
      isDemo: true,
      notice: 'Demo result — live weather/AI backends unavailable',
    );
  }

  @override
  Future<AiResult> recommendCrops({
    required String city,
    required String spaceType,
    required String areaSize,
    required String dailyTime,
    required String dailyUnit,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AiResult(
      text: '''**Demo crop recommendations for $city**

Space: $spaceType · Area: $areaSize · Daily care: $dailyTime $dailyUnit

1. **Tomato (cherry)** — high yield in pots/grow bags; 4–6 hrs sun.
2. **Greens (spinach / amaranth)** — quick harvest, shade-tolerant.
3. **Bush beans** — nitrogen-fixing, great for terrace rails.
4. **Onion (bunching)** — low maintenance, continuous harvest.
5. **Herbs (basil, mint)** — compact, kitchen-friendly.

Start with 2–3 crops that match your sun exposure. This is a simulated result for demo mode.''',
      isDemo: true,
      notice: 'Demo result',
    );
  }
}

/// Live AI when API keys are provided; falls back to [DemoAiService] on failure.
class LiveOrDemoAiService implements AiService {
  LiveOrDemoAiService({DemoAiService? demo}) : _demo = demo ?? DemoAiService();

  final DemoAiService _demo;
  final http.Client _client = http.Client();

  @override
  Future<AiResult> diagnosePlant(Uint8List imageBytes) async {
    if (!AppConfig.hasGeminiKey) {
      return _demo.diagnosePlant(imageBytes);
    }
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}',
      );
      final body = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'You are TeraDoc, a plant health assistant. Diagnose any '
                    'disease or stress visible in this plant photo. Give clear '
                    'steps a home grower can follow. Keep it under 250 words.',
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(imageBytes),
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        },
      };
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        final fallback = await _demo.diagnosePlant(imageBytes);
        return AiResult(
          text: fallback.text,
          isDemo: true,
          notice: 'Live AI failed (${response.statusCode}); showing demo result',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = _extractGeminiText(data) ?? 'No diagnosis returned.';
      return AiResult(text: text, isDemo: false);
    } catch (e) {
      final fallback = await _demo.diagnosePlant(imageBytes);
      return AiResult(
        text: fallback.text,
        isDemo: true,
        notice: 'Live AI unavailable; showing demo result',
      );
    }
  }

  @override
  Future<AiResult> plantCareAdvice({
    required String plant,
    required String city,
  }) async {
    String? weatherLine;
    if (AppConfig.hasOpenWeatherKey) {
      try {
        final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather'
          '?q=$city&appid=${AppConfig.openWeatherApiKey}&units=metric',
        );
        final response =
            await _client.get(url).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final main = data['main'] as Map<String, dynamic>?;
          final weather = (data['weather'] as List?)?.firstOrNull
              as Map<String, dynamic>?;
          weatherLine =
              '${main?['temp']}°C, ${main?['humidity']}% humidity, '
              '${weather?['description'] ?? 'clear'}';
        }
      } catch (_) {
        // Fall through to demo.
      }
    }

    if (AppConfig.hasGeminiKey) {
      try {
        final prompt = StringBuffer()
          ..writeln('Give concise plant care advice for $plant in $city.')
          ..writeln('Audience: urban terrace/rooftop gardener.')
          ..writeln('Keep under 200 words with bullet steps.');
        if (weatherLine != null) {
          prompt.writeln('Current weather: $weatherLine');
        }
        final text = await _geminiText(prompt.toString());
        if (text != null) {
          return AiResult(
            text: text,
            isDemo: false,
            notice: weatherLine == null
                ? 'Weather API unavailable; advice without live weather'
                : null,
          );
        }
      } catch (_) {
        // Fall through.
      }
    }

    final fallback =
        await _demo.plantCareAdvice(plant: plant, city: city);
    return AiResult(
      text: fallback.text,
      isDemo: true,
      notice: 'Live backends unavailable; showing demo result',
    );
  }

  @override
  Future<AiResult> recommendCrops({
    required String city,
    required String spaceType,
    required String areaSize,
    required String dailyTime,
    required String dailyUnit,
  }) async {
    if (AppConfig.hasGeminiKey) {
      try {
        final prompt = '''
Recommend 4–5 crops for an urban grower in $city.
Space type: $spaceType. Area: $areaSize.
Daily care time: $dailyTime $dailyUnit.
Focus on edible plants suited to Indian cities. Keep under 220 words.
''';
        final text = await _geminiText(prompt);
        if (text != null) {
          return AiResult(text: text, isDemo: false);
        }
      } catch (_) {
        // Fall through.
      }
    }

    final fallback = await _demo.recommendCrops(
      city: city,
      spaceType: spaceType,
      areaSize: areaSize,
      dailyTime: dailyTime,
      dailyUnit: dailyUnit,
    );
    return AiResult(
      text: fallback.text,
      isDemo: true,
      notice: 'Live recommendation service unavailable; showing demo result',
    );
  }

  Future<String?> _geminiText(String prompt) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}',
    );
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 1024,
            },
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _extractGeminiText(data);
  }

  String? _extractGeminiText(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;
    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;
    return parts.first['text'] as String?;
  }
}
