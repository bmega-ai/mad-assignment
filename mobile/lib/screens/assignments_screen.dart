import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/assignment.dart';
import 'assignment_detail_screen.dart';
import 'teacher_assignment_detail_screen.dart';
import 'create_assignment_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  bool _isLoading = true;
  List<AssignmentItem> _assignments = [];
  String _filter = 'All'; // For student: All, Pending, Submitted. For teacher: All, Active, Past Due
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get(ApiConstants.assignments);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _assignments = data.map((e) => AssignmentItem.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load assignments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  List<AssignmentItem> _getFilteredAssignments(bool isTeacher) {
    if (!isTeacher) {
      if (_filter == 'Pending') {
        return _assignments.where((a) => !a.isSubmitted).toList();
      } else if (_filter == 'Submitted') {
        return _assignments.where((a) => a.isSubmitted).toList();
      }
      return _assignments;
    } else {
      if (_filter == 'Active') {
        final now = DateTime.now();
        return _assignments.where((a) {
          try {
            final dt = DateTime.parse(a.dueDate);
            return dt.isAfter(now);
          } catch (_) {
            return true;
          }
        }).toList();
      } else if (_filter == 'Past Due') {
        final now = DateTime.now();
        return _assignments.where((a) {
          try {
            final dt = DateTime.parse(a.dueDate);
            return dt.isBefore(now);
          } catch (_) {
            return false;
          }
        }).toList();
      }
      return _assignments;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isTeacher = authProvider.role == 'faculty' || authProvider.role == 'admin';
    final theme = Theme.of(context);
    final filterOptions = isTeacher ? ['All', 'Active', 'Past Due'] : ['All', 'Pending', 'Submitted'];
    final displayedAssignments = _getFilteredAssignments(isTeacher);

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? 'Course Assignments' : 'Assignments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAssignments,
          ),
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Create Assignment',
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAssignmentScreen()),
                );
                if (res == true) _fetchAssignments();
              },
            ),
        ],
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAssignmentScreen()),
                );
                if (res == true) _fetchAssignments();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Assignment'),
            )
          : null,
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface,
            child: Row(
              children: filterOptions.map((filterName) {
                final isSelected = _filter == filterName;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filterName),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _filter = filterName);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Assignments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchAssignments, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : displayedAssignments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  _filter == 'Pending'
                                      ? 'No pending assignments!'
                                      : 'No assignments found',
                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchAssignments,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: displayedAssignments.length,
                              itemBuilder: (context, index) {
                                final item = displayedAssignments[index];
                                final isSub = item.isSubmitted;

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      if (isTeacher) {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TeacherAssignmentDetailScreen(assignment: item),
                                          ),
                                        );
                                      } else {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AssignmentDetailScreen(assignment: item),
                                          ),
                                        );
                                      }
                                      _fetchAssignments();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  item.subjectCode,
                                                  style: TextStyle(
                                                    color: theme.colorScheme.primary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (isTeacher)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF2563EB).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF2563EB)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${item.submissionsCount} Submitted',
                                                        style: const TextStyle(
                                                          color: Color(0xFF2563EB),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isSub
                                                        ? Colors.green.withOpacity(0.15)
                                                        : Colors.orange.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    isSub ? (item.userSubmission?.status ?? 'Submitted') : 'Pending',
                                                    style: TextStyle(
                                                      color: isSub ? Colors.green : Colors.orange,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            item.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.subjectName,
                                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.schedule, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Due: ${item.dueDateFormatted}',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${item.maxMarks} pts',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.primary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (isTeacher) ...[
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary.withOpacity(0.06),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.checklist_rounded, size: 16, color: theme.colorScheme.primary),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'View Student Submissions & Grade',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.primary),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
