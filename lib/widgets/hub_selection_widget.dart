import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/selected_hub_provider.dart';

class HubSelectionWidget extends ConsumerStatefulWidget {
  const HubSelectionWidget({super.key});

  @override
  ConsumerState<HubSelectionWidget> createState() => _HubSelectionWidgetState();
}

class _HubSelectionWidgetState extends ConsumerState<HubSelectionWidget> {
  String? _selectedDistrictCode;
  String? _selectedHubCode;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final selectedHub = ref.watch(selectedHubProvider);

    if (user == null) return const SizedBox.shrink();

    final role = user.userRole;
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 360;
    final isSmall = screenWidth < 480;

    // HUBUSER: fixed hub, auto-set
    if (role == 'HUBUSER') {
      if (selectedHub == null && user.hubCode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedHubProvider.notifier).state = user.hubCode;
        });
      }
      return const SizedBox.shrink();
    }

    final double fontSize = isVerySmall ? 12 : (isSmall ? 13 : 14);
    final double cardPadding = isVerySmall ? 6 : (isSmall ? 8 : 12);
    final double spacing = isVerySmall ? 4 : 8;

    // DISTRICTUSER: has listHubs, show hub dropdown only
    if (role == 'DISTRICTUSER') {
      if (user.listHubs.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('No hubs available for this district.'),
        );
      }
      return Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: DropdownButtonFormField<String>(
            value: _selectedHubCode ?? selectedHub,
            hint: Text('Select Hub', style: TextStyle(fontSize: fontSize)),
            items: user.listHubs.map((h) {
              return DropdownMenuItem(
                value: h['key'],
                child: Text(h['value'] ?? '', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedHubCode = val;
                ref.read(selectedHubProvider.notifier).state = val;
              });
            },
            decoration: const InputDecoration(labelText: 'Hub'),
            isExpanded: true,
            style: TextStyle(fontSize: fontSize, color: Colors.black87),
          ),
        ),
      );
    }

    // ADMIN or STATEUSER
    if (role == 'ADMIN' || role == 'STATEUSER') {
      if (user.listDistricts.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('No districts available.'),
        );
      }

      final filteredHubs = user.listHubs.where((h) {
        if (_selectedDistrictCode == null) return true;
        return h['value1'] == _selectedDistrictCode;
      }).toList();

      return Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: isSmall
              ? Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedDistrictCode,
                      hint: Text('Select District', style: TextStyle(fontSize: fontSize)),
                      items: user.listDistricts.map((d) {
                        return DropdownMenuItem(
                          value: d['key'],
                          child: Text(d['value'] ?? '', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDistrictCode = val;
                          _selectedHubCode = null;
                          ref.read(selectedHubProvider.notifier).state = null;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'District'),
                      isExpanded: true,
                      style: TextStyle(fontSize: fontSize, color: Colors.black87),
                    ),
                    SizedBox(height: spacing),
                    DropdownButtonFormField<String>(
                      value: _selectedHubCode,
                      hint: Text('Select Hub', style: TextStyle(fontSize: fontSize)),
                      items: filteredHubs.map((h) {
                        return DropdownMenuItem(
                          value: h['key'],
                          child: Text(h['value'] ?? '', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedHubCode = val;
                          ref.read(selectedHubProvider.notifier).state = val;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Hub'),
                      isExpanded: true,
                      style: TextStyle(fontSize: fontSize, color: Colors.black87),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDistrictCode,
                        hint: Text('Select District', style: TextStyle(fontSize: fontSize)),
                        items: user.listDistricts.map((d) {
                          return DropdownMenuItem(
                            value: d['key'],
                            child: Text(d['value'] ?? '', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDistrictCode = val;
                            _selectedHubCode = null;
                            ref.read(selectedHubProvider.notifier).state = null;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'District'),
                        isExpanded: true,
                        style: TextStyle(fontSize: fontSize, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedHubCode,
                        hint: Text('Select Hub', style: TextStyle(fontSize: fontSize)),
                        items: filteredHubs.map((h) {
                          return DropdownMenuItem(
                            value: h['key'],
                            child: Text(h['value'] ?? '', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedHubCode = val;
                            ref.read(selectedHubProvider.notifier).state = val;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Hub'),
                        isExpanded: true,
                        style: TextStyle(fontSize: fontSize, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}