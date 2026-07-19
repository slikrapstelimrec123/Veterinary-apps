import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class AnnouncementMediaStorage {
  AnnouncementMediaStorage._();

  static const bucket = 'announcement-media';
  static final Map<String, _SignedUrlEntry> _signedUrlCache = {};

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<String> uploadImage({
    required String announcementId,
    required File file,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Authentication required');

    final rawExtension = file.path.split('.').last.toLowerCase();
    final extension = rawExtension == 'jpeg' ? 'jpg' : rawExtension;
    final path =
        '${user.id}/$announcementId/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await _client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: const FileOptions(cacheControl: '86400'),
        );
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
