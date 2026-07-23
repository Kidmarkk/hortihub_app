class Rate {
  final String? rateCode;
  final String? hubCode;
  final String? cropCode;
  final String? packagingTypeCode;
  final String? quantity;
  final String? unitCode;
  final String? amount;
  final String? appliesFrom;
  final String? hubName;
  final String? cropName;
  final String? packagingTypeName;
  final String? unitName;
  final String? districtCode;
  final String? districtName;
  final String? cropCategoryCode;
  final String? cropCategoryName;
  final String? userCode;

  Rate({
    this.rateCode,
    this.hubCode,
    this.cropCode,
    this.packagingTypeCode,
    this.quantity,
    this.unitCode,
    this.amount,
    this.appliesFrom,
    this.hubName,
    this.cropName,
    this.packagingTypeName,
    this.unitName,
    this.districtCode,
    this.districtName,
    this.cropCategoryCode,
    this.cropCategoryName,
    this.userCode,
  });

  factory Rate.fromJson(Map<String, dynamic> json) => Rate(
    rateCode: json['rateCode']?.toString(),
    hubCode: json['hubCode']?.toString(),
    cropCode: json['cropCode']?.toString(),
    packagingTypeCode: json['packagingTypeCode']?.toString(),
    quantity: json['quantity']?.toString(),
    unitCode: json['unitCode']?.toString(),
    amount: json['amount']?.toString(),
    appliesFrom: json['appliesFrom'],
    hubName: json['hubName'],
    cropName: json['cropName'],
    packagingTypeName: json['packagingTypeName'],
    unitName: json['unitName'],
    districtCode: json['districtCode']?.toString(),
    districtName: json['districtName'],
    cropCategoryCode: json['cropCategoryCode']?.toString(),
    cropCategoryName: json['cropCategoryName'],
    userCode: json['userCode']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'rateCode': rateCode,
    'hubCode': hubCode,
    'cropCode': cropCode,
    'packagingTypeCode': packagingTypeCode,
    'quantity': quantity,
    'unitCode': unitCode,
    'amount': amount,
    'appliesFrom': appliesFrom,
    'hubName': hubName,
    'cropName': cropName,
    'packagingTypeName': packagingTypeName,
    'unitName': unitName,
    'districtCode': districtCode,
    'districtName': districtName,
    'cropCategoryCode': cropCategoryCode,
    'cropCategoryName': cropCategoryName,
    'userCode': userCode,
  };
}