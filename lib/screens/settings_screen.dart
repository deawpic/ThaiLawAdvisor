import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../constants/theme.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();

  String _maskedKey = '';
  bool _isEditingKey = false;
  String _selectedModel = 'gemini-3.5-flash';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    try {
      final storedKey = await StorageService.getApiKey();
      if (storedKey != null && storedKey.isNotEmpty) {
        _apiKeyController.text = storedKey;
        _maskedKey = _maskApiKey(storedKey);
        _isEditingKey = false;
        await GeminiService.fetchAvailableModels();
      } else {
        _isEditingKey = true;
      }

      final storedModel = await StorageService.getSelectedModel();

      setState(() {
        _selectedModel = storedModel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถดึงข้อมูลการตั้งค่าได้')),
        );
      }
    }
  }

  String _maskApiKey(String key) {
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••••••${key.substring(key.length - 4)}';
  }

  void _handleSaveApiKey() async {
    final keyToSave = _apiKeyController.text.trim();
    if (keyToSave.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอก API Key')));
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });
      await StorageService.saveApiKey(keyToSave);
      await GeminiService.fetchAvailableModels();
      setState(() {
        _maskedKey = _maskApiKey(keyToSave);
        _isEditingKey = false;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึก API Key เรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถบันทึก API Key ได้')),
        );
      }
    }
  }

  void _handleDeleteApiKey() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบ API Key'),
        content: const Text(
          'คุณต้องการลบ API Key ที่บันทึกไว้ใช่หรือไม่? สิ่งนี้จะทำให้ไม่สามารถทำการวิเคราะห์ใหม่ได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              await StorageService.deleteApiKey();
              setState(() {
                _apiKeyController.clear();
                _maskedKey = '';
                _isEditingKey = true;
              });
              navigator.pop();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('ลบ API Key เรียบร้อยแล้ว')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.lightError),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _handleSelectModel(String modelId) async {
    try {
      setState(() {
        _selectedModel = modelId;
      });
      await StorageService.saveSelectedModel(modelId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Failed to save model: $e');
    }
  }



  void _handleClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ล้างประวัติทั้งหมด'),
        content: const Text(
          'คุณต้องการลบประวัติการวิเคราะห์ทั้งหมดออกจากเครื่องใช่หรือไม่? การดำเนินการนี้ไม่สามารถย้อนคืนได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              DatabaseService.clearAllHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ล้างประวัติการวิเคราะห์เรียบร้อยแล้ว'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.lightError),
            child: const Text('ล้างข้อมูล'),
          ),
        ],
      ),
    );
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
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: GeminiService.supportedModels.map((model) {
                      final isSelected = _selectedModel == model.id;
                      return ListTile(
                        title: Text(
                          model.label,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                            : null,
                        onTap: () => _handleSelectModel(model.id),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ตั้งค่าการใช้งาน')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgElement = isDark
        ? AppColors.darkBgElement
        : AppColors.lightBgElement;

    final currentModelLabel = GeminiService.supportedModels
        .firstWhere(
          (m) => m.id == _selectedModel,
          orElse: () => GeminiModel(id: _selectedModel, label: _selectedModel),
        )
        .label;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ตั้งค่าการใช้งาน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: API Key
            _buildSectionHeader('ความปลอดภัยและ API KEY', textSecondary),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.key, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Gemini API Key',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isEditingKey) ...[
                      TextField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'ป้อน Gemini API Key ที่นี่...',
                          hintStyle: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                          fillColor: bgElement,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_maskedKey.isNotEmpty)
                            OutlinedButton(
                              onPressed: () =>
                                  setState(() => _isEditingKey = false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'ยกเลิก',
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _handleSaveApiKey,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('บันทึกคีย์'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _maskedKey,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                                color: textColor,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    setState(() => _isEditingKey = true),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                ),
                                child: Text(
                                  'แก้ไข',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  LucideIcons.trash_2,
                                  color: AppColors.lightError,
                                  size: 16,
                                ),
                                onPressed: _handleDeleteApiKey,
                                style: IconButton.styleFrom(
                                  side: BorderSide(
                                    color: AppColors.lightError.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgElement,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.shield_check,
                            color: AppColors.lightSuccess,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'API Key จะถูกบันทึกไว้อย่างปลอดภัยบนเครื่องของคุณผ่าน SecureStore เท่านั้น',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
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
            const SizedBox(height: 24),

            // Section 2: Model Configuration
            _buildSectionHeader('การตั้งค่าโมเดล AI', textSecondary),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Model Selector Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.cpu,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Flexible(
                                    child: Text(
                                      'โมเดลปัญญาประดิษฐ์',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'เลือกเวอร์ชันโมเดล Gemini เพื่อวิเคราะห์กฎหมาย',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _showModelPicker,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: bgElement,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 120,
                                ),
                                child: Text(
                                  currentModelLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.chevron_down,
                                size: 16,
                                color: textColor,
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
            const SizedBox(height: 24),

            // Section 3: Maintenance
            _buildSectionHeader('การจัดการข้อมูลระบบ', textSecondary),
            Card(
              child: InkWell(
                onTap: _handleClearHistory,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.rotate_ccw,
                            color: AppColors.lightError,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'ล้างประวัติการวิเคราะห์ทั้งหมด',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightError,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ลบประวัติการวิเคราะห์ในเครื่องนี้ทั้งหมด',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Version info
            Center(
              child: Column(
                children: [
                  Text(
                    'Thai Legal Intelligence Advisor App',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0 (Flutter 3.x)',
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}
