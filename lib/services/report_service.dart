import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:printing/printing.dart';
import '../models/history_record.dart';

class ReportService {
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  static Future<String?> _findChromeExecutable() async {
    if (Platform.isLinux) {
      final paths = [
        'google-chrome',
        'google-chrome-stable',
        'chromium',
        'chromium-browser',
        '/usr/bin/google-chrome',
        '/usr/bin/chromium',
      ];
      for (final path in paths) {
        try {
          final result = await Process.run('which', [path]);
          if (result.exitCode == 0) {
            return path;
          }
        } catch (_) {}
      }
    } else if (Platform.isWindows) {
      final paths = [
        r'C:\Program Files\Google\Chrome\Application\chrome.exe',
        r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
        r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
      ];
      for (final path in paths) {
        if (await File(path).exists()) {
          return path;
        }
      }
    }
    return null;
  }

  static Future<Uint8List> _convertHtmlToPdf(String htmlContent) async {
    final chromePath = await _findChromeExecutable();
    if (chromePath != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final htmlFile = File('${tempDir.path}/temp_$timestamp.html');
        final pdfFile = File('${tempDir.path}/temp_$timestamp.pdf');
        
        await htmlFile.writeAsString(htmlContent, encoding: utf8);
        
        final result = await Process.run(chromePath, [
          '--headless',
          '--disable-gpu',
          '--print-to-pdf=${pdfFile.path}',
          htmlFile.path,
        ]);
        
        if (result.exitCode == 0 && await pdfFile.exists()) {
          final bytes = await pdfFile.readAsBytes();
          // Clean up
          await htmlFile.delete();
          await pdfFile.delete();
          return bytes;
        } else {
          debugPrint('Chrome PDF generation failed: ${result.stderr}');
        }
      } catch (e) {
        debugPrint('Error running Chrome/Edge for PDF generation: $e');
      }
    }
    
    // Fallback to Printing.convertHtml for other platforms
    // ignore: deprecated_member_use
    return await Printing.convertHtml(
      html: htmlContent,
      format: PdfPageFormat.a4,
    );
  }

  static Future<void> shareAsPdf(HistoryRecord record) async {
    final escapedSituation = _escapeHtml(record.situation);
    final escapedTimestamp = _escapeHtml(record.timestamp);
    final escapedModel = _escapeHtml(record.selectedModel);
    final htmlAnalysisResult = md.markdownToHtml(record.analysisResult);

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>รายงานผลวิเคราะห์กฎหมายไทยโดย AI</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Sarabun:ital,wght@0,300;0,400;0,700;1,400&display=swap" rel="stylesheet">
  <style>
    @page {
      size: A4;
      margin: 20mm;
    }
    body {
      font-family: 'Sarabun', 'Tahoma', 'Leelawadee', sans-serif;
      margin: 0;
      padding: 0;
      color: #212121;
      line-height: 1.6;
      font-size: 14px;
    }
    .header {
      border-bottom: 2px solid #1565C0;
      padding-bottom: 12px;
      margin-bottom: 20px;
    }
    h1 {
      font-size: 24px;
      color: #1565C0;
      margin: 0 0 8px 0;
      font-weight: 700;
    }
    .metadata {
      font-size: 11px;
      color: #616161;
    }
    .metadata-item {
      margin-bottom: 4px;
    }
    .section-title {
      font-size: 14px;
      font-weight: 700;
      color: #212121;
      margin-top: 25px;
      margin-bottom: 10px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .situation-container {
      background-color: #F5F5F5;
      border-left: 4px solid #42A5F5;
      padding: 12px 16px;
      margin-bottom: 25px;
      border-radius: 4px;
      white-space: pre-wrap;
      font-size: 13px;
      color: #424242;
    }
    .analysis-container {
      font-size: 13px;
      color: #212121;
    }
    .analysis-container h1 {
      font-size: 18px;
      color: #1565C0;
      margin-top: 22px;
      margin-bottom: 10px;
      border-bottom: 1px solid #E0E0E0;
      padding-bottom: 6px;
      font-weight: 700;
    }
    .analysis-container h2 {
      font-size: 15px;
      color: #1976D2;
      margin-top: 18px;
      margin-bottom: 8px;
      font-weight: 700;
    }
    .analysis-container h3 {
      font-size: 13px;
      color: #212121;
      margin-top: 14px;
      margin-bottom: 6px;
      font-weight: 700;
    }
    .analysis-container p {
      margin-top: 0;
      margin-bottom: 10px;
      text-align: justify;
    }
    .analysis-container ul, .analysis-container ol {
      margin-top: 0;
      margin-bottom: 10px;
      padding-left: 24px;
    }
    .analysis-container li {
      margin-bottom: 6px;
    }
    .analysis-container strong {
      font-weight: 700;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>รายงานผลวิเคราะห์กฎหมายไทยโดย AI</h1>
    <div class="metadata">
      <div class="metadata-item">วิเคราะห์เมื่อ: $escapedTimestamp</div>
      <div class="metadata-item">โมเดล AI: $escapedModel</div>
    </div>
  </div>
  
  <div class="section-title">สถานการณ์ที่ส่งมาวิเคราะห์:</div>
  <div class="situation-container">$escapedSituation</div>
  
  <div class="section-title">ผลการวิเคราะห์ข้อกฎหมาย:</div>
  <div class="analysis-container">
    $htmlAnalysisResult
  </div>
</body>
</html>
''';

    final bytes = await _convertHtmlToPdf(htmlContent);

    if (Platform.isLinux || Platform.isWindows) {
      final String? selectedPath = await FilePicker.saveFile(
        dialogTitle: 'บันทึกรายงาน PDF',
        fileName: 'รายงานวิเคราะห์กฎหมาย_${record.id ?? DateTime.now().millisecondsSinceEpoch}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (selectedPath != null) {
        throw Exception('SAVED_TO_DOWNLOADS|$selectedPath');
      } else {
        throw Exception('CANCELLED');
      }
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/รายงานวิเคราะห์กฎหมาย_${record.id ?? DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        text: 'รายงานผลวิเคราะห์กฎหมายไทยโดย AI',
        files: [XFile(file.path, mimeType: 'application/pdf')],
      ),
    );
  }

  static Future<void> shareAsTxt(HistoryRecord record) async {
    final reportContent =
        'รายงานผลวิเคราะห์กฎหมายไทยโดย AI\n'
        'วิเคราะห์เมื่อ: ${record.timestamp}\n'
        'โมเดล AI: ${record.selectedModel}\n\n'
        'สถานการณ์ที่ส่งมาวิเคราะห์:\n'
        '${record.situation}\n\n'
        'ผลการวิเคราะห์ข้อกฎหมาย:\n'
        '${record.analysisResult}';

    final bytes = Uint8List.fromList(utf8.encode(reportContent));

    if (Platform.isLinux || Platform.isWindows) {
      final String? selectedPath = await FilePicker.saveFile(
        dialogTitle: 'บันทึกรายงานข้อความ',
        fileName: 'รายงานวิเคราะห์กฎหมาย_${record.id ?? DateTime.now().millisecondsSinceEpoch}.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: bytes,
      );

      if (selectedPath != null) {
        throw Exception('SAVED_TO_DOWNLOADS|$selectedPath');
      } else {
        throw Exception('CANCELLED');
      }
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/รายงานวิเคราะห์กฎหมาย_${record.id ?? DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        text: 'รายงานผลวิเคราะห์กฎหมายไทยโดย AI',
        files: [XFile(file.path, mimeType: 'text/plain')],
      ),
    );
  }
}
