import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class GeminiModel {
  final String id;
  final String label;

  const GeminiModel({required this.id, required this.label});
}

class GeminiService {
  static const List<GeminiModel> supportedModels = [
    GeminiModel(id: 'gemini-3.5-flash', label: 'Gemini 3.5 Flash'),
    GeminiModel(id: 'gemini-3.5-pro', label: 'Gemini 3.5 Pro'),
    GeminiModel(id: 'gemini-3.1-flash', label: 'Gemini 3.1 Flash'),
    GeminiModel(id: 'gemini-3.1-pro', label: 'Gemini 3.1 Pro'),
    GeminiModel(id: 'gemini-3.0-flash', label: 'Gemini 3.0 Flash'),
    GeminiModel(id: 'gemini-3.0-pro', label: 'Gemini 3.0 Pro'),
  ];

  static Future<String> analyzeLegalSituation(
    String situation,
    String model,
  ) async {
    final apiKey = await StorageService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY_MISSING');
    }

    const baseUrl = 'https://generativelanguage.googleapis.com';
    final url = Uri.parse(
      '$baseUrl/v1beta/models/$model:generateContent?key=$apiKey',
    );

    const systemPrompt =
        '''คุณคือ "ผู้ช่วยผู้เชี่ยวชาญด้านกฎหมายไทยและทนายความผู้มีความรอบรู้" (Thai legal intelligence advisor) หน้าที่ของคุณคือวิเคราะห์ชีวิตประจำวัน คดีความ ข้อขัดแย้งเชิงธุรกิจ หรือสถานการณ์ที่มีการป้อนเข้ามาในภาษาไทย โดยสรุปประเด็นกฎหมายไทยที่เกี่ยวข้องอย่างละเอียด ระบุเลขมาตรา พร้อมให้คำแนะนำและรายละเอียดศาล/พนักงานสอบสวนอย่างถูกต้องตามประมวลกฎหมายแพ่งและพาณิชย์ ประมวลกฎหมายอาญา กฎหมายวิธีพิจารณาความ กฎหมายแรงงาน กฎหมายปกครอง หรือพระราชบัญญัติเฉพาะทางอื่น ๆ ของราชอาณาจักรไทย

คุณต้องส่งกลับผลลัพธ์เป็นโครงสร้าง 10 หัวข้อดังนี้อย่างเคร่งครัด:
1. บทสรุปของสถานการณ์ว่าเข้าข่ายประเด็นอะไร (summary)
2. หมวดหมู่สำหรับข้อกฎหมายหลัก (category) เช่น "กฎหมายครอบครัว", "กฎหมายแรงงาน", "กฎหมายแพ่งและอาญา - ลักทรัพย์/ผิดสัญญา", "คุ้มครองผู้บริโภค"
3. รายการของข้อกฎหมาย/มาตราที่เกี่ยวข้องโดยตรง (laws) แต่ละมาตราต้องประกอบด้วย:
   - code: ชื่อหลักข้อกฎหมายหรือประมวลกฎหมาย
   - section: เลขมาตราที่เป็นประเด็นหลัก
   - content: เนื้อหาย่อของมาตราดังกล่าวเป็นภาษาไทย
   - relevance: เหตุผลหรือสาเหตุที่ทำไมมาตรานี้จึงมีความเกี่ยวโยงโดยตรงหรือปรับเข้ากับสถานการณ์ที่อธิบายไว้
4. ระบุประเภทคดีเป็นภาษาไทย (caseCategory)
5. ระบุประเภทของศาลที่ตัดสินคดีนี้โดยตรง (competentCourt)
6. แนวทางต่อสู้คดีของ โจทก์ / ผู้ร้อง / ผู้เสียหาย เพื่อเรียกร้องสิทธิ์และรวบรวมข้อมูลพยานหลักฐาน (plaintiffStrategy)
7. แนวทางต่อสู้คดีของ จำเลย / ผู้ถูกกล่าวหา เพื่อแก้ต่าง ปฏิเสธ หรือขอบรรเทาโทษตามหลักสิทธิ (defendantStrategy)
8. แนวทางทำคดีความของพนักงานสอบสวนหรือเจ้าหน้าที่ตำรวจ ในการหาหลักฐาน สอบปากคำ และทำสำนวนส่งอัยการ (investigatorGuideline)
9. แนวโน้มคำตัดสินของศาลสูงสุด หรือศาลฎีกา หรือคำตัดสินอันเป็นที่สุด ที่เป็นบรรทัดฐาน/แนวทางชี้นำทางคดีที่พึงเทียบเคียง (supremeCourtTrend)
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

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      debugPrint('Gemini API Error details: ${response.body}');
      throw Exception('API_ERROR_${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    try {
      final text =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text;
    } catch (e) {
      throw Exception('API_INVALID_RESPONSE');
    }
  }
}
