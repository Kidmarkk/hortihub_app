import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/auth_provider.dart';

class DrawerWidget extends ConsumerWidget {
  final Function(String screen, String title, Map params) onScreenChanged;
  final List<dynamic> hubs;

  const DrawerWidget({
    super.key,
    required this.onScreenChanged,
    required this.hubs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final role = user?.userRole ?? 'GUEST';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6D4C41), Color(0xFF388E3C)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // App logo + name (now wraps to two lines)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/hortihub_logo_1.jpg',
                      width: 40,
                      height: 40,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.white70,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MEG Horticulture Hub',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // User name
                Text(
                  user?.userName ?? 'HortiHub User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                // Role
                Text(
                  role,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          _buildHomeItem(context),
          // User Management – commented out (not needed)
          // if (role != 'HUBUSER') _buildUserManagementItem(context),
          // Admin-only items – commented out
          // if (role == 'ADMIN') _buildAdminOnlyItems(context),
          _buildInitializationItem(context, role),
          _buildProductionItem(context),
          _buildCollectionItem(context),
          _buildStockItem(context),
          _buildSalesItem(context),
          _buildReportsItem(context),
          // Farmer and Training – commented out
          // _buildFarmerItem(context),
          // _buildTrainingItem(context),
          _buildSettingsItem(context),
          // Audit Trail – commented out
          // if (role == 'ADMIN') _buildAuditTrailItem(context),
          const Divider(),
          _buildLogoutItem(context, ref),
        ],
      ),
    );
  }

  Widget _buildTile(
    String title,
    IconData icon,
    String route,
    BuildContext context, {
    Map params = const {},
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onScreenChanged(route, title, params);
      },
    );
  }

  Widget _buildHomeItem(BuildContext context) =>
      _buildTile('Home', Icons.home, '/home', context);

  // Removed User Management, Admin-only items, Farmer, Training, Audit Trail

  Widget _buildInitializationItem(BuildContext context, String role) {
    List<Map<String, dynamic>> subItems = [];

    // Only Rates is needed
    subItems.addAll([
      {'title': 'Rates', 'route': '/rates'},
    ]);

    // sub-items commented out for future use
    /*
    if (role == 'ADMIN' || role == 'STATEUSER') {
      subItems.addAll([
        {'title': 'Polyhouse', 'route': '/initialization/polyhouse'},
        {'title': 'Hub', 'route': '/initialization/hub'},
        {'title': 'Crop', 'route': '/initialization/crop'},
        {'title': 'Crop Category', 'route': '/initialization/crop-category'},
        {'title': 'Financial Year', 'route': '/initialization/financial-year'},
      ]);
    } else if (role == 'DISTRICTUSER') {
      subItems.addAll([
        {'title': 'Polyhouse', 'route': '/initialization/polyhouse'},
        {'title': 'Hub', 'route': '/initialization/hub'},
      ]);
    } else if (role == 'HUBUSER') {
      subItems.addAll([
        {'title': 'Polyhouse', 'route': '/initialization/polyhouse'},
      ]);
    }
    */

    return ExpansionTile(
      leading: Icon(Icons.build, color: Colors.green[700]),
      title: const Text('Initialization'),
      children: subItems.map((item) {
        return ListTile(
          leading: Icon(Icons.arrow_right, color: Colors.green[700]),
          title: Text(item['title']),
          onTap: () {
            Navigator.pop(context);
            onScreenChanged(item['route'], item['title'], {});
          },
        );
      }).toList(),
    );
  }

  Widget _buildProductionItem(BuildContext context) =>
      _buildTile('Production', Icons.agriculture, '/production', context);
  Widget _buildCollectionItem(BuildContext context) =>
      _buildTile('Collection', Icons.inventory, '/collection', context);
  Widget _buildStockItem(BuildContext context) =>
      _buildTile('Stock', Icons.store, '/stock_availability', context);
  Widget _buildSalesItem(BuildContext context) =>
      _buildTile('Sales', Icons.sell, '/view_sales', context);
  Widget _buildReportsItem(BuildContext context) =>
      _buildTile('Reports', Icons.bar_chart, '/reports', context);

  Widget _buildSettingsItem(BuildContext context) {
    return ExpansionTile(
      leading: Icon(Icons.settings, color: Colors.green[700]),
      title: const Text('Settings'),
      children: [
        ListTile(
          leading: Icon(Icons.arrow_right, color: Colors.green[700]),
          title: const Text('Change Password'),
          onTap: () {
            Navigator.pop(context);
            onScreenChanged('/settings', 'Change Password', {});
          },
        ),
      ],
    );
  }

  Widget _buildLogoutItem(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('Logout'),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(authStateProvider.notifier).logout();
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          onScreenChanged('/login', 'Login', {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
