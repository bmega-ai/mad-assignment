class TeacherReviewItem {
  final int id;
  final int student;
  final String studentId;
  final String studentName;
  final int assignment;
  final String assignmentTitle;
  final int submission;
  final double similarityScore;
  final String matchedStudent;
  final String requestStatus;
  final String? teacherFeedback;
  final String createdAt;

  TeacherReviewItem({
    required this.id,
    required this.student,
    required this.studentId,
    required this.studentName,
    required this.assignment,
    required this.assignmentTitle,
    required this.submission,
    required this.similarityScore,
    required this.matchedStudent,
    required this.requestStatus,
    this.teacherFeedback,
    required this.createdAt,
  });

  factory TeacherReviewItem.fromJson(Map<String, dynamic> json) {
    return TeacherReviewItem(
      id: json['id'] ?? 0,
      student: json['student'] ?? 0,
      studentId: json['student_id'] ?? '',
      studentName: json['student_name'] ?? 'Student',
      assignment: json['assignment'] ?? 0,
      assignmentTitle: json['assignment_title'] ?? 'Assignment',
      submission: json['submission'] ?? 0,
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      matchedStudent: json['matched_student'] ?? '',
      requestStatus: json['request_status'] ?? 'PENDING',
      teacherFeedback: json['teacher_feedback'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
