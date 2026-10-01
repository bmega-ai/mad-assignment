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
import '../widgets/learnova_logo.dart';

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
              leading: const Padding(
                padding: EdgeInsets.all(8.0),
                child: LearnovaLogo(size: 38, borderRadius: 10, showShadow: false),
              ),
              title: const Text('Learnova Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      tooltip: 'Notifications',
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
            )
          : null,
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Timetable',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library_rounded),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _unreadNotificationsCount > 0,
              label: Text('$_unreadNotificationsCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: _unreadNotificationsCount > 0,
              label: Text('$_unreadNotificationsCount'),
              child: const Icon(Icons.notifications_active_rounded),
            ),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

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
                                'Good Day, $_studentName 👋',
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
                                _departmentInfo,
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
            const SizedBox(height: 16),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Attendance',
                    '$_attendancePercentage%',
                    Icons.verified_user_rounded,
                    _attendancePercentage >= 85 ? Colors.green : Colors.orange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    'Pending Tasks',
                    '$_pendingAssignmentsCount',
                    Icons.pending_actions_rounded,
                    Colors.orange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    'Events',
                    '$_upcomingEventsCount',
                    Icons.celebration_rounded,
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
                Text(
                  "Today's Schedule",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _currentIndex = 1);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_todayClasses.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No classes remaining for today. Great job!',
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary, size: 20),
                      ),
                      title: Text(
                        c['subject'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor),
                      ),
                      subtitle: Text(
                        '${c['start_time']} - ${c['end_time']} • Room ${c['room']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    ),
                  )),

            const SizedBox(height: 20),

            // Services & Features Grid
            Text(
              'Campus Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.02,
              children: [
                _buildServiceCard('Timetable', Icons.calendar_month_rounded, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen()));
                }),
                _buildServiceCard('Attendance', Icons.how_to_reg_rounded, Colors.green, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
                }),
                _buildServiceCard('Assignments', Icons.task_alt_rounded, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen()));
                }),
                _buildServiceCard('Study Notes', Icons.menu_book_rounded, Colors.teal, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
                }),
                _buildServiceCard('Events', Icons.celebration_rounded, Colors.purple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
                }),
                _buildServiceCard('Faculty', Icons.badge_rounded, Colors.indigo, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FacultyDirectoryScreen()));
                }),
                _buildServiceCard('Notifications', Icons.notifications_active_rounded, Colors.deepOrange, () {
                  setState(() => _currentIndex = 3);
                }),
                _buildServiceCard('OCR / Uploads', Icons.document_scanner_rounded, Colors.cyan, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen()));
                }),
                _buildServiceCard('My Profile', Icons.account_circle_rounded, Colors.blueGrey, () {
                  setState(() => _currentIndex = 4);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
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
