class CropCategory {
  final String code;
  final String name;
  CropCategory({required this.code, required this.name});
  factory CropCategory.fromJson(Map<String, dynamic> json) => CropCategory(
    code: json['key']?.toString() ?? '',
    name: json['value'] ?? '',
  );
}

class Crop {
  final String code;
  final String name;
  final String categoryCode;
  Crop({required this.code, required this.name, required this.categoryCode});
  factory Crop.fromJson(Map<String, dynamic> json) => Crop(
    code: json['key']?.toString() ?? '',
    name: json['value'] ?? '',
    categoryCode: json['value1']?.toString() ?? '',
  );
}

class PackagingType {
  final String code;
  final String name;
  PackagingType({required this.code, required this.name});
  factory PackagingType.fromJson(Map<String, dynamic> json) => PackagingType(
    code: json['key']?.toString() ?? '',
    name: json['value'] ?? '',
  );
}

class Unit {
  final String code;
  final String name;
  Unit({required this.code, required this.name});
  factory Unit.fromJson(Map<String, dynamic> json) =>
      Unit(code: json['key']?.toString() ?? '', name: json['value'] ?? '');
}

class RateInfo {
  final String cropCode;
  final String packagingTypeCode;
  final String unitCode;
  RateInfo({
    required this.cropCode,
    required this.packagingTypeCode,
    required this.unitCode,
  });
  factory RateInfo.fromJson(Map<String, dynamic> json) => RateInfo(
    cropCode: json['cropCode']?.toString() ?? '',
    packagingTypeCode: json['packagingTypeCode']?.toString() ?? '',
    unitCode: json['unitCode']?.toString() ?? '',
  );
}

class FinancialYear {
  final String code;
  final String name;
  FinancialYear({required this.code, required this.name});
  factory FinancialYear.fromJson(Map<String, dynamic> json) => FinancialYear(
    code: json['key']?.toString() ?? '',
    name: json['value'] ?? '',
  );
}

class FarmerInfo {
  final String code;
  final String name;
  final String? village;
  final String? mobile;

  FarmerInfo({
    required this.code,
    required this.name,
    this.village,
    this.mobile,
  });

  factory FarmerInfo.fromJson(Map<String, dynamic> json) => FarmerInfo(
    code: json['farmerCode']?.toString() ?? '',
    name: json['farmerName'] ?? '',
    village: json['villageName'],
    mobile: json['mobileno'],
  );
}

class MasterData {
  final List<CropCategory> cropCategories;
  final List<Crop> crops;
  final List<PackagingType> packagingTypes;
  final List<Unit> units;
  final List<RateInfo> rates;

  final Set<String> validCropCodes;
  final Map<String, Set<String>> cropPackagingMap;
  final Map<String, Set<String>> cropUnitMap;

  MasterData({
    required this.cropCategories,
    required this.crops,
    required this.packagingTypes,
    required this.units,
    required this.rates,
  }) : validCropCodes = rates.map((r) => r.cropCode).toSet(),
       cropPackagingMap = _buildCropPackagingMap(rates),
       cropUnitMap = _buildCropUnitMap(rates);

  static Map<String, Set<String>> _buildCropPackagingMap(List<RateInfo> rates) {
    final map = <String, Set<String>>{};
    for (var rate in rates) {
      map.putIfAbsent(rate.cropCode, () => {});
      map[rate.cropCode]!.add(rate.packagingTypeCode);
    }
    return map;
  }

  static Map<String, Set<String>> _buildCropUnitMap(List<RateInfo> rates) {
    final map = <String, Set<String>>{};
    for (var rate in rates) {
      map.putIfAbsent(rate.cropCode, () => {});
      map[rate.cropCode]!.add(rate.unitCode);
    }
    return map;
  }
}
