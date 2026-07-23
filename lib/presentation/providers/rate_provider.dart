import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/rate_models.dart';
import '../../data/repositories/rate_repository.dart';

final rateRepositoryProvider = Provider((ref) => RateRepository());

final ratesListProvider = FutureProvider.family<List<Rate>, String>((ref, hubCode) async {
  final repo = ref.read(rateRepositoryProvider);
  return await repo.getRatesList(hubCode);
});

final addRateNotifierProvider = StateNotifierProvider<AddRateNotifier, AsyncValue<void>>((ref) {
  return AddRateNotifier(ref.read(rateRepositoryProvider));
});

class AddRateNotifier extends StateNotifier<AsyncValue<void>> {
  final RateRepository _repo;
  AddRateNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> addRate(Map<String, String> payload) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addRate(payload);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRate(Map<String, String> payload) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateRate(payload);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}