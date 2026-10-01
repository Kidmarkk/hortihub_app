import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/sales_models.dart';
import '../../data/repositories/sales_repository.dart';
import 'stock_provider.dart';

final salesRepositoryProvider = Provider((ref) => SalesRepository());

// Provider for sales list of a specific hub
final salesListProvider = FutureProvider.family<List<SalesOrder>, String>((
  ref,
  hubCode,
) async {
  final repo = ref.read(salesRepositoryProvider);
  return await repo.getSalesList(hubCode);
});

// Provider for stock items (for sale)
final stockForSaleProvider =
    FutureProvider.family<List<StockItemForSale>, String>((ref, hubCode) async {
      await ref.watch(stockListProvider(hubCode).future);
      final repo = ref.read(salesRepositoryProvider);
      final result = await repo.getStockForSale(hubCode);
      return result;
    });

// Notifier for adding a sale (handles loading state)
final addSaleNotifierProvider =
    StateNotifierProvider<AddSaleNotifier, AsyncValue<void>>((ref) {
      return AddSaleNotifier(ref.read(salesRepositoryProvider));
    });

class AddSaleNotifier extends StateNotifier<AsyncValue<void>> {
  final SalesRepository _repo;
  AddSaleNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> addSale(SalesOrder order) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addSaleOrder(order);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
