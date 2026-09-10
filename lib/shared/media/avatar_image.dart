import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Downscales and JPEG-encodes avatar crop bytes for upload (avoids 413).
Uint8List compressAvatar(
  Uint8List bytes, {
  int maxSide = 512,
  int quality = 85,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
  final img.Image resized;
  if (longest <= maxSide) {
    resized = decoded;
  } else {
    resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxSide : null,
      height: decoded.height > decoded.width ? maxSide : null,
      interpolation: img.Interpolation.linear,
    );
  }

  return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
}
