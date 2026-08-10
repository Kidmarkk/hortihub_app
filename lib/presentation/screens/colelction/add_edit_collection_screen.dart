import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import '../../../data/models/collection_models.dart';
import '../../../data/models/dropdown_models.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/collection_provider.dart';
import '../../../presentation/providers/collection_master_data_provider.dart';

class AddEditCollectionScreen extends ConsumerStatefulWidget {
  final String hubCode;
  final Collection? collection;
  const AddEditCollectionScreen({
    super.key,
    required this.hubCode,
    this.collection,
  });

  @override
  ConsumerState<AddEditCollectionScreen> createState() =>
      _AddEditCollectionScreenState();
}

class _AddEditCollectionScreenState
    extends ConsumerState<AddEditCollectionScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedFinancialYearCode;
  String? _selectedFarmerCode;
  String? _selectedCropCategoryCode;
  String? _selectedCropCode;
  String? _selectedUnitCode;
  String? _quantity;
  String? _rejected;

  @override
  void initState() {
    super.initState();
    if (widget.collection != null) {
      _selectedFinancialYearCode = widget.collection!.finyearCode;
      _selectedFarmerCode = widget.collection!.farmerCode;
      _selectedCropCode = widget.collection!.cropCode;
      _selectedUnitCode = widget.collection!.unitCode;
      _quantity = widget.collection!.quantity;
      _rejected = widget.collection!.rejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isEditing = widget.collection != null;
    final hubCode = int.tryParse(widget.hubCode) ?? 0;
    final isVerySmall = Responsive.isVerySmallScreen(context);
    final fontSize = Responsive.getResponsiveFontSize(context, baseSize: 14);
    final spacing = isVerySmall ? 6.0 : 12.0;
    final padding = Responsive.getResponsivePadding(context);

    final masterDataAsync = ref.watch(collectionMasterDataProvider);
    final farmersAsync = ref.watch(collectionFarmersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Collection' : 'Add Collection',
          style: TextStyle(fontSize: Responsive.getResponsiveFontSize(context, baseSize: 18)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(padding),
          children: [
            masterDataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(fontSize: fontSize))),
              data: (masterData) {
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
                    // Financial Year dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedFinancialYearCode,
                      hint: Text('Select Financial Year', style: TextStyle(fontSize: fontSize)),
                      items: masterData.financialYears.map((fy) {
                        return DropdownMenuItem(
                          value: fy.code,
                          child: Text(fy.name, style: TextStyle(fontSize: fontSize)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedFinancialYearCode = val),
                      validator: (v) => v == null ? 'Required' : null,
                      decoration: InputDecoration(
                        labelText: 'Financial Year',
                        labelStyle: TextStyle(fontSize: fontSize),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 4 : 8,
                          horizontal: 8,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing),

                    // Farmer dropdown
                    farmersAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (err, _) => Text('Error: $err', style: TextStyle(fontSize: fontSize)),
                      data: (farmers) => DropdownButtonFormField<String>(
                        initialValue: _selectedFarmerCode,
                        hint: Text('Select Farmer', style: TextStyle(fontSize: fontSize)),
                        items: farmers.map((f) {
                          return DropdownMenuItem(
                            value: f.code,
                            child: Text(f.name, style: TextStyle(fontSize: fontSize)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedFarmerCode = val),
                        validator: (v) => v == null ? 'Required' : null,
                        decoration: InputDecoration(
                          labelText: 'Farmer',
                          labelStyle: TextStyle(fontSize: fontSize),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isVerySmall ? 4 : 8,
                            horizontal: 8,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: spacing),

                    // Crop Category dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCropCategoryCode,
                      hint: Text('Select Crop Category', style: TextStyle(fontSize: fontSize)),
                      items: masterData.cropCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.code,
                          child: Text(cat.name, style: TextStyle(fontSize: fontSize)),
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
                        labelStyle: TextStyle(fontSize: fontSize),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 4 : 8,
                          horizontal: 8,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing),

                    // Crop dropdown (only if category selected)
                    if (_selectedCropCategoryCode != null)
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCropCode,
                            hint: Text('Select Crop', style: TextStyle(fontSize: fontSize)),
                            items: filteredCrops.map((c) {
                              return DropdownMenuItem(
                                value: c.code,
                                child: Text(c.name, style: TextStyle(fontSize: fontSize)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCropCode = val),
                            validator: (v) => v == null ? 'Required' : null,
                            decoration: InputDecoration(
                              labelText: 'Crop',
                              labelStyle: TextStyle(fontSize: fontSize),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isVerySmall ? 4 : 8,
                                horizontal: 8,
                              ),
                            ),
                          ),
                          SizedBox(height: spacing),
                        ],
                      ),

                    // Quantity Collected
                    TextFormField(
                      initialValue: _quantity,
                      style: TextStyle(fontSize: fontSize),
                      decoration: InputDecoration(
                        labelText: 'Quantity Collected',
                        labelStyle: TextStyle(fontSize: fontSize),
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 8 : 14,
                          horizontal: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _quantity = val,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: spacing),

                    // Quantity Rejected
                    TextFormField(
                      initialValue: _rejected,
                      style: TextStyle(fontSize: fontSize),
                      decoration: InputDecoration(
                        labelText: 'Quantity Rejected After Grading',
                        labelStyle: TextStyle(fontSize: fontSize),
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 8 : 14,
                          horizontal: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _rejected = val,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: spacing),

                    // Unit dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUnitCode,
                      hint: Text('Select Unit', style: TextStyle(fontSize: fontSize)),
                      items: masterData.units.map((u) {
                        return DropdownMenuItem(
                          value: u.code,
                          child: Text(u.name, style: TextStyle(fontSize: fontSize)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedUnitCode = val),
                      validator: (v) => v == null ? 'Required' : null,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        labelStyle: TextStyle(fontSize: fontSize),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 4 : 8,
                          horizontal: 8,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing * 2),
                  ],
                );
              },
            ),

            // Submit button
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not logged in')),
                  );
                  return;
                }

                final payload = <String, String>{
                  'hubCode': hubCode.toString(),
                  'finyearCode': _selectedFinancialYearCode!,
                  'farmerCode': _selectedFarmerCode!,
                  'cropCode': _selectedCropCode!,
                  'quantity': _quantity!,
                  'rejected': _rejected ?? '0',
                  'unitCode': _selectedUnitCode!,
                  'userCode': user.userCode.toString(),
                };

                if (isEditing) {
                  payload['collectionCode'] = widget.collection!.collectionCode!;
                }

                final notifier = ref.read(addCollectionNotifierProvider.notifier);
                if (isEditing) {
                  await notifier.updateCollection(payload);
                } else {
                  await notifier.addCollection(payload);
                }

                ref.refresh(collectionListProvider(widget.hubCode));
                ref.refresh(collectionMasterDataProvider);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Collection saved successfully')),
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
              child: Text(
                isEditing ? 'Update' : 'Add',
                style: TextStyle(fontSize: Responsive.getResponsiveFontSize(context, baseSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}