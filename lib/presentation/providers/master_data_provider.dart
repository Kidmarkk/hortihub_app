import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../data/models/dropdown_models.dart';
import 'auth_provider.dart';

final masterDataRepositoryProvider = Provider((ref) => MasterDataRepository());

// Provider that fetches master data using the current user's hubCode
final masterDataProvider = FutureProvider<MasterData>((ref) async {
  final user = ref.watch(authStateProvider).value;
  final hubCode = user?.hubCode ?? '1'; // fallback hubCode
  final repo = ref.read(masterDataRepositoryProvider);
  return await repo.getMasterData(hubCode);
});

// Individual providers for each list
final cropCategoriesProvider = FutureProvider<List<CropCategory>>((ref) async {
  final data = await ref.watch(masterDataProvider.future);
  return data.cropCategories;
});

final cropsProvider = FutureProvider<List<Crop>>((ref) async {
  final data = await ref.watch(masterDataProvider.future);
  return data.crops;
});

final packagingTypesProvider = FutureProvider<List<PackagingType>>((ref) async {
  final data = await ref.watch(masterDataProvider.future);
  return data.packagingTypes;
});

final unitsProvider = FutureProvider<List<Unit>>((ref) async {
  final data = await ref.watch(masterDataProvider.future);
  return data.units;
});