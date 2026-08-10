import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/models/dropdown_models.dart';
import 'auth_provider.dart';

final masterDataRepositoryProvider = Provider((ref) => MasterDataRepository());

final masterDataProvider = FutureProvider.family<MasterData, String>((ref, hubCode) async {
  final repo = ref.read(masterDataRepositoryProvider);
  return await repo.getMasterData(hubCode);
});

final cropCategoriesProvider = FutureProvider.family<List<CropCategory>, String>((ref, hubCode) async {
  final data = await ref.watch(masterDataProvider(hubCode).future);
  return data.cropCategories;
});

final cropsProvider = FutureProvider.family<List<Crop>, String>((ref, hubCode) async {
  final data = await ref.watch(masterDataProvider(hubCode).future);
  return data.crops;
});

final packagingTypesProvider = FutureProvider.family<List<PackagingType>, String>((ref, hubCode) async {
  final data = await ref.watch(masterDataProvider(hubCode).future);
  return data.packagingTypes;
});

final unitsProvider = FutureProvider.family<List<Unit>, String>((ref, hubCode) async {
  final data = await ref.watch(masterDataProvider(hubCode).future);
  return data.units;
});