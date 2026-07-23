import '../../core/constants/api_constants.dart';
import '../datasources/remote/api_service.dart';
import '../models/dropdown_models.dart';
import '../models/production_master_data.dart';

class ProductionMasterDataRepository {
  final ApiService _api = ApiService();

  Future<ProductionMasterData> getProductionMasterData(String hubCode) async {
    final response = await _api.postWithoutBodyNative(
      '${ApiConstants.productionList}$hubCode',
    );
    final data = response.data;
    return ProductionMasterData(
      financialYears: (data['listFinancialYears'] as List?)
          ?.map((e) => FinancialYear.fromJson(e))
          .toList() ?? [],
      cropCategories: (data['listCropCategory'] as List?)
          ?.map((e) => CropCategory.fromJson(e))
          .toList() ?? [],
      crops: (data['listCrops'] as List?)
          ?.map((e) => Crop.fromJson(e))
          .toList() ?? [],
      units: (data['listUnits'] as List?)
          ?.map((e) => Unit.fromJson(e))
          .toList() ?? [],
    );
  }
}