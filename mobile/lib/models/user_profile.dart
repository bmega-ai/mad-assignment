class UserProfile {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final String? profileImage;
  final String? studentId;
  final String? facultyId;
  final String? department;
  final int? year;
  final String? section;
  final int? semester;
  final String? designation;
  final String? office;
  final String? phone;

  UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.profileImage,
    this.studentId,
    this.facultyId,
    this.department,
    this.year,
    this.section,
    this.semester,
    this.designation,
    this.office,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? (json['username'] ?? ''),
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      profileImage: json['profile_image'],
      studentId: json['student_id'],
      facultyId: json['faculty_id'],
      department: json['department'],
      year: json['year'],
      section: json['section'],
      semester: json['semester'],
      designation: json['designation'],
      office: json['office'],
      phone: json['phone'],
    );
  }
}
