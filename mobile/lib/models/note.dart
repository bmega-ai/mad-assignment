class NoteItem {
  final int id;
  final String title;
  final String subjectName;
  final String subjectCode;
  final String facultyName;
  final String? fileUrl;
  final String uploadDateFormatted;

  NoteItem({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.subjectCode,
    required this.facultyName,
    this.fileUrl,
    required this.uploadDateFormatted,
  });

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      subjectName: json['subject_name'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      facultyName: json['faculty_name'] ?? 'Faculty',
      fileUrl: json['file_url'],
      uploadDateFormatted: json['upload_date_formatted'] ?? json['upload_date'] ?? '',
    );
  }
}
