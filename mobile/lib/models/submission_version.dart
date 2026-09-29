class SubmissionVersionItem {
  final int id;
  final int versionNumber;
  final String? fileUrl;
  final String status;
  final String ocrText;
  final String ocrStatus;
  final double ocrConfidence;
  final double similarityPercentage;
  final double originalityPercentage;
  final String decision;
  final String teacherFeedback;
  final String createdAt;

  SubmissionVersionItem({
    required this.id,
    required this.versionNumber,
    this.fileUrl,
    required this.status,
    required this.ocrText,
    required this.ocrStatus,
    required this.ocrConfidence,
    required this.similarityPercentage,
    required this.originalityPercentage,
    required this.decision,
    required this.teacherFeedback,
    required this.createdAt,
  });

  factory SubmissionVersionItem.fromJson(Map<String, dynamic> json) {
    return SubmissionVersionItem(
      id: json['id'] ?? 0,
      versionNumber: json['version_number'] ?? 1,
      fileUrl: json['file_url'],
      status: json['status'] ?? 'SUBMITTED',
      ocrText: json['ocr_text'] ?? '',
      ocrStatus: json['ocr_status'] ?? 'COMPLETED',
      ocrConfidence: (json['ocr_confidence'] as num?)?.toDouble() ?? 0.0,
      similarityPercentage: (json['similarity_percentage'] as num?)?.toDouble() ?? 0.0,
      originalityPercentage: (json['originality_percentage'] as num?)?.toDouble() ?? 100.0,
      decision: json['decision'] ?? '',
      teacherFeedback: json['teacher_feedback'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
