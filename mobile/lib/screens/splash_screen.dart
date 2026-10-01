import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/api_constants.dart';
import 'login_screen.dart';
import 'student_home.dart';
import 'faculty_home.dart';
import 'admin_home.dart';
import '../widgets/learnova_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _showingPrompt = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        _promptServerIp();
      }
    });
  }

  void _promptServerIp() {
    if (_showingPrompt) return;
    _showingPrompt = true;

    final ipController = TextEditingController(text: ApiConstants.serverIp);
    final portController = TextEditingController(text: ApiConstants.serverPort);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
        final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subtitleColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
        final fieldFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
        final inputTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final labelColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
        final hintColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
        final iconColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF2563EB);
        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 24, spreadRadius: 6),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF312E81) : Colors.indigo.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.wifi_tethering_rounded, color: isDark ? const Color(0xFFA5B4FC) : Colors.indigo.shade700, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connect to Server',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enter your PC\'s Wi-Fi IPv4 address',
                            style: TextStyle(fontSize: 13, color: subtitleColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFFB45309) : const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Run "ipconfig" in PC CMD to find your Wireless LAN IPv4 Address.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ipController,
                  style: TextStyle(
                    color: inputTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Server IPv4 Address',
                    labelStyle: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    hintText: 'e.g. 10.143.206.252',
                    hintStyle: TextStyle(color: hintColor, fontSize: 14),
                    prefixIcon: Icon(Icons.desktop_windows_outlined, color: iconColor),
                    filled: true,
                    fillColor: fieldFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 2.0)),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portController,
                  style: TextStyle(
                    color: inputTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Port (Default: 8000)',
                    labelStyle: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    hintText: '8000',
                    hintStyle: TextStyle(color: hintColor, fontSize: 14),
                    prefixIcon: Icon(Icons.numbers_outlined, color: iconColor),
                    filled: true,
                    fillColor: fieldFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1.5)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: iconColor, width: 2.0)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final ip = ipController.text.trim();
                    final port = portController.text.trim();
                    if (ip.isNotEmpty) {
                      await ApiConstants.updateHostAndPort(ip, port);
                    }
                    if (mounted) {
                      Navigator.pop(ctx);
                      _checkAuthAndNavigate();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  child: const Text('Connect & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _checkAuthAndNavigate();
                  },
                  child: Text(
                    'Use Default (${ApiConstants.serverIp})',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _checkAuthAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      final role = authProvider.role;
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
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const LearnovaLogo(
                  size: 110,
                  borderRadius: 28,
                  showShadow: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'LEARNOVA',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Learn. Connect. Experience.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
