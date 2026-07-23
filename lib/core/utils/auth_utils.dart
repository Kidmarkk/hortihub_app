import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class AuthUtils {
  // The secret key provided by the backend team
  static const String secretKey =
      "10e1b3b9d80c78cb6c771564f7f9a7ca3850300ea535c220cbaba25f706a613a";

  /// Generate dynamic authKey for the current day
  static String generateAuthKey() {
    tz.initializeTimeZones();
    final location = tz.getLocation('Asia/Kolkata');
    final now = tz.TZDateTime.now(location);
    final datePart = DateFormat('dd-MM-yyyy').format(now);
    final String raw = "$secretKey : $datePart";
    final bytes = utf8.encode(raw);
    final hash = sha512.convert(bytes);
    return hash.toString();
  }

  /// Hash password twice: first SHA512, then SHA256
  static String hashPassword(String plainPassword) {
    // SHA512 of the plain password (as bytes)
    final sha512Bytes = sha512.convert(utf8.encode(plainPassword)).bytes;

    // Convert bytes to a lowercase hex string (128 chars)
    final sha512Hex = sha512Bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    // SHA256 of the hex string (as UTF-8)
    final finalHash = sha256.convert(utf8.encode(sha512Hex));

    print("SHA512 hex: $sha512Hex");
    print("Final hash: $finalHash");

    return finalHash.toString();
  }
}
