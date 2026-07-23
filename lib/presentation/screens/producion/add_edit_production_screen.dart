import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import '../../../data/models/production_models.dart';
import '../../../data/models/dropdown_models.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/production_provider.dart';
import '../../../presentation/providers/production_master_data_provider.dart';

class AddEditProductionScreen extends ConsumerStatefulWidget {
  final String hubCode;
  final Production? production;
  const AddEditProductionScreen({
    super.key,
    required this.hubCode,
    this.production,
  });

  @override
  ConsumerState<AddEditProductionScreen> createState() =>
      _AddEditProductionScreenState();
}

class _AddEditProductionScreenState
    extends ConsumerState<AddEditProductionScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedFinancialYearCode;
  String? _selectedCropCategoryCode;
  String? _selectedCropCode;
  String? _selectedUnitCode;
  String? _season;
  String? _area;
  String? _expectedYield;
  String? _actualYield;

  @override
  void initState() {
    super.initState();
    if (widget.production != null) {
      _selectedFinancialYearCode = widget.production!.finyearCode;
      _selectedCropCode = widget.production!.cropCode;
      _selectedUnitCode = widget.production!.unitCode;
      _season = widget.production!.season;
      _area = widget.production!.area;
      _expectedYield = widget.production!.expectedYield;
      _actualYield = widget.production!.actualYield;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isEditing = widget.production != null;
    final isVerySmall = Responsive.isVerySmallScreen(context);
    final fontSize = Responsive.getResponsiveFontSize(context, baseSize: 14);
    final spacing = isVerySmall ? 6.0 : 12.0;
    final padding = Responsive.getResponsivePadding(context);

    final masterDataAsync = ref.watch(productionMasterDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Production' : 'Add Production',
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
                      value: _selectedFinancialYearCode,
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

                    // Season text field
                    TextFormField(
                      initialValue: _season,
                      style: TextStyle(fontSize: fontSize),
                      decoration: InputDecoration(
                        labelText: 'Season',
                        labelStyle: TextStyle(fontSize: fontSize),
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 8 : 14,
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (val) => _season = val,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: spacing),

                    // Crop Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCropCategoryCode,
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
                            value: _selectedCropCode,
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

                    // Area text field
                    TextFormField(
                      initialValue: _area,
                      style: TextStyle(fontSize: fontSize),
                      decoration: InputDecoration(
                        labelText: 'Area',
                        labelStyle: TextStyle(fontSize: fontSize),
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 8 : 14,
                          horizontal: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _area = val,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: spacing),

                    // Expected Yield text field
                    TextFormField(
                      initialValue: _expectedYield,
                      style: TextStyle(fontSize: fontSize),
                      decoration: InputDecoration(
                        labelText: 'Expected Yield',
                        labelStyle: TextStyle(fontSize: fontSize),
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 8 : 14,
                          horizontal: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _expectedYield = val,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: spacing),

                    // Actual Yield text field
                    TextFormField(
                      initialValue: _actualYield,
                      style: TextStyle(fontSize: fontSize),
                      decoration: InputDecoration(
                        labelText: 'Actual Yield',
                        labelStyle: TextStyle(fontSize: fontSize),
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 8 : 14,
                          horizontal: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _actualYield = val,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: spacing),

                    // Unit dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedUnitCode,
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

                final hubCode = int.tryParse(widget.hubCode) ?? 0;

                final payload = <String, String>{
                  'hubCode': hubCode.toString(),
                  'finyearCode': _selectedFinancialYearCode!,
                  'cropCode': _selectedCropCode!,
                  'area': _area!,
                  'season': _season!,
                  'expectedYield': _expectedYield!,
                  'actualYield': _actualYield!,
                  'unitCode': _selectedUnitCode!,
                  'userCode': user.userCode.toString(),
                };

                if (isEditing) {
                  payload['productionCode'] = widget.production!.productionCode!;
                }

                final notifier = ref.read(addProductionNotifierProvider.notifier);
                if (isEditing) {
                  await notifier.updateProduction(payload);
                } else {
                  await notifier.addProduction(payload);
                }

                ref.refresh(productionListProvider(widget.hubCode));
                ref.refresh(productionMasterDataProvider);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Production saved successfully')),
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