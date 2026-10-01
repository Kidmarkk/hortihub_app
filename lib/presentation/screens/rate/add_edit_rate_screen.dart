import 'package:flutter/services.dart';
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
  String? _quantity;

  @override
  void initState() {
    super.initState();
    if (widget.rate != null) {
      _selectedCropCode = widget.rate!.cropCode;
      _selectedPackagingTypeCode = widget.rate!.packagingTypeCode;
      _quantity = widget.rate!.quantity;
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
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C))),
            error: (err, _) => Text('Error: $err'),
            data: (masterData) {
              // If editing, auto-select the crop category from the selected crop
              if (isEditing &&
                  _selectedCropCode != null &&
                  _selectedCropCategoryCode == null) {
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
                  // ✅ Crop Category – searchable
                  _SearchableDropdown(
                    label: 'Crop Category',
                    value: _selectedCropCategoryCode,
                    enabled: !isEditing,
                    options: masterData.cropCategories
                        .map((c) => MapEntry(c.code, c.name))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCropCategoryCode = val;
                        _selectedCropCode = null;
                      });
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  SizedBox(height: isVerySmall ? 8 : 12),

                  // ✅ Crop – searchable
                  if (_selectedCropCategoryCode != null) ...[
                    _SearchableDropdown(
                      label: 'Crop',
                      value: _selectedCropCode,
                      enabled: !isEditing,
                      options: filteredCrops
                          .map((c) => MapEntry(c.code, c.name))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedCropCode = val);
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    SizedBox(height: isVerySmall ? 8 : 12),
                  ],

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
                            ? const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              )
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
                          ? const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: isVerySmall ? 8 : 12),

                  // ✅ NEW: Quantity per Package (decimal allowed)
                  TextFormField(
                    initialValue: _quantity,
                    decoration: InputDecoration(
                      labelText: 'Quantity per Package',
                      hintText: 'e.g., 0.50',
                      helperText:
                          'Amount of crop in one package (e.g., 0.50 KG per MINI bag)',
                      helperMaxLines: 2,
                      isDense: true,
                      contentPadding: isVerySmall
                          ? const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            )
                          : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (val) => _quantity = val,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null)
                        return 'Enter a valid number (e.g., 0.50)';
                      return null;
                    },
                  ),
                  SizedBox(height: isVerySmall ? 8 : 12),

                  // Amount per Unit field (editable)
                  TextFormField(
                    initialValue: _amount,
                    decoration: InputDecoration(
                      labelText: 'Amount per Unit (₹)',
                      isDense: true,
                      contentPadding: isVerySmall
                          ? const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _amount = val,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
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
                            ? const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              )
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
                          const SnackBar(
                            content: Text('Please select Applies From date'),
                          ),
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
                        'quantity': _quantity!,
                        'unitCode': _selectedUnitCode!,
                        'amount': _amount!,
                        'appliesFrom': DateFormat(
                          'yyyy-MM-dd',
                        ).format(_appliesFrom!),
                        'userCode': user.userCode.toString(),
                      };

                      if (isEditing) {
                        payload['rateCode'] = widget.rate!.rateCode!;
                      }

                      final notifier = ref.read(
                        addRateNotifierProvider.notifier,
                      );
                      if (isEditing) {
                        await notifier.updateRate(payload);
                      } else {
                        await notifier.addRate(payload);
                      }

                      ref.refresh(masterDataProvider(widget.hubCode));
                      ref.refresh(ratesListProvider(widget.hubCode));

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rate saved successfully'),
                          ),
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

class _SearchableDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final List<MapEntry<String, String>> options; // (code, name)
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String? Function(String?)? validator;

  const _SearchableDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
    this.validator,
  });

  @override
  State<_SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<_SearchableDropdown> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayText());
  }

  @override
  void didUpdateWidget(covariant _SearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _displayText();
    }
  }

  String _displayText() {
    if (widget.value == null) return '';
    final match = widget.options.where((o) => o.key == widget.value).toList();
    return match.isNotEmpty ? match.first.value : '';
  }

  Future<void> _openSearch() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SearchableListSheet(
        title: widget.label,
        options: widget.options,
        selectedValue: widget.value,
      ),
    );
    if (selected != null) {
      widget.onChanged(selected);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      enabled: widget.enabled,
      onTap: widget.enabled ? _openSearch : null,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        filled: !widget.enabled,
        fillColor: !widget.enabled ? Colors.grey.shade100 : null,
        isDense: true,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEARCHABLE LIST BOTTOM SHEET
// ─────────────────────────────────────────────────────────────
class _SearchableListSheet extends StatefulWidget {
  final String title;
  final List<MapEntry<String, String>> options;
  final String? selectedValue;

  const _SearchableListSheet({
    required this.title,
    required this.options,
    this.selectedValue,
  });

  @override
  State<_SearchableListSheet> createState() => _SearchableListSheetState();
}

class _SearchableListSheetState extends State<_SearchableListSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) => o.value.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Select ${widget.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title}...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _query = ''),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No matches for "$_query"',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final opt = filtered[i];
                        final isSelected = opt.key == widget.selectedValue;
                        return ListTile(
                          title: Text(opt.value),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          selected: isSelected,
                          selectedTileColor: Colors.green.withAlpha(20),
                          onTap: () => Navigator.pop(ctx, opt.key),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
