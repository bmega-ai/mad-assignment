class FacultyItem {
  final int id;
  final String facultyId;
  final String name;
  final String departmentName;
  final String designation;
  final String office;
  final String? phone;
  final String email;

  FacultyItem({
    required this.id,
    required this.facultyId,
    required this.name,
    required this.departmentName,
    required this.designation,
    required this.office,
    this.phone,
    required this.email,
  });

  factory FacultyItem.fromJson(Map<String, dynamic> json) {
    return FacultyItem(
      id: json['id'] ?? 0,
      facultyId: json['faculty_id'] ?? '',
      name: json['name'] ?? '',
      departmentName: json['department_name'] ?? 'CSE',
      designation: json['designation'] ?? 'Faculty',
      office: json['office'] ?? '',
      phone: json['phone'],
      email: json['email'] ?? '',
    );
  }
}
