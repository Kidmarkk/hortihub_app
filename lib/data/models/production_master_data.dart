import 'dropdown_models.dart';

class ProductionMasterData {
  final List<FinancialYear> financialYears;
  final List<CropCategory> cropCategories;
  final List<Crop> crops;
  final List<Unit> units;

  ProductionMasterData({
    required this.financialYears,
    required this.cropCategories,
    required this.crops,
    required this.units,
  });
}