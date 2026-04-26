import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

// ── API Base URL ─────────────────────────────────────────────────────────────
// • Web (Chrome)      → http://localhost:3000
// • Android emulator  → http://10.0.2.2:3000
// • Real device       → your PC's local IP (e.g., http://192.168.1.147:3000)
final String baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

class ApiService {
  // ── Notes ────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getNotes() async {
    final res = await http.get(Uri.parse('$baseUrl/notes'));
    _assertOk(res);
    return List<Map<String, dynamic>>.from(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>> getNoteById(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/notes/$id'));
    _assertOk(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>> createNote(
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/notes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _assertOk(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>> updateNote(
    int id,
    Map<String, dynamic> body,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/notes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _assertOk(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<void> deleteNote(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/notes/$id'));
    _assertOk(res);
  }

  // ── File upload ──────────────────────────────────────────────────────────

  /// Lets the user pick a JPG / PNG / PDF and uploads it.
  /// Returns the public [file_url] string or null if the user cancelled.
  static Future<String?> pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result == null) return null;

    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

    if (kIsWeb) {
      final bytes = result.files.single.bytes;
      if (bytes == null) return null;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: result.files.single.name,
      ));
    } else {
      final filePath = result.files.single.path;
      if (filePath == null) return null;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    }

    final streamedResponse = await request.send();
    final body = jsonDecode(await streamedResponse.stream.bytesToString());

    if (streamedResponse.statusCode != 200) {
      throw Exception('Upload failed: ${body['error']}');
    }
    return body['file_url'] as String;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static void _assertOk(http.Response res) {
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Request failed (${res.statusCode})');
    }
  }
}
