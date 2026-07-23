import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/collection_master_data_repository.dart';
import '../../data/models/dropdown_models.dart';
import '../../data/models/collection_master_data.dart';
import 'auth_provider.dart';

final collectionMasterDataRepositoryProvider = Provider((ref) => CollectionMasterDataRepository());

final collectionMasterDataProvider = FutureProvider<CollectionMasterData>((ref) async {
  final user = ref.watch(authStateProvider).value;
  final hubCode = user?.hubCode ?? '1';
  final repo = ref.read(collectionMasterDataRepositoryProvider);
  return await repo.getCollectionMasterData(hubCode);
});

final collectionFinancialYearsProvider = FutureProvider<List<FinancialYear>>((ref) async {
  final data = await ref.watch(collectionMasterDataProvider.future);
  return data.financialYears;
});

final collectionCropCategoriesProvider = FutureProvider<List<CropCategory>>((ref) async {
  final data = await ref.watch(collectionMasterDataProvider.future);
  return data.cropCategories;
});

final collectionCropsProvider = FutureProvider<List<Crop>>((ref) async {
  final data = await ref.watch(collectionMasterDataProvider.future);
  return data.crops;
});

final collectionUnitsProvider = FutureProvider<List<Unit>>((ref) async {
  final data = await ref.watch(collectionMasterDataProvider.future);
  return data.units;
});

final collectionFarmersProvider = FutureProvider<List<FarmerInfo>>((ref) async {
  final data = await ref.watch(collectionMasterDataProvider.future);
  return data.farmers;
});