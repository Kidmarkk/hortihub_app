import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../data/models/sales_models.dart';

class PrintService {
  /// Show the system print dialog for the given PDF base64 string.
  static Future<void> printReceipt(String base64Pdf) async {
    try {
      // Decode base64 to bytes
      final bytes = base64Decode(base64Pdf);
      // Open the system print dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
      );
    } catch (e) {
      throw Exception('Failed to print: $e');
    }
  }
}