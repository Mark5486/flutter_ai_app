import 'dart:convert';

import 'package:flutter/material.dart';

class MessageImage extends StatelessWidget {
  const MessageImage({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final Widget image;

    if (imageUrl.startsWith('data:')) {
      image = _decodeDataUrl();
    } else {
      image = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return const SizedBox(
            height: 180,
            width: 240,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (context, error, stackTrace) => _brokenImage(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: image,
    );
  }

  Widget _decodeDataUrl() {
    try {
      return Image.memory(
        base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1)),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _brokenImage(),
      );
    } catch (_) {
      return _brokenImage();
    }
  }

  Widget _brokenImage() {
    return const SizedBox(
      height: 120,
      width: 200,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white70),
      ),
    );
  }
}
