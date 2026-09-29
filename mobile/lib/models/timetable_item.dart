class TimetableItem {
  final int id;
  final String day;
  final String startTime;
  final String endTime;
  final String subjectName;
  final String subjectCode;
  final String facultyName;
  final String room;

  TimetableItem({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subjectName,
    required this.subjectCode,
    required this.facultyName,
    required this.room,
  });

  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    return TimetableItem(
      id: json['id'] ?? 0,
      day: json['day'] ?? '',
      startTime: json['start_time_formatted'] ?? json['start_time'] ?? '',
      endTime: json['end_time_formatted'] ?? json['end_time'] ?? '',
      subjectName: json['subject_name'] ?? json['subject']?.toString() ?? '',
      subjectCode: json['subject_code'] ?? '',
      facultyName: json['faculty_name'] ?? 'Faculty',
      room: json['room'] ?? '',
    );
  }
}
