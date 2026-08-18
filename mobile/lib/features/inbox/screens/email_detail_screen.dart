import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/email_model.dart';
import '../repositories/email_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../notifications/services/fcm_service.dart';
import '../../deadlines/repositories/deadline_repository.dart';
import '../../deadlines/screens/deadline_screen.dart';

final emailDetailProvider = FutureProvider.family<EmailModel, String>((ref, id) async {
  final repo = ref.watch(emailRepositoryProvider);
  return repo.getEmailById(id);
});

/// Email detail screen with Event Timeline, Attachment scanning, AI Reasoning, and Reminder Alarm trigger.
class EmailDetailScreen extends ConsumerWidget {
  final String emailId;
  const EmailDetailScreen({super.key, required this.emailId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailAsync = ref.watch(emailDetailProvider(emailId));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Email Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showCategoryOverrideSheet(context, ref),
          ),
        ],
      ),
      body: emailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading email: $err', style: TextStyle(color: cs.error))),
        data: (email) => _EmailDetailContent(email: email),
      ),
    );
  }

  void _showCategoryOverrideSheet(BuildContext context, WidgetRef ref) {
    final email = ref.read(emailDetailProvider(emailId)).value;
    if (email == null) return;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change Category / Priority', style: AppTypography.titleLg.copyWith(color: cs.onSurface)),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.category_outlined, color: cs.primary),
                title: Text('Category', style: TextStyle(color: cs.onSurface)),
                subtitle: Text('Current: ${email.category}', style: TextStyle(color: cs.onSurfaceVariant)),
                trailing: DropdownButton<String>(
                  value: email.category,
                  dropdownColor: cs.surfaceContainerLow,
                  items: ['Placement', 'Academic', 'Personal', 'Promotions', 'Others']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: cs.onSurface))))
                      .toList(),
                  onChanged: (newCat) async {
                    if (newCat != null) {
                      Navigator.pop(context);
                      await ref.read(emailRepositoryProvider).changeCategory(emailId, category: newCat);
                      ref.invalidate(emailDetailProvider(emailId));
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.secondary),
                title: Text('Priority', style: TextStyle(color: cs.onSurface)),
                subtitle: Text('Current: ${email.priority}', style: TextStyle(color: cs.onSurfaceVariant)),
                trailing: DropdownButton<String>(
                  value: email.priority,
                  dropdownColor: cs.surfaceContainerLow,
                  items: ['High', 'Medium', 'Low']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: cs.onSurface))))
                      .toList(),
                  onChanged: (newPrio) async {
                    if (newPrio != null) {
                      Navigator.pop(context);
                      await ref.read(emailRepositoryProvider).changeCategory(emailId, priority: newPrio);
                      ref.invalidate(emailDetailProvider(emailId));
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmailDetailContent extends ConsumerWidget {
  final EmailModel email;
  const _EmailDetailContent({required this.email});

  String _cleanText(String input) {
    return input
        .replaceAll(RegExp(r"^['&quot;\s]+|['&quot;\s]+$"), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  Color _eventTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PPT':
        return const Color(0xFF7C3AED); // Purple
      case 'TEST':
        return const Color(0xFFEC4899); // Pink / Magenta
      case 'INTERVIEW':
        return const Color(0xFF2563EB); // Royal Blue
      case 'DEADLINE':
        return const Color(0xFFD97706); // Amber
      default:
        return const Color(0xFF0EA5E9); // Cyan
    }
  }

  String _cleanSummaryText(String rawText) {
    if (rawText.isEmpty) return '';
    var text = rawText
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1')
        .replaceAll('*', '')
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true), '')
        .trim();

    final lines = text.split('\n').map((l) {
      var trimmed = l.trim();
      if (trimmed.isEmpty) return '';
      trimmed = trimmed.replaceAll(RegExp(r'^[•\-\*\s]+'), '').trim();
      if (trimmed.isEmpty) return '';
      return '• $trimmed';
    }).where((l) => l.isNotEmpty).toList();

    return lines.join('\n\n');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final cleanSender = _cleanText(email.sender);
    final cleanSubject = _cleanText(email.subject);
    final cleanBody = _cleanText(email.body);

    String displayInitial = '?';
    final letters = cleanSender.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (letters.isNotEmpty) {
      displayInitial = letters[0].toUpperCase();
    }

    final rawSummary = (email.autoSummary != null && email.autoSummary!.isNotEmpty)
        ? email.autoSummary!
        : (email.aiReasoning != null && email.aiReasoning!.isNotEmpty && !email.aiReasoning!.toLowerCase().contains('fallback'))
            ? email.aiReasoning!
            : '${cleanSubject}\n${email.snippet}';
    final formattedSummary = _cleanSummaryText(rawSummary);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── SHORTLISTED BANNER ────────────────────────
          if (email.isShortlisted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFEA580C)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONFIRMED SHORTLIST',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your Reg No / Name was verified in the official shortlisted student record.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ─── Subject Title ───────────────────────────
          Text(
            cleanSubject,
            style: AppTypography.headlineMd.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 12),

          // ─── Sender Row ──────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  displayInitial,
                  style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanSender,
                      style: AppTypography.titleMd.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email.senderEmail,
                      style: AppTypography.bodyMd.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${email.receivedAt.day}/${email.receivedAt.month}/${email.receivedAt.year}',
                style: AppTypography.labelMd.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── PRIMARY VIEW: EXECUTIVE AI SUMMARY CARD ─────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Executive Summary',
                        style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('AI Digest', style: TextStyle(color: cs.primary, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  formattedSummary,
                  style: TextStyle(color: cs.onSurface, fontSize: 13.5, height: 1.65, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── ASK AI CUSTOM SUMMARIZER SECTION ─────────────────────
          _CustomSummarizerSection(email: email),
          const SizedBox(height: 20),

          // ─── AI CLASSIFICATION BADGES ───────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                _Badge(label: email.category, color: cs.primaryContainer, textColor: cs.onPrimaryContainer),
                const SizedBox(width: 8),
                _Badge(
                  label: '${email.priority} Priority',
                  color: email.isHighPriority ? AppColors.secondaryContainer : cs.surfaceContainerHigh,
                  textColor: email.isHighPriority ? AppColors.onSecondaryContainer : cs.onSurfaceVariant,
                ),
                const Spacer(),
                Text(
                  '${(email.aiConfidence * 100).toStringAsFixed(0)}% AI Match',
                  style: AppTypography.labelMd.copyWith(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── EVENT TIMELINE SECTION ──────────────────
          if (email.events.isNotEmpty) ...[
            Text('Event Schedule & Timeline', style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: email.events.map((ev) {
                  final title = ev['title'] as String? ?? 'Event';
                  final type = ev['type'] as String? ?? 'EVENT';
                  final rawDate = ev['date'] as String? ?? '';
                  final parsedDate = DateTime.tryParse(rawDate);
                  final displayDate = parsedDate != null
                      ? '${parsedDate.day}/${parsedDate.month}/${parsedDate.year} at ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}'
                      : rawDate;
                  final badgeColor = _eventTypeColor(type);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(left: BorderSide(color: badgeColor, width: 4)),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      type.toUpperCase(),
                                      style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800, fontSize: 10),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 14, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(displayDate, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),
                         Row(
                           children: [
                             IconButton(
                               padding: EdgeInsets.zero,
                               constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                               iconSize: 20,
                               tooltip: 'Add to My Deadlines',
                               icon: const Icon(Icons.add_task_rounded, color: Color(0xFFD97706)),
                               onPressed: () async {
                                 try {
                                   final repo = ref.read(deadlineRepositoryProvider);
                                   await repo.createDeadline({
                                     'title': '[${type.toUpperCase()}] $title',
                                     'dueDate': parsedDate?.toIso8601String() ?? DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                                     'source': cleanSender,
                                     'category': email.category,
                                     'emailId': email.id,
                                   });
                                   ref.invalidate(deadlinesListProvider);
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                       content: Text('Added "$title" to your Deadlines session! 📅'),
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
                             ),
                             IconButton(
                               padding: EdgeInsets.zero,
                               constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                               iconSize: 20,
                               tooltip: 'Set Alarm / Reminder',
                               icon: Icon(Icons.alarm_add_rounded, color: cs.primary),
                               onPressed: () async {
                                 await FcmService.showNotification(
                                   title: '⏰ Reminder Set: $type',
                                   body: '$title scheduled for $displayDate',
                                 );
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                     content: Text('Reminder set for $title ($displayDate)'),
                                     behavior: SnackBarBehavior.floating,
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                   ),
                                 );
                               },
                             ),
                           ],
                         ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ─── ATTACHMENTS SECTION ─────────────────────
          if (email.attachments.isNotEmpty) ...[
            Text('Attachments (${email.attachments.length})', style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: email.attachments.map((att) {
                  final filename = att['filename'] as String? ?? 'Attachment';
                  final size = att['size'] as num? ?? 0;
                  final sizeKb = (size / 1024).toStringAsFixed(1);
                  final isExcel = filename.endsWith('.xlsx') || filename.endsWith('.xls') || filename.endsWith('.csv');
                  final isPdf = filename.endsWith('.pdf');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExcel ? Icons.table_chart_rounded : isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                          color: isExcel ? const Color(0xFF107C41) : isPdf ? const Color(0xFFE11D48) : cs.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(filename, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                              Text('$sizeKb KB', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (email.isShortlisted && isExcel) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Scanned', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ─── Deadline Banner ────────────────────────
          if (email.deadline != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondary, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, color: AppColors.secondary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Extracted Deadline', style: AppTypography.titleMd.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w800)),
                        Text(
                          email.deadlineDescription ?? email.deadline!.toLocal().toString().split(' ').first,
                          style: AppTypography.bodyMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.alarm_add_rounded, color: AppColors.secondary),
                    onPressed: () async {
                      await FcmService.showNotification(
                        title: '⏰ Deadline Reminder',
                        body: 'Deadline for ${email.subject}',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Deadline alarm reminder set!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ─── COLLAPSIBLE FULL RAW EMAIL BODY ─────────────
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Icon(Icons.article_outlined, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'View Original Raw Email Body',
                      style: AppTypography.bodyMd.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Text(
                    cleanBody,
                    style: AppTypography.bodyMd.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w400,
                      fontSize: 13.5,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Action Buttons ─────────────────────────
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: email.isApplied
                      ? null
                      : () async {
                          await ref.read(emailRepositoryProvider).markApplied(email.id);
                          ref.invalidate(emailDetailProvider(email.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Marked as Applied! Application tracked.')),
                          );
                        },
                  icon: Icon(email.isApplied ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded),
                  label: Text(email.isApplied ? 'Application Tracked' : 'Mark as Applied'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const _Badge({required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: AppTypography.labelMd.copyWith(color: textColor ?? Colors.white),
      ),
    );
  }
}

class _CustomSummarizerSection extends ConsumerStatefulWidget {
  final EmailModel email;
  const _CustomSummarizerSection({required this.email});

  @override
  ConsumerState<_CustomSummarizerSection> createState() => _CustomSummarizerSectionState();
}

class _CustomSummarizerSectionState extends ConsumerState<_CustomSummarizerSection> {
  bool _isLoading = false;
  String? _customSummary;
  final _promptController = TextEditingController();

  Future<void> _generateSummary([String? presetPrompt]) async {
    final prompt = presetPrompt ?? _promptController.text.trim();
    setState(() { _isLoading = true; });
    try {
      final summary = await ref.read(emailRepositoryProvider).summarizeEmail(
        widget.email.id,
        customPrompt: prompt.isNotEmpty ? prompt : null,
      );
      if (mounted) {
        setState(() {
          _customSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        final isRateLimit = e.toString().contains('429');
        final errorMsg = isRateLimit
            ? '⚡ Google Gemini rate limit reached. Please wait ~10 seconds and try again.'
            : 'Could not generate summary. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: cs.primary, size: 22),
              const SizedBox(width: 8),
              Text('Ask AI Custom Summary', style: AppTypography.titleMd.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (_isLoading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _promptController,
            style: TextStyle(color: cs.onSurface, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Ask prompt e.g. "What are test topics & deadline?"',
              filled: true,
              fillColor: cs.surfaceContainer,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded, size: 18),
                color: cs.primary,
                onPressed: _isLoading ? null : () => _generateSummary(),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _generateSummary(),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: const Text('⚡ Action Items', style: TextStyle(fontSize: 10.5)),
                  onPressed: () => _generateSummary('Summarize key action items and next steps'),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: const Text('🎯 Test & Eligibility', style: TextStyle(fontSize: 10.5)),
                  onPressed: () => _generateSummary('Summarize test dates, duration, topics, and eligibility'),
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: const Text('💰 Package / CTC', style: TextStyle(fontSize: 10.5)),
                  onPressed: () => _generateSummary('What is the salary, stipend, or package mentioned?'),
                ),
              ],
            ),
          ),
          if (_customSummary != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                _customSummary!,
                style: TextStyle(color: cs.onSurface, fontSize: 13, height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
