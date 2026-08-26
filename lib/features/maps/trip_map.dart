import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class TripMap extends StatefulWidget {
  const TripMap({
    super.key,
    this.pickup,
    this.delivery,
    this.driver,
    this.height = 220,
    this.showLiveBadge = false,
    this.expandable = false,
    this.showCollapse = false,
    this.onCollapse,
    this.clipCorners = true,
  });

  final LatLng? pickup;
  final LatLng? delivery;
  final LatLng? driver;
  final double height;
  final bool showLiveBadge;
  final bool expandable;
  final bool showCollapse;
  final VoidCallback? onCollapse;
  final bool clipCorners;

  @override
  State<TripMap> createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  final _controller = MapController();
  late final ValueNotifier<LatLng?> _driverNotifier;

  @override
  void initState() {
    super.initState();
    _driverNotifier = ValueNotifier(widget.driver);
  }

  @override
  void dispose() {
    _driverNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.driver != oldWidget.driver) {
      _driverNotifier.value = widget.driver;
      if (widget.driver != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fit();
        });
      }
    }
  }

  void _fit() {
    final points = <LatLng>[
      if (widget.pickup != null) widget.pickup!,
      if (widget.driver != null) widget.driver!,
      if (widget.delivery != null) widget.delivery!,
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _controller.move(points.first, 10);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _controller.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(36)));
  }

  void _expand() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _ExpandedTripMapPage(
          pickup: widget.pickup,
          delivery: widget.delivery,
          driverListenable: _driverNotifier,
          showLiveBadge: widget.showLiveBadge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!AppConfig.hasMapbox) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: widget.clipCorners ? BorderRadius.circular(12) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.mapMissingToken, textAlign: TextAlign.center),
        ),
      );
    }

    final center = widget.pickup ?? widget.delivery ?? const LatLng(9.0250, 38.7469);
    final line = <LatLng>[
      if (widget.pickup != null) widget.pickup!,
      if (widget.driver != null) widget.driver!,
      if (widget.delivery != null) widget.delivery!,
    ];

    final map = SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: center,
              initialZoom: widget.pickup != null ? 10 : 4,
              onMapReady: _fit,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token={accessToken}',
                additionalOptions: {'accessToken': AppConfig.mapboxToken},
                userAgentPackageName: 'com.direexpress.app',
              ),
              if (line.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: line,
                      color: AppColors.secondary,
                      strokeWidth: 3,
                      pattern: StrokePattern.dashed(segments: const [8, 6]),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (widget.pickup != null)
                    Marker(
                      point: widget.pickup!,
                      width: 28,
                      height: 28,
                      child: const Icon(Icons.circle, color: AppColors.secondary, size: 16),
                    ),
                  if (widget.delivery != null)
                    Marker(
                      point: widget.delivery!,
                      width: 32,
                      height: 32,
                      child: const Icon(Icons.location_on, color: AppColors.secondary, size: 28),
                    ),
                  if (widget.driver != null)
                    Marker(
                      point: widget.driver!,
                      width: 36,
                      height: 36,
                      child: const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.local_shipping, color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (widget.showLiveBadge)
            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                right: false,
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(l10n.mapLiveTracking, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              left: false,
              bottom: false,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.expandable) ...[
                    _MapRoundButton(
                      tooltip: l10n.mapExpand,
                      icon: Icons.fullscreen,
                      onPressed: _expand,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.showCollapse) ...[
                    _MapRoundButton(
                      tooltip: l10n.mapCollapse,
                      icon: Icons.fullscreen_exit,
                      onPressed: widget.onCollapse ?? () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _MapRoundButton(
                    tooltip: l10n.mapRecenter,
                    icon: Icons.my_location,
                    onPressed: _fit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.clipCorners) return map;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: map,
    );
  }
}

class _ExpandedTripMapPage extends StatefulWidget {
  const _ExpandedTripMapPage({
    required this.pickup,
    required this.delivery,
    required this.driverListenable,
    required this.showLiveBadge,
  });

  final LatLng? pickup;
  final LatLng? delivery;
  final ValueNotifier<LatLng?> driverListenable;
  final bool showLiveBadge;

  @override
  State<_ExpandedTripMapPage> createState() => _ExpandedTripMapPageState();
}

class _ExpandedTripMapPageState extends State<_ExpandedTripMapPage> {
  LatLng? _driver;

  @override
  void initState() {
    super.initState();
    _driver = widget.driverListenable.value;
    widget.driverListenable.addListener(_onDriver);
  }

  @override
  void dispose() {
    widget.driverListenable.removeListener(_onDriver);
    super.dispose();
  }

  void _onDriver() {
    if (!mounted) return;
    setState(() => _driver = widget.driverListenable.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TripMap(
        pickup: widget.pickup,
        delivery: widget.delivery,
        driver: _driver,
        height: MediaQuery.sizeOf(context).height,
        showLiveBadge: widget.showLiveBadge,
        showCollapse: true,
        onCollapse: () => Navigator.of(context).pop(),
        clipCorners: false,
      ),
    );
  }
}

class _MapRoundButton extends StatelessWidget {
  const _MapRoundButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.secondary),
      ),
    );
  }
}
