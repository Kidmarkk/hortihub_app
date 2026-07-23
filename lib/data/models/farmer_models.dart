class Farmer {
  final String? farmerCode;
  final String? farmerName;
  final String? villageName;
  final String? mobileno;
  final String? hubCode;
  final String? hubName;
  final String? districtCode;
  final String? districtName;
  final String? collectionCode; // added

  Farmer({
    this.farmerCode,
    this.farmerName,
    this.villageName,
    this.mobileno,
    this.hubCode,
    this.hubName,
    this.districtCode,
    this.districtName,
    this.collectionCode,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) => Farmer(
    farmerCode: json['farmerCode']?.toString(),
    farmerName: json['farmerName'],
    villageName: json['villageName'],
    mobileno: json['mobileno'],
    hubCode: json['hubCode']?.toString(),
    hubName: json['hubName'],
    districtCode: json['districtCode']?.toString(),
    districtName: json['districtName'],
    collectionCode: json['collectionCode']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'farmerCode': farmerCode,
    'farmerName': farmerName,
    'villageName': villageName,
    'mobileno': mobileno,
    'hubCode': hubCode,
    'hubName': hubName,
    'districtCode': districtCode,
    'districtName': districtName,
    'collectionCode': collectionCode,
  };
}