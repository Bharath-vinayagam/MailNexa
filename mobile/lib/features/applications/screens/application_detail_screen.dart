import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/application_model.dart';
import '../repositories/application_repository.dart';
import 'applications_screen.dart';
import '../../deadlines/repositories/deadline_repository.dart';
import '../../deadlines/screens/deadline_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

final applicationDetailProvider = FutureProvider.family<ApplicationModel, String>((ref, id) async {
  final repo = ref.watch(applicationRepositoryProvider);
  return repo.getApplicationById(id);
});

class ApplicationDetailScreen extends ConsumerWidget {
  final String applicationId;
  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appAsync = ref.watch(applicationDetailProvider(applicationId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Application Timeline',
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Delete Application',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: appAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading application: $err')),
        data: (app) => _ApplicationDetailContent(app: app, ref: ref),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Application?'),
        content: const Text('This will permanently delete this application record.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(applicationRepositoryProvider).deleteApplication(applicationId);
              ref.invalidate(groupedApplicationsProvider);
              if (context.mounted) context.pop();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ApplicationDetailContent extends StatefulWidget {
  final ApplicationModel app;
  final WidgetRef ref;

  const _ApplicationDetailContent({required this.app, required this.ref});

  @override
  State<_ApplicationDetailContent> createState() => _ApplicationDetailContentState();
}

class _ApplicationDetailContentState extends State<_ApplicationDetailContent> {
  late TextEditingController _notesController;
  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.app.notes);
  }

  @override
  void didUpdateWidget(covariant _ApplicationDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.app.notes != widget.app.notes && _notesController.text != widget.app.notes) {
      _notesController.text = widget.app.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'offer':
      case 'selected':
      case 'accepted':
        return const Color(0xFF10B981); // Emerald Green
      case 'interview':
      case 'shortlisted':
        return const Color(0xFFF59E0B); // Amber
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      default:
        return AppColors.primary; // Blue
    }
  }

  List<StatusHistoryItem> get _deduplicatedHistory {
    final history = widget.app.statusHistory;
    final List<StatusHistoryItem> clean = [];
    for (final item in history) {
      if (clean.isEmpty || clean.last.status.toLowerCase() != item.status.toLowerCase()) {
        clean.add(item);
      }
    }
    return clean;
  }

  Future<void> _updateStatus(String newStatus) async {
    if (newStatus.toLowerCase() == widget.app.status.toLowerCase()) return;
    await widget.ref.read(applicationRepositoryProvider).updateStatus(widget.app.id, newStatus);
    widget.ref.invalidate(applicationDetailProvider(widget.app.id));
    widget.ref.invalidate(groupedApplicationsProvider);
  }

  Future<void> _saveNotes() async {
    setState(() => _isSavingNotes = true);
    try {
      await widget.ref.read(applicationRepositoryProvider).updateApplication(
        widget.app.id,
        {'notes': _notesController.text.trim()},
      );
      widget.ref.invalidate(applicationDetailProvider(widget.app.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes updated successfully!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save notes: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingNotes = false);
    }
  }

  void _showAddReminderDialog() {
    final titleController = TextEditingController(text: '${widget.app.companyName.toUpperCase()} - Interview / Test');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.event_available_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add Application Reminder',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Reminder Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                title: const Text('Due Date'),
                subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: const Text('Change'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await widget.ref.read(deadlineRepositoryProvider).createDeadline({
                  'title': titleController.text.trim(),
                  'dueDate': selectedDate.toIso8601String(),
                  'description': 'Reminder for ${widget.app.companyName} (${widget.app.role})',
                  'category': 'Placement',
                });
                widget.ref.invalidate(deadlinesListProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reminder added to Deadlines!'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              },
              child: const Text('Add Reminder', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.app.status);
    final companyDisplay = widget.app.companyName.toUpperCase();
    final roleDisplay = widget.app.role.isEmpty ? 'Role Unspecified' : widget.app.role;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. EXECUTIVE COMPANY HEADER CARD ─────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, const Color(0xFFF1F5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Company Logo Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          companyDisplay.isNotEmpty ? companyDisplay[0] : 'C',
                          style: AppTypography.headlineMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyDisplay,
                            style: AppTypography.titleLg.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            roleDisplay,
                            style: AppTypography.bodyMd.copyWith(color: const Color(0xFF475569), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.app.status,
                            style: AppTypography.labelMd.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.app.location.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(widget.app.location, style: AppTypography.bodyMd.copyWith(color: const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 2. QUICK STATUS SWITCHER CHIPS ───────────────────
          Text('Change Application Status', style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Applied', 'Interview', 'Offer', 'Rejected'].map((status) {
                final isSelected = widget.app.status.toLowerCase() == status.toLowerCase();
                final chipColor = _getStatusColor(status);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(status),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : chipColor,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: chipColor,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSelected ? chipColor : chipColor.withOpacity(0.3)),
                    ),
                    onSelected: (_) => _updateStatus(status),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 28),

          // ─── 3. SELECTION STAGE PROGRESS STEPPER ───────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selection Stage Progress', style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildStageStepper(widget.app.status),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ─── 4. CLEAN STATUS HISTORY TIMELINE ─────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Status History Timeline',
                  style: AppTypography.titleLg.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_alarm_rounded, color: AppColors.primary),
                tooltip: 'Add Interview Reminder',
                onPressed: _showAddReminderDialog,
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _deduplicatedHistory.length; i++)
                  _TimelineItem(
                    item: _deduplicatedHistory[i],
                    isLast: i == _deduplicatedHistory.length - 1,
                    statusColor: _getStatusColor(_deduplicatedHistory[i].status),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ─── 5. INTERACTIVE NOTES & REMINDERS SECTION ──────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: const [
                          Icon(Icons.notes_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Application Notes & Prep',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      icon: _isSavingNotes
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save'),
                      onPressed: _isSavingNotes ? null : _saveNotes,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add interview prep notes, test topics, HR details...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── 6. ADD REMINDER ACTION BUTTON ─────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.alarm_add_rounded, color: AppColors.primary),
              label: const Text('Add Interview / Exam Reminder', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: _showAddReminderDialog,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStageStepper(String currentStatus) {
    final stages = ['Applied', 'Test / OA', 'Interview', 'Offer'];
    int currentIndex = 0;
    switch (currentStatus.toLowerCase()) {
      case 'interview':
      case 'shortlisted':
        currentIndex = 2;
        break;
      case 'offer':
      case 'selected':
        currentIndex = 3;
        break;
      case 'rejected':
        currentIndex = 1;
        break;
      default:
        currentIndex = 0;
    }

    return Row(
      children: List.generate(stages.length, (index) {
        final isPassed = index <= currentIndex && currentStatus.toLowerCase() != 'rejected';
        final isCurrent = index == currentIndex;
        final isRejected = currentStatus.toLowerCase() == 'rejected' && index == currentIndex;
        final stepColor = isRejected ? AppColors.error : (isPassed ? const Color(0xFF10B981) : const Color(0xFFCBD5E1));

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 3, color: index == 0 ? Colors.transparent : (index <= currentIndex ? stepColor : const Color(0xFFE2E8F0)))),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: stepColor, shape: BoxShape.circle),
                    child: Icon(
                      isRejected ? Icons.close : (isPassed ? Icons.check : Icons.circle_outlined),
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(child: Container(height: 3, color: index == stages.length - 1 ? Colors.transparent : (index < currentIndex ? stepColor : const Color(0xFFE2E8F0)))),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                stages[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? stepColor : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final StatusHistoryItem item;
  final bool isLast;
  final Color statusColor;

  const _TimelineItem({
    required this.item,
    required this.isLast,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final date = item.changedAt;
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.status,
                      style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: AppTypography.labelMd.copyWith(color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
              if (item.note != null && item.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item.note!, style: AppTypography.bodyMd.copyWith(color: const Color(0xFF64748B))),
              ],
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}
