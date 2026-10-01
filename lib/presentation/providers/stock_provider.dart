import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/stock_models.dart';
import '../../data/repositories/stock_repository.dart';

final stockRepositoryProvider = Provider((ref) => StockRepository());

// Provider for stock list of a specific hub
final stockListProvider = FutureProvider.family<List<StockItem>, String>((
  ref,
  hubCode,
) async {
  final repo = ref.read(stockRepositoryProvider);
  return await repo.getStockList(hubCode);
});

// Notifier for add/edit stock
final addStockNotifierProvider =
    StateNotifierProvider<AddStockNotifier, AsyncValue<void>>((ref) {
      return AddStockNotifier(ref.read(stockRepositoryProvider));
    });

class AddStockNotifier extends StateNotifier<AsyncValue<void>> {
  final StockRepository _repo;
  String? _lastResponseMessage;

  AddStockNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<String> addStock(Map<String, String> payload, String token) async {
    state = const AsyncValue.loading();
    try {
      final message = await _repo.addStockItem(payload, token);
      _lastResponseMessage = message;
      state = const AsyncValue.data(null);
      return message;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStock(Map<String, String> payload, String token) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateStockItem(payload, token);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> updateAvailability({
    required String hubCode,
    required String userCode,
    String? districtCode,
    required List<String> isAvailableArray,
    required List<String> isNotAvailableArray,
  }) async {
    state = const AsyncValue.loading();
    try {
      final message = await _repo.updateAvailability(
        hubCode: hubCode,
        userCode: userCode,
        districtCode: districtCode,
        isAvailableArray: isAvailableArray,
        isNotAvailableArray: isNotAvailableArray,
      );
      _lastResponseMessage = message;
      state = const AsyncValue.data(null);
      return message;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  String? get lastResponseMessage => _lastResponseMessage;
}
