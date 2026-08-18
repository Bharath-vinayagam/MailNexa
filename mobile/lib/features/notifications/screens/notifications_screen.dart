import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_typography.dart';

final notificationsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.notifications);
  final list = response.data['data']['notifications'] as List? ?? [];
  return list.map((e) => e as Map<String, dynamic>).toList();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final client = ref.read(apiClientProvider);
              await client.patch(ApiEndpoints.notificationsMarkAllRead);
              ref.invalidate(notificationsListProvider);
            },
            child: Text('Mark All Read', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: cs.error))),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: cs.outline),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: AppTypography.titleMd.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsListProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = list[i];
                final isRead = item['isRead'] as bool? ?? false;
                final type = item['type'] as String? ?? '';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead ? cs.surfaceContainerLow : cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: type.contains('EMAIL') ? cs.primaryContainer.withValues(alpha: 0.3) : cs.tertiaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          type.contains('EMAIL') ? Icons.mark_email_unread_rounded : Icons.alarm_rounded,
                          color: type.contains('EMAIL') ? cs.primary : cs.tertiary,
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] as String? ?? '', style: AppTypography.titleMd.copyWith(color: cs.onSurface)),
                            const SizedBox(height: 2),
                            Text(item['body'] as String? ?? '', style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
