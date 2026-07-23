import '../../core/constants/api_constants.dart';
import '../datasources/remote/api_service.dart';
import '../models/production_models.dart';

class ProductionRepository {
  final ApiService _api = ApiService();

  Future<List<Production>> getProductionList(String hubCode) async {
    final response = await _api.postWithoutBodyNative(
      '${ApiConstants.productionList}$hubCode',
    );
    final list = response.data['listDetails'] as List?;
    return list?.map((json) => Production.fromJson(json)).toList() ?? [];
  }

  Future<void> addProduction(Map<String, String> payload) async {
    final response = await _api.postWithFormData(ApiConstants.productionAdd, payload);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Add failed: ${response.data}');
    }
  }

  Future<void> updateProduction(Map<String, String> payload) async {
    final response = await _api.postWithFormData(ApiConstants.productionUpdate, payload);
    if (response.statusCode != 200) {
      throw Exception('Update failed: ${response.data}');
    }
  }
}