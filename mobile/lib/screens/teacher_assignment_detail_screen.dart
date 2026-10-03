import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/assignment.dart';

class TeacherAssignmentDetailScreen extends StatefulWidget {
  final AssignmentItem assignment;

  const TeacherAssignmentDetailScreen({Key? key, required this.assignment}) : super(key: key);

  @override
  State<TeacherAssignmentDetailScreen> createState() => _TeacherAssignmentDetailScreenState();
}

class _TeacherAssignmentDetailScreenState extends State<TeacherAssignmentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _assignmentData;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _submittedStudents = [];
  List<Map<String, dynamic>> _notSubmittedStudents = [];

  String _submittedSearch = '';
  String _notSubmittedSearch = '';
  bool _isSendingBulkReminder = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRoster();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoster() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.get(ApiConstants.getAssignmentRosterUrl(widget.assignment.id));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _assignmentData = data['assignment'];
          _stats = data['stats'];
          _submittedStudents = List<Map<String, dynamic>>.from(data['submitted'] ?? []);
          _notSubmittedStudents = List<Map<String, dynamic>>.from(data['not_submitted'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load assignment roster';
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

  // --- Grade Submission Dialog ---
  void _openGradeDialog(Map<String, dynamic> item) {
    final marksController = TextEditingController(
      text: item['marks_obtained'] != null ? item['marks_obtained'].toString() : '',
    );
    final feedbackController = TextEditingController(
      text: item['teacher_feedback'] ?? '',
    );
    final maxMarks = item['max_marks'] ?? 100;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Grade Submission - ${item["student_name"]}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Roll: ${item["student_id"]} • Max Marks: $maxMarks',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: marksController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Marks Obtained (out of $maxMarks)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.grade_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Teacher Feedback',
                  hintText: 'Great work! Well explained...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final marksText = marksController.text.trim();
                      if (marksText.isEmpty) return;
                      final marksVal = int.tryParse(marksText);
                      if (marksVal == null || marksVal < 0 || marksVal > maxMarks) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter valid marks between 0 and $maxMarks'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        final res = await ApiService.post(
                          ApiConstants.getGradeSubmissionUrl(item['submission_id']),
                          {
                            'marks': marksVal,
                            'feedback': feedbackController.text.trim(),
                          },
                        );

                        if (res.statusCode == 200) {
                          Navigator.pop(ctx);
                          _fetchRoster();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Graded ${item["student_name"]} successfully!'),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          setDialogState(() => isSaving = false);
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Grade'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Send Reminder ---
  Future<void> _sendReminder({int? studentProfileId, String? studentName}) async {
    try {
      final res = await ApiService.post(
        ApiConstants.getAssignmentRemindUrl(widget.assignment.id),
        studentProfileId != null ? {'student_profile_id': studentProfileId} : {},
      );

      if (res.statusCode == 200) {
        final msg = jsonDecode(res.body)['message'] ?? 'Reminder sent successfully!';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(msg)),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Open File URL ---
  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Assignment Submissions'),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRoster,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              icon: const Icon(Icons.check_circle_outline_rounded),
              text: 'Submitted (${_stats?["submitted_count"] ?? _submittedStudents.length})',
            ),
            Tab(
              icon: const Icon(Icons.pending_actions_rounded),
              text: 'Not Submitted (${_stats?["not_submitted_count"] ?? _notSubmittedStudents.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchRoster, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Assignment Summary Header Card
                    _buildAssignmentHeader(isDark),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSubmittedTab(isDark),
                          _buildNotSubmittedTab(isDark),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // --- Top Assignment Header Card ---
  Widget _buildAssignmentHeader(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final a = _assignmentData ?? {};
    final s = _stats ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Code
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['title'] ?? widget.assignment.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${a["subject_code"] ?? widget.assignment.subjectCode} - ${a["subject_name"] ?? widget.assignment.subjectName}',
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Max: ${a["max_marks"] ?? widget.assignment.maxMarks} pts',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stat Pills Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatPill('Enrolled', '${s["total_enrolled"] ?? 0}', const Color(0xFF3B82F6), isDark),
              _buildStatPill('Submitted', '${s["submitted_count"] ?? 0}', const Color(0xFF10B981), isDark),
              _buildStatPill('Pending', '${s["not_submitted_count"] ?? 0}', const Color(0xFFEF4444), isDark),
              _buildStatPill('Online', '${s["online_count"] ?? 0}', const Color(0xFF10B981), isDark),
              _buildStatPill('Rate', '${s["submission_rate"] ?? 0}%', const Color(0xFF8B5CF6), isDark),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: SUBMITTED STUDENTS
  // =========================================================================
  Widget _buildSubmittedTab(bool isDark) {
    final filtered = _submittedStudents.where((s) {
      if (_submittedSearch.isEmpty) return true;
      final q = _submittedSearch.toLowerCase();
      final name = (s['student_name'] ?? '').toString().toLowerCase();
      final id = (s['student_id'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            onChanged: (v) => setState(() => _submittedSearch = v),
            decoration: InputDecoration(
              hintText: 'Search submitted students...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            ),
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text('No submissions match your search.', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isOnline = item['is_online'] == true;
                    final simPct = (item['similarity_percentage'] as num?)?.toDouble() ?? 0.0;
                    final isHighSim = simPct >= 70.0;
                    final marks = item['marks_obtained'];

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isHighSim ? Colors.red.withOpacity(0.4) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Student Profile Header
                            Row(
                              children: [
                                // Avatar with Online / Offline Dot
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFF2563EB),
                                      child: Text(
                                        (item['student_name'] ?? 'S')[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 11,
                                        height: 11,
                                        decoration: BoxDecoration(
                                          color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
                                const SizedBox(width: 10),

                                // Name and Online Status
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['student_name'] ?? 'Student',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item['student_id'] ?? '',
                                              style: const TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Online / Offline Text badge
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isOnline ? 'Online' : 'Offline',
                                                style: TextStyle(
                                                  color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item['status'] ?? 'Submitted',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),

                            // Submission Details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Submitted: ${item["submitted_at"]}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                // Similarity Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isHighSim
                                        ? const Color(0xFFEF4444).withOpacity(0.12)
                                        : const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isHighSim ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                                        size: 13,
                                        color: isHighSim ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$simPct% Similarity',
                                        style: TextStyle(
                                          color: isHighSim ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Marks Display
                            Row(
                              children: [
                                Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  marks != null
                                      ? 'Marks: $marks / ${item["max_marks"]}'
                                      : 'Not Graded Yet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: marks != null ? const Color(0xFF2563EB) : Colors.grey.shade600,
                                  ),
                                ),
                                if (item['teacher_feedback'] != null && (item['teacher_feedback'] as String).isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '• "${item["teacher_feedback"]}"',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Actions: View File and Grade Button
                            Row(
                              children: [
                                if (item['file_url'] != null)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openFile(item['file_url']),
                                      icon: const Icon(Icons.file_present_rounded, size: 16),
                                      label: const Text('View File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openGradeDialog(item),
                                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                                    label: Text(
                                      marks != null ? 'Update Grade' : 'Grade Student',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      ],
    );
  }

  // =========================================================================
  // TAB 2: NOT SUBMITTED STUDENTS
  // =========================================================================
  Widget _buildNotSubmittedTab(bool isDark) {
    final filtered = _notSubmittedStudents.where((s) {
      if (_notSubmittedSearch.isEmpty) return true;
      final q = _notSubmittedSearch.toLowerCase();
      final name = (s['student_name'] ?? '').toString().toLowerCase();
      final id = (s['student_id'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();

    return Column(
      children: [
        // Top Action & Search Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _notSubmittedSearch = v),
                      decoration: InputDecoration(
                        hintText: 'Search pending students...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSendingBulkReminder
                        ? null
                        : () async {
                            setState(() => _isSendingBulkReminder = true);
                            await _sendReminder();
                            setState(() => _isSendingBulkReminder = false);
                          },
                    icon: _isSendingBulkReminder
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.notifications_active_rounded, size: 16),
                    label: const Text('Remind All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 56, color: const Color(0xFF10B981)),
                      const SizedBox(height: 8),
                      const Text(
                        'All enrolled students have submitted!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isOnline = item['is_online'] == true;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Avatar with Online Dot
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.8),
                                  child: Text(
                                    (item['student_name'] ?? 'S')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 11,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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

                            // Student Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['student_name'] ?? 'Student Name',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item['student_id'] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isOnline ? 'Online' : 'Offline',
                                            style: TextStyle(
                                              color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Send Reminder Button
                            OutlinedButton.icon(
                              onPressed: () => _sendReminder(
                                studentProfileId: item['student_profile_id'],
                                studentName: item['student_name'],
                              ),
                              icon: const Icon(Icons.send_rounded, size: 14, color: Color(0xFFEF4444)),
                              label: const Text(
                                'Remind',
                                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Helper Widget: Stat Pill ---
  Widget _buildStatPill(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
