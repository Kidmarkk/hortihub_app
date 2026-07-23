import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/farmer_models.dart';
import '../../data/repositories/farmer_repository.dart';

final farmerRepositoryProvider = Provider((ref) => FarmerRepository());

final farmerListProvider = FutureProvider.family<List<Farmer>, String>((
  ref,
  hubCode,
) async {
  final repo = ref.read(farmerRepositoryProvider);
  return await repo.getFarmers(hubCode);
});

final addFarmerNotifierProvider =
    StateNotifierProvider<AddFarmerNotifier, AsyncValue<void>>((ref) {
      return AddFarmerNotifier(ref.read(farmerRepositoryProvider));
    });

class AddFarmerNotifier extends StateNotifier<AsyncValue<void>> {
  final FarmerRepository _repo;
  AddFarmerNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> addFarmer(Map<String, String> payload, String hubCode) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addFarmer(payload, hubCode);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateFarmer(Map<String, String> payload) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateFarmer(payload);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
