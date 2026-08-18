import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../main.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/router/app_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _showEditDialog(BuildContext context, WidgetRef ref, String label, String currentValue, String field) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Text('Edit $label', style: AppTypography.titleMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This value is used to scan placement shortlist files.', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'Enter $label',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(authStateProvider.notifier).updateProfile({field: newValue});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label updated to $newValue ✅'), backgroundColor: AppColors.primary),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCustomPromptDialog(BuildContext context, WidgetRef ref, String? currentPrompt) {
    final controller = TextEditingController(text: currentPrompt ?? 'Summarize email highlighting placement action items, test links, shortlist status, deadlines, and mandatory next steps.');
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: cs.surfaceContainerLow,
        title: Row(
          children: [
            Icon(Icons.psychology_outlined, color: cs.primary, size: 24),
            const SizedBox(width: 10),
            Text('Custom AI Prompt', style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w800)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tell Gemini AI how you want your incoming emails summarized:', style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                style: TextStyle(color: cs.onSurface, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'e.g. Focus on test dates, CTC, and mandatory action items...',
                  filled: true,
                  fillColor: cs.surfaceContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              Text('Quick Presets:', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('🚀 Placement & Action Items', style: TextStyle(fontSize: 11)),
                    onPressed: () => controller.text = 'Summarize email highlighting placement action items, test links, shortlist status, deadlines, and mandatory next steps.',
                  ),
                  ActionChip(
                    label: const Text('⚡ Interview & Dates Focus', style: TextStyle(fontSize: 11)),
                    onPressed: () => controller.text = 'Focus on interview dates, test platform link, duration, eligibility criteria, and required documents.',
                  ),
                  ActionChip(
                    label: const Text('🎯 3 Bullet Briefing', style: TextStyle(fontSize: 11)),
                    onPressed: () => controller.text = 'Summarize in exactly 3 bullet points: 1) Email core topic, 2) Key dates/deadlines, 3) Action required from me.',
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrompt = controller.text.trim();
              if (newPrompt.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(authStateProvider.notifier).updateProfile({'customAiPrompt': newPrompt});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom AI Summarizer Prompt saved! 🤖✨')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save prompt: $e')),
                );
              }
            },
            child: const Text('Save Prompt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final user = authState.user;
    final cs = Theme.of(context).colorScheme;

    // Helper: card decoration
    BoxDecoration cardDeco() => BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: cs.outlineVariant, width: 1),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant, width: 1),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: user?.picture != null ? NetworkImage(user!.picture!) : null,
                  child: user?.picture == null
                      ? Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                          style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 22),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Student', style: AppTypography.titleLg.copyWith(color: cs.onSurface)),
                      Text(user?.email ?? '', style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (user?.role ?? 'user').toUpperCase(),
                          style: AppTypography.labelMd.copyWith(color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Placement & Shortlist Identifiers section
          Text('Placement & Shortlist Identifiers', style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          Container(
            decoration: cardDeco(),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: cs.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.badge_outlined, color: cs.primary, size: 20),
                  ),
                  title: Text('Registration Number', style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
                  subtitle: Text('Used for Excel & PDF shortlist scanning', style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          (user?.registrationNumber != null && user!.registrationNumber.isNotEmpty) ? user!.registrationNumber : 'Not Set',
                          style: AppTypography.labelMd.copyWith(color: cs.primary, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_outlined, size: 18, color: cs.primary),
                    ],
                  ),
                  onTap: () => _showEditDialog(context, ref, 'Registration Number', user?.registrationNumber ?? '', 'registrationNumber'),
                ),
                Divider(height: 1, color: cs.outlineVariant),
                ListTile(
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: cs.tertiary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.fingerprint_rounded, color: cs.tertiary, size: 20),
                  ),
                  title: Text('NeoPAT / Campus ID', style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
                  subtitle: Text('Scanned in all placement attachment files', style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: cs.tertiary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          (user?.neoPatId != null && user!.neoPatId.isNotEmpty) ? user!.neoPatId : 'Not Set',
                          style: AppTypography.labelMd.copyWith(color: cs.tertiary, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_outlined, size: 18, color: cs.tertiary),
                    ],
                  ),
                  onTap: () => _showEditDialog(context, ref, 'NeoPAT / Campus ID', user?.neoPatId ?? '', 'neoPatId'),
                ),
                Divider(height: 1, color: cs.outlineVariant),
                ListTile(
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: cs.secondary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.person_outline_rounded, color: cs.secondary, size: 20),
                  ),
                  title: Text('Full Name (for scanning)', style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
                  subtitle: Text('First name matched in shortlist files', style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: cs.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      user?.name ?? 'Vinayagam Bharath',
                      style: AppTypography.labelMd.copyWith(color: cs.secondary, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Preferences section
          Text('Preferences', style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          Container(
            decoration: cardDeco(),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Dark Theme', style: AppTypography.titleMd.copyWith(color: cs.onSurface)),
                  value: themeMode == ThemeMode.dark,
                  activeColor: cs.primary,
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
                Divider(height: 1, color: cs.outlineVariant),
                ListTile(
                  leading: Icon(Icons.psychology_outlined, color: cs.secondary),
                  title: Text('Custom AI Summarizer Prompt', style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
                  subtitle: Text('Configure how Gemini AI summarizes your emails', style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant, fontSize: 12)),
                  trailing: Icon(Icons.edit_outlined, size: 18, color: cs.secondary),
                  onTap: () => _showCustomPromptDialog(context, ref, user?.customAiPrompt),
                ),
                Divider(height: 1, color: cs.outlineVariant),
                ListTile(
                  leading: Icon(Icons.notifications_active_outlined, color: cs.primary),
                  title: Text('Notification Preferences', style: AppTypography.titleMd.copyWith(color: cs.onSurface)),
                  subtitle: Text('Configure high priority alerts and deadline reminders', style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant, fontSize: 12)),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: cs.onSurfaceVariant),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Security & About
          Text('Security & Privacy', style: AppTypography.titleMd.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),

          Container(
            decoration: cardDeco(),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.shield_outlined, color: cs.primary),
                  title: Text('Encryption Status', style: AppTypography.titleMd.copyWith(color: cs.onSurface)),
                  subtitle: Text('AES-256 Enabled', style: AppTypography.bodyMd.copyWith(color: cs.onSurfaceVariant, fontSize: 12)),
                ),
                Divider(height: 1, color: cs.outlineVariant),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: cs.primary),
                  title: Text('Data Privacy Policy', style: AppTypography.titleMd.copyWith(color: cs.onSurface)),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: cs.onSurfaceVariant),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go(Routes.signIn);
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
