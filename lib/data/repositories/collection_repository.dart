import '../../core/constants/api_constants.dart';
import '../datasources/remote/api_service.dart';
import '../models/collection_models.dart';

class CollectionRepository {
  final ApiService _api = ApiService();

  Future<List<Collection>> getCollectionList(String hubCode) async {
    final response = await _api.postWithoutBodyNative(
      '${ApiConstants.collectionList}$hubCode',
    );
    final list = response.data['listDetails'] as List?;
    return list?.map((json) => Collection.fromJson(json)).toList() ?? [];
  }

  Future<void> addCollection(Map<String, String> payload) async {
    final response = await _api.postWithFormData(ApiConstants.collectionAdd, payload);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Add failed: ${response.data}');
    }
  }

  Future<void> updateCollection(Map<String, String> payload) async {
    final response = await _api.postWithFormData(ApiConstants.collectionUpdate, payload);
    if (response.statusCode != 200) {
      throw Exception('Update failed: ${response.data}');
    }
  }
}