class HistoryRecord {
  final int? id;
  final String situation;
  final String timestamp;
  final String selectedModel;
  final String analysisResult;

  HistoryRecord({
    this.id,
    required this.situation,
    required this.timestamp,
    required this.selectedModel,
    required this.analysisResult,
  });

  Map<String, dynamic> toMap() {
    return {
      'situation': situation,
      'timestamp': timestamp,
      'selected_model': selectedModel,
      'analysis_result': analysisResult,
    };
  }

  factory HistoryRecord.fromMap(int id, Map<dynamic, dynamic> map) {
    return HistoryRecord(
      id: id,
      situation: map['situation'] as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '',
      selectedModel: map['selected_model'] as String? ?? 'gemini-3.5-flash',
      analysisResult: map['analysis_result'] as String? ?? '',
    );
  }
}
