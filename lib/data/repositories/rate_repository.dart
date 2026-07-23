import '../../core/constants/api_constants.dart';
import '../datasources/remote/api_service.dart';
import '../models/rate_models.dart';

class RateRepository {
  final ApiService _api = ApiService();

  Future<List<Rate>> getRatesList(String hubCode) async {
    final response = await _api.postWithoutBodyNative(
      '${ApiConstants.ratesList}$hubCode',
    );
    final list = response.data['listDetails'] as List?;
    return list?.map((json) => Rate.fromJson(json)).toList() ?? [];
  }

  Future<void> addRate(Map<String, String> payload) async {
    final response = await _api.postWithFormData(ApiConstants.ratesAdd, payload);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Add rate failed: ${response.data}');
    }
  }

  Future<void> updateRate(Map<String, String> payload) async {
    final response = await _api.postWithFormData(ApiConstants.ratesUpdate, payload);
    if (response.statusCode != 200) {
      throw Exception('Update rate failed: ${response.data}');
    }
  }
}