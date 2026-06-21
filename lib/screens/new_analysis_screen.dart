import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../constants/theme.dart';
import '../models/history_record.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import 'settings_screen.dart';
import 'analysis_result_screen.dart';

class SuggestionItem {
  final String title;
  final String text;
  final String category;

  const SuggestionItem({
    required this.title,
    required this.text,
    required this.category,
  });
}

class NewAnalysisScreen extends StatefulWidget {
  const NewAnalysisScreen({super.key});

  @override
  State<NewAnalysisScreen> createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends State<NewAnalysisScreen> {
  final TextEditingController _controller = TextEditingController();
  String _situation = '';
  String _model = 'gemini-3.5-flash';
  bool _isLoading = false;
  int _loadingStep = 0;
  bool _hasApiKey = false;
  Timer? _loadingTimer;

  static const List<SuggestionItem> _suggestions = [
    SuggestionItem(
      title: 'กู้ยืมเงินแล้วไม่คืน',
      text:
          'เพื่อนขอยืมเงินจำนวน 50,000 บาท มีการแชทคุยกันทาง LINE สัญญาว่าจะคืนภายใน 3 เดือน ตอนนี้เลยกำหนดมาแล้ว 5 เดือน ทวงถามแล้วบ่ายเบี่ยงตลอด ไม่มีหนังสือสัญญาเงินกู้กระดาษ สามารถฟ้องร้องหรือทำอย่างไรได้บ้างครับ',
      category: 'แพ่ง - กู้ยืมเงิน',
    ),
    SuggestionItem(
      title: 'นายจ้างเลิกจ้างกะทันหัน',
      text:
          'ทำงานบริษัทเอกชนมาเป็นเวลา 3 ปี วันนี้ฝ่ายบุคคลแจ้งเลิกจ้างกะทันหันโดยมีผลทันที โดยอ้างว่าบริษัทต้องการลดค่าใช้จ่าย ไม่ได้มีข้อผิดพลาดร้ายแรงใดๆ และบริษัทไม่ยอมจ่ายค่าชดเชยหรือค่าบอกกล่าวล่วงหน้า หนูมีสิทธิ์เรียกร้องอะไรได้บ้างคะ',
      category: 'แรงงาน',
    ),
    SuggestionItem(
      title: 'โกงซื้อของออนไลน์',
      text:
          'สั่งซื้อโทรศัพท์มือถือราคา 15,000 บาทผ่านทางเพจ Facebook โอนเงินเข้าบัญชีส่วนตัวของแม่ค้าไปเรียบร้อยแล้ว ผ่านมา 7 วัน เพจปิดหนี บล็อกไลน์ ติดต่อไม่ได้ และยังไม่ได้รับสินค้าเลยครับ',
      category: 'อาญา - ฉ้อโกง',
    ),
    SuggestionItem(
      title: 'เพื่อนบ้านเสียงดัง/รบกวน',
      text:
          'บ้านข้างๆ เปิดร้านซ่อมมอเตอร์ไซค์ ส่งเสียงดังจากการเบิ้ลเครื่องยนต์และทดสอบท่อไอเสียเกือบทั้งวัน ตั้งแต่ 8 โมงเช้าถึง 4 ทุ่ม และมีกลิ่นควันรถลอยเข้ามาในบ้านตลอดเวลา เคยเข้าไปคุยดีๆ แล้วแต่เขาไม่สนใจ',
      category: 'แพ่ง - ละเมิด/เหตุเดือดร้อนรำคาญ',
    ),
  ];

  static const List<String> _loadingTexts = [
    'กำลังเชื่อมต่อกับ Gemini API...',
    'กำลังวิเคราะห์ประเด็นและข้อเท็จจริงทางกฎหมาย...',
    'กำลังสืบค้นมาตรากฎหมายไทยที่เกี่ยวข้อง...',
    'กำลังวิเคราะห์แนวทางสู้คดีของโจทก์และจำเลย...',
    'กำลังจัดเตรียมบทสรุปและข้อเสนอแนะเพื่อความปลอดภัย...',
  ];

  @override
  void initState() {
    super.initState();
    _checkSetup();
    _controller.addListener(() {
      setState(() {
        _situation = _controller.text;
      });
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _checkSetup() async {
    final key = await StorageService.getApiKey();
    final modelName = await StorageService.getSelectedModel();
    setState(() {
      _hasApiKey = key != null && key.isNotEmpty;
      _model = modelName;
    });
  }

  void _showModelPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'เลือกโมเดล Gemini',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'ปิด',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...GeminiService.supportedModels.map((model) {
                final isSelected = _model == model.id;
                return ListTile(
                  title: Text(
                    model.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : textColor,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                  onTap: () => _handleSelectModel(model.id),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _handleSelectModel(String modelId) async {
    try {
      setState(() {
        _model = modelId;
      });
      await StorageService.saveSelectedModel(modelId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Failed to save model: $e');
    }
  }

  void _startLoadingTimer() {
    _loadingStep = 0;
    _loadingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _loadingStep = (_loadingStep + 1) % _loadingTexts.length;
      });
    });
  }

  void _stopLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  void _handleStartAnalysis() async {
    if (_situation.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลสถานการณ์ที่ต้องการวิเคราะห์'),
        ),
      );
      return;
    }

    if (!_hasApiKey) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ไม่พบ API Key'),
          content: const Text(
            'กรุณาตั้งค่า Gemini API Key ในเมนูตั้งค่าก่อนเริ่มต้นวิเคราะห์',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) => _checkSetup());
              },
              child: const Text('ไปที่หน้าตั้งค่า'),
            ),
          ],
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });
    _startLoadingTimer();

    try {
      final resultText = await GeminiService.analyzeLegalSituation(
        _situation.trim(),
        _model,
      );

      // Create format timestamp
      final now = DateTime.now();
      final months = [
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.',
      ];
      final formattedTime =
          '${now.day} ${months[now.month - 1]} ${now.year + 543} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final record = HistoryRecord(
        situation: _situation.trim(),
        timestamp: formattedTime,
        selectedModel: _model,
        analysisResult: resultText,
      );

      final newId = await DatabaseService.saveAnalysis(record);

      _stopLoadingTimer();
      setState(() {
        _isLoading = false;
      });

      // Navigate to results screen (replace current)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultScreen(id: newId),
          ),
        );
      }
    } catch (error) {
      _stopLoadingTimer();
      setState(() {
        _isLoading = false;
      });

      String errorMsg =
          'เกิดข้อผิดพลาดในการติดต่อระบบ ปัญญาประดิษฐ์ กรุณาตรวจสอบอินเทอร์เน็ตหรือความถูกต้องของ API Key';
      final errStr = error.toString();
      if (errStr.contains('API_ERROR_403')) {
        errorMsg =
            'สิทธิ์การเข้าถึงถูกปฏิเสธ (403) คีย์ API ของคุณอาจไม่ถูกต้อง หรือไม่มีสิทธิ์เรียกใช้งานโมเดลนี้';
      } else if (errStr.contains('API_ERROR_404')) {
        errorMsg = 'ไม่พบโมเดลนี้ (404) กรุณาเข้าไปเลือกโมเดลอื่นในเมนูตั้งค่า';
      } else if (errStr.contains('API_KEY_MISSING')) {
        errorMsg = 'ไม่พบ API Key กรุณากรอกคีย์ในเมนูตั้งค่า';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ข้อผิดพลาดในการวิเคราะห์'),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _applySuggestion(String text) {
    _controller.text = text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final secondaryColor = isDark
        ? AppColors.darkSecondary
        : AppColors.lightSecondary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgElement = isDark
        ? AppColors.darkBgElement
        : AppColors.lightBgElement;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'วิเคราะห์กฎหมายใหม่',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Main Input view
          IgnorePointer(
            ignoring: _isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Model Selection Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: border),
                    ),
                    color: cardColor,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _showModelPicker,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.sparkles,
                                color: primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'เลือกโมเดล AI ที่ใช้วิเคราะห์',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    GeminiService.supportedModels
                                        .firstWhere(
                                          (m) => m.id == _model,
                                          orElse: () => GeminiService
                                              .supportedModels
                                              .first,
                                        )
                                        .label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              LucideIcons.chevron_down,
                              color: textSecondary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TextArea Label
                  Text(
                    'อธิบายสถานการณ์ ข้อขัดแย้ง หรือปัญหาคดีความของคุณ',
                    style: TextStyle(
                      color: textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // TextArea Input
                  Container(
                    height: 240,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText:
                                  'พิมพ์อธิบายเรื่องราวที่ต้องการปรึกษากฎหมาย เช่น โดนคนกู้ยืมเงินแล้วไม่คืน, โดนเลิกจ้างไม่เป็นธรรม, ซื้อของออนไลน์แล้วโดนโกง ฯลฯ โดยระบุรายละเอียดและข้อเท็จจริงให้มากที่สุดเท่าที่เป็นไปได้...',
                              hintStyle: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '${_situation.length} ตัวอักษร',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Suggestions Slider (only if input is empty)
                  if (_situation.isEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          LucideIcons.circle_question_mark,
                          color: textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ตัวอย่างสถานการณ์ที่พบบ่อย (แตะเพื่อใช้)',
                          style: TextStyle(
                            color: textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final item = _suggestions[index];
                          return GestureDetector(
                            onTap: () => _applySuggestion(item.text),
                            child: Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '#${item.category}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      item.text,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: _situation.trim().isEmpty
                        ? null
                        : _handleStartAnalysis,
                    icon: const Icon(
                      LucideIcons.scale,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'เริ่มต้นวิเคราะห์กฎหมาย',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _situation.trim().isEmpty
                          ? bgElement
                          : primaryColor,
                      disabledBackgroundColor: bgElement,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Safety Disclaimer card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgElement,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.info, color: textSecondary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ข้อมูลทั้งหมดจะส่งตรงไปประมวลผลที่โมเดลปัญญาประดิษฐ์ของ Google เท่านั้น ไม่มีการจัดเก็บข้อมูลส่วนบุคคลบนเซิร์ฟเวอร์ภายนอกอื่นใด',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading Screen overlay
          if (_isLoading)
            Container(
              color:
                  (isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground)
                      .withValues(alpha: 0.93),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: primaryColor),
                          const SizedBox(height: 24),
                          Text(
                            'ระบบกำลังดำเนินการ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            child: Text(
                              _loadingTexts[_loadingStep],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '* ขั้นตอนนี้อาจใช้เวลาประมาณ 10-20 วินาที',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.lightError,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
