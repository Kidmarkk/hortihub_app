import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import 'package:hortihub_new_app/presentation/providers/master_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';
import '../../../data/models/sales_models.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  final String hubCode;
  const NewSaleScreen({super.key, required this.hubCode});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buyerNameCtrl = TextEditingController();
  final _buyerAddressCtrl = TextEditingController();
  final _buyerMobileCtrl = TextEditingController();

  List<SalesOrderItem> items = [];

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) => AddItemDialog(
        hubCode: widget.hubCode,
        onAdd: (item) {
          setState(() => items.add(item));
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => items.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }

    final user = ref.read(authStateProvider).value;
    final userCode = user?.userCode ?? 0;
    if (userCode == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in properly')),
      );
      return;
    }

    final totalPrice = items.fold(0.0, (sum, item) => sum + item.totalPrice);

    final order = SalesOrder(
      hubCode: int.tryParse(widget.hubCode) ?? 0,
      buyerName: _buyerNameCtrl.text,
      buyerAddress: _buyerAddressCtrl.text,
      buyerMobile: _buyerMobileCtrl.text,
      userCode: userCode,
      items: items,
      totalPrice: totalPrice,
    );

    final notifier = ref.read(addSaleNotifierProvider.notifier);
    await notifier.addSale(order);

    ref.invalidate(salesListProvider(widget.hubCode));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale created successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerySmall = Responsive.isVerySmallScreen(context);
    final fontSize = Responsive.getResponsiveFontSize(context, baseSize: 14);
    final padding = Responsive.getResponsivePadding(context);
    final double spacing = isVerySmall ? 6 : 12;

    return Scaffold(
      appBar: AppBar(
        title: Text('New Sale', style: TextStyle(fontSize: Responsive.getResponsiveFontSize(context, baseSize: 18))),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(padding),
          children: [
            Text(
              'Buyer Details',
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: _buyerNameCtrl,
              decoration: InputDecoration(
                labelText: 'Buyer Name',
                labelStyle: TextStyle(fontSize: fontSize),
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: isVerySmall ? 8 : 14,
                  horizontal: 12,
                ),
              ),
              style: TextStyle(fontSize: fontSize),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: _buyerAddressCtrl,
              decoration: InputDecoration(
                labelText: 'Buyer Address',
                labelStyle: TextStyle(fontSize: fontSize),
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: isVerySmall ? 8 : 14,
                  horizontal: 12,
                ),
              ),
              style: TextStyle(fontSize: fontSize),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: _buyerMobileCtrl,
              decoration: InputDecoration(
                labelText: 'Mobile',
                labelStyle: TextStyle(fontSize: fontSize),
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: isVerySmall ? 8 : 14,
                  horizontal: 12,
                ),
              ),
              keyboardType: TextInputType.phone,
              style: TextStyle(fontSize: fontSize),
            ),
            SizedBox(height: spacing * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(onPressed: _addItem, icon: Icon(Icons.add, size: isVerySmall ? 20 : 24)),
              ],
            ),
            if (items.isEmpty)
              Text('No items added', style: TextStyle(fontSize: fontSize, color: Colors.grey)),
            ...items.asMap().entries.map((entry) {
              int idx = entry.key;
              var item = entry.value;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: 4,
                  ),
                  title: Text(
                    '${item.cropName} - ${item.packagingTypeName}',
                    style: TextStyle(fontSize: fontSize),
                  ),
                  subtitle: Text(
                    'Qty: ${item.quantity}, Price: ₹${item.itemPrice.toStringAsFixed(2)}, Total: ₹${item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: fontSize * 0.85),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    iconSize: isVerySmall ? 18 : 24,
                    onPressed: () => _removeItem(idx),
                  ),
                ),
              );
            }),
            SizedBox(height: spacing * 2),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isVerySmall ? 10 : 14),
              ),
              child: Text(
                'Place Order',
                style: TextStyle(fontSize: Responsive.getResponsiveFontSize(context, baseSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog to add an item using stockForSaleProvider
class AddItemDialog extends ConsumerStatefulWidget {
  final String hubCode;
  final Function(SalesOrderItem) onAdd;
  const AddItemDialog({super.key, required this.hubCode, required this.onAdd});

  @override
  ConsumerState<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends ConsumerState<AddItemDialog> {
  String? _selectedCropCategoryCode;
  String? _selectedCropCategoryName;
  String? _selectedCropCode;
  String? _selectedCropName;
  String? _selectedPackagingCode;
  String? _selectedPackagingName;
  int? _selectedQuantity;
  double? _selectedPrice;

  // Track whether to show only an OK button
  bool _showOKOnly = false;

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(stockForSaleProvider(widget.hubCode));
    final masterDataAsync = ref.watch(masterDataProvider);
    final isVerySmall = Responsive.isVerySmallScreen(context);
    final fontSize = Responsive.getResponsiveFontSize(context, baseSize: 13);

    return AlertDialog(
      title: Text('Add Item', style: TextStyle(fontSize: Responsive.getResponsiveFontSize(context, baseSize: 18))),
      content: masterDataAsync.when(
        loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
        error: (err, _) => Text('Error loading master data: $err', style: TextStyle(fontSize: fontSize)),
        data: (masterData) {
          final cropCategories = masterData.cropCategories;
          final filteredCrops = masterData.crops
              .where((c) => c.categoryCode == _selectedCropCategoryCode)
              .toList();

          return stockAsync.when(
            loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            error: (err, _) => Text('Error loading stock: $err', style: TextStyle(fontSize: fontSize)),
            data: (stockItems) {
              // If no stock items at all, show informative message and set OK-only
              if (stockItems.isEmpty) {
                _showOKOnly = true;
                return SizedBox(
                  width: isVerySmall ? 200 : 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 48, color: Colors.orange),
                      const SizedBox(height: 12),
                      Text(
                        'No items available for sale.\n\n'
                        'Please ensure:\n'
                        '1. Rates are initialized for the crop\n'
                        '2. Stock has been added for that crop',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ],
                  ),
                );
              }

              final packagingOptions = stockItems
                  .where((e) => _selectedCropCode == null || e.cropCode.toString() == _selectedCropCode)
                  .toList();

              // If selected crop has no packaging options, show hint and set OK-only
              if (_selectedCropCode != null && packagingOptions.isEmpty) {
                _showOKOnly = true;
                return SizedBox(
                  width: isVerySmall ? 200 : 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 48, color: Colors.orange),
                      const SizedBox(height: 12),
                      Text(
                        'No stock available for the selected crop.\n\n'
                        'Please add stock for this crop first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ],
                  ),
                );
              }

              // Normal state – show the form
              _showOKOnly = false;
              final selectedStockItems = packagingOptions
                  .where((e) => _selectedPackagingCode == null || e.packagingTypeCode.toString() == _selectedPackagingCode)
                  .toList();

              final priceOptions = selectedStockItems
                  .map((e) => e.amount)
                  .where((a) => a != null && a > 0)
                  .toSet()
                  .toList();

              int maxQty = 0;
              if (_selectedPackagingCode != null) {
                final stockItem = selectedStockItems.firstWhere(
                  (e) => e.packagingTypeCode.toString() == _selectedPackagingCode,
                  orElse: () => StockItemForSale(
                    cropCode: 0,
                    cropName: '',
                    packagingTypeCode: 0,
                    packagingTypeName: '',
                    quantityAvailable: 0,
                    amount: 0,
                  ),
                );
                maxQty = stockItem.quantityAvailable;
              }

              final quantityOptions = List<int>.generate(maxQty, (i) => i + 1).toList();

              if (_selectedPrice == null && priceOptions.length == 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => _selectedPrice = priceOptions.first);
                });
              }

              return SizedBox(
                width: isVerySmall ? 200 : 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Crop Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCropCategoryCode,
                      hint: Text('Select Crop Category', style: TextStyle(fontSize: fontSize)),
                      items: cropCategories
                          .where((c) => c.code.isNotEmpty)
                          .map((c) => DropdownMenuItem(
                            value: c.code,
                            child: Text(c.name, style: TextStyle(fontSize: fontSize)),
                          ))
                          .toList(),
                      onChanged: (code) {
                        setState(() {
                          _selectedCropCategoryCode = code;
                          _selectedCropCategoryName = cropCategories.firstWhere((c) => c.code == code).name;
                          _selectedCropCode = null;
                          _selectedCropName = null;
                          _selectedPackagingCode = null;
                          _selectedPackagingName = null;
                          _selectedQuantity = null;
                          _selectedPrice = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Crop Category',
                        labelStyle: TextStyle(fontSize: fontSize),
                        contentPadding: EdgeInsets.symmetric(vertical: isVerySmall ? 4 : 8, horizontal: 8),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Crop dropdown (only if category selected)
                    if (_selectedCropCategoryCode != null)
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedCropCode,
                            hint: Text('Select Crop', style: TextStyle(fontSize: fontSize)),
                            items: filteredCrops
                                .where((c) => c.code.isNotEmpty)
                                .map((c) => DropdownMenuItem(
                                  value: c.code,
                                  child: Text(c.name, style: TextStyle(fontSize: fontSize)),
                                ))
                                .toList(),
                            onChanged: (code) {
                              setState(() {
                                _selectedCropCode = code;
                                _selectedCropName = filteredCrops.firstWhere((c) => c.code == code).name;
                                _selectedPackagingCode = null;
                                _selectedPackagingName = null;
                                _selectedQuantity = null;
                                _selectedPrice = null;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Crop',
                              labelStyle: TextStyle(fontSize: fontSize),
                              contentPadding: EdgeInsets.symmetric(vertical: isVerySmall ? 4 : 8, horizontal: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),

                    // Packaging dropdown (only if crop selected)
                    if (_selectedCropCode != null)
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedPackagingCode,
                            hint: Text('Select Packaging', style: TextStyle(fontSize: fontSize)),
                            items: packagingOptions
                                .map((p) => DropdownMenuItem(
                                  value: p.packagingTypeCode.toString(),
                                  child: Text(p.packagingTypeName, style: TextStyle(fontSize: fontSize)),
                                ))
                                .toList(),
                            onChanged: (code) {
                              setState(() {
                                _selectedPackagingCode = code;
                                _selectedPackagingName = packagingOptions
                                    .firstWhere((p) => p.packagingTypeCode.toString() == code)
                                    .packagingTypeName;
                                _selectedQuantity = null;
                                _selectedPrice = null;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Packaging',
                              labelStyle: TextStyle(fontSize: fontSize),
                              contentPadding: EdgeInsets.symmetric(vertical: isVerySmall ? 4 : 8, horizontal: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),

                    // Quantity and Price (only if packaging selected and stock available)
                    if (_selectedPackagingCode != null && maxQty > 0) ...[
                      DropdownButtonFormField<int>(
                        value: _selectedQuantity,
                        hint: Text('Select Quantity', style: TextStyle(fontSize: fontSize)),
                        items: quantityOptions
                            .map((q) => DropdownMenuItem(value: q, child: Text('$q', style: TextStyle(fontSize: fontSize))))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedQuantity = val),
                        decoration: InputDecoration(
                          labelText: 'Quantity (max $maxQty)',
                          labelStyle: TextStyle(fontSize: fontSize),
                          contentPadding: EdgeInsets.symmetric(vertical: isVerySmall ? 4 : 8, horizontal: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<double>(
                        value: _selectedPrice,
                        hint: Text('Select Price per unit', style: TextStyle(fontSize: fontSize)),
                        items: priceOptions
                            .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text('₹${p!.toStringAsFixed(2)}', style: TextStyle(fontSize: fontSize)),
                            ))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedPrice = val),
                        decoration: InputDecoration(
                          labelText: 'Price per unit',
                          labelStyle: TextStyle(fontSize: fontSize),
                          contentPadding: EdgeInsets.symmetric(vertical: isVerySmall ? 4 : 8, horizontal: 8),
                        ),
                      ),
                    ] else if (_selectedPackagingCode != null && maxQty == 0)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Out of stock', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      actions: _showOKOnly
          ? [
              // Single OK button when no stock or no packaging
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ]
          : [
              // Normal Cancel + Add buttons
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_selectedCropCode == null ||
                      _selectedPackagingCode == null ||
                      _selectedQuantity == null ||
                      _selectedPrice == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select all fields')),
                    );
                    return;
                  }
                  final qty = _selectedQuantity!;
                  final price = _selectedPrice!;
                  final total = qty * price;
                  final item = SalesOrderItem(
                    cropCode: int.tryParse(_selectedCropCode!) ?? 0,
                    packagingTypeCode: int.tryParse(_selectedPackagingCode!) ?? 0,
                    cropName: _selectedCropName ?? '',
                    packagingTypeName: _selectedPackagingName ?? '',
                    quantity: qty,
                    itemPrice: price,
                    totalPrice: total,
                  );
                  widget.onAdd(item);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
                child: Text('Add', style: TextStyle(fontSize: Responsive.getResponsiveFontSize(context, baseSize: 14))),
              ),
            ],
    );
  }
}