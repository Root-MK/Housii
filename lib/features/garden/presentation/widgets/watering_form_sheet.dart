import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/models/garden_bed_model.dart';
import '../../data/models/watering_log_model.dart';
import '../../data/water_index_service.dart';

/// Bottom sheet for adding a watering event to a garden bed.
class WateringFormSheet extends ConsumerStatefulWidget {
  final GardenBed bed;
  final DateTime? initialDate;

  const WateringFormSheet({
    super.key,
    required this.bed,
    this.initialDate,
  });

  @override
  ConsumerState<WateringFormSheet> createState() => _WateringFormSheetState();
}

class _WateringFormSheetState extends ConsumerState<WateringFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late DateTime _selectedDate;
  bool _inputInLiters = false; // Toggle between mm and liters
  final _notesController = TextEditingController();
  bool _isSaving = false;
  String? _editingLogId; // If set, we are editing this log

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _amountController.text = '10'; // Default to 10mm
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _bedAreaM2 => (widget.bed.width / 100) * (widget.bed.height / 100);

  double get _amountMm {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (_inputInLiters) {
      // Convert liters to mm: liters / area = mm
      return amount / _bedAreaM2;
    }
    return amount;
  }

  double get _amountLiters {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (_inputInLiters) {
      return amount;
    }
    // Convert mm to liters: mm * area = liters
    return amount * _bedAreaM2;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final homeState = ref.read(currentHomeProvider);
    final home = homeState.value;
    if (home == null) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(waterIndexServiceProvider);

      if (_editingLogId != null) {
        // Update existing log
        // We need to fetch the original log to copyWith, or just create a new object with same ID
        // Since we don't have the original object handy here easily without fetching, 
        // and we are replacing all fields anyway, we can just create a new one with the ID.
        // But WateringLog.create generates ID. We need a constructor that takes ID.
        // WateringLog const constructor takes ID.
        
        final log = WateringLog(
          id: _editingLogId!,
          homeId: home.id,
          bedId: widget.bed.id,
          date: _selectedDate,
          amountMm: _amountMm,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          createdAt: DateTime.now(), // Keep original? Ideally yes, but for now update is fine.
        );
        await service.addWateringLog(log); // set() overwrites
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vanding opdateret'), backgroundColor: Colors.green),
          );
          _resetForm();
        }
      } else {
        // Create new log
        final log = WateringLog.create(
          homeId: home.id,
          bedId: widget.bed.id,
          amountMm: _amountMm,
          date: _selectedDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
        await service.addWateringLog(log);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vanding registreret: ${_amountMm.toStringAsFixed(1)} mm'),
              backgroundColor: Colors.green,
            ),
          );
          // Don't pop, just reset so they can add more or see history
          _resetForm();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fejl: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    setState(() {
      _editingLogId = null;
      _amountController.text = '10';
      _notesController.clear();
      _selectedDate = DateTime.now();
      // Keep unit preference
    });
  }

  void _editLog(WateringLog log) {
    setState(() {
      _editingLogId = log.id;
      _selectedDate = log.date;
      _notesController.text = log.notes ?? '';
      
      if (_inputInLiters) {
        _amountController.text = log.toLiters(widget.bed.width, widget.bed.height).toStringAsFixed(1);
      } else {
        _amountController.text = log.amountMm.toStringAsFixed(1);
      }
    });
  }

  Future<void> _deleteLog(WateringLog log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet vanding?'),
        content: const Text('Er du sikker på, at du vil slette denne registrering?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuller')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Slet', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = ref.read(waterIndexServiceProvider);
        await service.deleteWateringLog(log.homeId, log.id);
        if (mounted && _editingLogId == log.id) {
          _resetForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fejl ved sletning: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _setQuickAmount(double mm) {
    setState(() {
      if (_inputInLiters) {
        // Convert to liters
        _amountController.text = (mm * _bedAreaM2).toStringAsFixed(1);
      } else {
        _amountController.text = mm.toStringAsFixed(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(currentHomeProvider);
    final home = homeState.value;
    final logsAsync = home != null 
        ? ref.watch(bedWateringLogsProvider((homeId: home.id, bedId: widget.bed.id)))
        : const AsyncValue.loading();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      height: MediaQuery.of(context).size.height * 0.85, // Fixed height for scrolling
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(
            children: [
              const Icon(Icons.water_drop, color: Colors.blue, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _editingLogId != null ? 'Rediger vanding' : 'Vand ${widget.bed.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${widget.bed.width.toInt()} × ${widget.bed.height.toInt()} cm = ${_bedAreaM2.toStringAsFixed(2)} m²',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          const Divider(height: AppSpacing.lg),

          // Scrollable content
          Expanded(
            child: ListView(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Quick amounts
                      Text(
                        'Hurtig vanding',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          _QuickButton(label: '5 mm', onTap: () => _setQuickAmount(5)),
                          _QuickButton(label: '10 mm', onTap: () => _setQuickAmount(10)),
                          _QuickButton(label: '15 mm', onTap: () => _setQuickAmount(15)),
                          _QuickButton(label: '20 mm', onTap: () => _setQuickAmount(20)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Amount input with unit toggle
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Mængde',
                                suffixText: _inputInLiters ? 'liter' : 'mm',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Indtast mængde';
                                }
                                final num = double.tryParse(value);
                                if (num == null || num <= 0) {
                                  return 'Indtast gyldigt tal';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(value: false, label: Text('mm')),
                                ButtonSegment(value: true, label: Text('L')),
                              ],
                              selected: {_inputInLiters},
                              onSelectionChanged: (selected) {
                                // Convert current value when switching units
                                final currentAmount = double.tryParse(_amountController.text) ?? 0;
                                setState(() {
                                  _inputInLiters = selected.first;
                                  if (_inputInLiters) {
                                    // Was mm, now liters
                                    _amountController.text = (currentAmount * _bedAreaM2).toStringAsFixed(1);
                                  } else {
                                    // Was liters, now mm
                                    _amountController.text = (currentAmount / _bedAreaM2).toStringAsFixed(1);
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Show conversion
                      Text(
                        _inputInLiters
                            ? '= ${_amountMm.toStringAsFixed(1)} mm vandstand'
                            : '= ${_amountLiters.toStringAsFixed(1)} liter vand',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Date picker
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                            locale: const Locale('da', 'DK'),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Dato',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('EEEE, d. MMMM yyyy', 'da_DK').format(_selectedDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Notes (optional)
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Noter (valgfrit)',
                          border: OutlineInputBorder(),
                          hintText: 'F.eks. morgen, drypvanding...',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Save button
                      Row(
                        children: [
                          if (_editingLogId != null)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _resetForm,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                ),
                                child: const Text('Annuller'),
                              ),
                            ),
                          if (_editingLogId != null) const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _save,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Icon(_editingLogId != null ? Icons.save : Icons.water_drop),
                              label: Text(_isSaving 
                                  ? 'Gemmer...' 
                                  : (_editingLogId != null ? 'Opdater vanding' : 'Registrer vanding')),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                
                // History List
                Text(
                  'Seneste vandinger',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                logsAsync.when(
                  data: (logs) {
                    if (logs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Ingen vandinger registreret endnu.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final liters = log.toLiters(widget.bed.width, widget.bed.height);
                        final isEditing = log.id == _editingLogId;
                        
                        return Container(
                          color: isEditing ? Colors.blue.withOpacity(0.1) : null,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 16,
                              child: Icon(Icons.water_drop, color: Colors.white, size: 16),
                            ),
                            title: Text(
                              '${log.amountMm.toStringAsFixed(1)} mm (${liters.toStringAsFixed(1)} L)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('d. MMM yyyy', 'da_DK').format(log.date)),
                                if (log.notes != null && log.notes!.isNotEmpty)
                                  Text(
                                    log.notes!,
                                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Rediger'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Slet', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editLog(log);
                                } else if (value == 'delete') {
                                  _deleteLog(log);
                                }
                              },
                            ),
                            onTap: () => _editLog(log),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Fejl: $e', style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.blue.shade50,
      labelStyle: TextStyle(color: Colors.blue.shade700),
    );
  }
}
