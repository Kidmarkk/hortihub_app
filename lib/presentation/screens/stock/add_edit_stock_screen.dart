import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import '../../../data/models/stock_models.dart';
import '../../../data/models/dropdown_models.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/stock_provider.dart';
import '../../../presentation/providers/master_data_provider.dart';
import '../rate/rate_list_screen.dart';

class AddEditStockScreen extends ConsumerStatefulWidget {
  final String hubCode;
  final StockItem? stockItem;
  const AddEditStockScreen({super.key, required this.hubCode, this.stockItem});

  @override
  ConsumerState<AddEditStockScreen> createState() => _AddEditStockScreenState();
}

class _AddEditStockScreenState extends ConsumerState<AddEditStockScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCropCategoryCode;
  String? _selectedCropCode;
  String? _selectedPackagingTypeCode;
  String? _selectedUnitCode;
  String? _isAvailable;
  int? _quantityAvailable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(masterDataProvider(widget.hubCode));
    });
    if (widget.stockItem != null) {
      _selectedCropCode = widget.stockItem!.cropCode?.toString();
      _selectedPackagingTypeCode = widget.stockItem!.packagingTypeCode
          ?.toString();
      _selectedUnitCode = widget.stockItem!.unitCode?.toString();
      _quantityAvailable = widget.stockItem!.quantityAvailable ?? 0;
      _isAvailable = widget.stockItem!.isAvailable == 'Yes' ? 'Y' : 'N';
    } else {
      _isAvailable = 'N';
    }
  }

  // Helper to get packaging items including current value if editing
  List<DropdownMenuItem<String>> _getPackagingItems(MasterData masterData) {
    final filtered = masterData.packagingTypes
        .where(
          (p) =>
              masterData.cropPackagingMap[_selectedCropCode]?.contains(
                p.code,
              ) ??
              false,
        )
        .toList();

    print(
      '🔍 Filtered packaging types for crop $_selectedCropCode: ${filtered.map((p) => '${p.code}:${p.name}').toList()}',
    );
    print(
      '🔍 cropPackagingMap for $_selectedCropCode: ${masterData.cropPackagingMap[_selectedCropCode]}',
    );

    // If editing and current value is not in filtered list, add it
    final isEditing = widget.stockItem != null;
    if (isEditing && _selectedPackagingTypeCode != null) {
      final exists = filtered.any((p) => p.code == _selectedPackagingTypeCode);
      if (!exists) {
        final current = masterData.packagingTypes.firstWhere(
          (p) => p.code == _selectedPackagingTypeCode,
          orElse: () =>
              PackagingType(code: _selectedPackagingTypeCode!, name: 'Unknown'),
        );
        filtered.add(current);
      }
    }

    return filtered.map((p) {
      return DropdownMenuItem(
        value: p.code,
        child: Text(
          p.name,
          style: TextStyle(
            fontSize: Responsive.getResponsiveFontSize(context, baseSize: 14),
          ),
        ),
      );
    }).toList();
  }

  // Helper to get unit items including current value if editing
  List<DropdownMenuItem<String>> _getUnitItems(MasterData masterData) {
    final filtered = masterData.units
        .where(
          (u) =>
              masterData.cropUnitMap[_selectedCropCode]?.contains(u.code) ??
              false,
        )
        .toList();

    // If editing and current value is not in filtered list, add it
    final isEditing = widget.stockItem != null;
    if (isEditing && _selectedUnitCode != null) {
      final exists = filtered.any((u) => u.code == _selectedUnitCode);
      if (!exists) {
        final current = masterData.units.firstWhere(
          (u) => u.code == _selectedUnitCode,
          orElse: () => Unit(code: _selectedUnitCode!, name: 'Unknown'),
        );
        filtered.add(current);
      }
    }

    return filtered.map((u) {
      return DropdownMenuItem(
        value: u.code,
        child: Text(
          u.name,
          style: TextStyle(
            fontSize: Responsive.getResponsiveFontSize(context, baseSize: 14),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isEditing = widget.stockItem != null;
    final isVerySmall = Responsive.isVerySmallScreen(context);
    final fontSize = Responsive.getResponsiveFontSize(context, baseSize: 14);
    final spacing = isVerySmall ? 6.0 : 12.0;
    final padding = Responsive.getResponsivePadding(context);

    final masterDataAsync = ref.watch(masterDataProvider(widget.hubCode));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Stock' : 'Add Stock',
          style: TextStyle(
            fontSize: Responsive.getResponsiveFontSize(context, baseSize: 18),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(padding),
          children: [
            // Informational note
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                'ℹ️ Stock will appear in the list only after a rate is initialized for this crop and packaging type.\n'
                'If you don’t see the stock after adding, please go to Initialization > Rates and add a rate first.',
                style: TextStyle(
                  fontSize: fontSize * 0.9,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            masterDataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
              data: (masterData) {
                print(
                  '🔍 All rates: ${masterData.rates.map((r) => 'crop=${r.cropCode}, pkg=${r.packagingTypeCode}')}',
                );
                print(
                  '🔍 cropPackagingMap for crop $_selectedCropCode: ${masterData.cropPackagingMap[_selectedCropCode]}',
                );
                final validCropCategories = masterData.cropCategories.where((
                  cat,
                ) {
                  return masterData.crops.any(
                    (c) =>
                        c.categoryCode == cat.code &&
                        masterData.validCropCodes.contains(c.code),
                  );
                }).toList();

                return Column(
                  children: [
                    // Crop Category dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCropCategoryCode,
                      hint: Text(
                        'Select Crop Category',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      items: validCropCategories.map((c) {
                        return DropdownMenuItem(
                          value: c.code,
                          child: Text(
                            c.name,
                            style: TextStyle(fontSize: fontSize),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCropCategoryCode = val;
                          _selectedCropCode = null;
                          _selectedPackagingTypeCode = null;
                          _selectedUnitCode = null;
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

                    // Crop dropdown – only if category selected
                    if (_selectedCropCategoryCode != null)
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCropCode,
                            hint: Text(
                              'Select Crop',
                              style: TextStyle(fontSize: fontSize),
                            ),
                            items: masterData.crops
                                .where(
                                  (c) =>
                                      c.categoryCode ==
                                          _selectedCropCategoryCode &&
                                      masterData.validCropCodes.contains(
                                        c.code,
                                      ),
                                )
                                .map((c) {
                                  return DropdownMenuItem(
                                    value: c.code,
                                    child: Text(
                                      c.name,
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                  );
                                })
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCropCode = val;
                                _selectedPackagingTypeCode = null;
                                _selectedUnitCode = null;
                              });
                            },
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

                    // Packaging Type dropdown – only if crop selected
                    if (_selectedCropCode != null)
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPackagingTypeCode,
                            hint: Text(
                              'Select Packaging Type',
                              style: TextStyle(fontSize: fontSize),
                            ),
                            items: _getPackagingItems(masterData),
                            onChanged: (val) {
                              setState(() {
                                _selectedPackagingTypeCode = val;
                              });
                            },
                            validator: (v) => v == null ? 'Required' : null,
                            decoration: InputDecoration(
                              labelText: 'Packaging Type',
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

                    // Is Available
                    DropdownButtonFormField<String>(
                      initialValue: _isAvailable,
                      hint: Text(
                        'Is in Stock?',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Y', child: Text('Yes')),
                        DropdownMenuItem(value: 'N', child: Text('No')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _isAvailable = val;
                          if (val == 'N') {
                            _quantityAvailable = null;
                            _selectedUnitCode = null;
                          }
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                      decoration: InputDecoration(
                        labelText: 'Is in Stock?',
                        labelStyle: TextStyle(fontSize: fontSize),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 4 : 8,
                          horizontal: 8,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing),

                    // Quantity (only if Yes)
                    if (_isAvailable == 'Y')
                      // Quantity (only if Yes)
                      if (_isAvailable == 'Y')
                        Column(
                          children: [
                            TextFormField(
                              initialValue:
                                  _quantityAvailable?.toString() ?? '',
                              style: TextStyle(fontSize: fontSize),
                              decoration: InputDecoration(
                                labelText: 'Quantity Available',
                                labelStyle: TextStyle(fontSize: fontSize),
                                border: const OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: isVerySmall ? 8 : 14,
                                  horizontal: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ], // only allow digits
                              onChanged: (val) {
                                // Only update if it's a valid integer
                                final parsed = int.tryParse(val);
                                if (parsed != null) {
                                  _quantityAvailable = parsed;
                                } else {
                                  // If invalid, keep previous value (or set to null)
                                  // We'll rely on the validator to prevent submission.
                                }
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (int.tryParse(v) == null)
                                  return 'Enter a whole number (e.g., 5)';
                                return null;
                              },
                            ),
                            SizedBox(height: spacing),
                          ],
                        ),

                    // Unit (only if crop selected and available Yes)
                    if (_selectedCropCode != null && _isAvailable == 'Y')
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _selectedUnitCode,
                            hint: Text(
                              'Select Unit',
                              style: TextStyle(fontSize: fontSize),
                            ),
                            items: _getUnitItems(masterData),
                            onChanged: (val) {
                              setState(() {
                                _selectedUnitCode = val;
                              });
                            },
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
                      ),
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
                final cropCode = int.tryParse(_selectedCropCode!) ?? 0;
                final packagingTypeCode =
                    int.tryParse(_selectedPackagingTypeCode!) ?? 0;
                final quantityAvailable = _quantityAvailable ?? 0;
                final isAvailable = _isAvailable == 'Y' ? 'Yes' : 'No';

                // Unit code optional
                int? unitCode;
                if (_isAvailable == 'Y' && _selectedUnitCode != null) {
                  unitCode = int.tryParse(_selectedUnitCode!);
                }

                final notifier = ref.read(addStockNotifierProvider.notifier);

                if (isEditing) {
                  final payload = <String, String>{
                    'hubCode': hubCode.toString(),
                    'cropCode': cropCode.toString(),
                    'packagingTypeCode': packagingTypeCode.toString(),
                    'quantityAvailable': quantityAvailable.toString(),
                    'isAvailable': isAvailable,
                    'userCode': user.userCode.toString(),
                    'stockCode': widget.stockItem!.stockCode.toString(),
                  };
                  if (unitCode != null) {
                    payload['unitCode'] = unitCode.toString();
                  }
                  await notifier.updateStock(payload, user.token);
                  ref.refresh(stockListProvider(widget.hubCode));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stock updated successfully'),
                      ),
                    );
                    Navigator.pop(context);
                  }
                } else {
                  // ADD NEW STOCK
                  final payload = <String, String>{
                    'hubCode': hubCode.toString(),
                    'cropCode': cropCode.toString(),
                    'packagingTypeCode': packagingTypeCode.toString(),
                    'quantityAvailable': quantityAvailable.toString(),
                    'isAvailable': isAvailable,
                    'userCode': user.userCode.toString(),
                  };
                  if (unitCode != null) {
                    payload['unitCode'] = unitCode.toString();
                  }

                  // Get the response message
                  final message = await notifier.addStock(payload, user.token);
                  final isDuplicate = message.toLowerCase().contains(
                    'already exists',
                  );

                  // Check if stock appears in the list (rate exists)
                  ref.refresh(stockListProvider(widget.hubCode));
                  final freshList = await ref.read(
                    stockListProvider(widget.hubCode).future,
                  );

                  // 🔍 Debug prints – remove later
                  print('🟢 Fresh list after adding stock:');
                  for (var item in freshList) {
                    print(
                      '   cropCode: ${item.cropCode}, packagingTypeCode: ${item.packagingTypeCode}',
                    );
                  }
                  print(
                    '🔍 Looking for cropCode: $cropCode, packagingTypeCode: $packagingTypeCode',
                  );

                  // ✅ Correct comparison using int values
                  final exists = freshList.any(
                    (item) =>
                        item.cropCode == cropCode &&
                        item.packagingTypeCode == packagingTypeCode,
                  );

                  print('🔍 exists: $exists');

                  if (!exists) {
                    // Rate missing – show dialog with dynamic message
                    final dialogMessage = isDuplicate
                        ? 'Stock already exists, but it will not appear in the list because a rate has not been initialized for this crop and packaging type.\n\n'
                              'Would you like to add a rate now?'
                        : 'Stock was added successfully, but it will not appear in the list because a rate has not been initialized for this crop and packaging type.\n\n'
                              'Would you like to add a rate now?';

                    final shouldGoToRates = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          isDuplicate ? 'Stock Already Exists' : 'Stock Added',
                        ),
                        content: Text(dialogMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('No'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                    );

                    if (shouldGoToRates == true) {
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RateListScreen(),
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isDuplicate
                                  ? 'Stock already exists. Please initialize rate later.'
                                  : 'Stock added. Please initialize rate later.',
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    }
                  } else {
                    // Rate exists – show appropriate message
                    if (mounted) {
                      final snackMsg = isDuplicate
                          ? 'Stock already exists'
                          : 'Stock saved successfully';
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(snackMsg)));
                      Navigator.pop(context);
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isVerySmall ? 10 : 14),
              ),
              child: Text(
                isEditing ? 'Update' : 'Add',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    baseSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
