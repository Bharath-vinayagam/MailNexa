import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

/// Dashboard statistics model.
class DashboardStats {
  final Map<String, int> emailStats;
  final int todayHighPriorityCount;
  final int upcomingDeadlineCount;
  final int overdueDeadlineCount;
  final Map<String, int> applicationStats;
  final List<Map<String, dynamic>> recentHighPriorityEmails;
  final List<Map<String, dynamic>> upcomingDeadlines;

  const DashboardStats({
    required this.emailStats,
    required this.todayHighPriorityCount,
    required this.upcomingDeadlineCount,
    required this.overdueDeadlineCount,
    required this.applicationStats,
    required this.recentHighPriorityEmails,
    required this.upcomingDeadlines,
  });

  factory DashboardStats.empty() => const DashboardStats(
        emailStats: {},
        todayHighPriorityCount: 0,
        upcomingDeadlineCount: 0,
        overdueDeadlineCount: 0,
        applicationStats: {},
        recentHighPriorityEmails: [],
        upcomingDeadlines: [],
      );

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      emailStats: _castIntMap(json['emailStats']),
      todayHighPriorityCount: json['todayHighPriorityCount'] as int? ?? 0,
      upcomingDeadlineCount: json['upcomingDeadlineCount'] as int? ?? 0,
      overdueDeadlineCount: json['overdueDeadlineCount'] as int? ?? 0,
      applicationStats: _castIntMap(json['applicationStats']),
      recentHighPriorityEmails: List<Map<String, dynamic>>.from(
        (json['recentHighPriorityEmails'] as List? ?? []).map((e) => e as Map<String, dynamic>),
      ),
      upcomingDeadlines: List<Map<String, dynamic>>.from(
        (json['upcomingDeadlines'] as List? ?? []).map((e) => e as Map<String, dynamic>),
      ),
    );
  }

  static Map<String, int> _castIntMap(dynamic raw) {
    if (raw == null) return {};
    final map = raw as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toInt()));
  }
}

/// Provider for dashboard statistics.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.analyticsDashboard);
  final data = response.data['data'] as Map<String, dynamic>;
  return DashboardStats.fromJson(data);
});
