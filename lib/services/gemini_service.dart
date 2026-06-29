import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class GeminiModel {
  final String id;
  final String label;

  const GeminiModel({required this.id, required this.label});
}

class TimeoutClient extends http.BaseClient {
  final http.Client _inner;
  final Duration timeout;

  TimeoutClient(this._inner, {this.timeout = const Duration(minutes: 3)});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(timeout);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class GeminiService {
  static List<GeminiModel> supportedModels = [
    // Flash Lite (min -> max)
    const GeminiModel(id: 'gemini-3.0-flash-lite', label: 'Gemini 3.0 Flash Lite'),
    const GeminiModel(id: 'gemini-3.5-flash-lite', label: 'Gemini 3.5 Flash Lite'),
    // Flash (min -> max)
    const GeminiModel(id: 'gemini-1.5-flash', label: 'Gemini 1.5 Flash'),
    const GeminiModel(id: 'gemini-3.0-flash', label: 'Gemini 3.0 Flash'),
    const GeminiModel(id: 'gemini-3.1-flash', label: 'Gemini 3.1 Flash'),
    const GeminiModel(id: 'gemini-3.5-flash', label: 'Gemini 3.5 Flash'),
    // Pro (min -> max)
    const GeminiModel(id: 'gemini-1.5-pro', label: 'Gemini 1.5 Pro'),
    const GeminiModel(id: 'gemini-3.0-pro', label: 'Gemini 3.0 Pro'),
    const GeminiModel(id: 'gemini-3.1-pro', label: 'Gemini 3.1 Pro'),
    const GeminiModel(id: 'gemini-3.5-pro', label: 'Gemini 3.5 Pro'),
  ];

  static Future<List<GeminiModel>> fetchAvailableModels() async {
    final apiKey = await StorageService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return supportedModels;
    }
    final httpClient = TimeoutClient(http.Client(), timeout: const Duration(minutes: 3));
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
      );
      final response = await _executeWithRetry(
        () => httpClient.get(url).timeout(const Duration(minutes: 3)),
        maxRetries: 4,
        initialDelay: const Duration(milliseconds: 2000),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic>? modelsList = data['models'];
        if (modelsList != null) {
          final List<GeminiModel> fetchedModels = [];
          for (var item in modelsList) {
            final String? name = item['name'];
            if (name == null) continue;

            final List<dynamic>? methods = item['supportedGenerationMethods'];
            if (methods == null) continue;
            final hasGenerateContent = methods.any((m) =>
                m.toString().toLowerCase() == 'generatecontent' ||
                m.toString().toLowerCase().contains('generatecontent'));
            if (!hasGenerateContent) continue;

            final modelId = name.replaceFirst('models/', '');
            final lowerId = modelId.toLowerCase();
            final isMatch = lowerId.endsWith('-flash') ||
                lowerId.endsWith('-flash-lite') ||
                lowerId.endsWith('-pro');
            if (!isMatch) continue;

            fetchedModels.add(GeminiModel(id: modelId, label: _formatLabel(modelId)));
          }

          double parseVersion(String id) {
            final match = RegExp(r'gemini-(\d+(?:\.\d+)?)').firstMatch(id);
            if (match != null) {
              return double.tryParse(match.group(1) ?? '0.0') ?? 0.0;
            }
            return 0.0;
          }

          // Group by tier
          final liteModels = fetchedModels
              .where((m) => m.id.endsWith('-flash-lite'))
              .toList();
          final flashModels = fetchedModels
              .where((m) => m.id.endsWith('-flash'))
              .toList();
          final proModels = fetchedModels
              .where((m) => m.id.endsWith('-pro'))
              .toList();

          int compareModelsDescending(GeminiModel a, GeminiModel b) {
            final versionA = parseVersion(a.id);
            final versionB = parseVersion(b.id);
            if (versionA != versionB) {
              return versionB.compareTo(versionA); // Descending (max to min)
            }
            final isPreviewA = a.id.contains('-preview') ? 1 : 0;
            final isPreviewB = b.id.contains('-preview') ? 1 : 0;
            return isPreviewA.compareTo(isPreviewB); // Stable (0) before preview (1)
          }

          liteModels.sort(compareModelsDescending);
          flashModels.sort(compareModelsDescending);
          proModels.sort(compareModelsDescending);

          // Take 4 latest version models per tier
          final latestLite = liteModels.take(4).toList();
          final latestFlash = flashModels.take(4).toList();
          final latestPro = proModels.take(4).toList();

          // Sort each group ascending by version (min -> max)
          int compareModelsAscending(GeminiModel a, GeminiModel b) {
            final versionA = parseVersion(a.id);
            final versionB = parseVersion(b.id);
            if (versionA != versionB) {
              return versionA.compareTo(versionB); // Ascending (min to max)
            }
            final isPreviewA = a.id.contains('-preview') ? 1 : 0;
            final isPreviewB = b.id.contains('-preview') ? 1 : 0;
            return isPreviewA.compareTo(isPreviewB); // Stable (0) before preview (1)
          }

          latestLite.sort(compareModelsAscending);
          latestFlash.sort(compareModelsAscending);
          latestPro.sort(compareModelsAscending);

          // Combine categories sequentially: min->max(Flash Lite) -> min->max(Flash) -> min->max(Pro)
          final List<GeminiModel> finalModels = [];
          finalModels.addAll(latestLite);
          finalModels.addAll(latestFlash);
          finalModels.addAll(latestPro);

          if (finalModels.isNotEmpty) {
            supportedModels = finalModels;
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching Gemini models: $e');
      debugPrint('Stacktrace: $stackTrace');
    } finally {
      httpClient.close();
    }
    return supportedModels;
  }

  static String _formatLabel(String id) {
    String label = id.replaceAll('gemini-', 'Gemini ');
    label = label.replaceAll('-flash-lite', ' Flash Lite');
    label = label.replaceAll('-flash', ' Flash');
    label = label.replaceAll('-pro', ' Pro');
    label = label.replaceAll('-preview', ' Preview');
    label = label.replaceAll('-', ' ');
    // Title Case format helper
    return label.split(' ').map((str) {
      if (str.isEmpty) return str;
      return str[0].toUpperCase() + str.substring(1);
    }).join(' ');
  }

  static Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() requestFn, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 1000),
    double backoffFactor = 2.0,
  }) async {
    int retryCount = 0;
    final random = Random();
    while (true) {
      try {
        final response = await requestFn();
        if ((response.statusCode == 429 || response.statusCode == 503) && retryCount < maxRetries) {
          retryCount++;
          final exponentialDelayMs = (initialDelay.inMilliseconds * pow(backoffFactor, retryCount - 1)).toInt();
          final jitter = random.nextInt((exponentialDelayMs * 0.5).toInt() + 1); // 50% max jitter
          final sleepDuration = Duration(milliseconds: exponentialDelayMs + jitter);
          
          debugPrint('Gemini API ${response.statusCode} detected. Retrying ($retryCount/$maxRetries) in ${sleepDuration.inMilliseconds}ms...');
          await Future.delayed(sleepDuration);
          continue;
        }
        return response;
      } catch (e) {
        if ((e is TimeoutException || e is http.ClientException) && retryCount < maxRetries) {
          retryCount++;
          final exponentialDelayMs = (initialDelay.inMilliseconds * pow(backoffFactor, retryCount - 1)).toInt();
          final jitter = random.nextInt((exponentialDelayMs * 0.5).toInt() + 1); // 50% max jitter
          final sleepDuration = Duration(milliseconds: exponentialDelayMs + jitter);
          
          debugPrint('Gemini API transient error ($e) detected. Retrying ($retryCount/$maxRetries) in ${sleepDuration.inMilliseconds}ms...');
          await Future.delayed(sleepDuration);
          continue;
        }
        rethrow;
      }
    }
  }

  static Future<({String text, String model, int promptTokens, int candidateTokens, int totalTokens})> analyzeLegalSituation(
    String situation,
    String model, {
    http.Client? client,
    int? maxRetries,
    Duration? initialDelay,
  }) async {
    final apiKey = await StorageService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY_MISSING');
    }
    const baseUrl = 'https://generativelanguage.googleapis.com';
    const systemPrompt =
        '''คุณคือ "ผู้ช่วยผู้เชี่ยวชาญด้านกฎหมายไทยและทนายความผู้มีความรอบรู้" (Thai legal intelligence advisor) หน้าที่ของคุณคือวิเคราะห์ชีวิตประจำวัน คดีความ ข้อขัดแย้งเชิงธุรกิจ หรือสถานการณ์ที่มีการป้อนเข้ามาในภาษาไทย โดยสรุปประเด็นกฎหมายไทยที่เกี่ยวข้องอย่างละเอียด ระบุเลขมาตรา พร้อมให้คำแนะนำและรายละเอียดศาล/พนักงานสอบสวนอย่างถูกต้องตามประมวลกฎหมายแพ่งและพาณิชย์ ประมวลกฎหมายอาญา กฎหมายวิธีพิจารณาความ กฎหมายแรงงาน กฎหมายปกครอง หรือพระราชบัญญัติเฉพาะทางอื่น ๆ ของราชอาณาจักรไทย

คุณต้องส่งกลับผลลัพธ์เป็นโครงสร้าง 10 หัวข้อดังนี้อย่างเคร่งครัด:
1. บทสรุปของสถานการณ์ว่าเข้าข่ายประเด็นอะไร (summary)
2. หมวดหมู่สำหรับข้อกฎหมายหลัก (category) เช่น "กฎหมายครอบครัว", "กฎหมายแรงงาน", "กฎหมายแพ่งและอาญา - ลักทรัพย์/ผิดสัญญา", "คุ้มครองผู้บริโภค"
3. รายการของข้อกฎหมาย/มาตราที่เกี่ยวข้องโดยตรง (laws) แต่ละมาตราต้องประกอบด้วย:
   - ชื่อกฎหมาย: ชื่อหลักข้อกฎหมายหรือประมวลกฎหมาย
   - บทบัญญัติ: เลขมาตราที่เป็นประเด็นหลัก
   - เนื้อหา: เนื้อหาย่อของมาตราดังกล่าวเป็นภาษาไทย
   - ความเกี่ยวข้อง: เหตุผลหรือสาเหตุที่ทำไมมาตรานี้จึงมีความเกี่ยวโยงโดยตรงหรือปรับเข้ากับสถานการณ์ที่อธิบายไว้
4. ระบุประเภทคดีเป็นภาษาไทย (caseCategory)
5. ระบุประเภทของศาลที่ตัดสินคดีนี้โดยตรง (competentCourt)
6. แนวทางต่อสู้คดีของ โจทก์ / ผู้ร้อง / ผู้เสียหาย เพื่อเรียกร้องสิทธิ์และรวบรวมข้อมูลพยานหลักฐาน (plaintiffStrategy)
7. แนวทางต่อสู้คดีของ จำเลย / ผู้ถูกกล่าวหา เพื่อแก้ต่าง ปฏิเสธ หรือขอบรรเทาโทษตามหลักสิทธิ (defendantStrategy)
8. แนวทางทำคดีความของพนักงานสอบสวนหรือเจ้าหน้าที่ตำรวจ ในการหาหลักฐาน สอบปากคำ และทำสำนวนส่งอัยการ (investigatorGuideline)
9. แนวโน้มคำตัดสินของศาลสูงสุด หรือศาลฎีกา หรือคำตัดสินอันเป็นที่สุด ที่เป็นบรรทัดฐาน/แนวทางชี้นำทางคดีที่พึงเทียบเคียง ให้ลบข้อความที่เป็นเลขที่ฎีกาออก เพื่อป้องกันเลขที่ผิดพลาด (supremeCourtTrend)
10. คำแนะนำเพิ่มเติมเบื้องต้นเพื่อความปลอดภัยของฝ่ายผู้ใช้ (advice)''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': situation},
          ],
        },
      ],
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'generationConfig': {'temperature': 0.0, 'topP': 0.1},
    };

    final httpClient = client ?? TimeoutClient(http.Client(), timeout: const Duration(minutes: 3));
    try {
      final url = Uri.parse(
        '$baseUrl/v1beta/models/$model:generateContent?key=$apiKey',
      );

      final timeoutDuration = (httpClient is TimeoutClient) ? httpClient.timeout : const Duration(minutes: 3);
      final response = await _executeWithRetry(
        () => httpClient.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        ).timeout(timeoutDuration),
        maxRetries: maxRetries ?? 5,
        initialDelay: initialDelay ?? const Duration(milliseconds: 3000),
      );

      if (response.statusCode != 200) {
        debugPrint('Gemini API Error details for $model: ${response.body}');
        throw Exception('API_ERROR_${response.statusCode}');
      }

      final Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else {
          throw Exception('API_INVALID_RESPONSE_FORMAT');
        }
      } catch (_) {
        throw Exception('API_INVALID_RESPONSE_FORMAT');
      }

      if (data['error'] != null) {
        final errorMsg = data['error']['message'] ?? 'Unknown API Error';
        throw Exception('API_RESPONSE_ERROR: $errorMsg');
      }

      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        final promptFeedback = data['promptFeedback'];
        if (promptFeedback != null && promptFeedback['blockReason'] != null) {
          throw Exception('PROMPT_BLOCKED_SAFETY: ${promptFeedback['blockReason']}');
        }
        throw Exception('API_NO_CANDIDATES');
      }

      final candidate = candidates[0];
      final finishReason = candidate['finishReason'];
      if (finishReason != null && finishReason != 'STOP' && finishReason != 'MAX_TOKENS') {
        throw Exception('CANDIDATE_BLOCKED: $finishReason');
      }

      final content = candidate['content'];
      if (content == null) {
        throw Exception('CONTENT_MISSING');
      }

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('PARTS_MISSING');
      }

      final text = parts[0]['text'] as String?;
      if (text == null) {
        throw Exception('TEXT_MISSING');
      }
      
      int promptTokens = 0;
      int candidateTokens = 0;
      int totalTokens = 0;
      if (data['usageMetadata'] != null) {
        promptTokens = data['usageMetadata']['promptTokenCount'] as int? ?? 0;
        candidateTokens = data['usageMetadata']['candidatesTokenCount'] as int? ?? 0;
        totalTokens = data['usageMetadata']['totalTokenCount'] as int? ?? 0;
      }

      return (
        text: text,
        model: model,
        promptTokens: promptTokens,
        candidateTokens: candidateTokens,
        totalTokens: totalTokens,
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
