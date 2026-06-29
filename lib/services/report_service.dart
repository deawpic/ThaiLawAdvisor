import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../models/history_record.dart';

class ReportService {
  static List<pw.Widget> _parseMarkdownToPdfWidgets(String markdown, pw.Font regular, pw.Font bold) {
    final List<pw.Widget> widgets = [];
    final lines = markdown.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
        continue;
      }
      
      if (trimmed.startsWith('###')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Text(
              trimmed.replaceFirst('###', '').trim(),
              style: pw.TextStyle(font: bold, fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ),
        );
      } else if (trimmed.startsWith('##')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Text(
              trimmed.replaceFirst('##', '').trim(),
              style: pw.TextStyle(font: bold, fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
          ),
        );
      } else if (trimmed.startsWith('#')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            child: pw.Text(
              trimmed.replaceFirst('#', '').trim(),
              style: pw.TextStyle(font: bold, fontSize: 17, fontWeight: pw.FontWeight.bold),
            ),
          ),
        );
      } else if (trimmed.startsWith('-') || trimmed.startsWith('*')) {
        final content = trimmed.substring(1).trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(font: regular, fontSize: 12)),
                pw.Expanded(
                  child: _buildRichText(content, regular, bold, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: _buildRichText(trimmed, regular, bold, fontSize: 12),
          ),
        );
      }
    }
    return widgets;
  }

  static pw.Widget _buildRichText(String text, pw.Font regular, pw.Font bold, {double fontSize = 12}) {
    final parts = text.split('**');
    final List<pw.TextSpan> spans = [];
    
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(
        pw.TextSpan(
          text: parts[i],
          style: pw.TextStyle(
            font: isBold ? bold : regular,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }
    
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(font: regular, fontSize: fontSize, height: 1.4),
        children: spans,
      ),
    );
  }

  static Future<Uint8List> generatePdfBytes(HistoryRecord record) async {
    final doc = pw.Document();
    
    pw.Font regularFont;
    pw.Font boldFont;
    try {
      regularFont = await PdfGoogleFonts.sarabunRegular();
      boldFont = await PdfGoogleFonts.sarabunBold();
    } catch (_) {
      regularFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Text(
              'รายงานผลวิเคราะห์กฎหมายไทยโดย AI',
              style: pw.TextStyle(font: boldFont, fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'วิเคราะห์เมื่อ: ${record.timestamp}',
              style: pw.TextStyle(font: regularFont, fontSize: 10),
            ),
            pw.Text(
              'โมเดล AI: ${record.selectedModel}',
              style: pw.TextStyle(font: regularFont, fontSize: 10),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 12),
            
            pw.Text(
              'สถานการณ์ที่ส่งมาวิเคราะห์:',
              style: pw.TextStyle(font: boldFont, fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              record.situation,
              style: pw.TextStyle(font: regularFont, fontSize: 12, height: 1.4),
            ),
            pw.SizedBox(height: 16),
            
            pw.Text(
              'ผลการวิเคราะห์ข้อกฎหมาย:',
              style: pw.TextStyle(font: boldFont, fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            ..._parseMarkdownToPdfWidgets(record.analysisResult, regularFont, boldFont),
          ];
        },
      ),
    );

    return doc.save();
  }

  static Future<void> shareAsPdf(HistoryRecord record) async {
    final bytes = await generatePdfBytes(record);

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
