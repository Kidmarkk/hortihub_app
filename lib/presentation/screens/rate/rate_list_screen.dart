import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import 'package:hortihub_new_app/widgets/icon_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rate_provider.dart';
import '../../providers/selected_hub_provider.dart';
import '../../../data/models/rate_models.dart';
import '../../../widgets/hub_selection_widget.dart';
import 'add_edit_rate_screen.dart';

class RateListScreen extends ConsumerStatefulWidget {
  final String? hubCode;
  const RateListScreen({super.key, this.hubCode});

  @override
  ConsumerState<RateListScreen> createState() => _RateListScreenState();
}

class _RateListScreenState extends ConsumerState<RateListScreen> {
  void _viewDetails(Rate rate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rate Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Crop Name', rate.cropName ?? 'N/A'),
              _detailRow('Crop Category', rate.cropCategoryName ?? 'N/A'),
              _detailRow('Packaging Type', rate.packagingTypeName ?? 'N/A'),
              _detailRow('Quantity In Packaging', rate.quantity ?? 'N/A'),
              _detailRow(
                'Price',
                rate.amount != null ? '₹${rate.amount}' : 'N/A',
              ),
              _detailRow('Applied From', rate.appliesFrom ?? 'N/A'),
              _detailRow('Hub Name', rate.hubName ?? 'N/A'),
              _detailRow('District', rate.districtName ?? 'N/A'),
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = Responsive.isVerySmallScreen(context);
    final isSmall = Responsive.isSmallScreen(context);

    // Responsive font sizes
    final double titleSize = Responsive.getResponsiveFontSize(
      context,
      baseSize: 16,
    );
    final double subtitleSize = Responsive.getResponsiveFontSize(
      context,
      baseSize: 14,
    );
    final double iconSize = isVerySmall ? 18 : 24;
    final double iconSpacing = isVerySmall ? 4 : 8;

    // For hubuser, auto-set the hub if not set
    if (user?.userRole == 'HUBUSER' &&
        selectedHub == null &&
        user?.hubCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedHubProvider.notifier).state = user?.hubCode;
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF388E3C))));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rates List')),
      body: Column(
        children: [
          const HubSelectionWidget(),
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
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Select a district and hub to view rate data',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Consumer(
                    builder: (ctx, ref, _) {
                      final ratesAsync = ref.watch(
                        ratesListProvider(selectedHub!),
                      );
                      return ratesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C))),
                        error: (err, _) => Center(child: Text('Error: $err')),
                        data: (items) => items.isEmpty
                            ? const Center(child: Text('No rates found'))
                            : ListView.builder(
                                padding: EdgeInsets.all(
                                  Responsive.getResponsivePadding(context),
                                ),
                                itemCount: items.length,
                                itemBuilder: (ctx, i) {
                                  final rate = items[i];
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: isVerySmall ? 4 : 8,
                                      vertical: isVerySmall ? 4 : 8,
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(
                                        isVerySmall ? 6 : 8,
                                      ),
                                      title: Text(
                                        '${rate.cropName} - ${rate.packagingTypeName}',
                                        style: TextStyle(
                                          fontSize: titleSize,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        'Price: ₹${rate.amount} | Qty: ${rate.quantity} ${rate.unitName}',
                                        style: TextStyle(
                                          fontSize: subtitleSize,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Wrap(
                                        spacing: iconSpacing,
                                        runSpacing: 4,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove_red_eye,
                                              size: iconSize,
                                            ),
                                            color: Colors.blue[700],
                                            onPressed: () => _viewDetails(rate),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              size: iconSize,
                                            ),
                                            color: Colors.green[700],
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      AddEditRateScreen(
                                                        hubCode: selectedHub!,
                                                        rate: rate,
                                                      ),
                                                ),
                                              );
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditRateScreen(hubCode: selectedHub!),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
