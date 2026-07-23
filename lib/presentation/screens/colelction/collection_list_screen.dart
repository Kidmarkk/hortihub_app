import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import 'package:hortihub_new_app/widgets/icon_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/selected_hub_provider.dart';
import '../../../data/models/collection_models.dart';
import '../../../widgets/hub_selection_widget.dart';
import 'add_edit_collection_screen.dart';

class CollectionListScreen extends ConsumerStatefulWidget {
  final String? hubCode;
  const CollectionListScreen({super.key, this.hubCode});

  @override
  ConsumerState<CollectionListScreen> createState() =>
      _CollectionListScreenState();
}

class _CollectionListScreenState extends ConsumerState<CollectionListScreen> {
  void _viewDetails(Collection item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Collection Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Farmer Name', item.farmerName ?? 'N/A'),
              _detailRow('Crop Category', item.cropCategoryName ?? 'N/A'),
              _detailRow('Crop Name', item.cropName ?? 'N/A'),
              _detailRow('Quantity Collected', item.quantity ?? 'N/A'),
              _detailRow('Quantity Rejected', item.rejected ?? 'N/A'),
              _detailRow('Financial Year', item.finyearName ?? item.finyearCode ?? 'N/A'),
              _detailRow('Hub Name', item.hubName ?? 'N/A'),
              _detailRow('District', item.districtName ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
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

    if (user?.userRole == 'HUBUSER' && selectedHub == null && user?.hubCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedHubProvider.notifier).state = user?.hubCode;
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Collection List')),
      body: Column(
        children: [
          const HubSelectionWidget(),
          IconHelper(
            items: [
              IconHelperItem(icon: Icons.remove_red_eye, label: 'View Details', color: Colors.blue),
              IconHelperItem(icon: Icons.edit, label: 'Edit Details', color: Colors.green),
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
                          'Select a district and hub to view collection data',
                          style: TextStyle(color: Colors.grey, fontSize: fontSize),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Consumer(
                    builder: (ctx, ref, _) {
                      final collectionAsync = ref.watch(collectionListProvider(selectedHub));
                      return collectionAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(fontSize: fontSize))),
                        data: (items) => items.isEmpty
                            ? Center(child: Text('No collection records', style: TextStyle(fontSize: fontSize)))
                            : ListView.builder(
                                padding: EdgeInsets.all(padding),
                                itemCount: items.length,
                                itemBuilder: (ctx, i) {
                                  final item = items[i];
                                  return Card(
                                    margin: cardMargin,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: padding,
                                        vertical: 4,
                                      ),
                                      title: Text(
                                        item.cropName ?? 'Unknown',
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                      subtitle: Text(
                                        'Farmer: ${item.farmerName} | Qty: ${item.quantity} ${item.unitName} | Rejected: ${item.rejected}',
                                        style: TextStyle(fontSize: fontSize * 0.85),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_red_eye),
                                            color: Colors.blue[700],
                                            iconSize: iconSize,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _viewDetails(item),
                                            tooltip: 'View Details',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            color: Colors.green[700],
                                            iconSize: iconSize,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => AddEditCollectionScreen(
                                                    hubCode: selectedHub,
                                                    collection: item,
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
                MaterialPageRoute(
                  builder: (_) => AddEditCollectionScreen(hubCode: selectedHub),
                ),
              ),
              child: Icon(Icons.add, color: Colors.white, size: isVerySmall ? 20 : 24),
            )
          : null,
    );
  }
}