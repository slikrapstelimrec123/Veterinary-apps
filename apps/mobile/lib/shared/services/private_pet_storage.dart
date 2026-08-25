import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class PrivatePetStorage {
  PrivatePetStorage._();

  static const bucket = 'pet-documents';
  static final Map<String, _SignedUrlEntry> _signedUrlCache = {};

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
    // The common avatar path is uploaded with upsert. Invalidate the cached
    // signed URL so screens can receive a fresh URL and show the new image
    // immediately after saving.
    _signedUrlCache.remove(path);
    return path;
  }

  static Future<String?> signedUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    final cached = _signedUrlCache[path];
    final now = DateTime.now();
    if (cached != null && cached.expiresAt.isAfter(now)) return cached.url;

    final url = await _client.storage.from(bucket).createSignedUrl(path, 3600);
    _signedUrlCache[path] = _SignedUrlEntry(
      url,
      now.add(const Duration(minutes: 50)),
    );
    return url;
  }
}

class _SignedUrlEntry {
  const _SignedUrlEntry(this.url, this.expiresAt);

  final String url;
  final DateTime expiresAt;
}
