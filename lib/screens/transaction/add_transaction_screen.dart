import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/property_provider.dart';
import '../../providers/transaction_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const AddTransactionScreen({super.key, required this.propertyId});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedPaidBy;
  DateTime _selectedDate = DateTime.now();
  File? _attachedDocument;
  String? _documentName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() {
        _attachedDocument = File(image.path);
        _documentName = image.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final transactionService = ref.read(transactionServiceProvider);
      await transactionService.createTransaction(
        propertyId: widget.propertyId,
        category: _selectedCategory!,
        amount: double.parse(_amountController.text.trim()),
        transactionDate: _selectedDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        paidBy: _selectedPaidBy,
        document: _attachedDocument,
        documentName: _documentName,
      );

      ref.invalidate(transactionsProvider(widget.propertyId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final investorsAsync = ref.watch(investorsProvider(widget.propertyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: AppConstants.userCategories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(AppConstants.categoryLabel(cat)),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value),
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),

              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Paid by dropdown
              investorsAsync.when(
                loading: () => const InputDecorator(
                  decoration: InputDecoration(labelText: 'Paid By'),
                  child: LinearProgressIndicator(),
                ),
                error: (error, _) => InputDecorator(
                  decoration: const InputDecoration(labelText: 'Paid By'),
                  child: Text(
                    'Could not load investors',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                ),
                data: (investors) {
                  final accepted =
                      investors.where((inv) => inv.isAccepted).toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedPaidBy,
                    decoration: const InputDecoration(
                      labelText: 'Paid By',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: accepted
                        .map((inv) => DropdownMenuItem(
                              value: inv.userId,
                              child: Text(inv.name),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedPaidBy = value),
                    hint: const Text('Select investor'),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Document attachment
              OutlinedButton.icon(
                onPressed: _pickDocument,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _attachedDocument != null
                      ? _documentName ?? 'Document attached'
                      : 'Attach Document (optional)',
                ),
              ),
              if (_attachedDocument != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: AppTheme.successColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _documentName ?? 'Document attached',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _attachedDocument = null;
                        _documentName = null;
                      }),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
