import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

/// Shared Mapbox raster tile cache used by TripMap and offline downloads.
class MapboxTileCache {
  MapboxTileCache._();

  static final instance = CacheManager(
    Config(
      'mapboxTileCache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 12000,
    ),
  );

  static const tileUrlTemplate =
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token={accessToken}';
}

class MapboxCachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      headers: headers,
      cacheManager: MapboxTileCache.instance,
    );
  }
}
