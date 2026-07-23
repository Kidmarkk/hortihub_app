import '../../core/constants/api_constants.dart';
import '../datasources/remote/api_service.dart';
import '../models/stock_models.dart';

class StockRepository {
  final ApiService _api = ApiService();

  // Fetch stock list for a given hub
  Future<List<StockItem>> getStockList(String hubCode) async {
    final response = await _api.postWithoutBodyNative(
      '${ApiConstants.stockList}$hubCode',
    );
    print('📦 Stock full response: ${response.data}');

    // Print each stockCode separately to avoid truncation
    final list = response.data['listDetails'] as List?;
    if (list != null) {
      print('📦 Number of stocks: ${list.length}');
      for (var item in list) {
        print('📦 stockCode: ${item['stockCode']}');
      }
    } else {
      print('⚠️ listDetails is null');
      return [];
    }

    return list.map((json) => StockItem.fromJson(json)).toList();
  }

  // Add new stock item
  Future<String> addStockItem(
    Map<String, dynamic> payload,
    String token,
  ) async {
    print('🟢 ADD STOCK PAYLOAD: $payload');
    final response = await _api.postWithFormData(
      ApiConstants.stockAdd,
      payload,
    );
    print('🟢 ADD RESPONSE STATUS: ${response.statusCode}');
    print('🟢 ADD RESPONSE BODY: ${response.data}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Add failed: ${response.data}');
    }
    // Extract the message from the response
    final raw =
        response.data['raw'] as String? ?? response.data['message'] as String?;
    return raw ?? 'Details Saved!';
  }

  Future<void> updateStockItem(
    Map<String, String> payload,
    String token,
  ) async {
    final response = await _api.postFormData(ApiConstants.stockUpdate, payload);
    if (response.statusCode != 200) throw Exception('Update failed');
  }
}
