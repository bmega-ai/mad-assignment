import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/faculty_item.dart';

class FacultyDirectoryScreen extends StatefulWidget {
  const FacultyDirectoryScreen({Key? key}) : super(key: key);

  @override
  State<FacultyDirectoryScreen> createState() => _FacultyDirectoryScreenState();
}

class _FacultyDirectoryScreenState extends State<FacultyDirectoryScreen> {
  bool _isLoading = true;
  List<FacultyItem> _facultyList = [];
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFaculty();
  }

  Future<void> _fetchFaculty() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get(ApiConstants.faculty);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _facultyList = data.map((e) => FacultyItem.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load faculty directory';
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

  List<FacultyItem> get _filteredFaculty {
    if (_searchQuery.trim().isEmpty) return _facultyList;
    final q = _searchQuery.toLowerCase();
    return _facultyList.where((f) {
      return f.name.toLowerCase().contains(q) ||
          f.designation.toLowerCase().contains(q) ||
          f.departmentName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFaculty,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, designation, department...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Faculty List
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
                            ElevatedButton(onPressed: _fetchFaculty, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _filteredFaculty.isEmpty
                        ? const Center(child: Text('No faculty members found'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredFaculty.length,
                            itemBuilder: (context, index) {
                              final item = _filteredFaculty[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                                            child: Text(
                                              item.name.isNotEmpty ? item.name[0] : 'F',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${item.designation} • ${item.departmentName}',
                                                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.meeting_room_outlined, size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(item.office, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (item.phone != null && item.phone!.isNotEmpty)
                                            OutlinedButton.icon(
                                              onPressed: () => _callPhone(item.phone!),
                                              icon: const Icon(Icons.phone, size: 16),
                                              label: const Text('Call'),
                                              style: OutlinedButton.styleFrom(
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () => _sendEmail(item.email),
                                            icon: const Icon(Icons.email, size: 16),
                                            label: const Text('Email'),
                                            style: ElevatedButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
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
      ),
    );
  }
}
