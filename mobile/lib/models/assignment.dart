class UserSubmission {
  final int id;
  final String status;
  final String submittedAt;
  final int? marksObtained;
  final String? fileUrl;
  final double similarityPercentage;
  final double originalityPercentage;

  UserSubmission({
    required this.id,
    required this.status,
    required this.submittedAt,
    this.marksObtained,
    this.fileUrl,
    required this.similarityPercentage,
    required this.originalityPercentage,
  });

  factory UserSubmission.fromJson(Map<String, dynamic> json) {
    return UserSubmission(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'Submitted',
      submittedAt: json['submitted_at'] ?? '',
      marksObtained: json['marks_obtained'],
      fileUrl: json['file_url'],
      similarityPercentage: (json['similarity_percentage'] as num?)?.toDouble() ?? 0.0,
      originalityPercentage: (json['originality_percentage'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class AssignmentItem {
  final int id;
  final String title;
  final String description;
  final String subjectName;
  final String subjectCode;
  final String facultyName;
  final String dueDateFormatted;
  final int maxMarks;
  final String? attachmentUrl;
  final UserSubmission? userSubmission;

  AssignmentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectName,
    required this.subjectCode,
    required this.facultyName,
    required this.dueDateFormatted,
    required this.maxMarks,
    this.attachmentUrl,
    this.userSubmission,
  });

  bool get isSubmitted => userSubmission != null;

  factory AssignmentItem.fromJson(Map<String, dynamic> json) {
    return AssignmentItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subjectName: json['subject_name'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      facultyName: json['faculty_name'] ?? 'Faculty',
      dueDateFormatted: json['due_date_formatted'] ?? json['due_date'] ?? '',
      maxMarks: json['max_marks'] ?? 100,
      attachmentUrl: json['attachment_url'],
      userSubmission: json['user_submission'] != null
          ? UserSubmission.fromJson(json['user_submission'])
          : null,
    );
  }
}
