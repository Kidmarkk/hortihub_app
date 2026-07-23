import 'dropdown_models.dart';

class CollectionMasterData {
  final List<FinancialYear> financialYears;
  final List<CropCategory> cropCategories;
  final List<Crop> crops;
  final List<Unit> units;
  final List<FarmerInfo> farmers; 

  CollectionMasterData({
    required this.financialYears,
    required this.cropCategories,
    required this.crops,
    required this.units,
    required this.farmers,
  });
}