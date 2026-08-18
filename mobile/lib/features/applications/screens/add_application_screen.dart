import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/application_repository.dart';
import 'applications_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AddApplicationScreen extends ConsumerStatefulWidget {
  const AddApplicationScreen({super.key});

  @override
  ConsumerState<AddApplicationScreen> createState() => _AddApplicationScreenState();
}

class _AddApplicationScreenState extends ConsumerState<AddApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'Applied';
  bool _isLoading = false;

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(applicationRepositoryProvider).createApplication({
        'companyName': _companyController.text.trim(),
        'role': _roleController.text.trim(),
        'location': _locationController.text.trim(),
        'status': _status,
        'notes': _notesController.text.trim(),
      });

      ref.invalidate(groupedApplicationsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application added successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Add New Application')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Company Name', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _companyController,
                  validator: (v) => (v == null || v.isEmpty) ? 'Company name is required' : null,
                  decoration: const InputDecoration(hintText: 'e.g., Google'),
                ),
                const SizedBox(height: 20),

                Text('Role / Position', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _roleController,
                  validator: (v) => (v == null || v.isEmpty) ? 'Role is required' : null,
                  decoration: const InputDecoration(hintText: 'e.g., Software Engineer Intern'),
                ),
                const SizedBox(height: 20),

                Text('Location (Optional)', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(hintText: 'e.g., Mountain View, CA or Remote'),
                ),
                const SizedBox(height: 20),

                Text('Initial Status', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _status,
                  items: ['Applied', 'Interview', 'Offer', 'Rejected']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => _status = val!),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 20),

                Text('Notes (Optional)', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Referral details, application link, etc...'),
                ),
                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveApplication,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Application'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
