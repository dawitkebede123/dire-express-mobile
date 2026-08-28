import 'dart:math' as math;

import 'config.dart';
import '../features/maps/mapbox_tiles.dart';

/// Downloads Mapbox 1x tiles for the Addis–Djibouti freight corridor for offline use.
class OfflineMapService {
  OfflineMapService._();
  static final instance = OfflineMapService._();

  /// Freight corridor covering central Ethiopia ↔ Djibouti.
  static const south = 8.4;
  static const north = 12.6;
  static const west = 38.0;
  static const east = 43.6;
  static const minZoom = 6;
  static const maxZoom = 11;

  var _cancel = false;

  void cancel() => _cancel = true;

  Future<void> downloadRegion({
    required void Function(int progressPercent) onProgress,
  }) async {
    if (!AppConfig.hasMapbox) {
      throw StateError('Mapbox token missing');
    }
    _cancel = false;
    final urls = <String>[];
    for (var z = minZoom; z <= maxZoom; z++) {
      final x0 = _lonToTileX(west, z);
      final x1 = _lonToTileX(east, z);
      final y0 = _latToTileY(north, z);
      final y1 = _latToTileY(south, z);
      for (var x = math.min(x0, x1); x <= math.max(x0, x1); x++) {
        for (var y = math.min(y0, y1); y <= math.max(y0, y1); y++) {
          urls.add(
            MapboxTileCache.tileUrlTemplate
                .replaceAll('{z}', '$z')
                .replaceAll('{x}', '$x')
                .replaceAll('{y}', '$y')
                .replaceAll('{accessToken}', AppConfig.mapboxToken),
          );
        }
      }
    }

    final total = urls.length;
    if (total == 0) {
      onProgress(100);
      return;
    }
    var done = 0;
    const batch = 6;
    for (var i = 0; i < urls.length; i += batch) {
      if (_cancel) throw StateError('cancelled');
      final chunk = urls.sublist(i, math.min(i + batch, urls.length));
      await Future.wait(chunk.map((url) async {
        try {
          await MapboxTileCache.instance.getSingleFile(url);
        } catch (_) {}
      }));
      done += chunk.length;
      onProgress(((done / total) * 100).floor().clamp(0, 100));
    }
    onProgress(100);
  }

  int _lonToTileX(double lon, int zoom) {
    final n = 1 << zoom;
    return ((lon + 180.0) / 360.0 * n).floor().clamp(0, n - 1);
  }

  int _latToTileY(double lat, int zoom) {
    final n = 1 << zoom;
    final latRad = lat * math.pi / 180.0;
    final y = (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n;
    return y.floor().clamp(0, n - 1);
  }
}
