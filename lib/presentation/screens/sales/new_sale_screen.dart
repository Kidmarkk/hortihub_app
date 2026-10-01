import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import 'package:hortihub_new_app/data/models/dropdown_models.dart';
import 'package:hortihub_new_app/data/models/rate_models.dart';
import 'package:hortihub_new_app/presentation/providers/master_data_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hortihub_new_app/services/thermal_printer_service.dart';

import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';
import '../../../data/models/sales_models.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  final String hubCode;
  const NewSaleScreen({super.key, required this.hubCode});

  static Future<bool> _checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.bluetooth.isGranted &&
          await Permission.bluetoothConnect.isGranted &&
          await Permission.bluetoothScan.isGranted) {
        return true;
      }
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();
      return statuses[Permission.bluetooth]!.isGranted &&
          statuses[Permission.bluetoothConnect]!.isGranted &&
          statuses[Permission.bluetoothScan]!.isGranted;
    }
    return true; // iOS handles permissions differently
  }

  // Reusable static method to show confirmation dialog and print receipt
  static Future<void> printReceiptDialog({
    required BuildContext context,
    required WidgetRef ref,
    required SalesOrder sale,
    required String hubCode,
  }) async {
    // 1. Prompt User Confirmation
    final shouldPrint = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Print Receipt'),
        content: const Text('Do you want to print this receipt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldPrint != true) return;

    if (!context.mounted) return;

    // 2. Show loading modal while sending bytes to printer
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.green[700]),
                const SizedBox(height: 16),
                const Text("Printing receipt..."),
              ],
            ),
          ),
        ),
      ),
    );

    bool printedSuccessfully = false;

    try {
      final user = ref.read(authStateProvider).value;
      String? currentHubName = sale.hubName;
      String? currentDistrictName = sale.districtName;

      // Resolve district name from auth state
      String resolveDistrictName(String? districtCode) {
        if (districtCode == null || districtCode.isEmpty) return '';
        if (user == null) return districtCode;
        if (user.userRole == 'DISTRICTUSER' && user.districtName != null) {
          return user.districtName!;
        }
        final match = user.listDistricts.firstWhere(
          (d) => d['key'] == districtCode,
          orElse: () => {'value': districtCode},
        );
        return match['value'] ?? districtCode;
      }

      if (user != null) {
        if (user.listHubs.isNotEmpty) {
          final match = user.listHubs.firstWhere(
            (h) => h['key'].toString() == hubCode.toString(),
            orElse: () => {},
          );
          if (match.containsKey('value') &&
              match['value'].toString().isNotEmpty) {
            currentHubName = match['value'].toString();
          }
          if (match.containsKey('value1')) {
            currentDistrictName = resolveDistrictName(
              match['value1'].toString(),
            );
          }
        } else if (user.hubCode != null) {
          currentHubName = user.hubName ?? 'HUB ${user.hubCode}';
          currentDistrictName = resolveDistrictName(user.districtCode);
        }
      }

      final orderData = {
        'hubName': currentHubName,
        'districtName': currentDistrictName,
        'receiptNo': sale.salesOrderCode?.toString() ?? 'N/A',
        'buyerName': sale.buyerName,
        'date': DateTime.now().toString().split(' ')[0],
        'total': (sale.totalPrice ?? 0.0).toStringAsFixed(2),
        'items': sale.items.map((item) {
          print('🔍 ${item.cropName}: unitName = ${item.unitName}');

          return {
            'name': '${item.cropName} (${item.packagingTypeName})',
            'qty': item.quantity,
            'unit': item.unitName ?? '',
            'price': (item.totalPrice ?? 0.0).toStringAsFixed(2),
          };
        }).toList(),
      };

      debugPrint('Order Data: $orderData');

      // Print execution
      ThermalPrinterService printer = ThermalPrinterService();
      printedSuccessfully = await printer.printReceipt(context, orderData);
    } catch (e) {
      debugPrint("Printing execution error: $e");
    } finally {
      if (context.mounted) Navigator.of(context).pop(); // Dismiss loading modal
    }

    // 3. User feedback SnackBar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            printedSuccessfully
                ? 'Receipt printed successfully!'
                : 'Could not connect to printer. Please ensure:\n'
                      '• USB cable is properly connected\n'
                      '• Printer is powered ON\n'
                      '• Bluetooth is enabled (required for USB detection)\n'
                      '• You have granted USB permission when prompted',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

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
    ref.refresh(masterDataProvider(widget.hubCode));
    ref.refresh(stockForSaleProvider(widget.hubCode));
    showDialog(
      context: context,
      builder: (ctx) => AddItemDialog(
        hubCode: widget.hubCode,
        cartItems: items,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item')));
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
        const SnackBar(content: Text('Sale created. Preparing receipt...')),
      );
    }

    // Give the provider a moment to refresh and then fetch the updated list
    await Future.delayed(const Duration(milliseconds: 800));
    final salesList = await ref.read(salesListProvider(widget.hubCode).future);

    // Find the newly created sale
    final newSale = salesList.isNotEmpty
        ? salesList.firstWhere(
            (s) => s.buyerName == order.buyerName,
            orElse: () => salesList.first,
          )
        : order;

    if (mounted) {
      // Trigger prompt and printing workflow
      await NewSaleScreen.printReceiptDialog(
        context: context,
        ref: ref,
        sale: newSale,
        hubCode: widget.hubCode,
      );

      // Close New Sale Screen and navigate back
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number is required';
    if (value.length != 10) return 'Must be exactly 10 digits';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'Only digits allowed';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isVerySmall = Responsive.isVerySmallScreen(context);
    final fontSize = Responsive.getResponsiveFontSize(context, baseSize: 14);
    final padding = Responsive.getResponsivePadding(context);
    final double spacing = isVerySmall ? 6 : 12;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Sale',
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
            Text(
              'Buyer Details',
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  baseSize: 18,
                ),
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
              validator: _validateMobile,
            ),
            SizedBox(height: spacing * 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      baseSize: 18,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _addItem,
                  icon: Icon(Icons.add, size: isVerySmall ? 20 : 24),
                ),
              ],
            ),
            if (items.isEmpty)
              Text(
                'No items added',
                style: TextStyle(fontSize: fontSize, color: Colors.grey),
              ),
            ...items.asMap().entries.map((entry) {
              int idx = entry.key;
              var item = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
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

// Dialog to add an item using stockForSaleProvider
class AddItemDialog extends ConsumerStatefulWidget {
  final String hubCode;
  final Function(SalesOrderItem) onAdd;
  final List<SalesOrderItem> cartItems;

  const AddItemDialog({
    super.key,
    required this.hubCode,
    required this.onAdd,
    required this.cartItems,
  });

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
  String? _selectedUnitName;
  int? _selectedQuantity;
  double? _selectedPrice;

  bool _showOKOnly = false;

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(stockForSaleProvider(widget.hubCode));
    final masterDataAsync = ref.watch(masterDataProvider(widget.hubCode));
    final isVerySmall = Responsive.isVerySmallScreen(context);
    final fontSize = Responsive.getResponsiveFontSize(context, baseSize: 13);

    return AlertDialog(
      title: Text(
        'Add Item',
        style: TextStyle(
          fontSize: Responsive.getResponsiveFontSize(context, baseSize: 18),
        ),
      ),
      content: masterDataAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: Color(0xFF388E3C))),
        ),
        error: (err, _) => Text(
          'Error loading master data: $err',
          style: TextStyle(fontSize: fontSize),
        ),
        data: (masterData) {
          return stockAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF388E3C))),
            ),
            error: (err, _) => Text(
              'Error loading stock: $err',
              style: TextStyle(fontSize: fontSize),
            ),
            data: (stockItems) {
              if (stockItems.isEmpty) {
                _showOKOnly = true;
                return SizedBox(
                  width: isVerySmall ? 200 : 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.orange,
                      ),
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

              final validCropCategories = masterData.cropCategories.where((
                cat,
              ) {
                return masterData.crops.any(
                  (c) =>
                      c.categoryCode == cat.code &&
                      stockItems.any(
                        (stock) => stock.cropCode.toString() == c.code,
                      ),
                );
              }).toList();

              final filteredCrops = masterData.crops
                  .where(
                    (c) =>
                        c.categoryCode == _selectedCropCategoryCode &&
                        stockItems.any(
                          (stock) => stock.cropCode.toString() == c.code,
                        ),
                  )
                  .toList();

              final packagingOptions = stockItems
                  .where(
                    (e) =>
                        _selectedCropCode == null ||
                        e.cropCode.toString() == _selectedCropCode,
                  )
                  .toList();

              if (_selectedCropCode != null && packagingOptions.isEmpty) {
                _showOKOnly = true;
                return SizedBox(
                  width: isVerySmall ? 200 : 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.orange,
                      ),
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

              _showOKOnly = false;
              final selectedStockItems = packagingOptions
                  .where(
                    (e) =>
                        _selectedPackagingCode == null ||
                        e.packagingTypeCode.toString() ==
                            _selectedPackagingCode,
                  )
                  .toList();

              final priceOptions = selectedStockItems
                  .map((e) => e.amount)
                  .where((a) => a != null && a > 0)
                  .toSet()
                  .toList();

              int maxQty = 0;
              if (_selectedPackagingCode != null) {
                final stockItem = selectedStockItems.firstWhere(
                  (e) =>
                      e.packagingTypeCode.toString() == _selectedPackagingCode,
                  orElse: () => StockItemForSale(
                    cropCode: 0,
                    cropName: '',
                    packagingTypeCode: 0,
                    packagingTypeName: '',
                    quantityAvailable: 0,
                    amount: 0,
                  ),
                );

                final usedQty = widget.cartItems
                    .where(
                      (item) =>
                          item.cropCode == int.tryParse(_selectedCropCode!) &&
                          item.packagingTypeCode ==
                              int.tryParse(_selectedPackagingCode!),
                    )
                    .fold(0, (sum, item) => sum + item.quantity);

                maxQty = stockItem.netQuantity - usedQty;
                if (maxQty < 0) maxQty = 0;
              }

              final quantityOptions = List<int>.generate(
                maxQty,
                (i) => i + 1,
              ).toList();

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
                    DropdownButtonFormField<String>(
                      value: _selectedCropCategoryCode,
                      hint: Text(
                        'Select Crop Category',
                        style: TextStyle(fontSize: fontSize),
                      ),
                      items: validCropCategories
                          .where((c) => c.code.isNotEmpty)
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.code,
                              child: Text(
                                c.name,
                                style: TextStyle(fontSize: fontSize),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (code) {
                        setState(() {
                          _selectedCropCategoryCode = code;
                          _selectedCropCategoryName = validCropCategories
                              .firstWhere((c) => c.code == code)
                              .name;
                          _selectedCropCode = null;
                          _selectedCropName = null;
                          _selectedPackagingCode = null;
                          _selectedPackagingName = null;
                          _selectedUnitName = null;
                          _selectedQuantity = null;
                          _selectedPrice = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Crop Category',
                        labelStyle: TextStyle(fontSize: fontSize),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: isVerySmall ? 4 : 8,
                          horizontal: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedCropCategoryCode != null)
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedCropCode,
                            hint: Text(
                              'Select Crop',
                              style: TextStyle(fontSize: fontSize),
                            ),
                            items: filteredCrops
                                .where((c) => c.code.isNotEmpty)
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.code,
                                    child: Text(
                                      c.name,
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (code) {
                              setState(() {
                                _selectedCropCode = code;
                                _selectedCropName = filteredCrops
                                    .firstWhere((c) => c.code == code)
                                    .name;
                                _selectedPackagingCode = null;
                                _selectedPackagingName = null;
                                _selectedUnitName = null;
                                _selectedQuantity = null;
                                _selectedPrice = null;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Crop',
                              labelStyle: TextStyle(fontSize: fontSize),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isVerySmall ? 4 : 8,
                                horizontal: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    if (_selectedCropCode != null)
                      Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedPackagingCode,
                            hint: Text(
                              'Select Packaging',
                              style: TextStyle(fontSize: fontSize),
                            ),
                            items: packagingOptions.map((p) {
                              // Find rate for this crop+packaging
                              RateInfo? rate;
                              for (final r in masterData.rates) {
                                if (r.cropCode == _selectedCropCode &&
                                    r.packagingTypeCode ==
                                        p.packagingTypeCode.toString()) {
                                  rate = r;
                                  break;
                                }
                              }

                              String displayName = p.packagingTypeName;
                              if (rate?.quantity != null &&
                                  rate!.quantity!.isNotEmpty &&
                                  rate.unitName != null &&
                                  rate.unitName!.isNotEmpty) {
                                final qty =
                                    double.tryParse(rate.quantity!) ?? 0.0;
                                displayName =
                                    '${p.packagingTypeName} (${qty.toStringAsFixed(2)} ${rate.unitName})';
                              }

                              return DropdownMenuItem(
                                value: p.packagingTypeCode.toString(),
                                child: Text(displayName),
                              );
                            }).toList(),
                            onChanged: (code) {
                              setState(() {
                                _selectedPackagingCode = code;
                                final selectedStock = packagingOptions
                                    .firstWhere(
                                      (p) =>
                                          p.packagingTypeCode.toString() ==
                                          code,
                                    );
                                _selectedPackagingName =
                                    selectedStock.packagingTypeName;
                                _selectedUnitName = selectedStock.unitName;
                                _selectedQuantity = null;
                                _selectedPrice = null;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Packaging',
                              labelStyle: TextStyle(fontSize: fontSize),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isVerySmall ? 4 : 8,
                                horizontal: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    if (_selectedPackagingCode != null && maxQty > 0) ...[
                      DropdownButtonFormField<int>(
                        value: _selectedQuantity,
                        hint: Text(
                          'Select Quantity',
                          style: TextStyle(fontSize: fontSize),
                        ),
                        items: quantityOptions
                            .map(
                              (q) => DropdownMenuItem(
                                value: q,
                                child: Text(
                                  '$q',
                                  style: TextStyle(fontSize: fontSize),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedQuantity = val),
                        decoration: InputDecoration(
                          labelText: 'Quantity (max $maxQty)',
                          labelStyle: TextStyle(fontSize: fontSize),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isVerySmall ? 4 : 8,
                            horizontal: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<double>(
                        value: _selectedPrice,
                        hint: Text(
                          'Select Price per unit',
                          style: TextStyle(fontSize: fontSize),
                        ),
                        items: priceOptions
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  '₹${p!.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: fontSize),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedPrice = val),
                        decoration: InputDecoration(
                          labelText: 'Price per unit',
                          labelStyle: TextStyle(fontSize: fontSize),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isVerySmall ? 4 : 8,
                            horizontal: 8,
                          ),
                        ),
                      ),
                    ] else if (_selectedPackagingCode != null && maxQty == 0)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Out of stock',
                          style: TextStyle(color: Colors.red),
                        ),
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
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

                  final masterDataValue = ref
                      .read(masterDataProvider(widget.hubCode))
                      .value;
                  final rates = masterDataValue?.rates ?? [];

                  RateInfo? matchingRate;
                  for (final r in rates) {
                    if (r.cropCode == _selectedCropCode &&
                        r.packagingTypeCode == _selectedPackagingCode) {
                      matchingRate = r;
                      break;
                    }
                  }

                  String combinedPackagingName = _selectedPackagingName ?? '';

                  if (matchingRate != null &&
                      matchingRate.quantity != null &&
                      matchingRate.quantity!.isNotEmpty &&
                      matchingRate.unitName != null &&
                      matchingRate.unitName!.isNotEmpty) {
                    final rateQty =
                        double.tryParse(matchingRate.quantity!) ?? 0.0;
                    combinedPackagingName =
                        '${_selectedPackagingName ?? ''} '
                        '(${rateQty.toStringAsFixed(2)} ${matchingRate.unitName})';
                  } else if (_selectedUnitName != null &&
                      _selectedUnitName!.isNotEmpty) {
                    // Fallback: use selected unit without quantity
                    combinedPackagingName =
                        '${_selectedPackagingName ?? ''} ($_selectedUnitName)';
                  }

                  final qty = _selectedQuantity!;
                  final price = _selectedPrice!;
                  final total = qty * price;

                  final item = SalesOrderItem(
                    cropCode: int.tryParse(_selectedCropCode!) ?? 0,
                    packagingTypeCode:
                        int.tryParse(_selectedPackagingCode!) ?? 0,
                    cropName: _selectedCropName ?? '',
                    packagingTypeName:
                        combinedPackagingName, // "MINI (0.50 KILOGRAM)"
                    unitName: matchingRate?.unitName ?? _selectedUnitName,
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                ),
                child: Text(
                  'Add',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      baseSize: 14,
                    ),
                  ),
                ),
              ),
            ],
    );
  }
}
