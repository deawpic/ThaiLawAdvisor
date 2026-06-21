import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../constants/theme.dart';
import '../models/history_record.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import 'new_analysis_screen.dart';
import 'settings_screen.dart';
import 'analysis_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<HistoryRecord> _history = [];
  String _searchQuery = '';
  bool _hasApiKey = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final records = DatabaseService.getAllHistory();
    final key = await StorageService.getApiKey();
    setState(() {
      _history = records;
      _hasApiKey = key != null && key.isNotEmpty;
    });
  }

  void _handleDelete(int id, String titleSnippet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบประวัติ'),
        content: Text(
          'คุณต้องการลบการวิเคราะห์สำหรับ "$titleSnippet" ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              DatabaseService.deleteHistoryById(id);
              Navigator.pop(ctx);
              _loadData();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.lightError),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  String _getCategory(String resultText) {
    final lines = resultText.split('\n');
    int startIdx = -1;
    int endIdx = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final cleanLine = line.replaceAll('*', '').trim();
      if (startIdx == -1 &&
          (cleanLine.startsWith('2.') ||
              cleanLine.startsWith('2 ') ||
              cleanLine.contains('หมวดหมู่สำหรับข้อกฎหมายหลัก'))) {
        startIdx = i;
      } else if (startIdx != -1 &&
          endIdx == -1 &&
          (cleanLine.startsWith('3.') ||
              cleanLine.startsWith('3 ') ||
              cleanLine.contains('รายการของข้อกฎหมาย'))) {
        endIdx = i;
        break;
      }
    }

    if (startIdx != -1) {
      final end = (endIdx != -1)
          ? endIdx
          : (startIdx + 3 < lines.length ? startIdx + 3 : lines.length);
      final categoryLines = lines.sublist(startIdx, end);

      String fullText = categoryLines.join('\n');
      fullText = fullText.replaceAll('*', '');

      // Remove common headings
      fullText = fullText.replaceFirst(
        RegExp(
          r'^2\.\s*หมวดหมู่สำหรับข้อกฎหมายหลัก[^\n:]*:\s*',
          caseSensitive: false,
        ),
        '',
      );
      fullText = fullText.replaceFirst(
        RegExp(
          r'^2\.\s*หมวดหมู่สำหรับข้อกฎหมายหลัก[^\n\)]*\)\s*',
          caseSensitive: false,
        ),
        '',
      );
      fullText = fullText.replaceFirst(
        RegExp(r'^2\.\s*หมวดหมู่[^\n:]*:\s*', caseSensitive: false),
        '',
      );
      fullText = fullText.replaceFirst(
        RegExp(r'^2\.\s*หมวดหมู่[^\n\)]*\)\s*', caseSensitive: false),
        '',
      );

      final firstLine = fullText.split('\n').first;
      if (firstLine.contains('หมวดหมู่') ||
          firstLine.contains('category') ||
          firstLine.startsWith('2.')) {
        fullText = fullText.substring(firstLine.length).trim();
      }

      return fullText.trim();
    }

    return 'วิเคราะห์กฎหมาย';
  }

  String _getSummary(String resultText) {
    final lines = resultText.split('\n');
    int startIdx = -1;
    int endIdx = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final cleanLine = line.replaceAll('*', '').trim();
      if (startIdx == -1 &&
          (cleanLine.startsWith('1.') ||
              cleanLine.startsWith('1 ') ||
              cleanLine.contains('บทสรุปของสถานการณ์'))) {
        startIdx = i;
      } else if (startIdx != -1 &&
          endIdx == -1 &&
          (cleanLine.startsWith('2.') ||
              cleanLine.startsWith('2 ') ||
              cleanLine.contains('หมวดหมู่สำหรับข้อกฎหมายหลัก'))) {
        endIdx = i;
        break;
      }
    }

    if (startIdx != -1) {
      final end = (endIdx != -1)
          ? endIdx
          : (startIdx + 5 < lines.length ? startIdx + 5 : lines.length);
      final summaryLines = lines.sublist(startIdx, end);

      String fullText = summaryLines.join('\n');
      fullText = fullText.replaceAll('*', '');

      // Remove common headings
      fullText = fullText.replaceFirst(
        RegExp(r'^1\.\s*บทสรุปของสถานการณ์[^\n:]*:\s*', caseSensitive: false),
        '',
      );
      fullText = fullText.replaceFirst(
        RegExp(r'^1\.\s*บทสรุปของสถานการณ์[^\n\)]*\)\s*', caseSensitive: false),
        '',
      );
      fullText = fullText.replaceFirst(
        RegExp(r'^1\.\s*บทสรุป[^\n:]*:\s*', caseSensitive: false),
        '',
      );
      fullText = fullText.replaceFirst(
        RegExp(r'^1\.\s*บทสรุป[^\n\)]*\)\s*', caseSensitive: false),
        '',
      );

      // Generic fallback: remove the first line if it contains the word "บทสรุป" or "summary"
      final firstLine = fullText.split('\n').first;
      if (firstLine.isNotEmpty &&
          (firstLine.contains('บทสรุป') ||
              firstLine.contains('summary') ||
              firstLine.startsWith('1.'))) {
        fullText = fullText.substring(firstLine.length).trim();
      }

      return fullText.trim();
    }
    return '';
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

    final filteredHistory = _history.where((item) {
      final query = _searchQuery.toLowerCase();
      final situationMatch = item.situation.toLowerCase().contains(query);
      final resultMatch = item.analysisResult.toLowerCase().contains(query);
      return situationMatch || resultMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'วิเคราะห์กฎหมายไทย',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Warning Banner when API key is missing
          if (!_hasApiKey)
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                _loadData();
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightError.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.lightError.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.triangle_alert,
                      color: AppColors.lightError,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ยังไม่ได้ตั้งค่า API Key',
                            style: TextStyle(
                              color: AppColors.lightError,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'แตะที่นี่เพื่อใส่ Gemini API Key ในการเริ่มต้นใช้งาน',
                            style: TextStyle(color: textColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevron_right,
                      color: AppColors.lightError,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'กด +  ด้านล่างเพื่อวิเคราะห์ใหม่',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          LucideIcons.search,
                          color: AppColors.lightTextSecondary,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'ค้นหาจากประวัติ...',
                            hintStyle: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: TextStyle(color: textColor, fontSize: 14),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.lightTextSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats header
          if (_history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ประวัติการวิเคราะห์ทั้งหมด: ${_history.length} รายการ',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ),
            ),

          // History List
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.scale,
                            size: 64,
                            color: textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'ไม่พบข้อมูลที่ค้นหา'
                                : 'ยังไม่มีประวัติการวิเคราะห์',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'ลองพิมพ์ค้นหาด้วยคำอื่น'
                                : 'เริ่มต้นวิเคราะห์ปัญหาข้อขัดแย้งทางกฎหมายของคุณได้ทันที',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final target = _hasApiKey
                                    ? const NewAnalysisScreen()
                                    : const SettingsScreen();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => target,
                                  ),
                                );
                                _loadData();
                              },
                              icon: const Icon(
                                LucideIcons.plus,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                _hasApiKey
                                    ? 'เริ่มวิเคราะห์ตอนนี้'
                                    : 'ตั้งค่า API Key เพื่อเริ่มต้น',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = filteredHistory[index];
                      final category = _getCategory(item.analysisResult);
                      final summary = _getSummary(item.analysisResult);
                      final truncatedSituation = item.situation.length > 80
                          ? '${item.situation.substring(0, 80)}...'
                          : item.situation;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: border, width: 1),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AnalysisResultScreen(id: item.id!),
                              ),
                            );
                            _loadData();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category & Delete
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bgElement,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              LucideIcons.scale,
                                              size: 14,
                                              color: secondaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                category,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: secondaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        LucideIcons.trash_2,
                                        size: 16,
                                        color: AppColors.lightError,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _handleDelete(
                                        item.id!,
                                        item.situation.length > 20
                                            ? '${item.situation.substring(0, 20)}...'
                                            : item.situation,
                                      ),
                                    ),
                                  ],
                                ),
                                // Situation
                                Text(
                                  truncatedSituation,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                if (summary.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: bgElement.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: border.withValues(alpha: 0.6),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              LucideIcons.file_text,
                                              size: 13,
                                              color: primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'บทสรุป',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          summary.length > 150
                                              ? '${summary.substring(0, 150)}...'
                                              : summary,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                // Footer
                                const Divider(height: 1, thickness: 0.5),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.calendar,
                                            size: 12,
                                            color: textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              item.timestamp,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.sparkles,
                                            size: 12,
                                            color: primaryColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              item.selectedModel.replaceAll(
                                                'gemini-',
                                                'Gemini ',
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            LucideIcons.chevron_right,
                                            size: 16,
                                            color: textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _hasApiKey
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewAnalysisScreen(),
                  ),
                );
                _loadData();
              },
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(LucideIcons.plus, size: 28),
            )
          : null,
    );
  }
}
