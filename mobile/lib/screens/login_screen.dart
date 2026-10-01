import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';
import 'student_home.dart';
import 'faculty_home.dart';
import 'admin_home.dart';
import '../widgets/learnova_logo.dart';

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
      final msg = authProvider.errorMessage ?? 'Invalid ID or password. Please verify your credentials.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          '$roleTitle Password Reset',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'For security, password resets are handled by your Campus Administration / HOD office.\n\nPlease contact admin@learnova.edu with your institutional ID to reset credentials.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: ApiConstants.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.dns_rounded, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(
              'Server IP Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the Django server API URL (e.g. your PC Wi-Fi IP):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Backend API URL',
                labelStyle: TextStyle(
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                  fontWeight: FontWeight.bold,
                ),
                hintText: 'http://10.143.206.252:8000/api',
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                prefixIcon: Icon(Icons.link, color: isDark ? const Color(0xFF818CF8) : const Color(0xFF2563EB)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF818CF8) : const Color(0xFF2563EB), width: 2.0)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await ApiConstants.setBaseUrl(newUrl);
                if (mounted) setState(() {});
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server URL set to: ${ApiConstants.baseUrl}')),
              );
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _showServerConfigDialog,
                icon: Icon(
                  Icons.wifi_tethering,
                  size: 16,
                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                ),
                label: Text(
                  'Server: ${ApiConstants.baseUrl.replaceAll('/api', '').replaceAll('http://', '')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
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
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final studentColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF2563EB);
    final teacherColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);

    return Column(
      key: const ValueKey('roleSelection'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: LearnovaLogo(
            size: 84,
            borderRadius: 22,
            showShadow: true,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'LEARNOVA',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Learn. Connect. Experience.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: secondaryTextColor,
          ),
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
              Text(
                'Choose Your Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your role to access your personalized campus dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 32),

              // Student Card Button
              _buildRoleCard(
                title: 'STUDENT',
                subtitle: 'Submit assignments, view grades, attendance & timetable',
                icon: '👨‍🎓',
                color: studentColor,
                subtitleColor: secondaryTextColor,
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
                color: teacherColor,
                subtitleColor: secondaryTextColor,
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
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(isDark ? 0.6 : 0.4), width: 1.5),
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(isDark ? 0.15 : 0.06),
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
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
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final inputTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
    final hintColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final fieldFill = isDark ? const Color(0xFF1E293B) : Colors.white;
    final iconColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF2563EB);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final inputTextStyle = TextStyle(
      color: inputTextColor,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    return Column(
      key: const ValueKey('studentLogin'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: primaryTextColor),
              onPressed: () {
                setState(() => _currentMode = AuthViewMode.roleSelection);
              },
            ),
            Text(
              'Back to Roles',
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Center(
          child: Column(
            children: [
              const Text('👨‍🎓', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(
                'Student Portal',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in with your Student ID',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
                style: inputTextStyle,
                decoration: InputDecoration(
                  labelText: 'Student ID / Username',
                  labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                  hintText: 'e.g. 23CSE001',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  prefixIcon: Icon(Icons.badge_outlined, color: iconColor),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: iconColor, width: 2.0)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter Student ID' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentPasswordController,
                obscureText: !_studentPasswordVisible,
                style: inputTextStyle,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                  prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                  suffixIcon: IconButton(
                    icon: Icon(_studentPasswordVisible ? Icons.visibility : Icons.visibility_off, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    onPressed: () => setState(() => _studentPasswordVisible = !_studentPasswordVisible),
                  ),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: iconColor, width: 2.0)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter Password' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog('Student'),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                    ),
                  ),
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
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Student Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.4) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo Student ID: 23CSE001 | Password: student123',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E40AF),
                    fontWeight: FontWeight.bold,
                  ),
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
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final inputTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
    final hintColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final fieldFill = isDark ? const Color(0xFF1E293B) : Colors.white;
    final iconColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final inputTextStyle = TextStyle(
      color: inputTextColor,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    return Column(
      key: const ValueKey('teacherLogin'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: primaryTextColor),
              onPressed: () {
                setState(() => _currentMode = AuthViewMode.roleSelection);
              },
            ),
            Text(
              'Back to Roles',
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Center(
          child: Column(
            children: [
              const Text('👨‍🏫', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(
                'Teacher Portal',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in with your Teacher ID',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
                style: inputTextStyle,
                decoration: InputDecoration(
                  labelText: 'Teacher ID / Username',
                  labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                  hintText: 'e.g. FAC001',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  prefixIcon: Icon(Icons.badge_outlined, color: iconColor),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: iconColor, width: 2.0)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter Teacher ID' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _teacherPasswordController,
                obscureText: !_teacherPasswordVisible,
                style: inputTextStyle,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                  prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                  suffixIcon: IconButton(
                    icon: Icon(_teacherPasswordVisible ? Icons.visibility : Icons.visibility_off, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    onPressed: () => setState(() => _teacherPasswordVisible = !_teacherPasswordVisible),
                  ),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: iconColor, width: 2.0)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter Password' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog('Teacher'),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
                    ),
                  ),
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
                    backgroundColor: isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Teacher Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
            Text("New Teacher? ", style: TextStyle(fontSize: 14, color: secondaryTextColor, fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: () {
                setState(() => _currentMode = AuthViewMode.teacherRegister);
              },
              child: Text(
                'Register Here',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
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
            color: isDark ? const Color(0xFF042F2E).withOpacity(0.5) : const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo Teacher ID: FAC001 | Password: faculty123',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF99F6E4) : const Color(0xFF0F766E),
                    fontWeight: FontWeight.bold,
                  ),
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
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final inputTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
    final hintColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final fieldFill = isDark ? const Color(0xFF1E293B) : Colors.white;
    final iconColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final inputTextStyle = TextStyle(
      color: inputTextColor,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );

    return Column(
      key: const ValueKey('teacherRegister'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: primaryTextColor),
              onPressed: () {
                setState(() => _currentMode = AuthViewMode.teacherLogin);
              },
            ),
            Text(
              'Back to Teacher Login',
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Text(
          'Faculty Registration',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Submit your credentials for departmental approval',
          style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),

        Form(
          key: _regFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _regFullNameController,
                style: inputTextStyle,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                  hintText: 'e.g. Dr. Suresh Verma',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  prefixIcon: Icon(Icons.person_outline, color: iconColor),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 2.0)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _regTeacherIdController,
                style: inputTextStyle,
                decoration: InputDecoration(
                  labelText: 'Teacher ID',
                  labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                  hintText: 'e.g. FAC003',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  prefixIcon: Icon(Icons.badge_outlined, color: iconColor),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 2.0)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter Teacher ID' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _regEmailController,
                keyboardType: TextInputType.emailAddress,
                style: inputTextStyle,
                decoration: InputDecoration(
                  labelText: 'Institutional Email',
                  labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                  hintText: 'suresh@learnova.edu',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  prefixIcon: Icon(Icons.email_outlined, color: iconColor),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 2.0)),
                ),
                validator: (val) => val == null || !val.contains('@') ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _regPhoneController,
                keyboardType: TextInputType.phone,
                style: inputTextStyle,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                  hintText: '+91 98765 43210',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  prefixIcon: Icon(Icons.phone_outlined, color: iconColor),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 2.0)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _regDeptController,
                      style: inputTextStyle,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                        hintText: 'CSE / ECE',
                        hintStyle: TextStyle(color: hintColor, fontSize: 14),
                        filled: true,
                        fillColor: fieldFill,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 2.0)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _regDesignationController,
                      style: inputTextStyle,
                      decoration: InputDecoration(
                        labelText: 'Designation',
                        labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                        hintText: 'Asst. Professor',
                        hintStyle: TextStyle(color: hintColor, fontSize: 14),
                        filled: true,
                        fillColor: fieldFill,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 2.0)),
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
                style: inputTextStyle,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                  prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 2.0)),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _regConfirmPasswordController,
                obscureText: true,
                style: inputTextStyle,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
                  prefixIcon: Icon(Icons.lock_reset, color: iconColor),
                  filled: true,
                  fillColor: fieldFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 2.0)),
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
                    backgroundColor: isDark ? const Color(0xFF0D9488) : const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isRegistering
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Teacher Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: Newly registered teacher accounts are set to PENDING status until verified by Campus Administration.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
