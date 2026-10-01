import 'dart:async';
import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart'
    hide CapabilityProfile, Generator, PaperSize;

class ThermalPrinterService {
  final PrinterManager _manager = PrinterManager();

  Future<Uint8List> _buildReceiptBytes(Map<String, dynamic> orderData) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    final String hubTitle = (orderData['hubName'] ?? 'HORTICULTURE HUB')
        .toString()
        .toUpperCase();
    final String districtTitle = (orderData['districtName'] ?? '')
        .toString()
        .toUpperCase();

    bytes += generator.reset();
    bytes += generator.text(
      hubTitle,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );
    if (districtTitle.isNotEmpty) {
      bytes += generator.text(
        districtTitle,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    bytes += generator.text(
      'GOVERNMENT OF MEGHALAYA',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      '------------------------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text('Receipt No: ${orderData['receiptNo'] ?? ''}');
    bytes += generator.text('Buyer: ${orderData['buyerName'] ?? ''}');
    bytes += generator.text('Date: ${orderData['date'] ?? ''}');
    bytes += generator.text(
      '------------------------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.row([
      PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: 'Qty',
        width: 2,
        styles: const PosStyles(bold: true, align: PosAlign.center),
      ),
      PosColumn(
        text: 'Price',
        width: 4,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);
    bytes += generator.text(
      '------------------------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
    List items = orderData['items'] ?? [];
    for (var item in items) {
      final qty = item['qty'].toString();
      final unit = item['unit']?.toString() ?? '';
      final qtyWithUnit = unit.isNotEmpty ? '$qty $unit' : qty;

      bytes += generator.row([
        PosColumn(text: item['name'].toString(), width: 6),
        PosColumn(
          text: qtyWithUnit,
          width: 2,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: item['price'].toString(),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.text(
      '------------------------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'GRAND TOTAL: ${orderData['total'] ?? '0.00'}',
      styles: const PosStyles(
        align: PosAlign.right,
        bold: true,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();
    return Uint8List.fromList(bytes);
  }

  /// Show a dialog to let the user select a printer
  Future<PrinterDevice?> _selectPrinterDialog(
    BuildContext context,
    List<PrinterDevice> devices,
  ) async {
    return showDialog<PrinterDevice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Printer'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (ctx, index) {
              final device = devices[index];
              return ListTile(
                title: Text(device.name ?? 'Unknown Printer'),
                subtitle: Text(device.connectionType.toString()),
                leading: device.connectionType == ConnectionType.USB
                    ? const Icon(Icons.usb)
                    : const Icon(Icons.print),
                onTap: () => Navigator.pop(ctx, device),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Main print function – uses unified_esc_pos_printer
  Future<bool> printReceipt(
    BuildContext context,
    Map<String, dynamic> orderData,
  ) async {
    try {
      // 1. Scan for printers (USB + Bluetooth)
      final devices = await _manager
          .scanAll(timeout: const Duration(seconds: 5))
          .first;

      if (devices.isEmpty) {
        debugPrint('No printers found.');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No printers found. Please connect a printer.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }

      // 2. Select printer
      PrinterDevice targetDevice;
      if (devices.length == 1) {
        targetDevice = devices.first;
      } else {
        final selected = await _selectPrinterDialog(context, devices);
        if (selected == null) {
          debugPrint('User cancelled printer selection.');
          return false;
        }
        targetDevice = selected;
      }

      debugPrint('Selected printer: ${targetDevice.name}');

      // 3. Connect – THIS HANDLES PERMISSION CORRECTLY
      // The connection waits for the user to grant USB permission
      await _manager.connect(targetDevice);

      debugPrint('Connected successfully.');

      // 4. Build receipt bytes
      final bytes = await _buildReceiptBytes(orderData);

      // 5. Send data to printer
      await _manager.printBytes(bytes);

      debugPrint('Receipt printed successfully.');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt printed successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return true;
    } on PrinterException catch (e) {
      debugPrint('Printer error: ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printer error: ${e.message}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Print error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to print. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    } finally {
      // 6. Always disconnect
      try {
        await _manager.disconnect();
        debugPrint('Disconnected.');
      } catch (_) {}
    }
  }

  /// Dispose resources when done
  void dispose() {
    _manager.dispose();
  }
}
