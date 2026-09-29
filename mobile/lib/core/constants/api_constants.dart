class ApiConstants {
  // Use 10.0.2.2 for Android Emulator, or your PC's IP for real devices.
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
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
}
