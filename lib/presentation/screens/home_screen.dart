import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import 'package:hortihub_new_app/presentation/screens/hub_detail_screen.dart';
import '../providers/auth_provider.dart';
import '../../data/models/hub_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final role = user?.userRole ?? 'GUEST';
    final userName = user?.userName ?? 'User';

    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = Responsive.isVerySmallScreen(context);
    final crossAxisCount = Responsive.getGridColumns(context);

    // Responsive font sizes using the utility
    final double titleFontSize = Responsive.getResponsiveFontSize(context, baseSize: 22);
    final double subTitleFontSize = Responsive.getResponsiveFontSize(context, baseSize: 14);
    final double cardTitleSize = Responsive.getResponsiveFontSize(context, baseSize: 14);
    final double cardSubSize = Responsive.getResponsiveFontSize(context, baseSize: 12);
    final double welcomeTextSize = Responsive.getResponsiveFontSize(context, baseSize: 13);
    final double imageHeight = isVerySmall ? 60 : 90;
    final double spacing = isVerySmall ? 6 : 12;

    // Helper to resolve district name
    String _resolveDistrictName(String? districtCode) {
      if (districtCode == null || districtCode.isEmpty) return '';
      if (user == null) return districtCode;
      if (role == 'DISTRICTUSER' && user.districtName != null) {
        return user.districtName!;
      }
      final match = user.listDistricts.firstWhere(
        (d) => d['key'] == districtCode,
        orElse: () => {'value': districtCode},
      );
      return match['value'] ?? districtCode;
    }

    List<Hub> hubs = [];
    if (user != null) {
      if (user.listHubs.isNotEmpty) {
        hubs = user.listHubs.map((map) {
          final hubCode = map['key'] ?? '';
          final hubName = map['value'] ?? '';
          final districtCode = map['value1'] ?? '';
          final districtName = _resolveDistrictName(districtCode);
          return Hub(
            code: hubCode,
            name: hubName,
            districtCode: districtCode,
            districtName: districtName,
          );
        }).toList();
      } else if (user.hubCode != null) {
        String districtName = _resolveDistrictName(user.districtCode);
        if (districtName.isEmpty) {
          districtName = 'EAST KHASI HILLS';
        }
        hubs = [
          Hub(
            code: user.hubCode!,
            name: user.hubName ?? 'Hub ${user.hubCode}',
            districtCode: user.districtCode ?? '',
            districtName: districtName,
          )
        ];
      }
    }

    final imageBase = 'assets/images/';
    final fallbackImages = ['bg.webp', 'hortihub.webp'];
    final customImageForHub1 = '${imageBase}hub1.webp';

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card (responsive padding)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: Responsive.getResponsivePadding(context, basePadding: 12),
              horizontal: Responsive.getResponsivePadding(context, basePadding: 16),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D4C41), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $userName!',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: $role',
                  style: TextStyle(
                    fontSize: subTitleFontSize,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the menu to manage your hub activities.',
                  style: TextStyle(
                    fontSize: welcomeTextSize,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hub Profiles section
          Text(
            'Hub Profiles',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a Horti Hub to view details.',
            style: TextStyle(
              fontSize: subTitleFontSize,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),

          if (hubs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No hubs available.'),
              ),
            )
          else
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              childAspectRatio: 1.1,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              crossAxisCount: crossAxisCount,
              children: hubs.asMap().entries.map((entry) {
                final index = entry.key;
                final hub = entry.value;
                String imagePath;
                if (hub.code == '1') {
                  imagePath = customImageForHub1;
                } else {
                  final imageName = index % 2 == 0 ? fallbackImages[0] : fallbackImages[1];
                  imagePath = '$imageBase$imageName';
                }
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HubDetailScreen(hub: hub),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                          child: Image.asset(
                            imagePath,
                            height: imageHeight,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported, size: 50),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hub.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: cardTitleSize,
                                ),
                              ),
                              Text(
                                hub.districtName ?? hub.districtCode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: cardSubSize,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}