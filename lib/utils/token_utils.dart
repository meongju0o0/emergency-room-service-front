import 'dart:convert';
import 'package:crypto/crypto.dart';

String encodeToken(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('Invalid JWT format');
  }

  String normalizeBase64(String input) {
    while (input.length % 4 != 0) {
      input += '=';
    }
    return input;
  }

  final header = base64Url.decode(normalizeBase64(parts[0]));
  final payload = base64Url.decode(normalizeBase64(parts[1]));

  final hmac = Hmac(sha256, utf8.encode("my_secure_key"));
  final signature = hmac.convert(utf8.encode('${parts[0]}.${parts[1]}'));

  return '${parts[0]}.${parts[1]}.${base64Url.encode(signature.bytes)}';
}
