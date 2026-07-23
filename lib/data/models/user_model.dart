import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String token;
  final String type;
  final String userId;
  final String userName;
  final String userRole;
  final String mobileNo;
  final int userCode;
  final String? hubCode;
  final String? hubName;
  final String? districtCode;
  final String? districtName;
  final List<Map<String, String>> listDistricts;
  final List<Map<String, String>> listHubs;

  const UserModel({
    required this.token,
    required this.type,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.mobileNo,
    required this.userCode,
    this.hubCode,
    this.hubName,
    this.districtCode,
    this.districtName,
    this.listDistricts = const [],
    this.listHubs = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final jwtDetails = json['jwtDetails'];
    final userDetails = json['userDetails'];

    final List<Map<String, String>> listDistricts =
        (json['listDistricts'] as List?)
            ?.map<Map<String, String>>(
              (e) => {
                'key': e['key']?.toString() ?? '',
                'value': e['value'] ?? '',
              },
            )
            .toList() ??
        const [];

    final List<Map<String, String>> listHubs =
        (json['listHubs'] as List?)
            ?.map<Map<String, String>>(
              (e) => {
                'key': e['key']?.toString() ?? '',
                'value': e['value'] ?? '',
                'value1': e['value1']?.toString() ?? '',
                'districtName': e['districtName'] ?? '',
              },
            )
            .toList() ??
        const [];

    return UserModel(
      token: jwtDetails['token'],
      type: jwtDetails['type'] ?? 'Bearer',
      userId: userDetails['userId'],
      userName: userDetails['userName'],
      userRole: userDetails['userRole'],
      mobileNo: userDetails['mobileNo'],
      userCode: userDetails['userCode'],
      hubCode: userDetails['hubCode']?.toString(),
      hubName: userDetails['hubName'],
      districtCode: userDetails['districtCode']?.toString(),
      districtName: userDetails['districtName'],
      listDistricts: listDistricts,
      listHubs: listHubs,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'type': type,
    'userId': userId,
    'userName': userName,
    'userRole': userRole,
    'mobileNo': mobileNo,
    'userCode': userCode,
    'hubCode': hubCode,
    'hubName': hubName,
    'districtCode': districtCode,
    'districtName': districtName,
    'listDistricts': listDistricts,
    'listHubs': listHubs,
  };

  @override
  List<Object?> get props => [
    token,
    type,
    userId,
    userName,
    userRole,
    mobileNo,
    userCode,
    hubCode,
    hubName,
    districtCode,
    districtName,
    listDistricts,
    listHubs,
  ];
}
