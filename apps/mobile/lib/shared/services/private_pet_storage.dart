import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class PrivatePetStorage {
  PrivatePetStorage._();

  static const bucket = 'pet-documents';

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<String> uploadImage({
    required String petId,
    required String category,
    required File file,
    bool upsert = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Authentication required');

    final rawExtension = file.path.split('.').last.toLowerCase();
    final extension = rawExtension == 'jpeg' ? 'jpg' : rawExtension;
    final fileName = upsert
        ? 'current.$extension'
        : '${DateTime.now().microsecondsSinceEpoch}.$extension';
    final path = '${user.id}/$petId/$category/$fileName';

    await _client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: FileOptions(upsert: upsert),
        );
    return path;
  }

  static Future<String?> signedUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    return _client.storage.from(bucket).createSignedUrl(path, 3600);
  }
}
