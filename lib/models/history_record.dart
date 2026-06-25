class HistoryRecord {
  final int? id;
  final String situation;
  final String timestamp;
  final String selectedModel;
  final String analysisResult;
  final int promptTokens;
  final int candidateTokens;
  final int totalTokens;

  HistoryRecord({
    this.id,
    required this.situation,
    required this.timestamp,
    required this.selectedModel,
    required String analysisResult,
    this.promptTokens = 0,
    this.candidateTokens = 0,
    this.totalTokens = 0,
  }) : analysisResult = _formatAnalysisResult(analysisResult);

  static String _formatAnalysisResult(String resultText) {
    return resultText
        .replaceAll('code:', 'ชื่อกฎหมาย:')
        .replaceAll('Code:', 'ชื่อกฎหมาย:')
        .replaceAll('section:', 'บทบัญญัติ:')
        .replaceAll('Section:', 'บทบัญญัติ:')
        .replaceAll('content:', 'เนื้อหา:')
        .replaceAll('Content:', 'เนื้อหา:')
        .replaceAll('relevance:', 'ความเกี่ยวข้อง:')
        .replaceAll('Relevance:', 'ความเกี่ยวข้อง:');
  }

  Map<String, dynamic> toMap() {
    return {
      'situation': situation,
      'timestamp': timestamp,
      'selected_model': selectedModel,
      'analysis_result': analysisResult,
      'prompt_tokens': promptTokens,
      'candidate_tokens': candidateTokens,
      'total_tokens': totalTokens,
    };
  }

  factory HistoryRecord.fromMap(int id, Map<dynamic, dynamic> map) {
    return HistoryRecord(
      id: id,
      situation: map['situation'] as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '',
      selectedModel: map['selected_model'] as String? ?? 'gemini-3.5-flash',
      analysisResult: map['analysis_result'] as String? ?? '',
      promptTokens: map['prompt_tokens'] as int? ?? 0,
      candidateTokens: map['candidate_tokens'] as int? ?? 0,
      totalTokens: map['total_tokens'] as int? ?? 0,
    );
  }
}
