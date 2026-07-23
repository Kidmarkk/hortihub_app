import '../../core/constants/api_constants.dart';
import '../datasources/remote/api_service.dart';
import '../models/sales_models.dart';
import '../../core/utils/auth_utils.dart';

class SalesRepository {
  final ApiService _api = ApiService();

  // Fetch sales list for a given hub
  Future<List<SalesOrder>> getSalesList(String hubCode) async {
    final response = await _api.postWithoutBodyNative(
      '${ApiConstants.salesList}$hubCode',
    );
    print('📦 Sales full response: ${response.data}');
    // The response has a key "listDetails" (list of sales orders)
    final list = response.data['listDetails'] as List?;
    if (list == null) {
      print('⚠️ listDetails is null, raw response: ${response.data}');
      return [];
    }
    return list.map((json) => SalesOrder.fromJson(json)).toList();
  }

  // Fetch stock items for a hub (to populate the "add sale" dropdowns)
  Future<List<StockItemForSale>> getStockForSale(String hubCode) async {
    final response = await _api.postWithoutBodyNative(
      '${ApiConstants.salesList}$hubCode',
    );
    final list = response.data['listDetailsForStock'] as List;
    return list.map((json) => StockItemForSale.fromJson(json)).toList();
  }

  // Add new sale order
  Future<void> addSaleOrder(SalesOrder order) async {
    await _api.post(ApiConstants.salesAdd, data: order.toJson());
  }

  // Generate invoice (returns base64 string)
  Future<String> generateInvoice(String salesOrderCode, String token) async {
    final response = await _api.getNative(
      ApiConstants.generateInvoice,
      queryParameters: {'salesOrderCode': salesOrderCode},
      customHeaders: {'Authorization': 'Bearer $token'}, // token already passed
    );
    return response.data['pdfData'];
  }
}
