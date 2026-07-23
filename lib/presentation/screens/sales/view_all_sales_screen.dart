import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import 'package:hortihub_new_app/widgets/icon_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/selected_hub_provider.dart';
import '../../../data/models/sales_models.dart';
import '../../../widgets/hub_selection_widget.dart';
import 'new_sale_screen.dart';

class ViewAllSalesScreen extends ConsumerStatefulWidget {
  final String? hubCode;
  const ViewAllSalesScreen({super.key, this.hubCode});

  @override
  ConsumerState<ViewAllSalesScreen> createState() => _ViewAllSalesScreenState();
}

class _ViewAllSalesScreenState extends ConsumerState<ViewAllSalesScreen> {
  Future<void> _downloadInvoice(String salesOrderCode, String token) async {
    try {
      final repo = ref.read(salesRepositoryProvider);
      final base64 = await repo.generateInvoice(salesOrderCode, token);
      final bytes = base64Decode(base64);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invoice_$salesOrderCode.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice for Sale Order $salesOrderCode');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate invoice: $e')));
    }
  }

  void _viewDetails(SalesOrder sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sale Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Receipt: ${sale.receiptno ?? 'N/A'}'),
              Text('Buyer: ${sale.buyerName}'),
              Text('Address: ${sale.buyerAddress}'),
              Text('Mobile: ${sale.buyerMobile}'),
              Text('Date: ${sale.entrydate}'),
              Text('Hub: ${sale.hubName ?? 'N/A'}'),
              Text('District: ${sale.districtName ?? 'N/A'}'),
              Text('Total: ₹${sale.totalPrice}'),
              const SizedBox(height: 8),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(sale.items ?? []).map(
                (item) => Text('${item.cropName} x${item.quantity} = ₹${item.totalPrice}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
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
    final padding = EdgeInsets.all(Responsive.getResponsivePadding(context));

    // For hubuser, auto-set the hub if not set
    if (user?.userRole == 'HUBUSER' && selectedHub == null && user?.hubCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedHubProvider.notifier).state = user?.hubCode;
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sales Orders')),
      body: Column(
        children: [
          const HubSelectionWidget(),
          IconHelper(
            items: [
              IconHelperItem(
                icon: Icons.picture_as_pdf,
                label: 'Generate Invoice',
                color: Colors.redAccent,
              ),
              IconHelperItem(
                icon: Icons.remove_red_eye,
                label: 'View Details',
                color: Colors.blue,
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
                          'Select a district and hub to view sales data',
                          style: TextStyle(color: Colors.grey, fontSize: fontSize),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Consumer(
                    builder: (ctx, ref, _) {
                      final salesAsync = ref.watch(salesListProvider(selectedHub!));
                      return salesAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                        data: (sales) => sales.isEmpty
                            ? Center(child: Text('No sales found', style: TextStyle(fontSize: fontSize)))
                            : ListView.builder(
                                padding: padding,
                                itemCount: sales.length,
                                itemBuilder: (ctx, i) {
                                  final sale = sales[i];
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: Responsive.getResponsivePadding(context, basePadding: 4),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: Responsive.getResponsivePadding(context, basePadding: 12),
                                        vertical: 4,
                                      ),
                                      title: Text(
                                        sale.buyerName ?? 'Unknown',
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                      subtitle: Text(
                                        '₹${sale.totalPrice} | ${sale.entrydate}',
                                        style: TextStyle(fontSize: fontSize * 0.85),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.picture_as_pdf),
                                            color: Colors.redAccent,
                                            iconSize: iconSize,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              if (user != null && sale.salesOrderCode != null) {
                                                _downloadInvoice(sale.salesOrderCode!.toString(), user.token);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('User not logged in or order code missing')),
                                                );
                                              }
                                            },
                                            tooltip: 'Invoice',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.remove_red_eye),
                                            color: Colors.blue[700],
                                            iconSize: iconSize,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _viewDetails(sale),
                                            tooltip: 'Details',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: selectedHub != null
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF388E3C),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NewSaleScreen(hubCode: selectedHub!)),
              ),
              child: Icon(Icons.add, color: Colors.white, size: isVerySmall ? 20 : 24),
            )
          : null,
    );
  }
}