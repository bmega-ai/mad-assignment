import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Selected subject and date
  List<Map<String, dynamic>> _subjects = [];
  Map<String, dynamic>? _selectedSubject;
  DateTime _selectedDate = DateTime.now();

  // Tab 1: Mark Attendance State
  bool _isLoadingStudents = false;
  List<Map<String, dynamic>> _students = [];
  bool _alreadyMarked = false;
  bool _isSavingAttendance = false;

  // Tab 2: Attendance History State
  bool _isLoadingHistory = false;
  List<Map<String, dynamic>> _historyRecords = [];
  String _historySearchQuery = '';
  DateTime? _historyFilterDate;
  int _historyTotal = 0;
  int _historyPresent = 0;
  int _historyAbsent = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _historyRecords.isEmpty && !_isLoadingHistory) {
        _fetchAttendanceHistory();
      }
    });
    _fetchSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Fetch Teacher's Subjects ---
  Future<void> _fetchSubjects() async {
    try {
      final res = await ApiService.get(ApiConstants.subjects);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(data);
          if (_subjects.isNotEmpty) {
            _selectedSubject = _subjects.first;
          }
        });
        if (_selectedSubject != null) {
          _fetchStudentsForAttendance();
        }
      }
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
    }
  }

  // --- Tab 1: Fetch Students for Selected Subject & Date ---
  Future<void> _fetchStudentsForAttendance() async {
    if (_selectedSubject == null) return;
    setState(() {
      _isLoadingStudents = true;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final subjectId = _selectedSubject!['id'].toString();

    try {
      final res = await ApiService.get(
        ApiConstants.attendanceStudents,
        queryParams: {'subject_id': subjectId, 'date': dateStr},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List list = data['students'] ?? [];
        setState(() {
          _students = List<Map<String, dynamic>>.from(list);
          _alreadyMarked = data['already_marked'] ?? false;
          _isLoadingStudents = false;
        });
      } else {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  // --- Tab 1: Save / Submit Attendance ---
  Future<void> _saveAttendance() async {
    if (_selectedSubject == null || _students.isEmpty) return;

    setState(() {
      _isSavingAttendance = true;
    });

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final records = _students.map((s) {
      return {
        'student_id': s['id'],
        'status': s['status'] ?? true,
      };
    }).toList();

    try {
      final res = await ApiService.post(
        ApiConstants.attendance,
        {
          'subject_id': _selectedSubject!['id'],
          'date': dateStr,
          'records': records,
        },
      );

      setState(() {
        _isSavingAttendance = false;
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _alreadyMarked = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('Attendance saved for ${_students.length} students!'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        _fetchAttendanceHistory();
      } else {
        final err = jsonDecode(res.body)['error'] ?? 'Failed to save attendance';
        _showErrorSnackBar(err.toString());
      }
    } catch (e) {
      setState(() {
        _isSavingAttendance = false;
      });
      _showErrorSnackBar('Network error: $e');
    }
  }

  // --- Tab 2: Fetch Attendance History ---
  Future<void> _fetchAttendanceHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    final Map<String, String> params = {};
    if (_selectedSubject != null) {
      params['subject_id'] = _selectedSubject!['id'].toString();
    }
    if (_historyFilterDate != null) {
      params['date'] = DateFormat('yyyy-MM-dd').format(_historyFilterDate!);
    }

    try {
      final res = await ApiService.get(ApiConstants.attendance, queryParams: params);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List list = data['records'] ?? [];
        setState(() {
          _historyRecords = List<Map<String, dynamic>>.from(list);
          _historyTotal = data['total_records'] ?? _historyRecords.length;
          _historyPresent = data['present_count'] ?? 0;
          _historyAbsent = data['absent_count'] ?? 0;
          _isLoadingHistory = false;
        });
      } else {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  // --- Tab 2: Toggle Attendance Status in History ---
  Future<void> _toggleHistoryStatus(int index) async {
    final record = _historyRecords[index];
    final recordId = record['id'];
    final currentStatus = record['status'] as bool;
    final newStatus = !currentStatus;

    setState(() {
      _historyRecords[index]['status'] = newStatus;
      if (newStatus) {
        _historyPresent++;
        _historyAbsent = (_historyAbsent - 1).clamp(0, 9999);
      } else {
        _historyAbsent++;
        _historyPresent = (_historyPresent - 1).clamp(0, 9999);
      }
    });

    try {
      final res = await ApiService.patch(
        ApiConstants.getAttendanceDetailUrl(recordId),
        {'status': newStatus},
      );

      if (res.statusCode == 200) {
        if (mounted) {
          final studentName = record['student_name'] ?? 'Student';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Updated $studentName to ${newStatus ? "Present" : "Absent"}',
              ),
              backgroundColor: newStatus ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        setState(() {
          _historyRecords[index]['status'] = currentStatus;
        });
        _showErrorSnackBar('Failed to update status on server.');
      }
    } catch (e) {
      setState(() {
        _historyRecords[index]['status'] = currentStatus;
      });
      _showErrorSnackBar('Network error: $e');
    }
  }

  // --- Tab 2: Delete Attendance Record ---
  Future<void> _deleteHistoryRecord(int index) async {
    final record = _historyRecords[index];
    final recordId = record['id'];
    final studentName = record['student_name'] ?? 'Student';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Attendance Record'),
        content: Text('Remove attendance record for $studentName on ${record['date']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.delete(ApiConstants.getAttendanceDetailUrl(recordId));
      if (res.statusCode == 200) {
        setState(() {
          _historyRecords.removeAt(index);
          _historyTotal = (_historyTotal - 1).clamp(0, 9999);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance record deleted for $studentName.'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        _showErrorSnackBar('Failed to delete record.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _markAll(bool status) {
    setState(() {
      for (var s in _students) {
        s['status'] = status;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchStudentsForAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Attendance Manager',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.playlist_add_check_rounded),
              text: 'Mark Attendance',
            ),
            Tab(
              icon: Icon(Icons.history_rounded),
              text: 'History & Update',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTopFilterHeader(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMarkAttendanceTab(isDark),
                _buildHistoryTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilterHeader(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  value: _selectedSubject,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF2563EB)),
                  items: _subjects.map((s) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: s,
                      child: Text(
                        '${s["code"]} - ${s["name"]}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newSub) {
                    if (newSub != null) {
                      setState(() {
                        _selectedSubject = newSub;
                      });
                      _fetchStudentsForAttendance();
                      if (_tabController.index == 1) {
                        _fetchAttendanceHistory();
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkAttendanceTab(bool isDark) {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedSubject == null) {
      return const Center(child: Text('Please select a subject above.'));
    }

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No enrolled students found for this class.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchStudentsForAttendance,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
          ],
        ),
      );
    }

    final presentCount = _students.where((s) => s['status'] == true).length;
    final absentCount = _students.length - presentCount;
    final attendancePct = _students.isNotEmpty
        ? (presentCount / _students.length * 100).toStringAsFixed(1)
        : '0.0';

    return RefreshIndicator(
      onRefresh: _fetchStudentsForAttendance,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              children: [
                if (_alreadyMarked)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: const Text(
                            'Attendance recorded for this date. Modifying will update records.',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatPill('Total', '${_students.length}', const Color(0xFF3B82F6), isDark),
                    _buildStatPill('Present', '$presentCount', const Color(0xFF10B981), isDark),
                    _buildStatPill('Absent', '$absentCount', const Color(0xFFEF4444), isDark),
                    _buildStatPill('Rate', '$attendancePct%', const Color(0xFF8B5CF6), isDark),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _markAll(true),
                        icon: const Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF10B981)),
                        label: const Text(
                          'Mark All Present',
                          style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF10B981)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _markAll(false),
                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                        label: const Text(
                          'Mark All Absent',
                          style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final isPresent = student['status'] == true;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isPresent
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : const Color(0xFFEF4444).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isPresent
                          ? const Color(0xFF10B981).withOpacity(0.04)
                          : const Color(0xFFEF4444).withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              child: Text(
                                (student['name'] ?? 'S')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: student['is_online'] == true
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['name'] ?? 'Student Name',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      student['student_id'] ?? '',
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sec: ${student["section"] ?? "A"} • Yr: ${student["year"] ?? "4"}',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: (student['is_online'] == true
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444))
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: student['is_online'] == true
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          student['is_online'] == true ? 'Online' : 'Offline',
                                          style: TextStyle(
                                            color: student['is_online'] == true
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _students[index]['status'] = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPresent ? const Color(0xFF10B981) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isPresent ? const Color(0xFF10B981) : Colors.grey.shade400,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: isPresent ? Colors.white : Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'P',
                                      style: TextStyle(
                                        color: isPresent ? Colors.white : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _students[index]['status'] = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: !isPresent ? const Color(0xFFEF4444) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: !isPresent ? const Color(0xFFEF4444) : Colors.grey.shade400,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.cancel_rounded,
                                      size: 14,
                                      color: !isPresent ? Colors.white : Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'A',
                                      style: TextStyle(
                                        color: !isPresent ? Colors.white : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSavingAttendance ? null : _saveAttendance,
                icon: _isSavingAttendance
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _isSavingAttendance
                      ? 'Saving Attendance...'
                      : _alreadyMarked
                          ? 'Update Attendance (${_students.length} Students)'
                          : 'Submit Attendance (${_students.length} Students)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _historyRecords.where((r) {
      if (_historySearchQuery.isEmpty) return true;
      final q = _historySearchQuery.toLowerCase();
      final name = (r['student_name'] ?? '').toString().toLowerCase();
      final id = (r['student_id'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchAttendanceHistory,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _historySearchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by student name or roll number...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('All Dates', style: TextStyle(fontSize: 12)),
                      selected: _historyFilterDate == null,
                      onSelected: (selected) {
                        setState(() {
                          _historyFilterDate = null;
                        });
                        _fetchAttendanceHistory();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(
                        _historyFilterDate == null
                            ? 'Pick Date'
                            : DateFormat('dd MMM yyyy').format(_historyFilterDate!),
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _historyFilterDate != null,
                      onSelected: (selected) async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _historyFilterDate ?? DateTime.now(),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _historyFilterDate = picked;
                          });
                          _fetchAttendanceHistory();
                        }
                      },
                    ),
                    const Spacer(),
                    Text(
                      '${filtered.length} records',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          'No attendance history found.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _fetchAttendanceHistory,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh History'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final rec = filtered[index];
                      final isPresent = rec['status'] == true;

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isPresent
                                ? const Color(0xFF10B981).withOpacity(0.3)
                                : const Color(0xFFEF4444).withOpacity(0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          rec['student_name'] ?? 'Student',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2563EB).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            rec['student_id'] ?? '',
                                            style: const TextStyle(
                                              color: Color(0xFF2563EB),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${rec["subject_code"]} • Date: ${rec["date"]}',
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final mainIndex = _historyRecords.indexOf(rec);
                                  if (mainIndex != -1) {
                                    _toggleHistoryStatus(mainIndex);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPresent
                                      ? const Color(0xFF10B981).withOpacity(0.12)
                                      : const Color(0xFFEF4444).withOpacity(0.12),
                                  foregroundColor: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isPresent ? 'Present' : 'Absent',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.sync_alt_rounded, size: 12),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                tooltip: 'Delete record',
                                onPressed: () {
                                  final mainIndex = _historyRecords.indexOf(rec);
                                  if (mainIndex != -1) {
                                    _deleteHistoryRecord(mainIndex);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
