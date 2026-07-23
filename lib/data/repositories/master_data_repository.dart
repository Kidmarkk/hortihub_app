import '../../core/constants/api_constants.dart';
import '../datasources/remote/api_service.dart';
import '../models/dropdown_models.dart';

class MasterDataRepository {
  final ApiService _api = ApiService();

  Future<MasterData> getMasterData(String hubCode) async {
    final response = await _api.postWithoutBodyNative(
      '${ApiConstants.ratesList}$hubCode',
    );
    final data = response.data;
    final rates = (data['listDetails'] as List?)
        ?.map((e) => RateInfo.fromJson(e))
        .toList() ?? [];
    return MasterData(
      cropCategories: (data['listCropCategory'] as List?)
          ?.map((e) => CropCategory.fromJson(e))
          .toList() ?? [],
      crops: (data['listCrops'] as List?)
          ?.map((e) => Crop.fromJson(e))
          .toList() ?? [],
      packagingTypes: (data['listPackagingTypes'] as List?)
          ?.map((e) => PackagingType.fromJson(e))
          .toList() ?? [],
      units: (data['listUnits'] as List?)
          ?.map((e) => Unit.fromJson(e))
          .toList() ?? [],
      rates: rates,
    );
  }
}