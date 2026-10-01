import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import 'package:hortihub_new_app/presentation/screens/hub_detail_screen.dart';
import '../providers/auth_provider.dart';
import '../../data/models/hub_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  //Helper: Build hub image from Base64 or fallback
  Widget _buildHubImage(Hub hub, double imageHeight) {
    // 1. Check if hub has Base64 image data
    if (hub.imageBase64 != null && hub.imageBase64!.isNotEmpty) {
      try {
        String base64String = hub.imageBase64!;
        // Remove data:image/jpeg;base64, prefix if present
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }

        final bytes = base64Decode(base64String);

        return Image.memory(
          bytes,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackImage(hub, imageHeight),
        );
      } catch (e) {
        // If decoding fails, use fallback
        return _buildFallbackImage(hub, imageHeight);
      }
    }

    // 2. Fallback to local assets
    return _buildFallbackImage(hub, imageHeight);
  }

  //Helper: Build fallback image from local assets
  Widget _buildFallbackImage(Hub hub, double imageHeight) {
    final imageBase = 'assets/images/';

    String imagePath;
    if (hub.code == '1') {
      imagePath = '${imageBase}hub1.webp';
    } else {
      // Default fallback
      imagePath = '${imageBase}bg.webp';
    }

    return Image.asset(
      imagePath,
      height: imageHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.image_not_supported, size: 50),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final role = user?.userRole ?? 'GUEST';
    final userName = user?.userName ?? 'User';

    final isVerySmall = Responsive.isVerySmallScreen(context);
    final crossAxisCount = Responsive.getGridColumns(context);

    // Responsive font sizes using the utility
    final double titleFontSize = Responsive.getResponsiveFontSize(
      context,
      baseSize: 22,
    );
    final double subTitleFontSize = Responsive.getResponsiveFontSize(
      context,
      baseSize: 14,
    );
    final double cardTitleSize = Responsive.getResponsiveFontSize(
      context,
      baseSize: 14,
    );
    final double cardSubSize = Responsive.getResponsiveFontSize(
      context,
      baseSize: 12,
    );
    final double welcomeTextSize = Responsive.getResponsiveFontSize(
      context,
      baseSize: 13,
    );
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

    //build hubs list with imageBase64
    List<Hub> hubs = [];
    if (user != null) {
      if (user.listHubs.isNotEmpty) {
        hubs = user.listHubs.map((map) {
          final hubCode = map['key'] ?? '';
          final hubName = map['value'] ?? '';
          final districtCode = map['value1'] ?? '';
          final districtName = _resolveDistrictName(districtCode);
          final imageBase64 = map['imageBase64'] ?? '';

          return Hub(
            code: hubCode,
            name: hubName,
            districtCode: districtCode,
            districtName: districtName,
            imageBase64: imageBase64.isNotEmpty ? imageBase64 : null,
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
            imageBase64:
                null, // Hub users don't get image data from userDetails
          ),
        ];
      }
    }

    final imageBase = 'assets/images/';
    final fallbackImages = ['bg.webp', 'hortihub.webp'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card (responsive padding)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: Responsive.getResponsivePadding(
                context,
                basePadding: 12,
              ),
              horizontal: Responsive.getResponsivePadding(
                context,
                basePadding: 16,
              ),
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
            style: TextStyle(fontSize: subTitleFontSize, color: Colors.black54),
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

                //Fallback image based on index
                String fallbackImagePath;
                if (hub.code == '1') {
                  fallbackImagePath = '${imageBase}hub1.webp';
                } else {
                  final imageName = index % 2 == 0
                      ? fallbackImages[0]
                      : fallbackImages[1];
                  fallbackImagePath = '$imageBase$imageName';
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
                          child: _buildHubImageWithFallback(
                            hub,
                            imageHeight,
                            fallbackImagePath,
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

  //Helper: Build hub image with fallback
  Widget _buildHubImageWithFallback(
    Hub hub,
    double imageHeight,
    String fallbackImagePath,
  ) {
    // 1. Check if hub has Base64 image data
    if (hub.imageBase64 != null && hub.imageBase64!.isNotEmpty) {
      try {
        String base64String = hub.imageBase64!;

        // Remove data:image/*;base64, prefix
        final regex = RegExp(r'^data:image\/[a-zA-Z]+;base64,');
        if (regex.hasMatch(base64String)) {
          base64String = base64String.replaceFirst(regex, '');
        }

        // If there's still a comma, split and take the last part
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }

        // Remove ALL whitespace (newlines, spaces, tabs, carriage returns)
        base64String = base64String.replaceAll(RegExp(r'\s+'), '');

        final bytes = base64Decode(base64String);

        return Image.memory(
          bytes,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(
            fallbackImagePath,
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        // If decoding fails, use fallback
        return Image.asset(
          fallbackImagePath,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }

    // 2. Fallback to local assets
    return Image.asset(
      fallbackImagePath,
      height: imageHeight,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}
