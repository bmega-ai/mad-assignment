class SubjectAttendance {
  final int subjectId;
  final String subjectName;
  final String subjectCode;
  final int totalClasses;
  final int attendedClasses;
  final double percentage;

  SubjectAttendance({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.totalClasses,
    required this.attendedClasses,
    required this.percentage,
  });

  factory SubjectAttendance.fromJson(Map<String, dynamic> json) {
    return SubjectAttendance(
      subjectId: json['subject_id'] ?? 0,
      subjectName: json['subject_name'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      totalClasses: json['total_classes'] ?? 0,
      attendedClasses: json['attended_classes'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AttendanceRecord {
  final int id;
  final String subjectName;
  final String subjectCode;
  final String date;
  final bool status;

  AttendanceRecord({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.date,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      subjectName: json['subject_name'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? false,
    );
  }
}

class AttendanceData {
  final double overallPercentage;
  final int totalClasses;
  final int attendedClasses;
  final int missedClasses;
  final List<SubjectAttendance> subjectSummary;
  final List<AttendanceRecord> recentRecords;

  AttendanceData({
    required this.overallPercentage,
    required this.totalClasses,
    required this.attendedClasses,
    required this.missedClasses,
    required this.subjectSummary,
    required this.recentRecords,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    return AttendanceData(
      overallPercentage: (json['overall_percentage'] as num?)?.toDouble() ?? 0.0,
      totalClasses: json['total_classes'] ?? 0,
      attendedClasses: json['attended_classes'] ?? 0,
      missedClasses: json['missed_classes'] ?? 0,
      subjectSummary: (json['subject_summary'] as List? ?? [])
          .map((e) => SubjectAttendance.fromJson(e))
          .toList(),
      recentRecords: (json['recent_records'] as List? ?? [])
          .map((e) => AttendanceRecord.fromJson(e))
          .toList(),
    );
  }
}
