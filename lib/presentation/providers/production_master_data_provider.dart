import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/production_master_data_repository.dart';
import '../../data/models/dropdown_models.dart';
import '../../data/models/production_master_data.dart';
import 'auth_provider.dart';

final productionMasterDataRepositoryProvider = Provider((ref) => ProductionMasterDataRepository());

final productionMasterDataProvider = FutureProvider<ProductionMasterData>((ref) async {
  final user = ref.watch(authStateProvider).value;
  final hubCode = user?.hubCode ?? '1';
  final repo = ref.read(productionMasterDataRepositoryProvider);
  return await repo.getProductionMasterData(hubCode);
});

final financialYearsProvider = FutureProvider<List<FinancialYear>>((ref) async {
  final data = await ref.watch(productionMasterDataProvider.future);
  return data.financialYears;
});

final productionCropCategoriesProvider = FutureProvider<List<CropCategory>>((ref) async {
  final data = await ref.watch(productionMasterDataProvider.future);
  return data.cropCategories;
});

final productionCropsProvider = FutureProvider<List<Crop>>((ref) async {
  final data = await ref.watch(productionMasterDataProvider.future);
  return data.crops;
});

final productionUnitsProvider = FutureProvider<List<Unit>>((ref) async {
  final data = await ref.watch(productionMasterDataProvider.future);
  return data.units;
});