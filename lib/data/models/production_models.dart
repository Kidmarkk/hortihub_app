class Production {
  final String? productionCode;
  final String? hubCode;
  final String? finyearCode;
  final String? cropCode;
  final String? area;
  final String? season;
  final String? expectedYield;
  final String? actualYield;
  final String? unitCode;
  final String? hubName;
  final String? cropName;
  final String? finyearName;
  final String? unitName;
  final String? districtCode;
  final String? districtName;
  final String? fromYear;
  final String? toYear;
  final String? cropCategoryCode;
  final String? cropCategoryName; // added

  Production({
    this.productionCode,
    this.hubCode,
    this.finyearCode,
    this.cropCode,
    this.area,
    this.season,
    this.expectedYield,
    this.actualYield,
    this.unitCode,
    this.hubName,
    this.cropName,
    this.finyearName,
    this.unitName,
    this.districtCode,
    this.districtName,
    this.fromYear,
    this.toYear,
    this.cropCategoryCode,
    this.cropCategoryName,
  });

  factory Production.fromJson(Map<String, dynamic> json) => Production(
    productionCode: json['productionCode']?.toString(),
    hubCode: json['hubCode']?.toString(),
    finyearCode: json['finyearCode']?.toString(),
    cropCode: json['cropCode']?.toString(),
    area: json['area']?.toString(),
    season: json['season'],
    expectedYield: json['expectedYield']?.toString(),
    actualYield: json['actualYield']?.toString(),
    unitCode: json['unitCode']?.toString(),
    hubName: json['hubName'],
    cropName: json['cropName'],
    finyearName: json['finyearName'],
    unitName: json['unitName'],
    districtCode: json['districtCode']?.toString(),
    districtName: json['districtName'],
    fromYear: json['fromYear'],
    toYear: json['toYear'],
    cropCategoryCode: json['cropCategoryCode']?.toString(),
    cropCategoryName: json['cropCategoryName'],
  );

  Map<String, dynamic> toJson() => {
    'productionCode': productionCode,
    'hubCode': hubCode,
    'finyearCode': finyearCode,
    'cropCode': cropCode,
    'area': area,
    'season': season,
    'expectedYield': expectedYield,
    'actualYield': actualYield,
    'unitCode': unitCode,
  };
}