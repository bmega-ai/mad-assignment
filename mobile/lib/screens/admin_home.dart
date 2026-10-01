import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'events_screen.dart';
import 'faculty_directory_screen.dart';
import 'assignments_screen.dart';
import 'timetable_screen.dart';
import 'notes_screen.dart';
import 'notifications_screen.dart';
import '../widgets/learnova_logo.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: LearnovaLogo(size: 38, borderRadius: 10, showShadow: false),
        ),
        title: const Text('Admin Console • Learnova', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Banner
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade800, Colors.deepPurple.shade700],
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
                        children: const [
                          SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Campus Administration',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'System Administrator • Master Controls',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                                maxLines: 1,
                                softWrap: false,
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
            const SizedBox(height: 24),

            const Text('Administrative Modules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.1,
              children: [
                _buildCard(
                  context,
                  'Campus Events',
                  Icons.celebration_rounded,
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
                ),
                _buildCard(
                  context,
                  'Faculty Directory',
                  Icons.badge_rounded,
                  Colors.indigo,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FacultyDirectoryScreen())),
                ),
                _buildCard(
                  context,
                  'Assignments',
                  Icons.task_alt_rounded,
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentsScreen())),
                ),
                _buildCard(
                  context,
                  'Master Timetable',
                  Icons.calendar_month_rounded,
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen())),
                ),
                _buildCard(
                  context,
                  'Broadcast Circulars',
                  Icons.campaign_rounded,
                  Colors.redAccent,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
                _buildCard(
                  context,
                  'Study Notes Library',
                  Icons.menu_book_rounded,
                  Colors.teal,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
