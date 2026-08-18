import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/email_model.dart';
import '../repositories/email_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/router/app_router.dart';
import '../../deadlines/repositories/deadline_repository.dart';
import '../../deadlines/screens/deadline_screen.dart';

/// Email list filter state
class InboxFilter {
  final String? category;
  final String? priority;
  final bool? isRead;
  final bool? isShortlisted;

  const InboxFilter({this.category, this.priority, this.isRead, this.isShortlisted});

  InboxFilter copyWith({String? category, String? priority, bool? isRead, bool? isShortlisted, bool clearShortlisted = false}) {
    return InboxFilter(
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
    );
  }
}

final inboxFilterProvider = StateProvider<InboxFilter>((ref) => const InboxFilter());

final inboxEmailsProvider = FutureProvider.autoDispose<List<EmailModel>>((ref) async {
  // Auto-refresh inbox every 15 seconds for real-time live email updates
  final timer = Timer.periodic(const Duration(seconds: 15), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final filter = ref.watch(inboxFilterProvider);
  final repo = ref.watch(emailRepositoryProvider);
  final data = await repo.getEmails(
    category: filter.category,
    priority: filter.priority,
    isRead: filter.isRead,
    isShortlisted: filter.isShortlisted,
    limit: 50,
  );
  final emails = (data['data'] as List? ?? [])
      .map((e) => EmailModel.fromJson(e as Map<String, dynamic>))
      .toList();

  return emails;
});

/// Inbox screen matching the wireframe:
/// - Search bar at top
/// - Priority filter chips
/// - Email list with category color-coded left border
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(inboxFilterProvider);
    final emailsAsync = ref.watch(inboxEmailsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Smart Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(Routes.search),
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: () async {
              final repo = ref.read(emailRepositoryProvider);
              try {
                await repo.triggerSync();
                ref.invalidate(inboxEmailsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync complete')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sync failed: $e'), backgroundColor: AppColors.error),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Filter Chips ─────────────────────────────
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter.category == null && filter.priority == null && filter.isShortlisted == null,
                  onTap: () => ref.read(inboxFilterProvider.notifier).state = const InboxFilter(),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '🔥 Shortlisted',
                  selected: filter.isShortlisted == true,
                  onTap: () {
                    final cur = ref.read(inboxFilterProvider);
                    ref.read(inboxFilterProvider.notifier).state = InboxFilter(
                      isShortlisted: cur.isShortlisted == true ? null : true,
                    );
                  },
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '🔴 High Priority',
                  selected: filter.priority == 'High',
                  onTap: () {
                    final cur = ref.read(inboxFilterProvider);
                    ref.read(inboxFilterProvider.notifier).state = InboxFilter(
                      priority: cur.priority == 'High' ? null : 'High',
                    );
                  },
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '💼 Placement',
                  selected: filter.category == 'Placement',
                  onTap: () {
                    final cur = ref.read(inboxFilterProvider);
                    ref.read(inboxFilterProvider.notifier).state = InboxFilter(
                      category: cur.category == 'Placement' ? null : 'Placement',
                    );
                  },
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '🎓 Academic',
                  selected: filter.category == 'Academic',
                  onTap: () {
                    final cur = ref.read(inboxFilterProvider);
                    ref.read(inboxFilterProvider.notifier).state = InboxFilter(
                      category: cur.category == 'Academic' ? null : 'Academic',
                    );
                  },
                  color: AppColors.tertiary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '📬 Unread',
                  selected: filter.isRead == false,
                  onTap: () {
                    final cur = ref.read(inboxFilterProvider);
                    ref.read(inboxFilterProvider.notifier).state = InboxFilter(
                      isRead: cur.isRead == false ? null : false,
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ─── Email List ───────────────────────────────
          Expanded(
            child: emailsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load emails: $err')),
              data: (emails) {
                if (emails.isEmpty) {
                  return const _EmptyInbox();
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(inboxEmailsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: emails.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _EmailTile(email: emails[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = color ?? cs.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: cs.outlineVariant, width: 1),
        ),
        child: Text(
          label,
          style: AppTypography.labelLg.copyWith(
            color: selected ? Colors.white : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _EmailTile extends ConsumerWidget {
  final EmailModel email;
  const _EmailTile({required this.email});

  Color get _categoryColor {
    switch (email.category) {
      case 'Placement': return AppColors.categoryPlacement;
      case 'Academic': return AppColors.categoryAcademic;
      case 'Personal': return AppColors.categoryPersonal;
      case 'Promotions': return AppColors.categoryPromotions;
      default: return AppColors.categoryOthers;
    }
  }

  String _cleanText(String input) {
    return input
        .replaceAll(RegExp(r"^['&quot;\s]+|['&quot;\s]+$"), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  String _cleanSummaryText(String rawText) {
    if (rawText.isEmpty) return '';
    var text = rawText
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1')
        .replaceAll('*', '')
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true), '')
        .replaceAll(RegExp(r'^\s*-\s*-\s*', multiLine: true), '• ')
        .replaceAll(RegExp(r'^\s*-\s*', multiLine: true), '• ')
        .trim();
    return text;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleanSender = _cleanText(email.sender);
    final cleanSubject = _cleanText(email.subject);
    final cleanSnippet = _cleanText(email.snippet);
    final cs = Theme.of(context).colorScheme;

    String displayInitial = '?';
    final letters = cleanSender.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (letters.isNotEmpty) {
      displayInitial = letters[0].toUpperCase();
    }

    return GestureDetector(
      onTap: () => context.push('/inbox/${email.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category Color Left Accent Bar
              Container(
                width: 4,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _categoryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: _categoryColor.withOpacity(0.12),
                child: Text(
                  displayInitial,
                  style: TextStyle(
                    color: _categoryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  cleanSender,
                                  style: AppTypography.titleMd.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: email.isRead ? FontWeight.w600 : FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (email.isShortlisted) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFDC2626), Color(0xFFEA580C)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('🔥 SHORTLISTED', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(email.receivedAt),
                          style: AppTypography.labelMd.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        if (!email.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      cleanSubject,
                      style: AppTypography.bodyMd.copyWith(
                        color: cs.onSurface,
                        fontWeight: email.isRead ? FontWeight.w400 : FontWeight.w700,
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // ─── AUTO-SUMMARY (custom prompt) OR raw snippet fallback ───
                    if (email.autoSummary != null && email.autoSummary!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.primary.withValues(alpha: 0.28), width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 13, color: cs.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _cleanSummaryText(email.autoSummary!),
                                style: AppTypography.bodyMd.copyWith(
                                  color: cs.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Fallback: show raw snippet while summary is being generated
                      Text(
                        cleanSnippet,
                        style: AppTypography.bodyMd.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),

                    // ─── EXPLICIT "ADD TO DEADLINE" ACTION BUTTON ───
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () async {
                          try {
                            final repo = ref.read(deadlineRepositoryProvider);
                            final title = email.deadlineDescription != null && email.deadlineDescription!.isNotEmpty
                                ? email.deadlineDescription!
                                : cleanSubject;
                            final dueDate = email.deadline ?? DateTime.now().add(const Duration(days: 2));

                            await repo.createDeadline({
                              'title': title,
                              'dueDate': dueDate.toIso8601String(),
                              'source': cleanSender,
                              'category': email.category,
                              'emailId': email.id,
                            });
                            ref.invalidate(deadlinesListProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added "$title" to Deadlines! 📅'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add deadline: $e')),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cs.secondary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_task_rounded, size: 13, color: cs.onSecondaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                'Add to Deadlines',
                                style: TextStyle(color: cs.onSecondaryContainer, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ],
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No emails found', style: AppTypography.titleMd.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Try adjusting your filters', style: AppTypography.bodyMd.copyWith(color: AppColors.outline)),
        ],
      ),
    );
  }
}
