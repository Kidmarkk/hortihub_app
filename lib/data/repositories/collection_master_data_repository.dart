import '../../core/constants/api_constants.dart';
import '../datasources/remote/api_service.dart';
import '../models/dropdown_models.dart';
import '../models/collection_master_data.dart';

class CollectionMasterDataRepository {
  final ApiService _api = ApiService();

  Future<CollectionMasterData> getCollectionMasterData(String hubCode) async {
    final response = await _api.postWithoutBodyNative(
      '${ApiConstants.collectionList}$hubCode',
    );
    final data = response.data;
    final details = data['listDetails'] as List?;

    // Extract unique farmers from listDetails
    final Map<String, FarmerInfo> farmerMap = {};
    if (details != null) {
      for (var item in details) {
        final code = item['farmerCode']?.toString();
        if (code != null && code.isNotEmpty) {
          final name = item['farmerName'] ?? '';
          final village = item['villageName'];
          final mobile = item['mobileno'];
          if (!farmerMap.containsKey(code)) {
            farmerMap[code] = FarmerInfo(
              code: code,
              name: name,
              village: village,
              mobile: mobile,
            );
          }
        }
      }
    }

    return CollectionMasterData(
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
      farmers: farmerMap.values.toList(),
    );
  }
}