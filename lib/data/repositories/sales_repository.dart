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

  Future<List<StockItemForSale>> getStockForSale(String hubCode) async {
  final response = await _api.postWithoutBodyNative(
    '${ApiConstants.stockList}$hubCode',
  );

  final listDetails = response.data['listDetails'];

  final list = listDetails as List? ?? [];

  final parsed = list.map((json) => StockItemForSale.fromJson(json)).toList();

  final filtered = parsed
      .where((item) {
      final avail = item.isAvailable?.trim().toLowerCase();
      final isMarkedAvailable = avail == 'yes' || avail == 'y';
      return isMarkedAvailable && item.netQuantity > 0;
    })
    .toList();

  return filtered;
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
