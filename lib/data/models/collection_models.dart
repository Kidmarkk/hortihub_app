class Collection {
  final String? collectionCode;
  final String? hubCode;
  final String? finyearCode;
  final String? farmerCode;
  final String? cropCode;
  final String? quantity;
  final String? rejected;
  final String? unitCode;
  final String? hubName;
  final String? farmerName;
  final String? cropName;
  final String? finyearName;
  final String? unitName;
  final String? districtCode;
  final String? districtName;
  final String? villageName;
  final String? mobileno;
  final String? cropCategoryCode;
  final String? cropCategoryName;

  Collection({
    this.collectionCode,
    this.hubCode,
    this.finyearCode,
    this.farmerCode,
    this.cropCode,
    this.quantity,
    this.rejected,
    this.unitCode,
    this.hubName,
    this.farmerName,
    this.cropName,
    this.finyearName,
    this.unitName,
    this.districtCode,
    this.districtName,
    this.villageName,
    this.mobileno,
    this.cropCategoryCode,
    this.cropCategoryName,
  });

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    collectionCode: json['collectionCode']?.toString(),
    hubCode: json['hubCode']?.toString(),
    finyearCode: json['finyearCode']?.toString(),
    farmerCode: json['farmerCode']?.toString(),
    cropCode: json['cropCode']?.toString(),
    quantity: json['quantity']?.toString(),
    rejected: json['rejected']?.toString(),
    unitCode: json['unitCode']?.toString(),
    hubName: json['hubName'],
    farmerName: json['farmerName'],
    cropName: json['cropName'],
    finyearName: json['finyearName'],
    unitName: json['unitName'],
    districtCode: json['districtCode']?.toString(),
    districtName: json['districtName'],
    villageName: json['villageName'],
    mobileno: json['mobileno'],
    cropCategoryCode: json['cropCategoryCode']?.toString(),
    cropCategoryName: json['cropCategoryName'],
  );

  // toJson remains unchanged (only fields required for add/update)
}