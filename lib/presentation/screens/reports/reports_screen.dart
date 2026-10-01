import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hortihub_new_app/core/constants/api_constants.dart';
import 'package:hortihub_new_app/core/utils/responsive.dart';
import 'package:hortihub_new_app/data/datasources/remote/api_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedDistrictCode;
  String? _selectedHubCode;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).value;
      if (user?.userRole == 'HUBUSER' && user?.hubCode != null) {
        setState(() {
          _selectedHubCode = user?.hubCode;
        });
      }
    });
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
      if (_toDate != null && _toDate!.isBefore(picked)) {
        setState(() => _toDate = null);
      }
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? (_fromDate ?? DateTime.now()),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  Future<void> _generateSalesReport() async {
    if (_selectedHubCode == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a hub.')));
      return;
    }
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both From Date and To Date.'),
        ),
      );
      return;
    }
    if (_fromDate!.isAfter(_toDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('From Date must be before or equal to To Date.'),
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      //Resolve hub name
      String hubName = '';
      final hub = user.listHubs.firstWhere(
        (h) => h['key'] == _selectedHubCode,
        orElse: () => {'value': 'Hub'},
      );
      hubName = hub['value'] ?? 'Hub';

      //Updated query params to match Swagger
      final queryParams = {
        'hubCode': _selectedHubCode!,
        'hubName': hubName, //Required by Swagger
        'fromdate': DateFormat('yyyy-MM-dd').format(_fromDate!), //Lowercase
        'todate': DateFormat('yyyy-MM-dd').format(_toDate!), // Lowercase
      };

      print('📊 Report query params: $queryParams');

      final api = ApiService();
      final response = await api.get(
        ApiConstants.salesReport,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;

      // Check for error in response
      if (data.containsKey('error') || data.containsKey('message')) {
        final errorMsg =
            data['message'] ?? data['error'] ?? 'Failed to generate report.';
        throw Exception(errorMsg);
      }

      final base64String = data['pdfData'] as String?;
      if (base64String == null || base64String.isEmpty) {
        throw Exception('No PDF data in response.');
      }

      final bytes = base64Decode(base64String);
      if (bytes.isEmpty) {
        throw Exception('Generated PDF is empty.');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Sales Report');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sales report generated and shared successfully!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final role = user?.userRole ?? 'GUEST';

    final isVerySmall = Responsive.isVerySmallScreen(context);
    final fontSize = Responsive.getResponsiveFontSize(context, baseSize: 14);
    final padding = Responsive.getResponsivePadding(context);
    final spacing = isVerySmall ? 8.0 : 16.0;
    final buttonPadding = EdgeInsets.symmetric(vertical: isVerySmall ? 10 : 14);

    final showDistrict = role == 'ADMIN' || role == 'STATEUSER';
    final showHub = role != 'HUBUSER';

    List<Map<String, String>> allHubs = user?.listHubs ?? [];
    List<Map<String, String>> filteredHubs = allHubs;
    if (showDistrict && _selectedDistrictCode != null) {
      filteredHubs = allHubs
          .where((h) => h['value1'] == _selectedDistrictCode)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sales Report',
          style: TextStyle(
            fontSize: Responsive.getResponsiveFontSize(context, baseSize: 18),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDistrict)
              DropdownButtonFormField<String>(
                value: _selectedDistrictCode,
                hint: Text(
                  'Select District',
                  style: TextStyle(fontSize: fontSize),
                ),
                items:
                    user?.listDistricts.map((d) {
                      return DropdownMenuItem(
                        value: d['key'],
                        child: Text(
                          d['value'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: fontSize),
                        ),
                      );
                    }).toList() ??
                    [],
                onChanged: (val) {
                  setState(() {
                    _selectedDistrictCode = val;
                    _selectedHubCode = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'District',
                  labelStyle: TextStyle(fontSize: fontSize),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isVerySmall ? 4 : 8,
                    horizontal: 8,
                  ),
                ),
                isExpanded: true,
              ),
            if (showDistrict) SizedBox(height: spacing),

            if (showHub)
              DropdownButtonFormField<String>(
                value: _selectedHubCode,
                hint: Text('Select Hub', style: TextStyle(fontSize: fontSize)),
                items: filteredHubs.map((h) {
                  return DropdownMenuItem(
                    value: h['key'],
                    child: Text(
                      h['value'] ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: fontSize),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedHubCode = val),
                decoration: InputDecoration(
                  labelText: 'Hub',
                  labelStyle: TextStyle(fontSize: fontSize),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isVerySmall ? 4 : 8,
                    horizontal: 8,
                  ),
                ),
                isExpanded: true,
              ),
            if (showHub) SizedBox(height: spacing),

            // From Date
            InkWell(
              onTap: () => _selectFromDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'From Date',
                  labelStyle: TextStyle(fontSize: fontSize),
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isVerySmall ? 8 : 14,
                    horizontal: 12,
                  ),
                ),
                child: Text(
                  _fromDate == null
                      ? 'Select From Date'
                      : DateFormat('dd/MM/yyyy').format(_fromDate!),
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
            SizedBox(height: spacing),

            // To Date
            InkWell(
              onTap: () => _selectToDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'To Date',
                  labelStyle: TextStyle(fontSize: fontSize),
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isVerySmall ? 8 : 14,
                    horizontal: 12,
                  ),
                ),
                child: Text(
                  _toDate == null
                      ? 'Select To Date'
                      : DateFormat('dd/MM/yyyy').format(_toDate!),
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
            SizedBox(height: spacing * 1.5),

            // Generate button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateSalesReport,
              icon: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.preview),
              label: Text(
                _isLoading ? 'Generating...' : 'Generate Sales Report',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    baseSize: 16,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: buttonPadding,
              ),
            ),

            SizedBox(height: spacing),

            // Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Sales report will be generated as a PDF and shared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: fontSize),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
