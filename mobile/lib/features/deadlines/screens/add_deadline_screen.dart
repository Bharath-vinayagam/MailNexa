import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/deadline_repository.dart';
import 'deadline_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AddDeadlineScreen extends ConsumerStatefulWidget {
  const AddDeadlineScreen({super.key});

  @override
  ConsumerState<AddDeadlineScreen> createState() => _AddDeadlineScreenState();
}

class _AddDeadlineScreenState extends ConsumerState<AddDeadlineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _sourceController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 23, minute: 59);
  String _category = 'Placement';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _saveDeadline() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await ref.read(deadlineRepositoryProvider).createDeadline({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'source': _sourceController.text.trim(),
        'dueDate': dueDate.toIso8601String(),
        'category': _category,
      });

      ref.invalidate(deadlinesListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deadline created successfully')),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Add New Deadline'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
                  decoration: const InputDecoration(hintText: 'e.g., TCS NQT Registration'),
                ),
                const SizedBox(height: 20),

                Text('Description (Optional)', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Add extra details or portal instructions...'),
                ),
                const SizedBox(height: 20),

                Text('Source (Optional)', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sourceController,
                  decoration: const InputDecoration(hintText: 'e.g., Campus Placement Portal'),
                ),
                const SizedBox(height: 20),

                Text('Category', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: ['Placement', 'Academic', 'Personal', 'General']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _category = val!),
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 20),

                Text('Due Date & Time', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _selectedDate = date);
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (time != null) setState(() => _selectedTime = time);
                        },
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveDeadline,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Deadline'),
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
