import '../../core/constants/api_constants.dart';
import '../datasources/remote/api_service.dart';

class HubRepository {
  final ApiService _api = ApiService();

  Future<List<Map<String, String>>> getHubsForDistrict(String districtCode) async {
    final response = await _api.postWithoutBodyNative(
      '${ApiConstants.hubListForDistrict}$districtCode',
    );
    final list = response.data as List?;
    if (list == null) return [];
    return list.map<Map<String, String>>((item) => {
          'key': item['key']?.toString() ?? '',
          'value': item['value'] ?? '',
        }).toList();
  }
}