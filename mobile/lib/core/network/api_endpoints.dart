/// MailGuard API endpoint constants.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000/api', // Reverse port-forwarded localhost
  );

  // ─── Auth ─────────────────────────────────────────────
  static const String authUrl = '/auth/url';
  static const String authGoogle = '/auth/google';
  static const String authDemoLogin = '/auth/demo-login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authProfile = '/auth/profile';
  static const String authFcmToken = '/auth/fcm-token';

  // ─── Emails ───────────────────────────────────────────
  static const String emails = '/emails';
  static const String emailsSearch = '/emails/search';
  static const String emailsTodayPriority = '/emails/today-priority';
  static const String emailsSync = '/emails/sync';

  static String emailById(String id) => '/emails/$id';
  static String emailMarkApplied(String id) => '/emails/$id/mark-applied';
  static String emailChangeCategory(String id) => '/emails/$id/category';
  static String emailSummarize(String id) => '/emails/$id/summarize';

  // ─── Deadlines ────────────────────────────────────────
  static const String deadlines = '/deadlines';
  static const String deadlinesToday = '/deadlines/today';
  static const String deadlinesUpcoming = '/deadlines/upcoming';
  static const String deadlinesOverdue = '/deadlines/overdue';

  static String deadlineById(String id) => '/deadlines/$id';
  static String deadlineComplete(String id) => '/deadlines/$id/complete';

  // ─── Applications ─────────────────────────────────────
  static const String applications = '/applications';
  static const String applicationsGrouped = '/applications/grouped';
  static const String applicationsStats = '/applications/stats';

  static String applicationById(String id) => '/applications/$id';
  static String applicationStatus(String id) => '/applications/$id/status';

  // ─── Notifications ────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsMarkAllRead = '/notifications/mark-all-read';

  static String notificationMarkRead(String id) => '/notifications/$id/read';

  // ─── Analytics ────────────────────────────────────────
  static const String analyticsDashboard = '/analytics/dashboard';
  static const String analyticsWeekly = '/analytics/weekly';
  static const String analyticsMonthly = '/analytics/monthly';

  // ─── Admin ────────────────────────────────────────────
  static const String adminUsers = '/admin/users';
  static const String adminStats = '/admin/stats';
  static String adminUserById(String id) => '/admin/users/$id';
  static String adminUserRole(String id) => '/admin/users/$id/role';

  // ─── Audit ────────────────────────────────────────────
  static const String auditMyLogs = '/audit/my-logs';
  static const String auditLoginHistory = '/audit/login-history';
}
