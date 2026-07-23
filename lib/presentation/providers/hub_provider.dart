import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/hub_repository.dart';

final hubRepositoryProvider = Provider((ref) => HubRepository());

final hubListProvider = FutureProvider.family<List<Map<String, String>>, String>((ref, districtCode) async {
  final repo = ref.read(hubRepositoryProvider);
  return await repo.getHubsForDistrict(districtCode);
});