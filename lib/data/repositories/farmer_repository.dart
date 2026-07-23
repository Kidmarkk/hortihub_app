import '../../core/constants/api_constants.dart';
import '../datasources/remote/api_service.dart';
import '../models/farmer_models.dart';

class FarmerRepository {
  final ApiService _api = ApiService();

  // Fetch farmers from collection list endpoint
  Future<List<Farmer>> getFarmers(String hubCode) async {
    final response = await _api.postWithoutBodyNative(
      '${ApiConstants.collectionList}$hubCode',
    );
    final list = response.data['listDetails'] as List?;
    if (list == null) return [];

    final uniqueFarmers = <String, Farmer>{};
    for (var item in list) {
      final farmerCode = item['farmerCode']?.toString();
      if (farmerCode != null && farmerCode.isNotEmpty) {
        final farmer = Farmer.fromJson(item);
        uniqueFarmers[farmerCode] = farmer;
      }
    }
    return uniqueFarmers.values.toList();
  }

  // Add a new farmer using the collection add endpoint
  Future<void> addFarmer(Map<String, String> payload, String hubCode) async {
    // Fetch existing farmers to get max farmerCode
    final existingFarmers = await getFarmers(hubCode);
    int maxCode = 0;
    for (var f in existingFarmers) {
      if (f.farmerCode != null) {
        final code = int.tryParse(f.farmerCode!) ?? 0;
        if (code > maxCode) maxCode = code;
      }
    }
    final newCode = (maxCode + 1).toString();

    // Build payload for collection add
    final collectionPayload = <String, String>{
      'hubCode': hubCode,
      'finyearCode': '9', // default – we'll ask the API handler for the correct default
      'farmerCode': newCode,
      'cropCode': '1', // default – need to confirm
      'quantity': '0',
      'rejected': '0',
      'unitCode': '1', // default – need to confirm
      'farmerName': payload['farmerName']!,
      'villageName': payload['villageName']!,
      'mobileno': payload['mobileno']!,
      'userCode': payload['userCode']!,
    };

    final response = await _api.postWithFormData(ApiConstants.collectionAdd, collectionPayload);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Add farmer failed: ${response.data}');
    }
  }

  // Update farmer – we'll implement when we get the endpoint
  Future<void> updateFarmer(Map<String, String> payload) async {
    // Placeholder
    throw UnimplementedError('Update farmer not yet implemented');
  }
}