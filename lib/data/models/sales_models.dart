class SalesOrder {
  int? salesOrderCode;
  int hubCode;
  String buyerName;
  String buyerAddress;
  String? buyerMobile;
  String? receiptno;
  String? entrydate;
  List<SalesOrderItem> items;
  double? totalPrice;
  String? hubName;
  int? districtCode;
  String? districtName;
  int userCode;

  SalesOrder({
    this.salesOrderCode,
    required this.hubCode,
    required this.buyerName,
    required this.buyerAddress,
    this.buyerMobile,
    this.receiptno,
    this.entrydate,
    required this.items,
    this.totalPrice,
    this.hubName,
    this.districtCode,
    this.districtName,
    required this.userCode,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) => SalesOrder(
    salesOrderCode: json['salesOrderCode'] != null ? int.tryParse(json['salesOrderCode'].toString()) : null,
    hubCode: int.tryParse(json['hubCode'].toString()) ?? 0,
    buyerName: json['buyerName'] ?? '',
    buyerAddress: json['buyerAddress'] ?? '',
    buyerMobile: json['buyerMobile'],
    receiptno: json['receiptno'],
    entrydate: json['entrydate'],
    totalPrice: json['totalPrice'] != null ? double.tryParse(json['totalPrice'].toString()) : null,
    hubName: json['hubName'],
    districtCode: json['districtCode'] != null ? int.tryParse(json['districtCode'].toString()) : null,
    districtName: json['districtName'],
    userCode: int.tryParse(json['userCode'].toString()) ?? 0,
    items: (json['items'] as List?)?.map((i) => SalesOrderItem.fromJson(i)).toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'salesOrderCode': salesOrderCode,
    'hubCode': hubCode,
    'buyerName': buyerName,
    'buyerAddress': buyerAddress,
    'buyerMobile': buyerMobile,
    'receiptno': receiptno,
    'entrydate': entrydate,
    'totalPrice': totalPrice,
    'hubName': hubName,
    'districtCode': districtCode,
    'districtName': districtName,
    'userCode': userCode,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

class SalesOrderItem {
  int? salesOrderCode;
  int? salesOrderItemCode;
  String? cropCategoryName;
  String? cropName;
  String? packagingTypeName;
  double itemPrice;
  int quantity;
  double totalPrice;
  int cropCode;
  int packagingTypeCode;

  SalesOrderItem({
    this.salesOrderCode,
    this.salesOrderItemCode,
    this.cropCategoryName,
    this.cropName,
    this.packagingTypeName,
    required this.itemPrice,
    required this.quantity,
    required this.totalPrice,
    required this.cropCode,
    required this.packagingTypeCode,
  });

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) => SalesOrderItem(
    salesOrderCode: json['salesOrderCode'] != null ? int.tryParse(json['salesOrderCode'].toString()) : null,
    salesOrderItemCode: json['salesOrderItemCode'] != null ? int.tryParse(json['salesOrderItemCode'].toString()) : null,
    cropCategoryName: json['cropCategoryName'],
    cropName: json['cropName'],
    packagingTypeName: json['packagingTypeName'],
    itemPrice: double.tryParse(json['itemPrice'].toString()) ?? 0.0,
    quantity: int.tryParse(json['quantity'].toString()) ?? 0,
    totalPrice: double.tryParse(json['totalPrice'].toString()) ?? 0.0,
    cropCode: int.tryParse(json['cropCode'].toString()) ?? 0,
    packagingTypeCode: int.tryParse(json['packagingTypeCode'].toString()) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'salesOrderCode': salesOrderCode,
    'salesOrderItemCode': salesOrderItemCode,
    'cropCategoryName': cropCategoryName,
    'cropName': cropName,
    'packagingTypeName': packagingTypeName,
    'itemPrice': itemPrice,
    'quantity': quantity,
    'totalPrice': totalPrice,
    'cropCode': cropCode,
    'packagingTypeCode': packagingTypeCode,
  };
}

// StockItemForSale (unchanged)
class StockItemForSale {
  final int cropCode;
  final String cropName;
  final int packagingTypeCode;
  final String packagingTypeName;
  final int quantityAvailable;
  final double? amount;

  StockItemForSale({
    required this.cropCode,
    required this.cropName,
    required this.packagingTypeCode,
    required this.packagingTypeName,
    required this.quantityAvailable,
    this.amount,
  });

  factory StockItemForSale.fromJson(Map<String, dynamic> json) => StockItemForSale(
    cropCode: int.tryParse(json['cropCode'].toString()) ?? 0,
    cropName: json['cropName'] ?? '',
    packagingTypeCode: int.tryParse(json['packagingTypeCode'].toString()) ?? 0,
    packagingTypeName: json['packagingTypeName'] ?? '',
    quantityAvailable: int.tryParse(json['quantityAvailable'].toString()) ?? 0,
    amount: double.tryParse(json['amount']?.toString() ?? ''),
  );
}