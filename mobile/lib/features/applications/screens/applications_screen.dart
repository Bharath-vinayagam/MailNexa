import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/router/app_router.dart';

final groupedApplicationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(applicationRepositoryProvider);
  return repo.getGroupedApplications();
});

/// Applications screen with full theme adaptation & status indicators.
class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupedApplicationsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Application Tracker'),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: cs.error))),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline_rounded, size: 64, color: cs.outline),
                  const SizedBox(height: 16),
                  Text('No applications tracked yet', style: AppTypography.titleMd.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Tap + to track your first job application', style: AppTypography.bodyMd.copyWith(color: cs.outline)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(groupedApplicationsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final group = groups[i];
                final company = group['company'] as String;
                final apps = (group['applications'] as List? ?? [])
                    .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
                    .toList();

                return _CompanyGroupCard(company: company, applications: apps);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.addApplication),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Application'),
      ),
    );
  }
}

class _CompanyGroupCard extends StatelessWidget {
  final String company;
  final List<ApplicationModel> applications;

  const _CompanyGroupCard({required this.company, required this.applications});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    company.isNotEmpty ? company[0].toUpperCase() : 'C',
                    style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Text(company.toUpperCase(), style: AppTypography.titleLg.copyWith(color: cs.onSurface, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${applications.length} ${applications.length == 1 ? 'role' : 'roles'}',
                    style: AppTypography.labelMd.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),

          // Role items
          for (final app in applications)
            InkWell(
              onTap: () => context.push('/applications/${app.id}'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: _statusColor(app.status), width: 4),
                    bottom: app == applications.last
                        ? BorderSide.none
                        : BorderSide(color: cs.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.role, style: AppTypography.titleMd.copyWith(color: cs.onSurface)),
                          if (app.location.isNotEmpty)
                            Text(app.location, style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    _StatusBadge(status: app.status),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Applied': return AppColors.statusApplied;
      case 'Interview': return AppColors.statusInterview;
      case 'Offer': return AppColors.statusOffer;
      case 'Rejected': return AppColors.statusRejected;
      default: return AppColors.outline;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    Color fg;

    switch (status) {
      case 'Applied':
        bg = cs.primaryContainer.withValues(alpha: 0.3);
        fg = cs.primary;
        break;
      case 'Interview':
        bg = AppColors.statusInterview.withValues(alpha: 0.2);
        fg = AppColors.statusInterview;
        break;
      case 'Offer':
        bg = AppColors.statusOffer.withValues(alpha: 0.2);
        fg = AppColors.statusOffer;
        break;
      case 'Rejected':
        bg = AppColors.errorContainer;
        fg = AppColors.error;
        break;
      default:
        bg = cs.surfaceContainerHigh;
        fg = cs.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.labelLg.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
