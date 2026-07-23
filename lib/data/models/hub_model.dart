class Hub {
  final String code;
  final String name;
  final String districtCode;
  final String? districtName;

  Hub({
    required this.code,
    required this.name,
    required this.districtCode,
    this.districtName,
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
    );
  }
}
