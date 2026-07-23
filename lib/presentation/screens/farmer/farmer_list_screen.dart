import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/presentation/providers/auth_provider.dart';
import 'package:hortihub_new_app/presentation/providers/farmer_provider.dart';
import 'package:hortihub_new_app/presentation/providers/selected_hub_provider.dart';
import 'package:hortihub_new_app/presentation/screens/farmer/add_edit_farmer_screen.dart';
import 'package:hortihub_new_app/widgets/hub_selection_widget.dart';
import '../../../data/models/farmer_models.dart';

class FarmerListScreen extends ConsumerStatefulWidget {
  final String? hubCode;
  const FarmerListScreen({super.key, this.hubCode});

  @override
  ConsumerState<FarmerListScreen> createState() => _FarmerListScreenState();
}

class _FarmerListScreenState extends ConsumerState<FarmerListScreen> {
  void _viewDetails(Farmer farmer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Farmer Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Farmer Name', farmer.farmerName ?? 'N/A'),
              _detailRow('Village', farmer.villageName ?? 'N/A'),
              _detailRow('Mobile', farmer.mobileno ?? 'N/A'),
              _detailRow('Hub Name', farmer.hubName ?? 'N/A'),
              _detailRow('District', farmer.districtName ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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

    // For hubuser, auto-set the hub if not set
    if (user?.userRole == 'HUBUSER' && selectedHub == null && user?.hubCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedHubProvider.notifier).state = user?.hubCode;
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Farmers')),
      body: Column(
        children: [
          const HubSelectionWidget(),
          Expanded(
            child: selectedHub == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Select a district and hub to view farmers',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Consumer(
                    builder: (ctx, ref, _) {
                      final farmersAsync = ref.watch(farmerListProvider(selectedHub!));
                      return farmersAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                        data: (farmers) => farmers.isEmpty
                            ? const Center(child: Text('No farmers found'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: farmers.length,
                                itemBuilder: (ctx, i) {
                                  final farmer = farmers[i];
                                  return Card(
                                    child: ListTile(
                                      title: Text(farmer.farmerName ?? 'Unknown'),
                                      subtitle: Text('Village: ${farmer.villageName ?? 'N/A'} | Mobile: ${farmer.mobileno ?? 'N/A'}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_red_eye),
                                            onPressed: () => _viewDetails(farmer),
                                            tooltip: 'View Details',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => AddEditFarmerScreen(
                                                    hubCode: selectedHub!,
                                                    farmer: farmer,
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditFarmerScreen(hubCode: selectedHub!),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}