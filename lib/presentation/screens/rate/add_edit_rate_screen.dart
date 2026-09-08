import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import '../../../data/models/rate_models.dart';
import '../../../data/models/dropdown_models.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/rate_provider.dart';
import '../../../presentation/providers/master_data_provider.dart';

class AddEditRateScreen extends ConsumerStatefulWidget {
  final String hubCode;
  final Rate? rate;
  const AddEditRateScreen({super.key, required this.hubCode, this.rate});

  @override
  ConsumerState<AddEditRateScreen> createState() => _AddEditRateScreenState();
}

class _AddEditRateScreenState extends ConsumerState<AddEditRateScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCropCategoryCode;
  String? _selectedCropCode;
  String? _selectedPackagingTypeCode;
  String? _selectedUnitCode;
  String? _amount;
  DateTime? _appliesFrom;

  @override
  void initState() {
    super.initState();
    if (widget.rate != null) {
      _selectedCropCode = widget.rate!.cropCode;
      _selectedPackagingTypeCode = widget.rate!.packagingTypeCode;
      _selectedUnitCode = widget.rate!.unitCode;
      _amount = widget.rate!.amount;
      _appliesFrom = widget.rate!.appliesFrom != null
          ? DateFormat('yyyy-MM-dd').parse(widget.rate!.appliesFrom!)
          : null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _appliesFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _appliesFrom = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isEditing = widget.rate != null;
    final hubCode = int.tryParse(widget.hubCode) ?? 0;

    final masterDataAsync = ref.watch(masterDataProvider(widget.hubCode));

    final isVerySmall = Responsive.isVerySmallScreen(context);
    final padding = Responsive.getResponsivePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Rate' : 'Add Rate')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: masterDataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
            data: (masterData) {
              // If editing, auto-select the crop category from the selected crop
              if (isEditing && _selectedCropCode != null && _selectedCropCategoryCode == null) {
                final crop = masterData.crops.firstWhere(
                  (c) => c.code == _selectedCropCode,
                  orElse: () => Crop(code: '', name: '', categoryCode: ''),
                );
                if (crop.code.isNotEmpty) {
                  _selectedCropCategoryCode = crop.categoryCode;
                }
              }

              final filteredCrops = masterData.crops
                  .where((c) => c.categoryCode == _selectedCropCategoryCode)
                  .toList();

              return Column(
                children: [
                  // Crop Category dropdown (disabled when editing)
                  IgnorePointer(
                    ignoring: isEditing,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCropCategoryCode,
                      hint: const Text('Select Crop Category'),
                      items: masterData.cropCategories.map((c) {
                        return DropdownMenuItem(
                          value: c.code,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCropCategoryCode = val;
                          _selectedCropCode = null;
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                      decoration: InputDecoration(
                        labelText: 'Crop Category',
                        filled: isEditing,
                        fillColor: isEditing ? Colors.grey.shade100 : null,
                        isDense: true,
                        contentPadding: isVerySmall
                            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: isVerySmall ? 8 : 12),

                  // Crop dropdown (only if category selected, disabled when editing)
                  if (_selectedCropCategoryCode != null)
                    Column(
                      children: [
                        IgnorePointer(
                          ignoring: isEditing,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCropCode,
                            hint: const Text('Select Crop'),
                            items: filteredCrops.map((c) {
                              return DropdownMenuItem(
                                value: c.code,
                                child: Text(c.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCropCode = val;
                              });
                            },
                            validator: (v) => v == null ? 'Required' : null,
                            decoration: InputDecoration(
                              labelText: 'Crop',
                              filled: isEditing,
                              fillColor: isEditing ? Colors.grey.shade100 : null,
                              isDense: true,
                              contentPadding: isVerySmall
                                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(height: isVerySmall ? 8 : 12),
                      ],
                    ),

                  // Packaging Type dropdown (disabled when editing)
                  IgnorePointer(
                    ignoring: isEditing,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPackagingTypeCode,
                      hint: const Text('Select Packaging Type'),
                      items: masterData.packagingTypes.map((p) {
                        return DropdownMenuItem(
                          value: p.code,
                          child: Text(p.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPackagingTypeCode = val;
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                      decoration: InputDecoration(
                        labelText: 'Packaging Type',
                        filled: isEditing,
                        fillColor: isEditing ? Colors.grey.shade100 : null,
                        isDense: true,
                        contentPadding: isVerySmall
                            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: isVerySmall ? 8 : 12),

                  // Unit dropdown (always editable)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnitCode,
                    hint: const Text('Select Unit'),
                    items: masterData.units.map((u) {
                      return DropdownMenuItem(
                        value: u.code,
                        child: Text(u.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedUnitCode = val);
                    },
                    validator: (v) => v == null ? 'Required' : null,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      isDense: true,
                      contentPadding: isVerySmall
                          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                          : null,
                    ),
                  ),
                  SizedBox(height: isVerySmall ? 8 : 12),

                  // Amount per Unit field (editable)
                  TextFormField(
                    initialValue: _amount,
                    decoration: InputDecoration(
                      labelText: 'Amount per Unit (₹)',
                      isDense: true,
                      contentPadding: isVerySmall
                          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _amount = val,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: isVerySmall ? 8 : 12),

                  // Applies From date picker (editable)
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Applies From',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: isVerySmall
                            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                            : null,
                      ),
                      child: Text(
                        _appliesFrom == null
                            ? 'Select Date'
                            : DateFormat('yyyy-MM-dd').format(_appliesFrom!),
                      ),
                    ),
                  ),
                  SizedBox(height: isVerySmall ? 16 : 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      if (_appliesFrom == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select Applies From date')),
                        );
                        return;
                      }
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User not logged in')),
                        );
                        return;
                      }

                      final payload = <String, String>{
                        'hubCode': hubCode.toString(),
                        'cropCode': _selectedCropCode!,
                        'packagingTypeCode': _selectedPackagingTypeCode!,
                        'quantity': '1', // Hardcoded base unit quantity for API DTO compliance
                        'unitCode': _selectedUnitCode!,
                        'amount': _amount!,
                        'appliesFrom': DateFormat('yyyy-MM-dd').format(_appliesFrom!),
                        'userCode': user.userCode.toString(),
                      };

                      if (isEditing) {
                        payload['rateCode'] = widget.rate!.rateCode!;
                      }

                      final notifier = ref.read(addRateNotifierProvider.notifier);
                      if (isEditing) {
                        await notifier.updateRate(payload);
                      } else {
                        await notifier.addRate(payload);
                      }

                      ref.refresh(masterDataProvider(widget.hubCode));
                      ref.refresh(ratesListProvider(widget.hubCode));

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rate saved successfully')),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isVerySmall ? 10 : 14,
                      ),
                    ),
                    child: Text(isEditing ? 'Update' : 'Add'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}