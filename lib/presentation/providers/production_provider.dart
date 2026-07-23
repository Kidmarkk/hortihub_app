import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/production_models.dart';
import '../../data/repositories/production_repository.dart';

final productionRepositoryProvider = Provider((ref) => ProductionRepository());

final productionListProvider = FutureProvider.family<List<Production>, String>((ref, hubCode) async {
  final repo = ref.read(productionRepositoryProvider);
  return await repo.getProductionList(hubCode);
});

final addProductionNotifierProvider = StateNotifierProvider<AddProductionNotifier, AsyncValue<void>>((ref) {
  return AddProductionNotifier(ref.read(productionRepositoryProvider));
});

class AddProductionNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductionRepository _repo;
  AddProductionNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> addProduction(Map<String, String> payload) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addProduction(payload);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProduction(Map<String, String> payload) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateProduction(payload);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}