import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/hub_model.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/rate_provider.dart';
import '../../presentation/providers/stock_provider.dart';

class HubDetailScreen extends ConsumerStatefulWidget {
  final Hub hub;
  const HubDetailScreen({super.key, required this.hub});

  @override
  ConsumerState<HubDetailScreen> createState() => _HubDetailScreenState();
}

class _HubDetailScreenState extends ConsumerState<HubDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final ratesAsync = ref.watch(ratesListProvider(widget.hub.code));
    final stocksAsync = ref.watch(stockListProvider(widget.hub.code));

    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    // Use the district name already set in the hub object
    final String districtName = widget.hub.districtName ?? 'EAST KHASI HILLS';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hub.name),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6D4C41), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hub header
              Row(
                children: [
                  Icon(Icons.location_city, color: Colors.green[700], size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.hub.name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'District: $districtName',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Crops section title
              Row(
                children: [
                  Icon(Icons.agriculture, color: Colors.green[700], size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Crops Available',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ratesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (rates) {
                    final uniqueCrops = rates
                        .map((r) => r.cropName)
                        .where((name) => name != null && name.isNotEmpty)
                        .toSet()
                        .toList();

                    if (uniqueCrops.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'No crops available for this hub.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return Consumer(
                      builder: (ctx, ref, _) {
                        final stocksState = ref.watch(stockListProvider(widget.hub.code));
                        final stockByCropAndPackaging = <String, Map<String, int>>{};
                        stocksState.whenData((stocks) {
                          for (var stock in stocks) {
                            final cropCode = stock.cropCode?.toString() ?? '';
                            final packagingCode = stock.packagingTypeCode?.toString() ?? '';
                            if (cropCode.isNotEmpty && packagingCode.isNotEmpty) {
                              stockByCropAndPackaging.putIfAbsent(cropCode, () => {});
                              stockByCropAndPackaging[cropCode]![packagingCode] =
                                  stock.quantityAvailable ?? 0;
                            }
                          }
                        });

                        return ListView.builder(
                          itemCount: uniqueCrops.length,
                          itemBuilder: (ctx, index) {
                            final cropName = uniqueCrops[index]!;
                            final cropRates = rates.where((r) => r.cropName == cropName).toList();
                            final cropCode = cropRates.isNotEmpty ? cropRates.first.cropCode ?? '' : '';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                leading: Icon(Icons.grass, color: Colors.green[700]),
                                title: Text(
                                  cropName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                children: cropRates.map((rate) {
                                  final packagingCode = rate.packagingTypeCode ?? '';
                                  final stockQty = stockByCropAndPackaging[cropCode]?[packagingCode] ?? 0;
                                  final isInStock = stockQty > 0;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  rate.packagingTypeName ?? 'N/A',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 12,
                                                  runSpacing: 4,
                                                  children: [
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.currency_rupee, size: 14, color: Colors.grey[600]),
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          '${rate.amount ?? '0'}',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.green[700],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.scale, size: 14, color: Colors.grey[600]),
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          '${rate.quantity ?? '0'} ${rate.unitName ?? ''}',
                                                          style: const TextStyle(color: Colors.black54),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isInStock ? Colors.green.shade100 : Colors.red.shade100,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isInStock ? Icons.check_circle : Icons.cancel,
                                                    color: isInStock ? Colors.green : Colors.red,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      isInStock ? 'In Stock: $stockQty' : 'Out of Stock',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        color: isInStock ? Colors.green[700] : Colors.red[700],
                                                        fontSize: 12,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}