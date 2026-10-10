import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

import '../core/app_config.dart';

/// Uploads files to Firebase Storage, or returns a local path in demo mode.
class MediaService {
  MediaService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadFile({
    required File file,
    required String path,
  }) async {
    if (AppConfig.demoMode) {
      // In demo mode we keep the local path so AppImage can render it.
      return file.path;
    }

    final ref = _storage.ref(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadBytes({
    required List<int> bytes,
    required String path,
    String contentType = 'image/jpeg',
  }) async {
    if (AppConfig.demoMode) {
      return 'demo://$path';
    }

    final ref = _storage.ref(path);
    await ref.putData(
      bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
      SettableMetadata(contentType: contentType),
    );
    return ref.getDownloadURL();
  }

  String fileNameFor(File file, {String? prefix}) {
    final base = p.basename(file.path);
    if (prefix == null) return base;
    return '$prefix/$base';
  }
}
