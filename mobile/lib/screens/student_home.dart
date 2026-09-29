import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import 'login_screen.dart';
import 'timetable_screen.dart';
import 'attendance_screen.dart';
import 'assignments_screen.dart';
import 'events_screen.dart';
import 'faculty_directory_screen.dart';
import 'notes_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;

  String _studentName = 'Student';
  String _departmentInfo = 'CSE • 4th Year • Section A';
  double _attendancePercentage = 88.5;
  int _pendingAssignmentsCount = 0;
  int _unreadNotificationsCount = 0;
  int _upcomingEventsCount = 0;
  List<dynamic> _todayClasses = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final response = await ApiService.get(ApiConstants.studentDashboard);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final student = data['student'] ?? {};
        final att = data['attendance'] ?? {};

        setState(() {
          _studentName = student['name'] ?? 'Arun Kumar';
          _departmentInfo = '${student['department'] ?? 'CSE'} • Year ${student['year'] ?? 4} • Sec ${student['section'] ?? 'A'}';
          _attendancePercentage = (att['percentage'] as num?)?.toDouble() ?? 88.5;
          _pendingAssignmentsCount = data['pending_assignments_count'] ?? 0;
          _unreadNotificationsCount = data['unread_notifications_count'] ?? 0;
          _upcomingEventsCount = data['upcoming_events_count'] ?? 0;
          _todayClasses = data['today_classes'] ?? [];
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
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // If tabs 1-4 selected, show sub-screens directly
    final List<Widget> pages = [
      _buildDashboardView(theme),
      const TimetableScreen(),
      const EventsScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('Learnova Dashboard'),
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        setState(() => _currentIndex = 3);
                      },
                    ),
                    if (_unreadNotificationsCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_unreadNotificationsCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
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
            )
          : null,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Timetable'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboardView(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Welcome Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: const Icon(Icons.school, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Day, $_studentName 👋',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _departmentInfo,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Attendance',
                    '$_attendancePercentage%',
                    Icons.check_circle_outline,
                    _attendancePercentage >= 85 ? Colors.green : Colors.orange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Pending Tasks',
                    '$_pendingAssignmentsCount',
                    Icons.assignment_outlined,
                    Colors.orange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Events',
                    '$_upcomingEventsCount',
                    Icons.event_available_outlined,
                    Colors.purple,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Today's Schedule Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Schedule",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _currentIndex = 1);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_todayClasses.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('No classes remaining for today. Great job!', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              )
            else
              ..._todayClasses.take(2).map((c) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.class_, color: theme.colorScheme.primary, size: 20),
                      ),
                      title: Text(c['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${c['start_time']} - ${c['end_time']} • Room ${c['room']}'),
                    ),
                  )),

            const SizedBox(height: 20),

            // Services & Features Grid
            const Text(
              'Campus Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: [
                _buildServiceCard('Timetable', Icons.calendar_today, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen()));
                }),
                _buildServiceCard('Attendance', Icons.fact_check, Colors.green, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
                }),
                _buildServiceCard('Assignments', Icons.assignment, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen()));
                }),
                _buildServiceCard('Study Notes', Icons.menu_book, Colors.teal, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
                }),
                _buildServiceCard('Events', Icons.event_available, Colors.purple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
                }),
                _buildServiceCard('Faculty', Icons.people_alt, Colors.indigo, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FacultyDirectoryScreen()));
                }),
              ],
            ),
          ],
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
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
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
