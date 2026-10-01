import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import 'package:hortihub_new_app/widgets/icon_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/selected_hub_provider.dart';
import '../../../data/models/stock_models.dart';
import '../../../widgets/hub_selection_widget.dart';
import 'add_edit_stock_screen.dart';

class StockListScreen extends ConsumerStatefulWidget {
  final String? hubCode;
  const StockListScreen({super.key, this.hubCode});

  @override
  ConsumerState<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends ConsumerState<StockListScreen> {
  // ✅ Bulk selection state
  bool _selectionMode = false;
  final Set<String> _selectedStockCodes = {};
  bool _isUpdating = false;

  /// Formats a double as a clean string (1.0 → "1", 1.5 → "1.5", 0.50 → "0.5")
  String _formatQty(double? q) {
    if (q == null) return '';
    if (q == q.truncateToDouble()) return q.toInt().toString();
    return q.toString();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedStockCodes.clear();
    });
  }

  void _toggleItemSelection(String stockCode) {
    setState(() {
      if (_selectedStockCodes.contains(stockCode)) {
        _selectedStockCodes.remove(stockCode);
      } else {
        _selectedStockCodes.add(stockCode);
      }
    });
  }

  void _selectAll(List<StockItem> items) {
    setState(() {
      if (_selectedStockCodes.length == items.length) {
        _selectedStockCodes.clear();
      } else {
        _selectedStockCodes
          ..clear()
          ..addAll(items.map((i) => i.stockCode.toString()));
      }
    });
  }

  // ✅ Bulk update action
  Future<void> _applyAvailabilityUpdate(
    bool markAsAvailable,
    String hubCode,
    List<StockItem> allItems,
  ) async {
    if (_selectedStockCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item.')),
      );
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }

    // Confirm
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          markAsAvailable ? 'Mark as Available' : 'Mark as Not Available',
        ),
        content: Text(
          'Are you sure you want to mark ${_selectedStockCodes.length} item(s) as '
          '${markAsAvailable ? "Available" : "Not Available"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
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
    if (confirm != true) return;

    setState(() => _isUpdating = true);

    try {
      final repo = ref.read(stockRepositoryProvider);

      // Split into two arrays
      final List<String> isAvailableArray = [];
      final List<String> isNotAvailableArray = [];

      if (markAsAvailable) {
        isAvailableArray.addAll(_selectedStockCodes);
      } else {
        isNotAvailableArray.addAll(_selectedStockCodes);
      }

      final message = await repo.updateAvailability(
        hubCode: hubCode,
        userCode: user.userCode.toString(),
        isAvailableArray: isAvailableArray,
        isNotAvailableArray: isNotAvailableArray,
      );

      // Refresh the list
      ref.invalidate(stockListProvider(hubCode));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      setState(() {
        _selectedStockCodes.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _viewDetails(StockItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stock Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Crop', item.cropName ?? 'N/A'),
              _detailRow('Crop Category', item.cropCategoryName ?? 'N/A'),
              _detailRow('Packaging Type', item.packagingTypeName ?? 'N/A'),
              _detailRow('Price (₹)', item.amount?.toString() ?? 'N/A'),
              _detailRow('In Stock', item.isAvailable ?? 'N/A'),
              _detailRow(
                'Quantity Available',
                item.quantityAvailable?.toString() ?? '0',
              ),
              _detailRow(
                'Quantity Damaged',
                item.quantityDamaged?.toString() ?? '0',
              ), // ✅ NEW
              _detailRow('Hub Name', item.hubName ?? 'N/A'),
              _detailRow('District', item.districtName ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final selectedHub = ref.watch(selectedHubProvider);
    final isVerySmall = Responsive.isVerySmallScreen(context);
    final double iconSize = isVerySmall ? 18.0 : 24.0;
    final fontSize = Responsive.getResponsiveFontSize(context, baseSize: 14);
    final padding = Responsive.getResponsivePadding(context);
    final cardMargin = EdgeInsets.symmetric(
      vertical: 4,
      horizontal: Responsive.getResponsivePadding(context, basePadding: 4),
    );

    if (user?.userRole == 'HUBUSER' &&
        selectedHub == null &&
        user?.hubCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedHubProvider.notifier).state = user?.hubCode;
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF388E3C))));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectionMode
              ? 'Select Items (${_selectedStockCodes.length})'
              : 'Stock List',
        ),
        actions: [
          if (selectedHub != null)
            IconButton(
              icon: Icon(_selectionMode ? Icons.close : Icons.checklist),
              tooltip: _selectionMode
                  ? 'Cancel Selection'
                  : 'Bulk Availability',
              onPressed: _isUpdating ? null : _toggleSelectionMode,
            ),
        ],
      ),
      body: Column(
        children: [
          const HubSelectionWidget(),
          if (!_selectionMode)
            IconHelper(
              items: [
                IconHelperItem(
                  icon: Icons.remove_red_eye,
                  label: 'View Details',
                  color: Colors.blue,
                ),
                IconHelperItem(
                  icon: Icons.edit,
                  label: 'Edit Details',
                  color: Colors.green,
                ),
              ],
            ),
          Expanded(
            child: selectedHub == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'Select a district and hub to view stock data',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: fontSize,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Consumer(
                    builder: (ctx, ref, _) {
                      final stockAsync = ref.watch(
                        stockListProvider(selectedHub!),
                      );
                      return stockAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C))),
                        error: (err, _) => Center(
                          child: Text(
                            'Error: $err',
                            style: TextStyle(fontSize: fontSize),
                          ),
                        ),
                        data: (items) => items.isEmpty
                            ? Center(
                                child: Text(
                                  'No stock items',
                                  style: TextStyle(fontSize: fontSize),
                                ),
                              )
                            : Column(
                                children: [
                                  // ✅ Select All row
                                  if (_selectionMode)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: padding,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value:
                                                _selectedStockCodes.length ==
                                                    items.length &&
                                                items.isNotEmpty,
                                            onChanged: (_) => _selectAll(items),
                                          ),
                                          Text(
                                            'Select All (${items.length})',
                                            style: TextStyle(
                                              fontSize: fontSize,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: EdgeInsets.all(padding),
                                      itemCount: items.length,
                                      itemBuilder: (ctx, i) {
                                        final item = items[i];
                                        final stockCodeStr = item.stockCode
                                            .toString();
                                        final isSelected = _selectedStockCodes
                                            .contains(stockCodeStr);

                                        return Card(
                                          margin: cardMargin,
                                          color: _selectionMode && isSelected
                                              ? Colors.green.shade50
                                              : null,
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: padding,
                                                  vertical: 4,
                                                ),
                                            leading: _selectionMode
                                                ? Checkbox(
                                                    value: isSelected,
                                                    onChanged: (_) =>
                                                        _toggleItemSelection(
                                                          stockCodeStr,
                                                        ),
                                                  )
                                                : null,
                                            title: Text(
                                              item.cropName ?? 'Unknown',
                                              style: TextStyle(
                                                fontSize: fontSize,
                                              ),
                                            ),
                                            subtitle: Text(
                                              // Qty: 5
                                              'Qty: ${item.quantityAvailable ?? 0}'
                                              // (MINI 1.5 KILOGRAM)
                                              '${item.packagingTypeName != null && item.quantity != null && item.unitName != null ? ' (${item.packagingTypeName} ${_formatQty(item.quantity)} ${item.unitName})' : ''}'
                                              // Packages Available / Out of stock
                                              ' Packages | '
                                              '${(item.isAvailable == 'Yes' || item.isAvailable == 'Y') ? 'Available' : 'Out of stock'}'
                                              // | Damaged: 1 (only if damaged > 0)
                                              '${item.quantityDamaged != null && item.quantityDamaged! > 0 ? ' | Damaged: ${item.quantityDamaged}' : ''}',
                                              style: TextStyle(
                                                fontSize: fontSize * 0.85,
                                              ),
                                            ),
                                            onTap: _selectionMode
                                                ? () => _toggleItemSelection(
                                                    stockCodeStr,
                                                  )
                                                : null,
                                            trailing: _selectionMode
                                                ? null
                                                : Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.remove_red_eye,
                                                        ),
                                                        color: Colors.blue[700],
                                                        iconSize: iconSize,
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                        onPressed: () =>
                                                            _viewDetails(item),
                                                        tooltip: 'View Details',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.edit,
                                                        ),
                                                        color:
                                                            Colors.green[700],
                                                        iconSize: iconSize,
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) =>
                                                                  AddEditStockScreen(
                                                                    hubCode:
                                                                        selectedHub,
                                                                    stockItem:
                                                                        item,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // ✅ Bulk action bar
                                  if (_selectionMode)
                                    SafeArea(
                                      child: Container(
                                        padding: EdgeInsets.all(padding),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(20),
                                              blurRadius: 6,
                                              offset: const Offset(0, -2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: _isUpdating
                                                    ? null
                                                    : () =>
                                                          _applyAvailabilityUpdate(
                                                            true,
                                                            selectedHub,
                                                            items,
                                                          ),
                                                icon: const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                ),
                                                label: const Text(
                                                  'Available',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.green[700],
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: _isUpdating
                                                    ? null
                                                    : () =>
                                                          _applyAvailabilityUpdate(
                                                            false,
                                                            selectedHub,
                                                            items,
                                                          ),
                                                icon: const Icon(
                                                  Icons.cancel,
                                                  color: Colors.white,
                                                ),
                                                label: const Text(
                                                  'Not Available',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red[700],
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: (selectedHub != null && !_selectionMode)
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF388E3C),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditStockScreen(hubCode: selectedHub),
                ),
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: isVerySmall ? 20 : 24,
              ),
            )
          : null,
    );
  }
}
