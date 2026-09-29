import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import 'student_home.dart';
import 'faculty_home.dart';
import 'admin_home.dart';

enum AuthViewMode {
  roleSelection,
  studentLogin,
  teacherLogin,
  teacherRegister,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthViewMode _currentMode = AuthViewMode.roleSelection;

  // Student Form
  final _studentFormKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController(text: '23CSE001');
  final _studentPasswordController = TextEditingController(text: 'student123');
  bool _studentPasswordVisible = false;

  // Teacher Form
  final _teacherFormKey = GlobalKey<FormState>();
  final _teacherIdController = TextEditingController(text: 'FAC001');
  final _teacherPasswordController = TextEditingController(text: 'faculty123');
  bool _teacherPasswordVisible = false;

  // Teacher Register Form
  final _regFormKey = GlobalKey<FormState>();
  final _regFullNameController = TextEditingController();
  final _regTeacherIdController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regDeptController = TextEditingController(text: 'CSE');
  final _regDesignationController = TextEditingController(text: 'Assistant Professor');
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  bool _isRegistering = false;

  void _login(String username, String password, String expectedRole) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(username.trim(), password);

    if (success && mounted) {
      final role = authProvider.role ?? expectedRole;
      Widget nextScreen;
      if (role == 'student') {
        nextScreen = const StudentHomeScreen();
      } else if (role == 'faculty') {
        nextScreen = const FacultyHomeScreen();
      } else {
        nextScreen = const AdminHomeScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid ID or password. Please verify your credentials.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _registerTeacher() async {
    if (!_regFormKey.currentState!.validate()) return;

    if (_regPasswordController.text != _regConfirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isRegistering = true);

    try {
      final response = await ApiService.post(ApiConstants.registerTeacher, {
        'full_name': _regFullNameController.text.trim(),
        'teacher_id': _regTeacherIdController.text.trim(),
        'email': _regEmailController.text.trim(),
        'phone': _regPhoneController.text.trim(),
        'department': _regDeptController.text.trim(),
        'designation': _regDesignationController.text.trim(),
        'password': _regPasswordController.text,
        'confirm_password': _regConfirmPasswordController.text,
      });

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher registered successfully! Account is pending admin approval.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          setState(() {
            _teacherIdController.text = _regTeacherIdController.text.trim();
            _teacherPasswordController.text = _regPasswordController.text;
            _currentMode = AuthViewMode.teacherLogin;
          });
        }
      } else {
        final err = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['error'] ?? 'Registration failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  void _showForgotPasswordDialog(String roleTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$roleTitle Password Reset'),
        content: Text(
          'For security, password resets are handled by your Campus Administration / HOD office.\n\nPlease contact admin@learnova.edu with your institutional ID to reset credentials.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentView(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView(ThemeData theme) {
    switch (_currentMode) {
      case AuthViewMode.roleSelection:
        return _buildRoleSelectionView(theme);
      case AuthViewMode.studentLogin:
        return _buildStudentLoginView(theme);
      case AuthViewMode.teacherLogin:
        return _buildTeacherLoginView(theme);
      case AuthViewMode.teacherRegister:
        return _buildTeacherRegisterView(theme);
    }
  }

  // 1. Role Selection View
  Widget _buildRoleSelectionView(ThemeData theme) {
    return Column(
      key: const ValueKey('roleSelection'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.school, size: 84, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        const Text(
          'LEARNOVA',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Learn. Connect. Experience.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(height: 48),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose Your Account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your role to access your personalized campus dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Student Card Button
              _buildRoleCard(
                title: 'STUDENT',
                subtitle: 'Submit assignments, view grades, attendance & timetable',
                icon: '👨‍🎓',
                color: theme.colorScheme.primary,
                onTap: () {
                  setState(() => _currentMode = AuthViewMode.studentLogin);
                },
              ),
              const SizedBox(height: 18),

              // Teacher Card Button
              _buildRoleCard(
                title: 'TEACHER',
                subtitle: 'Manage classes, review submissions & OCR similarity reports',
                icon: '👨‍🏫',
                color: Colors.teal.shade700,
                onTap: () {
                  setState(() => _currentMode = AuthViewMode.teacherLogin);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(0.05),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 38)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Student Login View
  Widget _buildStudentLoginView(ThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Column(
      key: const ValueKey('studentLogin'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() => _currentMode = AuthViewMode.roleSelection);
              },
            ),
            const Text(
              'Back to Roles',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Center(
          child: Column(
            children: [
              const Text('👨‍🎓', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text(
                'Student Portal',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Sign in with your Student ID',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Form(
          key: _studentFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _studentIdController,
                decoration: InputDecoration(
                  labelText: 'Student ID / Username',
                  hintText: 'e.g. 23CSE001',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter Student ID' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentPasswordController,
                obscureText: !_studentPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  suffixIcon: IconButton(
                    icon: Icon(_studentPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _studentPasswordVisible = !_studentPasswordVisible),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter Password' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog('Student'),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () {
                          if (_studentFormKey.currentState!.validate()) {
                            _login(_studentIdController.text, _studentPasswordController.text, 'student');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Student Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo Student ID: 23CSE001 | Password: student123',
                  style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Teacher Login View
  Widget _buildTeacherLoginView(ThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Column(
      key: const ValueKey('teacherLogin'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() => _currentMode = AuthViewMode.roleSelection);
              },
            ),
            const Text(
              'Back to Roles',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Center(
          child: Column(
            children: [
              const Text('👨‍🏫', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text(
                'Teacher Portal',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Sign in with your Teacher ID',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Form(
          key: _teacherFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _teacherIdController,
                decoration: InputDecoration(
                  labelText: 'Teacher ID / Username',
                  hintText: 'e.g. FAC001',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter Teacher ID' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _teacherPasswordController,
                obscureText: !_teacherPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  suffixIcon: IconButton(
                    icon: Icon(_teacherPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _teacherPasswordVisible = !_teacherPasswordVisible),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter Password' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog('Teacher'),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () {
                          if (_teacherFormKey.currentState!.validate()) {
                            _login(_teacherIdController.text, _teacherPasswordController.text, 'faculty');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Teacher Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // New Teacher Registration Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("New Teacher? ", style: TextStyle(fontSize: 14)),
            GestureDetector(
              onTap: () {
                setState(() => _currentMode = AuthViewMode.teacherRegister);
              },
              child: Text(
                'Register Here',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.teal, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo Teacher ID: FAC001 | Password: faculty123',
                  style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Teacher Registration View
  Widget _buildTeacherRegisterView(ThemeData theme) {
    return Column(
      key: const ValueKey('teacherRegister'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() => _currentMode = AuthViewMode.teacherLogin);
              },
            ),
            const Text(
              'Back to Teacher Login',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),

        const Text(
          'Faculty Registration',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Submit your credentials for departmental approval',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),

        Form(
          key: _regFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _regFullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. Dr. Suresh Verma',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _regTeacherIdController,
                decoration: InputDecoration(
                  labelText: 'Teacher ID',
                  hintText: 'e.g. FAC003',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter Teacher ID' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _regEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Institutional Email',
                  hintText: 'suresh@learnova.edu',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || !val.contains('@') ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _regPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+91 98765 43210',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _regDeptController,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        hintText: 'CSE / ECE',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _regDesignationController,
                      decoration: InputDecoration(
                        labelText: 'Designation',
                        hintText: 'Asst. Professor',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _regPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _regConfirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_reset),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Confirm password' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isRegistering ? null : _registerTeacher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isRegistering
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Teacher Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: Newly registered teacher accounts are set to PENDING status until verified by Campus Administration.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
