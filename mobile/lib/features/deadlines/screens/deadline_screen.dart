import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/deadline_model.dart';
import '../repositories/deadline_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/router/app_router.dart';

final deadlinesListProvider = FutureProvider.autoDispose<List<DeadlineModel>>((ref) async {
  final repo = ref.watch(deadlineRepositoryProvider);
  return repo.getDeadlines();
});

/// Deadline screen matching wireframe:
/// - Tabs: Active / Completed
/// - Deadline card with title, source, due date countdown, and completion checkbox
/// - FAB to add new manual deadline
class DeadlineScreen extends ConsumerWidget {
  const DeadlineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadlinesAsync = ref.watch(deadlinesListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Deadlines & Reminders'),
          bottom: TabBar(
            labelStyle: AppTypography.labelLg,
            unselectedLabelStyle: AppTypography.labelMd,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'ACTIVE'),
              Tab(text: 'COMPLETED'),
            ],
          ),
        ),
        body: deadlinesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (deadlines) {
            final active = deadlines.where((d) => !d.isCompleted).toList();
            final completed = deadlines.where((d) => d.isCompleted).toList();

            return TabBarView(
              children: [
                _DeadlineList(deadlines: active, ref: ref),
                _DeadlineList(deadlines: completed, ref: ref),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(Routes.addDeadline),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Deadline'),
        ),
      ),
    );
  }
}

class _DeadlineList extends StatelessWidget {
  final List<DeadlineModel> deadlines;
  final WidgetRef ref;

  const _DeadlineList({required this.deadlines, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (deadlines.isEmpty) {
      return Center(
        child: Text('No deadlines found', style: AppTypography.bodyMd.copyWith(color: AppColors.outline)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(deadlinesListProvider.future),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: deadlines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _DeadlineTile(deadline: deadlines[i], ref: ref),
      ),
    );
  }
}

class _DeadlineTile extends StatelessWidget {
  final DeadlineModel deadline;
  final WidgetRef ref;

  const _DeadlineTile({required this.deadline, required this.ref});

  Color _typeColor(String? title) {
    final t = (title ?? '').toUpperCase();
    if (t.contains('[PPT]')) return const Color(0xFF7C3AED);
    if (t.contains('[TEST]')) return const Color(0xFFDB2777);
    if (t.contains('[INTERVIEW]')) return const Color(0xFF0891B2);
    return AppColors.secondary;
  }

  String _typeLabel(String? title) {
    final t = (title ?? '').toUpperCase();
    if (t.contains('[PPT]')) return 'PPT';
    if (t.contains('[TEST]')) return 'TEST';
    if (t.contains('[INTERVIEW]')) return 'INTERVIEW';
    return 'DEADLINE';
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'^\[(PPT|TEST|INTERVIEW|DEADLINE)\]\s*'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final diff = deadline.dueDate.difference(DateTime.now());
    final isUrgent = !deadline.isCompleted && diff.inHours < 24 && !diff.isNegative;
    final isOverdue = !deadline.isCompleted && diff.isNegative;
    final typeColor = deadline.isCompleted ? AppColors.outline : _typeColor(deadline.title);
    final typeLabel = _typeLabel(deadline.title);
    final cleanTitle = _cleanTitle(deadline.title);

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: deadline.isCompleted
                ? AppColors.outline
                : isOverdue
                    ? AppColors.error
                    : isUrgent
                        ? AppColors.secondary
                        : typeColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: deadline.isCompleted,
            activeColor: AppColors.primary,
            visualDensity: VisualDensity.compact,
            onChanged: (val) async {
              if (val == true && !deadline.isCompleted) {
                await ref.read(deadlineRepositoryProvider).completeDeadline(deadline.id);
                ref.invalidate(deadlinesListProvider);
              }
            },
          ),
          const SizedBox(width: 6),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge + title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(color: typeColor, fontWeight: FontWeight.w800, fontSize: 10),
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Text('OVERDUE', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800, fontSize: 10)),
                      ),
                    ],
                    if (isUrgent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('${diff.inHours}H LEFT', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                Text(
                  cleanTitle,
                  style: AppTypography.titleMd.copyWith(
                    decoration: deadline.isCompleted ? TextDecoration.lineThrough : null,
                    color: deadline.isCompleted ? cs.outline : cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),
                // Full date display
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: isOverdue ? AppColors.error : cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      _formatFullDate(deadline.dueDate),
                      style: AppTypography.labelMd.copyWith(
                        color: isOverdue ? AppColors.error : cs.onSurfaceVariant,
                        fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time_rounded, size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      _formatRemaining(deadline.dueDate),
                      style: AppTypography.labelMd.copyWith(
                        color: isOverdue ? AppColors.error : isUrgent ? AppColors.secondary : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                if (deadline.source.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 12, color: AppColors.outline),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          deadline.source,
                          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime due) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${due.day} ${months[due.month - 1]} ${due.year}';
  }

  String _formatRemaining(DateTime due) {
    final diff = due.difference(DateTime.now());
    if (diff.isNegative) return 'OVERDUE';
    if (diff.inHours < 1) return 'Due in < 1h';
    if (diff.inHours < 24) return '${diff.inHours}h left';
    return '${diff.inDays}d left';
  }
}

