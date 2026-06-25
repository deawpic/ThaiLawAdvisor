import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../constants/theme.dart';
import '../models/history_record.dart';
import '../services/database_service.dart';
import '../services/report_service.dart';



class AnalysisResultScreen extends StatefulWidget {
  final int id;

  const AnalysisResultScreen({super.key, required this.id});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  HistoryRecord? _record;

  String _activeTab = 'interactive'; // 'interactive' or 'markdown'
  bool _showSituation = false;
  double _fontSize = 15.0;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  void _loadRecord() {
    final data = DatabaseService.getHistoryById(widget.id);
    if (data != null) {
      setState(() {
        _record = data;
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบข้อมูลการวิเคราะห์นี้')),
        );
        Navigator.pop(context);
      });
    }
  }



  void _handleCopyToClipboard() async {
    if (_record == null) return;
    await Clipboard.setData(ClipboardData(text: _record!.analysisResult));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('คัดลอกบทวิเคราะห์กฎหมายไปยังคลิปบอร์ดแล้ว'),
        ),
      );
    }
  }

  void _handleShare() {
    if (_record == null) return;
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
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'แชร์รายงานผลวิเคราะห์',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.article, color: Colors.teal),
                title: Text('บันทึกเป็นไฟล์ข้อความ (.txt)', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _shareTxt();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text('ส่งออกเป็นรายงาน PDF', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _sharePdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: Text('แชร์ไปยังแอปอื่น (ข้อความ)', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(context);
                  _shareToOtherApps();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareToOtherApps() async {
    final message =
        '[ผลวิเคราะห์กฎหมายไทยโดย AI]\n\nสถานการณ์:\n${_record!.situation}\n\nบทวิเคราะห์:\n${_record!.analysisResult}';
    await SharePlus.instance.share(
      ShareParams(text: message, title: 'ผลวิเคราะห์กฎหมายไทยโดย AI'),
    );
  }

  void _shareTxt() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังสร้างไฟล์ข้อความ (.txt)...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await ReportService.shareAsTxt(_record!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      final errorStr = e.toString();
      if (errorStr.contains('SAVED_TO_DOWNLOADS|')) {
        final path = errorStr.split('|')[1];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('บันทึกไฟล์ข้อความเรียบร้อยแล้วที่: $path'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (errorStr.contains('CANCELLED')) {
        // User cancelled
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้างไฟล์ข้อความ: $e')),
          );
        }
      }
    }
  }

  void _sharePdf() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังสร้างไฟล์ PDF และดาวน์โหลดฟอนต์...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await ReportService.shareAsPdf(_record!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      final errorStr = e.toString();
      if (errorStr.contains('SAVED_TO_DOWNLOADS|')) {
        final path = errorStr.split('|')[1];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('บันทึกรายงาน PDF เรียบร้อยแล้วที่: $path'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (errorStr.contains('CANCELLED')) {
        // User cancelled
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้างไฟล์ PDF: $e')),
          );
        }
      }
    }
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text(
          'คุณต้องการลบบทวิเคราะห์นี้ออกจากเครื่องถาวรใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              DatabaseService.deleteHistoryById(widget.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.lightError),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_record == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'วิเคราะห์สถานการณ์',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size, color: Colors.white),
            tooltip: 'ปรับขนาดอักษร',
            onPressed: () {
              setState(() {
                if (_fontSize == 15.0) {
                  _fontSize = 18.0;
                } else if (_fontSize == 18.0) {
                  _fontSize = 21.0;
                } else if (_fontSize == 21.0) {
                  _fontSize = 13.0;
                } else {
                  _fontSize = 15.0;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.copy, color: Colors.white),
            onPressed: _handleCopyToClipboard,
          ),
          IconButton(
            icon: const Icon(LucideIcons.share_2, color: Colors.white),
            onPressed: _handleShare,
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash_2, color: Colors.white),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Headers
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(bottom: BorderSide(color: border, width: 0.5)),
            ),
            child: Row(
              children: [
                /*                 Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 'interactive'),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTab == 'interactive'
                                ? primaryColor
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'สรุปประเด็นหลัก',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _activeTab == 'interactive'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _activeTab == 'interactive'
                              ? primaryColor
                              : textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                 */
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 'markdown'),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTab == 'markdown'
                                ? primaryColor
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'รายงานฉบับเต็ม',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _activeTab == 'markdown'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _activeTab == 'markdown'
                              ? primaryColor
                              : textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Situation Card at top
                  Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: border, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => setState(
                              () => _showSituation = !_showSituation,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.file_text,
                                        color: textSecondary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'เหตุการณ์และคำถามที่ปรึกษา',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _showSituation ? 'ย่อ' : 'ดูรายละเอียด',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _showSituation
                                          ? LucideIcons.chevron_up
                                          : LucideIcons.chevron_down,
                                      size: 16,
                                      color: secondaryColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _record!.situation,
                            maxLines: _showSituation ? null : 2,
                            overflow: _showSituation
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: _showSituation ? textColor : textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 0.5),
                          const SizedBox(height: 10),
                          Text(
                            'วิเคราะห์เมื่อ: ${_record!.timestamp} | ด้วย ${_record!.selectedModel.replaceAll('gemini-', 'Gemini ')}${_record!.totalTokens > 0 ? ' | ใช้โทเคนทั้งหมด: ${_record!.totalTokens} (Input: ${_record!.promptTokens}, Output: ${_record!.candidateTokens})' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab switch contents
                  /*                  if (_activeTab == 'interactive')
                    ..._sections.map((section) {
                      final isExpanded = _expandedSections[section.id] ?? false;
                      final themeColor = section.id == 10
                          ? accentColor
                          : primaryColor;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isExpanded ? themeColor : border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _expandedSections[section.id] = !isExpanded;
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color:
                                                  (section.id == 10
                                                          ? accentColor
                                                          : primaryColor)
                                                      .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              _getSectionIcon(section.id),
                                              color: themeColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'หมวดที่ ${section.id}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: textSecondary,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  section.title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? LucideIcons.chevron_up
                                          : LucideIcons.chevron_down,
                                      color: textSecondary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded) ...[
                              const Divider(height: 1, thickness: 0.5),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: MarkdownBody(
                                  data: section.content,
                                  styleSheet:
                                      MarkdownStyleSheet.fromTheme(
                                        Theme.of(context),
                                      ).copyWith(
                                        p: TextStyle(
                                          color: textColor,
                                          fontSize: 15,
                                          height: 1.5,
                                        ),
                                        strong: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        listBullet: TextStyle(
                                          color: textColor,
                                          fontSize: 15,
                                        ),
                                        h1: TextStyle(
                                          color: primaryColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        h2: TextStyle(
                                          color: secondaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    })
                  else
                    */
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: border, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.sparkles,
                                color: primaryColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'รายงานผลวิเคราะห์ฉบับสมบูรณ์',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          MarkdownBody(
                            data: _record!.analysisResult,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: TextStyle(
                                    color: textColor,
                                    fontSize: _fontSize,
                                    height: 1.5,
                                  ),
                                  strong: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: _fontSize,
                                  ),
                                  listBullet: TextStyle(
                                    color: textColor,
                                    fontSize: _fontSize,
                                  ),
                                  h1: TextStyle(
                                    color: primaryColor,
                                    fontSize: _fontSize + 4.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  h2: TextStyle(
                                    color: secondaryColor,
                                    fontSize: _fontSize + 2.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
