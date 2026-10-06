import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  // Configured with your PC's current local Wi-Fi IP so the physical phone APK connects directly.
  static String baseUrl = 'http://10.197.131.252:8000/api';
  
  static Future<void> loadBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('custom_base_url');
      if (saved != null && saved.trim().isNotEmpty) {
        baseUrl = saved.trim();
      }
    } catch (_) {}
  }

  static Future<void> setBaseUrl(String newUrl) async {
    baseUrl = newUrl.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_base_url', baseUrl);
    } catch (_) {}
  }

  static String get serverIp {
    try {
      final uri = Uri.parse(baseUrl);
      return uri.host.isNotEmpty ? uri.host : '10.197.131.252';
    } catch (_) {
      return '10.197.131.252';
    }
  }

  static String get serverPort {
    try {
      final uri = Uri.parse(baseUrl);
      return uri.hasPort ? uri.port.toString() : '8000';
    } catch (_) {
      return '8000';
    }
  }

  static Future<void> updateHostAndPort(String host, [String port = '8000']) async {
    String cleanHost = host.trim();
    cleanHost = cleanHost.replaceAll('http://', '').replaceAll('https://', '').replaceAll('/api', '').replaceAll('/', '');
    if (cleanHost.contains(':')) {
      final parts = cleanHost.split(':');
      cleanHost = parts[0];
      port = parts[1];
    }
    final cleanPort = port.trim().isEmpty ? '8000' : port.trim();
    final fullUrl = 'http://$cleanHost:$cleanPort/api';
    await setBaseUrl(fullUrl);
  }
  
  // Auth endpoints
  static const String login = '/auth/login/';
  static const String registerTeacher = '/auth/register-teacher/';
  
  // Dashboard endpoints
  static const String studentProfile = '/student/profile/';
  static const String studentDashboard = '/student/dashboard/';
  static const String teacherDashboard = '/teacher/dashboard/';
  
  // Academic endpoints
  static const String timetable = '/timetable/';
  static const String attendance = '/attendance/';
  static const String attendanceStudents = '/attendance/students/';
  static const String subjects = '/subjects/';
  static const String assignments = '/assignments/';
  static const String submissions = '/submissions/';
  
  // Events & Notes & Notifications
  static const String events = '/events/';
  static const String faculty = '/faculty/';
  static const String notifications = '/notifications/';
  static const String notes = '/notes/';
  
  // Teacher Review endpoints
  static const String teacherReviews = '/teacher/review-requests/';
  
  // Dynamic URLs
  static String getAssignmentSubmitUrl(int id) => '/assignments/$id/submit/';
  static String getSubmissionDetailUrl(int id) => '/submissions/$id/';
  static String getSubmissionStatusUrl(int id) => '/submissions/$id/status/';
  static String getSubmissionOcrUrl(int id) => '/submissions/$id/ocr/';
  static String getSubmissionSimilarityUrl(int id) => '/submissions/$id/similarity/';
  static String getSubmissionMatchesUrl(int id) => '/submissions/$id/matches/';
  static String getSubmissionVersionsUrl(int id) => '/submissions/$id/versions/';
  static String getSubmissionReviewRequestUrl(int id) => '/submissions/$id/review-request/';
  static String getSubmissionResubmitUrl(int id) => '/submissions/$id/resubmit/';
  static String getSubmissionApproveUrl(int id) => '/submissions/$id/approve/';
  static String getSubmissionRejectUrl(int id) => '/submissions/$id/reject/';
  static String getSubmissionRewriteRequestUrl(int id) => '/submissions/$id/rewrite-request/';
  static String getTeacherReviewActionUrl(int id) => '/teacher/review-requests/$id/action/';
  
  static String getSimilarityUrl(int id) => '/similarity/$id/';
  static String getEventMediaUrl(int id) => '/events/$id/media/';
  static String readNotificationUrl(int id) => '/notifications/$id/read/';
  static String getAttendanceDetailUrl(int id) => '/attendance/$id/';
  static String getAssignmentRosterUrl(int id) => '/assignments/$id/roster/';
  static String getAssignmentRemindUrl(int id) => '/assignments/$id/remind/';
  static String getGradeSubmissionUrl(int id) => '/submissions/$id/grade/';
}
