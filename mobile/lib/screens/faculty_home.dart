import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import 'login_screen.dart';
import 'teacher_review_requests_screen.dart';
import 'create_assignment_screen.dart';
import 'attendance_screen.dart';
import 'notes_screen.dart';
import 'events_screen.dart';
import 'notifications_screen.dart';
import 'assignments_screen.dart';
import 'timetable_screen.dart';
import '../widgets/learnova_logo.dart';

class FacultyHomeScreen extends StatefulWidget {
  const FacultyHomeScreen({Key? key}) : super(key: key);

  @override
  State<FacultyHomeScreen> createState() => _FacultyHomeScreenState();
}

class _FacultyHomeScreenState extends State<FacultyHomeScreen> {
  bool _isLoading = true;
  String _teacherName = 'Dr. Ramesh Sharma';
  String _designation = 'Professor & HOD';
  String _department = 'Computer Science & Engineering';
  int _assignmentsCount = 18;
  int _submissionsCount = 84;
  int _toReviewCount = 12;
  int _classesCount = 5;
  List<dynamic> _recentSubmissions = [];

  @override
  void initState() {
    super.initState();
    _fetchTeacherDashboard();
  }

  Future<void> _fetchTeacherDashboard() async {
    try {
      final response = await ApiService.get(ApiConstants.teacherDashboard);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final t = data['teacher'] ?? {};
        setState(() {
          _teacherName = t['name'] ?? 'Dr. Ramesh Sharma';
          _designation = t['designation'] ?? 'Professor & HOD';
          _department = t['department'] ?? 'Computer Science & Engineering';
          _assignmentsCount = data['assignments_count'] ?? 18;
          _submissionsCount = data['submissions_count'] ?? 84;
          _toReviewCount = data['to_review_count'] ?? 12;
          _classesCount = data['classes_count'] ?? 5;
          _recentSubmissions = data['recent_submissions'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade800,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: LearnovaLogo(size: 38, borderRadius: 10, showShadow: false),
        ),
        title: const Text('Teacher Portal • Learnova', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchTeacherDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTeacherDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Teacher Header
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade800, Colors.teal.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const LearnovaLogo(
                        size: 58,
                        borderRadius: 16,
                        showShadow: false,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Good Morning, $_teacherName 👋',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$_designation • $_department',
                                  maxLines: 1,
                                  softWrap: false,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4 Stat Cards: Assignments, Submissions, To Review, Attendance
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Assignments',
                      '$_assignmentsCount',
                      Icons.assignment,
                      Colors.blue,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      'Submissions',
                      '$_submissionsCount',
                      Icons.file_copy_outlined,
                      Colors.purple,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'To Review',
                      '$_toReviewCount',
                      Icons.rate_review_outlined,
                      Colors.orange.shade800,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherReviewRequestsScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      'Attendance',
                      '$_classesCount Classes',
                      Icons.check_circle_outline,
                      Colors.green,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: [
                  _buildServiceCard('Create Assignment', Icons.post_add_rounded, Colors.teal, () async {
                    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAssignmentScreen()));
                    if (res == true) _fetchTeacherDashboard();
                  }),
                  _buildServiceCard('Review Submissions', Icons.rule_folder_rounded, Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherReviewRequestsScreen()));
                  }),
                  _buildServiceCard('Attendance', Icons.how_to_reg_rounded, Colors.green, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
                  }),
                  _buildServiceCard('Circulars', Icons.campaign_rounded, Colors.red, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  }),
                  _buildServiceCard('Notes', Icons.menu_book_rounded, Colors.indigo, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
                  }),
                  _buildServiceCard('Events', Icons.celebration_rounded, Colors.purple, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Submissions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Submissions to Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherReviewRequestsScreen()));
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_recentSubmissions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text('No new submissions pending review.', style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  ),
                )
              else
                ..._recentSubmissions.map((sub) {
                  final sim = (sub['similarity_percentage'] as num?)?.toDouble() ?? 0.0;
                  final isHigh = sim > 70.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherReviewRequestsScreen()));
                      },
                      leading: CircleAvatar(
                        backgroundColor: (isHigh ? Colors.red : Colors.green).withOpacity(0.15),
                        child: Icon(
                          isHigh ? Icons.warning_amber : Icons.check_circle_outline,
                          color: isHigh ? Colors.red : Colors.green,
                        ),
                      ),
                      title: Text(
                        '${sub['student_name']} (${sub['student_id']})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${sub['assignment_title']} • v${sub['version']}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isHigh ? Colors.red : Colors.green).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$sim%',
                          style: TextStyle(
                            color: isHigh ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
