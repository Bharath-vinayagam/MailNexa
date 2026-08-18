import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Onboarding screen matching wireframe:
/// - Security connection visual
/// - 3 privacy guarantee cards
/// - "Allow Read-Only Access" CTA
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Logo
              const Icon(Icons.mark_email_read_rounded, size: 40, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                'MailNexa',
                style: AppTypography.titleMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 32),

              // Security visual card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // Connection visual
                    SizedBox(
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryContainer, width: 2),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 8)],
                                ),
                                child: const Icon(Icons.mail_outline_rounded, color: Colors.redAccent, size: 28),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  children: List.generate(
                                    3,
                                    (i) => Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Securely Connecting\nYour Gmail',
                      style: AppTypography.headlineMd.copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MailNexa acts as a privacy shield\nfor your academic inbox.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Privacy guarantee cards
              _PrivacyCard(
                icon: Icons.visibility_outlined,
                title: 'Smart Categorization',
                description: 'We only read emails to categorize them into academic priorities.',
              ),
              const SizedBox(height: 12),
              _PrivacyCard(
                icon: Icons.sync_alt_rounded,
                title: 'Ephemeral Storage',
                description: 'We never store full email bodies longer than needed for processing.',
              ),
              const SizedBox(height: 12),
              _PrivacyCard(
                icon: Icons.block_rounded,
                title: 'Read-Only Safety',
                description: 'We never send emails or modify your inbox on your behalf.',
              ),

              const Spacer(),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(authStateProvider.notifier).completeOnboarding(),
                  icon: const Icon(Icons.shield_outlined, size: 20),
                  label: const Text('Allow Read-Only Access'),
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Learn more about our Data Privacy Policy',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 12, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Text('AES-256 ENCRYPTED', style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
                  const SizedBox(width: 16),
                  const Icon(Icons.verified_outlined, size: 12, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Text('SOC2 COMPLIANT', style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMd),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
