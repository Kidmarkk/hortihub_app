import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/collection_models.dart';
import '../../data/repositories/collection_repository.dart';

final collectionRepositoryProvider = Provider((ref) => CollectionRepository());

final collectionListProvider = FutureProvider.family<List<Collection>, String>((ref, hubCode) async {
  final repo = ref.read(collectionRepositoryProvider);
  return await repo.getCollectionList(hubCode);
});

final addCollectionNotifierProvider = StateNotifierProvider<AddCollectionNotifier, AsyncValue<void>>((ref) {
  return AddCollectionNotifier(ref.read(collectionRepositoryProvider));
});

class AddCollectionNotifier extends StateNotifier<AsyncValue<void>> {
  final CollectionRepository _repo;
  AddCollectionNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> addCollection(Map<String, String> payload) async {
    state = const AsyncValue.loading();
    try {
      await _repo.addCollection(payload);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCollection(Map<String, String> payload) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateCollection(payload);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}