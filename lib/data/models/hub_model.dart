class Hub {
  final String code;
  final String name;
  final String districtCode;
  final String? districtName;
  final String? imageBase64;

  Hub({
    required this.code,
    required this.name,
    required this.districtCode,
    this.districtName,
    this.imageBase64,
  });

  factory Hub.fromMap(
    Map<String, String> map,
    List<Map<String, String>>? districts,
  ) {
    final districtCode = map['value1'] ?? '';
    final districtName =
        map['districtName'] ?? // from listHubs
        districts?.firstWhere(
          (d) => d['key'] == districtCode,
          orElse: () => {'value': districtCode},
        )['value'] ??
        districtCode;
    return Hub(
      code: map['key'] ?? '',
      name: map['value'] ?? '',
      districtCode: districtCode,
      districtName: districtName,
      imageBase64: map['imageBase64'] ?? '',
    );
  }
}
