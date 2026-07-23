class StockItem {
  final int? stockCode;
  final int? hubCode;
  final int? cropCode;
  final int? packagingTypeCode;
  final int? unitCode;
  final int? quantityAvailable;
  final String? isAvailable;
  final String? hubName;
  final String? cropName;
  final String? packagingTypeName;
  final String? unitName;
  final int? districtCode;
  final String? districtName;
  final int? cropCategoryCode;
  final String? cropCategoryName;
  final double? quantity;
  final double? amount;
  final int? userCode;

  StockItem({
    this.stockCode,
    this.hubCode,
    this.cropCode,
    this.packagingTypeCode,
    this.unitCode,
    this.quantityAvailable,
    this.isAvailable,
    this.hubName,
    this.cropName,
    this.packagingTypeName,
    this.unitName,
    this.districtCode,
    this.districtName,
    this.cropCategoryCode,
    this.cropCategoryName,
    this.quantity,
    this.amount,
    this.userCode,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    stockCode: int.tryParse(json['stockCode']?.toString() ?? ''),
    hubCode: int.tryParse(json['hubCode']?.toString() ?? ''),
    cropCode: int.tryParse(json['cropCode']?.toString() ?? ''),
    packagingTypeCode: int.tryParse(json['packagingTypeCode']?.toString() ?? ''),
    unitCode: int.tryParse(json['unitCode']?.toString() ?? ''),
    quantityAvailable: int.tryParse(json['quantityAvailable']?.toString() ?? ''),
    isAvailable: json['isAvailable'],
    hubName: json['hubName'],
    cropName: json['cropName'],
    packagingTypeName: json['packagingTypeName'],
    unitName: json['unitName'],
    districtCode: int.tryParse(json['districtCode']?.toString() ?? ''),
    districtName: json['districtName'],
    cropCategoryCode: int.tryParse(json['cropCategoryCode']?.toString() ?? ''),
    cropCategoryName: json['cropCategoryName'],
    quantity: double.tryParse(json['quantity']?.toString() ?? ''),
    amount: double.tryParse(json['amount']?.toString() ?? ''),
    userCode: int.tryParse(json['userCode']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'stockCode': stockCode,
    'hubCode': hubCode,
    'cropCode': cropCode,
    'packagingTypeCode': packagingTypeCode,
    'unitCode': unitCode,
    'quantityAvailable': quantityAvailable,
    'isAvailable': isAvailable,
    'hubName': hubName,
    'cropName': cropName,
    'packagingTypeName': packagingTypeName,
    'unitName': unitName,
    'districtCode': districtCode,
    'districtName': districtName,
    'cropCategoryCode': cropCategoryCode,
    'cropCategoryName': cropCategoryName,
    'quantity': quantity,
    'amount': amount,
    'userCode': userCode,
  };
}