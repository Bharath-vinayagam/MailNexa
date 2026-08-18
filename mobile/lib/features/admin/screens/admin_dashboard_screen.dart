import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.adminStats);
  return response.data['data']['stats'] as Map<String, dynamic>;
});

final adminUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.adminUsers);
  final list = response.data['data'] as List? ?? [];
  return list.map((e) => e as Map<String, dynamic>).toList();
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Admin Console')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Overview', style: AppTypography.titleLg),
            const SizedBox(height: 12),

            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Failed to load stats: $err'),
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _AdminStatCard(title: 'Total Users', value: '${stats['totalUsers'] ?? 0}'),
                  _AdminStatCard(title: 'Active Users', value: '${stats['activeUsers'] ?? 0}'),
                  _AdminStatCard(title: 'Total Emails', value: '${stats['totalEmails'] ?? 0}'),
                  _AdminStatCard(title: 'Total Applications', value: '${stats['totalApplications'] ?? 0}'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text('User Management', style: AppTypography.titleLg),
            const SizedBox(height: 12),

            usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Failed to load users: $err'),
              data: (users) => Column(
                children: [
                  for (final user in users)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Text((user['name'] as String? ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(user['name'] as String? ?? ''),
                        subtitle: Text(user['email'] as String? ?? ''),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: user['role'] == 'admin' ? AppColors.secondaryContainer : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (user['role'] as String? ?? 'user').toUpperCase(),
                            style: AppTypography.labelMd,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  const _AdminStatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTypography.headlineMd.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(title, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
