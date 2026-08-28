import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/system_price.dart';
import '../../shared/widgets/app_header.dart';
import '../../theme/app_theme.dart';
import 'mapbox_tiles.dart';

/// Full-screen map to pick an exact lat/lng for pickup or delivery.
class PickLocationScreen extends ConsumerStatefulWidget {
  const PickLocationScreen({
    super.key,
    this.initial,
    this.initialName,
  });

  final LatLng? initial;
  final String? initialName;

  @override
  ConsumerState<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends ConsumerState<PickLocationScreen> {
  late LatLng _point;
  var _busy = false;
  String? _placeName;

  @override
  void initState() {
    super.initState();
    _point = widget.initial ?? const LatLng(9.0250, 38.7469);
    _placeName = widget.initialName;
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final place = await ref.read(apiClientProvider).reverseGeocode(_point.latitude, _point.longitude);
      if (!mounted) return;
      final suggestion = place ??
          PlaceSuggestion(
            placeName: _placeName?.trim().isNotEmpty == true
                ? _placeName!.trim()
                : '${_point.latitude.toStringAsFixed(5)}, ${_point.longitude.toStringAsFixed(5)}',
            lat: _point.latitude,
            lng: _point.longitude,
          );
      Navigator.of(context).pop(suggestion);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(title: l10n.brokerMapPickTitle, showBack: true),
      body: !AppConfig.hasMapbox
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.mapMissingToken, textAlign: TextAlign.center)))
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _point,
                    initialZoom: 13,
                    maxZoom: 16,
                    onTap: (_, latLng) => setState(() {
                      _point = latLng;
                      _placeName = null;
                    }),
                    onPositionChanged: (camera, hasGesture) {
                      if (!hasGesture) return;
                      setState(() {
                        _point = camera.center;
                        _placeName = null;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapboxTileCache.tileUrlTemplate,
                      additionalOptions: {'accessToken': AppConfig.mapboxToken},
                      userAgentPackageName: 'com.direexpress.app',
                      maxZoom: 16,
                      tileProvider: MapboxCachedTileProvider(),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _point,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_on, color: AppColors.primary, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: SafeArea(
                    child: FilledButton(
                      onPressed: _busy ? null : _confirm,
                      child: Text(_busy ? l10n.commonLoading : l10n.brokerConfirmMapLocation),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
