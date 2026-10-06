import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/assignment.dart';
import '../models/submission_version.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final AssignmentItem assignment;

  const AssignmentDetailScreen({Key? key, required this.assignment}) : super(key: key);

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  late AssignmentItem _assignment;
  final TextEditingController _textController = TextEditingController();
  List<File> _selectedPages = [];
  File? _primaryDoc;
  bool _isSubmitting = false;
  List<SubmissionVersionItem> _versionHistory = [];
  Map<String, dynamic>? _liveSubmission;

  @override
  void initState() {
    super.initState();
    _assignment = widget.assignment;
    _fetchLatestSubmissionDetails();
  }

  Future<void> _fetchLatestSubmissionDetails() async {
    final sub = _assignment.userSubmission;
    if (sub == null) return;

    try {
      final statusUrl = ApiConstants.getSubmissionStatusUrl(sub.id);
      final statusRes = await ApiService.get(statusUrl);
      if (statusRes.statusCode == 200) {
        setState(() {
          _liveSubmission = jsonDecode(statusRes.body);
        });
      }

      final verUrl = ApiConstants.getSubmissionVersionsUrl(sub.id);
      final verRes = await ApiService.get(verUrl);
      if (verRes.statusCode == 200) {
        final List vList = jsonDecode(verRes.body);
        setState(() {
          _versionHistory = vList.map((e) => SubmissionVersionItem.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // Ignored
    }
  }

  void _showImageQualityTips(VoidCallback onContinue) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.tips_and_updates, color: Colors.amber),
            SizedBox(width: 8),
            Text('Handwritten Scan Tips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('For the best OCR recognition results:', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            _TipRow(icon: Icons.wb_sunny_outlined, text: 'Take clear, well-lit photographs.'),
            _TipRow(icon: Icons.crop_free, text: 'Keep the page flat and avoid shadows.'),
            _TipRow(icon: Icons.edit_note, text: 'Ensure handwriting is clearly legible.'),
            _TipRow(icon: Icons.library_books_outlined, text: 'Upload all pages in sequential order.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onContinue();
            },
            child: const Text('Got it, Choose Pages'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMultiPages() async {
    _showImageQualityTips(() async {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedPages = pickedFiles.map((x) => File(x.path)).toList();
          _primaryDoc = null;
        });
      }
    });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'py', 'java'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _primaryDoc = File(result.files.single.path!);
        _selectedPages.clear();
      });
    }
  }

  Future<void> _submitAssignment({bool isResubmit = false}) async {
    if (_primaryDoc == null && _selectedPages.isEmpty && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select handwritten pages, a PDF, or enter text.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _showProcessingProgressDialog();

    try {
      final endpoint = isResubmit
          ? ApiConstants.getSubmissionResubmitUrl(_assignment.userSubmission!.id)
          : ApiConstants.getAssignmentSubmitUrl(_assignment.id);

      File? mainFile = _primaryDoc ?? (_selectedPages.isNotEmpty ? _selectedPages.first : null);

      final response = await ApiService.uploadMultipart(
        endpoint,
        file: mainFile,
        fields: {
          'text': _textController.text.trim(),
        },
      );

      // Dismiss dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final simObj = data['similarity'] ?? data['similarity_report'] ?? {};

        final newSubmission = UserSubmission(
          id: data['id'] ?? 0,
          status: data['status'] ?? 'SUBMITTED',
          submittedAt: 'Just now',
          marksObtained: data['marks_obtained'],
          fileUrl: data['file_url'],
          similarityPercentage: (simObj['similarity_percentage'] as num?)?.toDouble() ?? 0.0,
          originalityPercentage: (simObj['originality_percentage'] as num?)?.toDouble() ?? 100.0,
        );

        setState(() {
          _assignment = AssignmentItem(
            id: _assignment.id,
            title: _assignment.title,
            description: _assignment.description,
            subjectName: _assignment.subjectName,
            subjectCode: _assignment.subjectCode,
            facultyName: _assignment.facultyName,
            dueDate: _assignment.dueDate,
            dueDateFormatted: _assignment.dueDateFormatted,
            maxMarks: _assignment.maxMarks,
            attachmentUrl: _assignment.attachmentUrl,
            userSubmission: newSubmission,
          );
          _selectedPages.clear();
          _primaryDoc = null;
        });

        _fetchLatestSubmissionDetails();

        if (mounted) {
          final isHigh = newSubmission.similarityPercentage > 70.0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isHigh
                    ? 'OCR & Similarity Complete: High similarity detected (${newSubmission.similarityPercentage}%).'
                    : 'Assignment analyzed successfully! Similarity: ${newSubmission.similarityPercentage}%.',
              ),
              backgroundColor: isHigh ? Colors.orange.shade800 : Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission failed: ${response.body}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showProcessingProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                  SizedBox(width: 14),
                  Text('Analyzing Assignment...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              _buildProgressStep('File uploaded securely', true),
              _buildProgressStep('Image preprocessing & noise removal', true),
              _buildProgressStep('OCR: Extracting handwritten text', true),
              _buildProgressStep('TF-IDF Vectorization & normalization', true),
              _buildProgressStep('Multi-student cosine similarity check', true),
              _buildProgressStep('Evaluating 70% threshold & status', true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(String text, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? Colors.green : Colors.grey, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _requestTeacherReview() async {
    final sub = _assignment.userSubmission;
    if (sub == null) return;

    try {
      final url = ApiConstants.getSubmissionReviewRequestUrl(sub.id);
      final res = await ApiService.post(url, {});

      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review request submitted! Your teacher has been notified to review the original document.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        _fetchLatestSubmissionDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${res.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = _assignment.userSubmission;
    final liveSim = (_liveSubmission?['similarity_percentage'] as num?)?.toDouble() ?? sub?.similarityPercentage ?? 0.0;
    final isHighSimilarity = liveSim > 70.0;
    final statusText = _liveSubmission?['status'] ?? sub?.status ?? 'Not Submitted';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Submission'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Summary Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _assignment.subjectCode,
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_assignment.subjectName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(_assignment.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(_assignment.facultyName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const Spacer(),
                        const Icon(Icons.grade_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${_assignment.maxMarks} Marks', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text('Deadline: ${_assignment.dueDateFormatted}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions
            const Text('Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(_assignment.description, style: const TextStyle(fontSize: 14, height: 1.4)),
              ),
            ),
            const SizedBox(height: 16),

            // ============================================
            // HIGH SIMILARITY (>70%) SCREEN (Requirement #22)
            // ============================================
            if (sub != null && isHighSimilarity && statusText != 'APPROVED') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade400, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'ASSIGNMENT REVIEW REQUIRED',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your submitted assignment has been flagged for high similarity against other submissions.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),

                    // Metrics
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Similarity Score:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text('$liveSim%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ),
                          if (_liveSubmission?['highest_match_student'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Matched with: ${_liveSubmission!['highest_match_student']}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('System Status:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                child: const Text(
                                  'REJECTED — REWRITE REQUIRED',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_liveSubmission?['teacher_feedback'] != null && _liveSubmission!['teacher_feedback'].toString().isNotEmpty) ...[
                      Text(
                        'Teacher Feedback: "${_liveSubmission!['teacher_feedback']}"',
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.brown),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const Text(
                      'You have two options:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    // Option 1 Button: Request Teacher Review
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: statusText == 'REVIEW_REQUESTED' ? null : _requestTeacherReview,
                      icon: const Icon(Icons.rate_review_outlined),
                      label: Text(
                        statusText == 'REVIEW_REQUESTED' ? 'Review Requested (Pending)' : '1. REQUEST TEACHER REVIEW',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Option 2 Button: Rewrite & Resubmit
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade800,
                        side: BorderSide(color: Colors.red.shade700),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        // Scroll to upload form
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please upload your rewritten assignment below to submit Version 2.')),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('2. REWRITE & RESUBMIT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else if (sub != null && statusText == 'APPROVED') ...[
              // APPROVED CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified, color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Assignment Approved!\nYour submission has been verified and accepted by your faculty.',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ============================================
            // SUBMISSION FORM (Upload or Resubmit)
            // ============================================
            Text(
              sub == null ? 'Upload Assignment' : 'Upload Revised Assignment (New Version)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Button 1: Scan Handwritten Pages
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _pickMultiPages,
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.teal),
                      label: Text(
                        _selectedPages.isEmpty
                            ? '📷 Scan Handwritten Pages (Multi-Page)'
                            : '${_selectedPages.length} Handwritten Page(s) Selected ✓',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Button 2: Upload PDF
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _pickDocument,
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                      label: Text(
                        _primaryDoc == null
                            ? '📄 Upload Document / PDF'
                            : 'Selected: ${_primaryDoc!.path.split(Platform.pathSeparator).last}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Center(child: Text('OR', style: TextStyle(color: Colors.grey))),
                    const SizedBox(height: 12),

                    // Direct Text Area
                    TextField(
                      controller: _textController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type or paste assignment text directly...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : () => _submitAssignment(isResubmit: sub != null),
                      child: Text(
                        sub == null ? 'Submit Assignment for OCR Analysis' : 'Submit Revision (v${(sub.id > 0 ? 2 : 1)})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ============================================
            // SUBMISSION VERSION HISTORY (Requirement #28)
            // ============================================
            if (_versionHistory.isNotEmpty) ...[
              const Text('Submission Version History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._versionHistory.map((ver) {
                final isVerHigh = ver.similarityPercentage > 70.0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Version ${ver.versionNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(ver.status, style: TextStyle(color: isVerHigh ? Colors.red : Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                            if (ver.teacherFeedback.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Feedback: ${ver.teacherFeedback}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isVerHigh ? Colors.red : Colors.green).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${ver.similarityPercentage}% Similar',
                            style: TextStyle(color: isVerHigh ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({Key? key, required this.icon, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
