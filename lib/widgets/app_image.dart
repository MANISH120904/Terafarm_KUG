import 'dart:io';

import 'package:flutter/material.dart';

/// Renders network URLs, local file paths, asset paths, or demo:// placeholders.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackAsset = 'assets/sample_farm.png',
  });

  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final child = _buildImage();
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildImage() {
    final src = source?.trim() ?? '';
    if (src.isEmpty || src.startsWith('demo://')) {
      return _asset(fallbackAsset);
    }
    if (src.startsWith('assets/')) {
      return _asset(src);
    }
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _asset(fallbackAsset),
      );
    }
    // Local filesystem path (demo uploads).
    try {
      final file = File(src);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _asset(fallbackAsset),
        );
      }
    } catch (_) {
      // Fall through to asset.
    }
    return _asset(src.startsWith('assets/') ? src : fallbackAsset);
  }

  Widget _asset(String path) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported, color: Colors.grey.shade600),
      ),
    );
  }
}
