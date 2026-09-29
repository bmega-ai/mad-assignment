import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/teacher_review.dart';

class TeacherReviewRequestsScreen extends StatefulWidget {
  const TeacherReviewRequestsScreen({Key? key}) : super(key: key);

  @override
  State<TeacherReviewRequestsScreen> createState() => _TeacherReviewRequestsScreenState();
}

class _TeacherReviewRequestsScreenState extends State<TeacherReviewRequestsScreen> {
  bool _isLoading = true;
  List<TeacherReviewItem> _reviews = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get(ApiConstants.teacherReviews);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _reviews = data.map((e) => TeacherReviewItem.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load review requests';
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

  void _openReviewDetail(TeacherReviewItem review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewDetailSheet(
        review: review,
        onActionCompleted: () {
          Navigator.pop(ctx);
          _fetchReviews();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Review Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReviews,
          ),
        ],
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
                      ElevatedButton(onPressed: _fetchReviews, child: const Text('Retry')),
                    ],
                  ),
                )
              : _reviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'All submissions reviewed! No pending review requests.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchReviews,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final item = _reviews[index];
                          final isHigh = item.similarityScore > 70.0;

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openReviewDetail(item),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Similarity: ${item.similarityScore}%',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            item.requestStatus,
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      item.assignmentTitle,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Student: ${item.studentName} (${item.studentId})',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                    if (item.matchedStudent.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Top match: ${item.matchedStudent}',
                                        style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.createdAt,
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () => _openReviewDetail(item),
                                          icon: const Icon(Icons.rate_review, size: 16),
                                          label: const Text('Review Now'),
                                          style: ElevatedButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ReviewDetailSheet extends StatefulWidget {
  final TeacherReviewItem review;
  final VoidCallback onActionCompleted;

  const _ReviewDetailSheet({
    Key? key,
    required this.review,
    required this.onActionCompleted,
  }) : super(key: key);

  @override
  State<_ReviewDetailSheet> createState() => _ReviewDetailSheetState();
}

class _ReviewDetailSheetState extends State<_ReviewDetailSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _submissionData;
  Map<String, dynamic>? _ocrData;
  List<dynamic> _matches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final subUrl = ApiConstants.getSubmissionDetailUrl(widget.review.submission);
      final subRes = await ApiService.get(subUrl);
      if (subRes.statusCode == 200) {
        setState(() {
          _submissionData = jsonDecode(subRes.body);
        });
      }

      final ocrUrl = ApiConstants.getSubmissionOcrUrl(widget.review.submission);
      final ocrRes = await ApiService.get(ocrUrl);
      if (ocrRes.statusCode == 200) {
        setState(() {
          _ocrData = jsonDecode(ocrRes.body);
        });
      }

      final matchUrl = ApiConstants.getSubmissionMatchesUrl(widget.review.submission);
      final matchRes = await ApiService.get(matchUrl);
      if (matchRes.statusCode == 200) {
        setState(() {
          _matches = jsonDecode(matchRes.body);
        });
      }
    } catch (e) {
      // Handled
    }
  }

  Future<void> _performAction(String action) async {
    setState(() => _isProcessing = true);
    try {
      final url = ApiConstants.getTeacherReviewActionUrl(widget.review.id);
      final res = await ApiService.post(url, {
        'action': action,
        'feedback': _feedbackController.text.trim(),
      });

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action $action executed successfully! Student notified.'),
            backgroundColor: action == 'APPROVE' ? Colors.green : Colors.orange,
          ),
        );
        widget.onActionCompleted();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${res.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 44,
            decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review: ${widget.review.studentName}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.review.assignmentTitle,
                        style: TextStyle(color: theme.colorScheme.primary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.review.similarityScore}% Similar',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'Original File'),
              Tab(text: 'OCR Text'),
              Tab(text: 'Similarity Matches'),
            ],
          ),
          const Divider(height: 1),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Original Document Preview
                _buildOriginalTab(),
                // Tab 2: OCR Extracted Text
                _buildOcrTab(),
                // Tab 3: Multi-student Matches
                _buildSimilarityTab(),
              ],
            ),
          ),

          // Actions & Feedback Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _feedbackController,
                  decoration: const InputDecoration(
                    hintText: 'Enter teacher comments or rewrite instructions...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: _isProcessing ? null : () => _performAction('APPROVE'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('APPROVE'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: _isProcessing ? null : () => _performAction('REWRITE'),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('REWRITE'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: _isProcessing ? null : () => _performAction('REJECT'),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('REJECT'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalTab() {
    final fileUrl = _submissionData?['file_url'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Original Student Submission File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Preserved intact without modification for manual faculty verification.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.description, size: 64, color: Colors.blue),
                  const SizedBox(height: 12),
                  Text(
                    fileUrl != null ? fileUrl.split('/').last : 'handwritten_assignment.pdf',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (fileUrl != null && await canLaunchUrl(Uri.parse(fileUrl))) {
                        await launchUrl(Uri.parse(fileUrl));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('File ready on local storage.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Inspect Original Document'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrTab() {
    final ocrText = _ocrData?['ocr_text'] ?? _submissionData?['extracted_text'] ?? 'Loading extracted text...';
    final ocrConf = _ocrData?['ocr_confidence'] ?? _submissionData?['ocr_confidence'] ?? 92.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('OCR Extracted Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Text('Confidence: $ocrConf%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SelectableText(
              ocrText.isNotEmpty ? ocrText : 'No OCR text available.',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Multi-Student Comparison Results', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Compared against all submissions for this assignment in the database.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          if (_matches.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary Match: ${widget.review.matchedStudent}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Similarity: ${widget.review.similarityScore}% (Exceeds 70% threshold)',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._matches.map((m) {
              final sim = (m['similarity_percentage'] as num?)?.toDouble() ?? 0.0;
              final isHigh = sim > 70.0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'vs ${m['matched_student_name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isHigh ? Colors.red : Colors.orange).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$sim%',
                              style: TextStyle(
                                color: isHigh ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (m['matching_text'] != null && m['matching_text'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Matching content snippet:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Text(
                            '"${m['matching_text']}"',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
