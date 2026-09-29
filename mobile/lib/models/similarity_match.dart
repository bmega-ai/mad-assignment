class SimilarityMatchItem {
  final int id;
  final String sourceStudentName;
  final String matchedStudentName;
  final double similarityPercentage;
  final String matchingText;

  SimilarityMatchItem({
    required this.id,
    required this.sourceStudentName,
    required this.matchedStudentName,
    required this.similarityPercentage,
    required this.matchingText,
  });

  factory SimilarityMatchItem.fromJson(Map<String, dynamic> json) {
    return SimilarityMatchItem(
      id: json['id'] ?? 0,
      sourceStudentName: json['source_student_name'] ?? '',
      matchedStudentName: json['matched_student_name'] ?? 'Other Student',
      similarityPercentage: (json['similarity_percentage'] as num?)?.toDouble() ?? 0.0,
      matchingText: json['matching_text'] ?? '',
    );
  }
}
