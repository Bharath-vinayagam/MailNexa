import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/router/app_router.dart';
import '../../notifications/services/fcm_service.dart';

/// Executive placement & academic email dashboard for MailGuard.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final dashboardAsync = ref.watch(dashboardStatsProvider);
    final user = authState.user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardStatsProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── TOP APP BAR ─────────────────────────────
                    _buildAppBar(context, user, cs),
                    const SizedBox(height: 20),

                    // ─── GREETING & STATUS BANNER ────────────────
                    _buildGreetingHeader(user, cs),
                    const SizedBox(height: 24),

                    // ─── ASYNC DASHBOARD CONTENT ──────────────────
                    dashboardAsync.when(
                      loading: () => const _DashboardSkeleton(),
                      error: (err, _) => _ErrorCard(message: err.toString()),
                      data: (stats) => _DashboardView(stats: stats),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, user, ColorScheme cs) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/mailnexa_logo.jpg',
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MailNexa AI',
                style: AppTypography.titleLg.copyWith(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Placement & Academic Intelligence',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => context.push(Routes.settings),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer,
            backgroundImage: user?.picture != null ? NetworkImage(user!.picture!) : null,
            child: user?.picture == null
                ? Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                    style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w800),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingHeader(user, ColorScheme cs) {
    final firstName = user?.name.split(' ').first ?? 'Student';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withValues(alpha: 0.12), cs.secondary.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 12, color: cs.primary),
                          const SizedBox(width: 6),
                          Text(
                            'AI AGENT ONLINE',
                            style: TextStyle(color: cs.primary, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome back, $firstName 👋',
                  style: AppTypography.headlineMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your placement emails are auto-categorized with AI summaries & deadline alarms.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final DashboardStats stats;
  const _DashboardView({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Column(
      children: [
        // ─── 4 TOP STAT CARDS ─────────────────────────────
        _buildStatsMetricsGrid(context, stats),
        const SizedBox(height: 24),

        // ─── MAIN RESPONSIVE LAYOUT ───────────────────────
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _HighPriorityUpdatesFeed(stats: stats),
                    const SizedBox(height: 20),
                    _CategoryDistributionCard(stats: stats),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _UpcomingDeadlinesCard(deadlines: stats.upcomingDeadlines),
                    const SizedBox(height: 20),
                    _QuickActionsCard(),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _HighPriorityUpdatesFeed(stats: stats),
              const SizedBox(height: 20),
              _CategoryDistributionCard(stats: stats),
              const SizedBox(height: 20),
              _UpcomingDeadlinesCard(deadlines: stats.upcomingDeadlines),
              const SizedBox(height: 20),
              _QuickActionsCard(),
            ],
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatsMetricsGrid(BuildContext context, DashboardStats stats) {
    final cs = Theme.of(context).colorScheme;
    final totalEmails = stats.emailStats.values.fold(0, (a, b) => a + b);
    final placementCount = stats.emailStats['Placement'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: count == 4 ? 1.8 : 1.35,
          children: [
            _MetricCard(
              title: 'Placement Emails',
              value: '$placementCount',
              subtitle: 'From CDC & Campus',
              icon: Icons.business_center_rounded,
              color: cs.primary,
              bgColor: cs.primaryContainer.withValues(alpha: 0.5),
            ),
            _MetricCard(
              title: 'High Priority',
              value: '${stats.todayHighPriorityCount}',
              subtitle: 'Require Attention',
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFDC2626),
              bgColor: const Color(0xFFDC2626).withOpacity(0.12),
            ),
            _MetricCard(
              title: 'Upcoming Deadlines',
              value: '${stats.upcomingDeadlineCount}',
              subtitle: 'Test & Reg Limits',
              icon: Icons.event_available_rounded,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFD97706).withOpacity(0.12),
            ),
            _MetricCard(
              title: 'Total Synced',
              value: '$totalEmails',
              subtitle: 'Auto-Summarized',
              icon: Icons.mark_email_read_rounded,
              color: const Color(0xFF059669),
              bgColor: const Color(0xFF059669).withOpacity(0.12),
            ),
          ],
        );
      },
    );
  }
}

// ─── Metric Mini Card ──────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: AppTypography.headlineMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 20)),
                Text(title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── High Priority Updates Feed ────────────────────────────
class _HighPriorityUpdatesFeed extends StatelessWidget {
  final DashboardStats stats;
  const _HighPriorityUpdatesFeed({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final recent = stats.recentHighPriorityEmails;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'High Priority Placement Alerts',
                  style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => context.go(Routes.inbox),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: Text('View Inbox', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: cs.primary, size: 36),
                  const SizedBox(height: 8),
                  Text('No urgent placement emails right now 🎉', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('Your placement status is up to date.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11.5)),
                ],
              ),
            )
          else
            Column(
              children: recent.take(4).map((emailData) {
                final subject = emailData['subject'] as String? ?? 'Placement Email';
                final isShortlisted = emailData['isShortlisted'] == true;
                final id = emailData['_id'] as String? ?? emailData['id'] as String? ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                      left: BorderSide(
                        color: isShortlisted ? const Color(0xFFDC2626) : cs.primary,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isShortlisted) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('🎉 SHORTLIST', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900, fontSize: 9.5)),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    subject,
                                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 13.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: cs.onSurfaceVariant),
                        onPressed: () {
                          if (id.isNotEmpty) context.push('/inbox/$id');
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Category Distribution Card ───────────────────────────
class _CategoryDistributionCard extends StatelessWidget {
  final DashboardStats stats;
  const _CategoryDistributionCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = stats.emailStats.values.fold(0, (a, b) => a + b);

    final categories = [
      {'name': 'Placement', 'count': stats.emailStats['Placement'] ?? 0, 'color': cs.primary, 'icon': Icons.business_center_rounded},
      {'name': 'Academic', 'count': stats.emailStats['Academic'] ?? 0, 'color': const Color(0xFF0284C7), 'icon': Icons.school_rounded},
      {'name': 'Personal', 'count': stats.emailStats['Personal'] ?? 0, 'color': const Color(0xFF10B981), 'icon': Icons.person_rounded},
      {'name': 'Promotions / Others', 'count': (stats.emailStats['Promotions'] ?? 0) + (stats.emailStats['Others'] ?? 0), 'color': const Color(0xFF8B5CF6), 'icon': Icons.folder_open_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Email Category Breakdown',
                  style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('$total Mails Total', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),

          // Visual Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: categories.map((cat) {
                  final count = cat['count'] as int;
                  final flex = total > 0 ? ((count / total) * 100).round() : 1;
                  return Expanded(
                    flex: flex > 0 ? flex : 1,
                    child: Container(color: cat['color'] as Color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category Detailed Legend Rows
          Column(
            children: categories.map((cat) {
              final count = cat['count'] as int;
              final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(cat['icon'] as IconData, size: 16, color: cat['color'] as Color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat['name'] as String,
                        style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$count mails ($pct%)', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming Deadlines Card ─────────────────────────────
class _UpcomingDeadlinesCard extends StatelessWidget {
  final List<Map<String, dynamic>> deadlines;
  const _UpcomingDeadlinesCard({required this.deadlines});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_rounded, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Upcoming Deadlines',
                  style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(Routes.deadlines),
                child: Text('VIEW ALL', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (deadlines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('No upcoming deadlines 🎉', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            )
          else
            Column(
              children: deadlines.take(4).map((dl) {
                final title = dl['title'] as String? ?? 'Deadline';
                final dueDateStr = dl['dueDate'] as String?;
                final displayTime = _formatDueDate(dueDateStr);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(displayTime, style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.alarm_add_rounded, color: cs.primary, size: 20),
                        onPressed: () async {
                          await FcmService.showNotification(title: '⏰ Alarm Set', body: title);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder set for $title')));
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _formatDueDate(String? dueDateStr) {
    if (dueDateStr == null) return '';
    final due = DateTime.tryParse(dueDateStr);
    if (due == null) return '';
    final diff = due.difference(DateTime.now());
    if (diff.isNegative) return 'OVERDUE';
    if (diff.inHours < 24) return 'DUE IN ${diff.inHours}h';
    return 'IN ${diff.inDays} DAYS (${due.day}/${due.month})';
  }
}

// ─── Quick Actions Panel ──────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 14),
          _QuickActionButton(
            icon: Icons.local_fire_department_rounded,
            label: 'View Shortlisted Mails',
            color: const Color(0xFFDC2626),
            onTap: () => context.go(Routes.inbox),
          ),
          const SizedBox(height: 8),
          _QuickActionButton(
            icon: Icons.checklist_rtl_rounded,
            label: 'Track Applications',
            color: cs.primary,
            onTap: () => context.go(Routes.applications),
          ),
          const SizedBox(height: 8),
          _QuickActionButton(
            icon: Icons.alarm_rounded,
            label: 'Manage Deadlines & Alarms',
            color: const Color(0xFFD97706),
            onTap: () => context.go(Routes.deadlines),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 13))),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton Loader ──────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          Text('Failed to load dashboard', style: AppTypography.titleMd.copyWith(color: AppColors.onErrorContainer)),
          Text(message, style: AppTypography.bodyMd.copyWith(color: AppColors.onErrorContainer), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
