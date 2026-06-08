import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui'; // ImageFilter
import 'dart:async';
import 'dart:math' as math;
import '../theme/theme.dart';
import '../widgets/scale_tap.dart';
import '../services/websocket_service.dart';
import '../utils/localization.dart';
import '../state/app_state_provider.dart';

/// Harita sekmesi — canlı filo takip ekranı.
class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  _OrderData? _selectedOrder;
  bool _isAIOptimized = false;
  bool _isRadarScanActive = false;

  void _onOptimizeRoutes() {
    setState(() => _isAIOptimized = true);
  }

  void _onTrafficAnalysis() {
    setState(() => _isRadarScanActive = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isRadarScanActive = false);
    });
  }

  // ── Global Hub (Türkiye Merkezli) Kurye Verileri ──────────────────────────
  static final _couriers = [
    // Türkiye İçi
    _CourierData(name: 'Ahmet Y.', status: 'Yolda', orders: 3, position: const LatLng(41.0082, 28.9784), color: const Color(0xFF4DBFB0)), // İstanbul
    _CourierData(name: 'Caner K.', status: 'Yolda', orders: 2, position: const LatLng(39.9334, 32.8597), color: const Color(0xFF00FFCC)), // Ankara
    _CourierData(name: 'Mehmet S.', status: 'Teslimatta', orders: 1, position: const LatLng(38.4237, 27.1428), color: const Color(0xFFFFAA00)), // İzmir
    _CourierData(name: 'Ali V.', status: 'Boşta', orders: 0, position: const LatLng(37.0662, 37.3833), color: const Color(0xFF9B7FFF)), // Gaziantep
    _CourierData(name: 'Serkan D.', status: 'Yolda', orders: 4, position: const LatLng(41.0053, 29.0122), color: const Color(0xFFFF0055)), // İstanbul (Anadolu)

    // Avrupa Hattı
    _CourierData(name: 'Oliver S.', status: 'Yolda', orders: 5, position: const LatLng(51.5074, -0.1278), color: const Color(0xFF00C3FF)), // London
    _CourierData(name: 'Hans B.', status: 'Yolda', orders: 2, position: const LatLng(52.5200, 13.4050), color: const Color(0xFF00FFCC)), // Berlin
    _CourierData(name: 'Pierre M.', status: 'Teslimatta', orders: 1, position: const LatLng(48.8566, 2.3522), color: const Color(0xFFFFAA00)), // Paris
    _CourierData(name: 'Luca R.', status: 'Yolda', orders: 3, position: const LatLng(41.9028, 12.4964), color: const Color(0xFF00C3FF)), // Rome
    _CourierData(name: 'Mateo C.', status: 'Yolda', orders: 4, position: const LatLng(40.4168, -3.7038), color: const Color(0xFF00C3FF)), // Madrid

    // Ortadoğu ve Asya Hattı
    _CourierData(name: 'Amir H.', status: 'Yolda', orders: 3, position: const LatLng(25.2048, 55.2708), color: const Color(0xFF00FFCC)), // Dubai
    _CourierData(name: 'Tariq A.', status: 'Teslimatta', orders: 1, position: const LatLng(24.7136, 46.6753), color: const Color(0xFFFFAA00)), // Riyadh
    _CourierData(name: 'Kenji T.', status: 'Yolda', orders: 2, position: const LatLng(35.6895, 139.6917), color: const Color(0xFF00C3FF)), // Tokyo
    _CourierData(name: 'Chen W.', status: 'Yolda', orders: 6, position: const LatLng(31.2304, 121.4737), color: const Color(0xFFFF0055)), // Shanghai
    _CourierData(name: 'Raj P.', status: 'Yolda', orders: 4, position: const LatLng(19.0760, 72.8777), color: const Color(0xFF00C3FF)), // Mumbai
  ];

  static final _activeOrders = [
    // --- AI Rotaları (Neon Mavi) ---
    _OrderData(id: 'LOOP-EU-101', customer: 'LogisTech GmbH', address: 'Berlin, Almanya', status: 'Yolda', courier: 'Hans B.', eta: '2s 15dk', statusColor: const Color(0xFF4DBFB0), routeType: 'ai', startPos: const LatLng(41.0082, 28.9784), endPos: const LatLng(52.5200, 13.4050)),
    _OrderData(id: 'LOOP-UK-205', customer: 'Global Trade Ltd', address: 'London, UK', status: 'Yolda', courier: 'Oliver S.', eta: '4s 30dk', statusColor: const Color(0xFF4DBFB0), routeType: 'ai', startPos: const LatLng(41.0082, 28.9784), endPos: const LatLng(51.5074, -0.1278)),
    _OrderData(id: 'LOOP-IT-309', customer: 'Roma Imports', address: 'Rome, Italy', status: 'Yolda', courier: 'Luca R.', eta: '1s 45dk', statusColor: const Color(0xFF4DBFB0), routeType: 'ai', startPos: const LatLng(38.4237, 27.1428), endPos: const LatLng(41.9028, 12.4964)),
    _OrderData(id: 'LOOP-JP-842', customer: 'Tokyo Electronics', address: 'Shibuya, Tokyo', status: 'Yolda', courier: 'Kenji T.', eta: '11s 20dk', statusColor: const Color(0xFF4DBFB0), routeType: 'ai', startPos: const LatLng(41.0082, 28.9784), endPos: const LatLng(35.6895, 139.6917)),
    _OrderData(id: 'LOOP-IN-404', customer: 'Mumbai Textiles', address: 'Mumbai, India', status: 'Yolda', courier: 'Raj P.', eta: '6s 10dk', statusColor: const Color(0xFF4DBFB0), routeType: 'ai', startPos: const LatLng(39.9334, 32.8597), endPos: const LatLng(19.0760, 72.8777)),
    _OrderData(id: 'LOOP-ES-502', customer: 'Madrid Supply', address: 'Madrid, Spain', status: 'Yolda', courier: 'Mateo C.', eta: '3s 50dk', statusColor: const Color(0xFF4DBFB0), routeType: 'ai', startPos: const LatLng(38.4237, 27.1428), endPos: const LatLng(40.4168, -3.7038)),

    // --- Anomali / Gecikme Rotaları (Neon Kırmızı) ---
    _OrderData(id: 'LOOP-CN-999', customer: 'Shanghai Auto', address: 'Shanghai, China', status: 'Gecikme', courier: 'Chen W.', eta: 'Gecikmeli', statusColor: const Color(0xFFFF0055), routeType: 'anomaly', startPos: const LatLng(41.0082, 28.9784), endPos: const LatLng(31.2304, 121.4737)),
    _OrderData(id: 'LOOP-TR-001', customer: 'Bosphorus AS', address: 'Kadikoy, Istanbul', status: 'Trafik', courier: 'Serkan D.', eta: '45 dk', statusColor: const Color(0xFFFF0055), routeType: 'anomaly', startPos: const LatLng(41.0053, 29.0122), endPos: const LatLng(40.9903, 29.0203)),
    
    // --- Teslimatta (Sarı) ---
    _OrderData(id: 'LOOP-FR-707', customer: 'Paris Fashion', address: 'Paris, France', status: 'Teslimatta', courier: 'Pierre M.', eta: '5 dk', statusColor: const Color(0xFFFFAA00), routeType: 'normal', startPos: const LatLng(41.0082, 28.9784), endPos: const LatLng(48.8566, 2.3522)),
    _OrderData(id: 'LOOP-SA-808', customer: 'Riyadh Holdings', address: 'Riyadh, KSA', status: 'Teslimatta', courier: 'Tariq A.', eta: '12 dk', statusColor: const Color(0xFFFFAA00), routeType: 'normal', startPos: const LatLng(37.0662, 37.3833), endPos: const LatLng(24.7136, 46.6753)),
    _OrderData(id: 'LOOP-TR-303', customer: 'Ege Tarım', address: 'Bornova, Izmir', status: 'Teslimatta', courier: 'Mehmet S.', eta: '8 dk', statusColor: const Color(0xFFFFAA00), routeType: 'normal', startPos: const LatLng(38.4237, 27.1428), endPos: const LatLng(38.4622, 27.2166)),

    // --- Normal Rotalar (Gri) ---
    _OrderData(id: 'LOOP-UAE-415', customer: 'Dubai Motors', address: 'Downtown, Dubai', status: 'Yolda', courier: 'Amir H.', eta: '3s 40dk', statusColor: const Color(0xFF4DBFB0), routeType: 'normal', startPos: const LatLng(37.0662, 37.3833), endPos: const LatLng(25.2048, 55.2708)),
    _OrderData(id: 'LOOP-TR-102', customer: 'Ankara Savunma', address: 'Cankaya, Ankara', status: 'Yolda', courier: 'Caner K.', eta: '25 dk', statusColor: const Color(0xFF4DBFB0), routeType: 'normal', startPos: const LatLng(39.9334, 32.8597), endPos: const LatLng(39.8906, 32.8569)),
    _OrderData(id: 'LOOP-TR-055', customer: 'Istanbul Tech', address: 'Levent, Istanbul', status: 'Yolda', courier: 'Ahmet Y.', eta: '18 dk', statusColor: const Color(0xFF4DBFB0), routeType: 'normal', startPos: const LatLng(41.0082, 28.9784), endPos: const LatLng(41.0825, 29.0118)),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep, // Bu değer global theme'den de alınabilir
      body: Stack(
          children: [
            // ── Harita alanı (En altta, tam ekran) ───────────────────────────
            Positioned.fill(
              child: _MapCanvas(
                couriers: _couriers,
                activeOrders: _activeOrders,
                pulseAnim: _pulse,
                selectedOrder: _selectedOrder,
                isAIOptimized: _isAIOptimized,
                isRadarScanActive: _isRadarScanActive,
                onOptimizeRoutes: _onOptimizeRoutes,
                onTrafficAnalysis: _onTrafficAnalysis,
                onOrderSelect: (order) {
                  setState(() => _selectedOrder = order);
                },
              ),
            ),

            // ── Üst Paneller (App Bar & Stats) ──────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _MapAppBar(),
                    const SizedBox(height: 8),
                    const _AILiveTicker(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1828).withAlpha(150),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Sipariş Takip Numarası',
                                hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withAlpha(150)),
                                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _StatsBar(),
                  ],
                ),
              ),
            ),

            // ── Aktif Siparişler (BottomSheet) ──────────────────────────────
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.35,
              minChildSize: 0.15,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return _ActiveOrdersList(
                  orders: _activeOrders,
                  selectedOrder: _selectedOrder,
                  onOrderSelect: (order) {
                    setState(() => _selectedOrder = order);
                  },
                  scrollController: scrollController,
                  onHandleTap: () {
                    if (_sheetController.isAttached) {
                      if (_sheetController.size < 0.5) {
                        _sheetController.animateTo(0.85, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      } else {
                        _sheetController.animateTo(0.15, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      }
                    }
                  },
                );
              },
            ),
          ],
        ),
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────

class _MapAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = AppStateProvider.of(context).locale;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Localization.translate('live_map', locale),
                  style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3)),
              Text(Localization.translate('fleet_tracked', locale),
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          // Canlı göstergesi
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2A30).withAlpha(150),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.transparent),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonRed.withAlpha(50),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                            color: AppColors.neonRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.neonRed, blurRadius: 4)
                            ])),
                    const SizedBox(width: 5),
                    Text(Localization.translate('live', locale),
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neonRed,
                            letterSpacing: 1,
                            shadows: [Shadow(color: AppColors.neonRed, blurRadius: 4)])),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// İstatistik Çubuğu
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            const _StatChip(
              icon: Icons.local_shipping_rounded,
              value: '24',
              label: 'Aktif Araç',
              color: AppColors.textAccent,
            ),
            const SizedBox(width: 10),
            const _StatChip(
              icon: Icons.check_circle_rounded,
              value: '18',
              label: 'Tamamlanan',
              color: Color(0xFF4DBFB0),
            ),
            const SizedBox(width: 10),
            const _StatChip(
              icon: Icons.warning_rounded,
              value: '2',
              label: 'Geciken',
              color: Color(0xFFFFAA00),
            ),
            const SizedBox(width: 10),
            const _StatChip(
              icon: Icons.eco_rounded,
              value: '₺12.4K',
              label: 'Yakıt Tasarrufu',
              color: Color(0xFF4DBFB0),
            ),
            const SizedBox(width: 10),
            const _StatChip(
              icon: Icons.timer_rounded,
              value: '%18',
              label: 'Kazanılan Zaman',
              color: Color(0xFF9B7FFF),
            ),
            const SizedBox(width: 10),
            const _StatChip(
              icon: Icons.co2_rounded,
              value: '1.4 Ton',
              label: 'Önlenen Emisyon',
              color: Color(0xFF00FFCC),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardBackground.withAlpha(180) : AppColors.lightCard.withAlpha(200);
    
    return Container(
      width: 140, // Fixed width
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.transparent),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(isDark ? 40 : 80),
                  blurRadius: 15,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16, shadows: [
                  Shadow(color: color, blurRadius: 10), // Neon Icon Glow
                ]),
                const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(value,
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                    height: 1)),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(label,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary)),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gerçek Dünya Haritası (FlutterMap)
// ─────────────────────────────────────────────────────────────────────────────

class _MapCanvas extends StatefulWidget {
  const _MapCanvas({
    required this.couriers, 
    required this.activeOrders,
    required this.pulseAnim, 
    this.selectedOrder, 
    required this.onOrderSelect,
    required this.isAIOptimized,
    required this.isRadarScanActive,
    required this.onOptimizeRoutes,
    required this.onTrafficAnalysis,
  });
  final List<_CourierData> couriers;
  final List<_OrderData> activeOrders;
  final Animation<double> pulseAnim;
  final _OrderData? selectedOrder;
  final Function(_OrderData) onOrderSelect;
  final bool isAIOptimized;
  final bool isRadarScanActive;
  final VoidCallback onOptimizeRoutes;
  final VoidCallback onTrafficAnalysis;

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LatLng _center = const LatLng(39.0, 35.0); // Türkiye Hub Center
  late AnimationController _vehicleAnimCtrl;
  bool _isHeatmapActive = false;

  @override
  void initState() {
    super.initState();
    _vehicleAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _vehicleAnimCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedOrder != null && oldWidget.selectedOrder != widget.selectedOrder) {
      _mapController.move(widget.selectedOrder!.endPos, 5.0); // Uzun mesafeler için zoom'u azalttık
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 4.5,
            maxZoom: 18.0,
            minZoom: 2.0,
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              userAgentPackageName: 'com.loop.lojistik',
            ),
            if (_isHeatmapActive)
              CircleLayer(
                circles: [
                  ...widget.activeOrders.map((order) {
                    return CircleMarker(
                      point: order.startPos,
                      color: Colors.red.withAlpha(100),
                      borderStrokeWidth: 0,
                      useRadiusInMeter: true,
                      radius: 20000,
                    );
                  }),
                  ...widget.couriers.map((courier) {
                    return CircleMarker(
                      point: courier.position,
                      color: Colors.green.withAlpha(80),
                      borderStrokeWidth: 0,
                      useRadiusInMeter: true,
                      radius: 30000,
                    );
                  }),
                ],
              ),
            if (widget.isRadarScanActive)
              AnimatedBuilder(
                animation: widget.pulseAnim,
                builder: (context, child) {
                  final progress = (widget.pulseAnim.value - 0.85) / 0.15;
                  return CircleLayer(
                    circles: [
                      CircleMarker(
                        point: const LatLng(39.0, 35.0),
                        color: AppColors.neonBlue.withAlpha((50 * (1.0 - progress)).toInt().clamp(0, 50)),
                        borderStrokeWidth: 2,
                        borderColor: AppColors.neonBlue.withAlpha(100),
                        useRadiusInMeter: true,
                        radius: 800000 * progress,
                      ),
                    ],
                  );
                },
              ),
            if (!_isHeatmapActive && widget.selectedOrder != null)
                  PolylineLayer(
                    polylines: <Polyline<Object>>[
                      Polyline(
                        points: [
                          widget.selectedOrder!.startPos,
                          widget.selectedOrder!.endPos,
                        ],
                        color: (widget.isAIOptimized && widget.selectedOrder!.routeType == 'anomaly')
                            ? AppColors.neonTeal
                            : widget.selectedOrder!.routeType == 'ai' 
                                ? AppColors.neonBlue 
                                : widget.selectedOrder!.routeType == 'anomaly' 
                                    ? AppColors.neonRed 
                                    : Colors.grey.withAlpha(120),
                        strokeWidth: widget.selectedOrder!.routeType == 'normal' ? 2.5 : 3.5,
                        gradientColors: (widget.isAIOptimized && widget.selectedOrder!.routeType == 'anomaly')
                            ? [AppColors.neonTeal.withAlpha(150), const Color(0xFF00FFCC).withAlpha(150)]
                            : widget.selectedOrder!.routeType == 'ai' 
                                ? [AppColors.neonTeal.withAlpha(150), AppColors.neonBlue.withAlpha(150)]
                                : widget.selectedOrder!.routeType == 'anomaly'
                                    ? [const Color(0xFFFF5500).withAlpha(150), AppColors.neonRed.withAlpha(150)]
                                    : null,
                      ),
                    ],
                  ),
            if (!_isHeatmapActive)
                MarkerLayer(
                  markers: widget.couriers.map((courier) {
                    final isSelected = widget.selectedOrder?.courier == courier.name;
                    return Marker(
                      point: courier.position,
                      width: 44,
                      height: 44,
                      child: _CorporateMarker(
                        color: courier.color,
                        status: courier.status,
                        isSelected: isSelected,
                      ),
                    );
                  }).toList(),
                ),
                // Moving Autonomous Vehicles
            if (!_isHeatmapActive)
                AnimatedBuilder(
                  animation: _vehicleAnimCtrl,
                  builder: (context, child) {
                    return MarkerLayer(
                      markers: widget.activeOrders.expand((order) {
                        final p = _vehicleAnimCtrl.value;
                        final lat = order.startPos.latitude + (order.endPos.latitude - order.startPos.latitude) * p;
                        final lng = order.startPos.longitude + (order.endPos.longitude - order.startPos.longitude) * p;
                        final currentPos = LatLng(lat, lng);
                        
                        // Digital Twin (10s ahead)
                        final twinP = (p + 0.05).clamp(0.0, 1.0);
                        final tLat = order.startPos.latitude + (order.endPos.latitude - order.startPos.latitude) * twinP;
                        final tLng = order.startPos.longitude + (order.endPos.longitude - order.startPos.longitude) * twinP;
                        final twinPos = LatLng(tLat, tLng);
                        
                        return [
                          Marker(
                            point: twinPos,
                            width: 30,
                            height: 30,
                            child: Opacity(
                              opacity: 0.4,
                              child: _CorporateMarker(
                                color: Colors.white,
                                status: 'Digital Twin',
                                isSelected: false,
                              ),
                            ),
                          ),
                          Marker(
                            point: currentPos,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => widget.onOrderSelect(order),
                              child: _CorporateMarker(
                                color: (widget.isAIOptimized && order.routeType == 'anomaly') ? AppColors.neonTeal : order.statusColor,
                                status: (widget.isAIOptimized && order.routeType == 'anomaly') ? 'Optimize Edildi' : order.status,
                                isSelected: widget.selectedOrder?.id == order.id,
                              ),
                            ),
                          ),
                        ];
                      }).toList(),
                    );
                  },
                ),
                // Eğer seçili sipariş varsa başlangıç ve bitiş noktalarına da marker ekleyelim
            if (!_isHeatmapActive && widget.selectedOrder != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: widget.selectedOrder!.startPos,
                        width: 30,
                        height: 30,
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                      ),
                      Marker(
                        point: widget.selectedOrder!.endPos,
                        width: 30,
                        height: 30,
                        child: const Icon(Icons.location_on_rounded, color: AppColors.textAccent, size: 30),
                      ),
                    ],
                  ),
              ],
            ),
            
            // Map Controls (Zoom & Heatmap)
            Positioned(
              right: 16,
              top: 200,
              child: Column(
                children: [
                  _MapBtn(
                    icon: _isHeatmapActive ? Icons.blur_off_rounded : Icons.blur_on_rounded,
                    onTap: () {
                      setState(() => _isHeatmapActive = !_isHeatmapActive);
                    },
                  ),
                  const SizedBox(height: 16),
                  _MapBtn(
                    icon: Icons.add_rounded,
                    onTap: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, currentZoom + 1);
                    },
                  ),
                  const SizedBox(height: 8),
                  _MapBtn(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, currentZoom - 1);
                    },
                  ),
                ],
              ),
            ),
            
            // AI Asistan FAB
            Positioned(
              right: 16,
              bottom: 240,
              child: _AIAssistantFab(
                onOptimizeRoutes: widget.onOptimizeRoutes,
                onTrafficAnalysis: widget.onTrafficAnalysis,
              ),
            ),
          ],
        );
  }
}

class _MapBtn extends StatelessWidget {
  const _MapBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1C2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
                color: AppColors.neonTeal.withAlpha(15), blurRadius: 8)
          ],
        ),
        child: Icon(icon, size: 16,
            color: AppColors.textSecondary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aktif Siparişler Listesi
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveOrdersList extends StatelessWidget {
  const _ActiveOrdersList({
    required this.orders,
    required this.selectedOrder,
    required this.onOrderSelect,
    this.scrollController,
    this.onHandleTap,
  });
  final List<_OrderData> orders;
  final _OrderData? selectedOrder;
  final Function(_OrderData) onOrderSelect;
  final ScrollController? scrollController;
  final VoidCallback? onHandleTap;

  @override
  Widget build(BuildContext context) {
    final locale = AppStateProvider.of(context).locale;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: isDark ? AppColors.backgroundDeep.withAlpha(200) : AppColors.lightBackground.withAlpha(220),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              GestureDetector(
                onTap: onHandleTap,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withAlpha(100),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        indicatorColor: AppColors.neonTeal,
                        labelColor: AppColors.textPrimary,
                        unselectedLabelColor: AppColors.textSecondary,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: Localization.translate('active_orders', locale)),
                          const Tab(text: "🏆 Performans"),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ListView.separated(
                              controller: scrollController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: orders.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                final isSelected = selectedOrder?.id == order.id;
                                return ScaleTap(
                                  onTap: () => onOrderSelect(order),
                                  child: _OrderCard(order: order, isSelected: isSelected),
                                );
                              },
                            ),
                            const _PerformanceLeaderboard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.isSelected});
  final _OrderData order;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColors = isDark 
        ? (isSelected ? AppColors.cardBackground.withAlpha(180) : AppColors.cardBackground.withAlpha(120))
        : (isSelected ? AppColors.lightCard.withAlpha(220) : AppColors.lightCard.withAlpha(180));
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColors,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.transparent),
            boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: AppColors.neonTeal.withAlpha(40),
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                ]
              : [
                  BoxShadow(
                    color: AppColors.cardBorder.withAlpha(isDark ? 20 : 60),
                    blurRadius: 10,
                  )
                ],
          ),
          child: Row(
            children: [
              // Sol ikon kutusu
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: order.statusColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2_rounded,
                    color: order.statusColor, size: 20),
              ),
              const SizedBox(width: 14),
              // Orta bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order.id,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: order.statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(order.status,
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: order.statusColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(order.customer,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 11, color: AppColors.textLabel),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(order.address,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time_rounded,
                            size: 11, color: AppColors.textLabel),
                        const SizedBox(width: 3),
                        Text(order.eta,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Veri modelleri
// ─────────────────────────────────────────────────────────────────────────────

class _CourierData {
  const _CourierData({
    required this.name,
    required this.status,
    required this.orders,
    required this.position,
    required this.color,
  });
  final String name;
  final String status;
  final int orders;
  final LatLng position;
  final Color color;
}

class _OrderData {
  const _OrderData({
    required this.id,
    required this.customer,
    required this.address,
    required this.status,
    required this.courier,
    required this.eta,
    required this.statusColor,
    required this.routeType,
    required this.startPos,
    required this.endPos,
  });
  final String id;
  final String customer;
  final String address;
  final String status;
  final String courier;
  final String eta;
  final Color statusColor;
  final String routeType;
  final LatLng startPos;
  final LatLng endPos;
}

// ─────────────────────────────────────────────────────────────────────────────
// Kurumsal Minimalist Marker (SaaS Stili)
// ─────────────────────────────────────────────────────────────────────────────

class _CorporateMarker extends StatelessWidget {
  const _CorporateMarker({
    required this.color,
    required this.status,
    required this.isSelected,
  });
  final Color color;
  final String status;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDelayed = status == 'Gecikme' || status == 'Trafik';
    final dotColor = isDelayed ? Colors.orange : const Color(0xFF4DBFB0);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(
              color: isSelected ? color : Colors.white,
              width: isSelected ? 2.5 : 0,
            ),
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: Color(0xFF0B132B), // Koyu lacivert
            size: 20,
          ),
        ),
        // Durum Belirteci (Nokta)
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Canlı Uyarı Ticker'ı (Marquee)
// ─────────────────────────────────────────────────────────────────────────────

class _AILiveTicker extends StatefulWidget {
  const _AILiveTicker({super.key});

  @override
  State<_AILiveTicker> createState() => _AILiveTickerState();
}

class _AILiveTickerState extends State<_AILiveTicker> {
  final List<String> _messages = [
    "⚠️ FSM Köprüsü'nde yoğun trafik: 3 otonom araç yeni rotaya aktarıldı.",
    "✅ AI Rota Optimizasyonu ile genel gecikmeler %18 azaltıldı.",
    "⛈️ Şiddetli hava uyarısı: Kuzey Marmara drone teslimatları askıya alındı.",
  ];
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() => _currentIndex = (_currentIndex + 1) % _messages.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1828).withAlpha(180),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neonBlue.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.neonBlue, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child, // Removed SlideTransition to prevent vertical bouncing, making it fade nicely.
                      );
                    },
                    child: Text(
                      _messages[_currentIndex],
                      key: ValueKey<int>(_currentIndex),
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Performans Liderlik Tablosu
// ─────────────────────────────────────────────────────────────────────────────

class _PerformanceLeaderboard extends StatelessWidget {
  const _PerformanceLeaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    final couriers = [
      {'name': 'Kurye Mehmet S.', 'score': '98/100', 'status': 'Aktif', 'color': const Color(0xFF4DBFB0)},
      {'name': 'Otonom Drone X1', 'score': '95/100', 'status': 'Şarjda', 'color': AppColors.neonBlue},
      {'name': 'Filo Kamyon #4', 'score': '88/100', 'status': 'Aktif', 'color': AppColors.textAccent},
    ];

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: couriers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = couriers[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withAlpha(120),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: (c['color'] as Color).withAlpha(30),
                child: Icon(Icons.person, color: c['color'] as Color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['name'] as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('Teslimat Skoru', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(c['score'] as String, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Holografik AI Asistan Düğmesi
// ─────────────────────────────────────────────────────────────────────────────

class _AIAssistantFab extends StatefulWidget {
  const _AIAssistantFab({super.key, required this.onOptimizeRoutes, required this.onTrafficAnalysis});
  final VoidCallback onOptimizeRoutes;
  final VoidCallback onTrafficAnalysis;

  @override
  State<_AIAssistantFab> createState() => _AIAssistantFabState();
}

class _AIAssistantFabState extends State<_AIAssistantFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: false);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _AIVoiceAssistantSheet(
            onOptimizeRoutes: widget.onOptimizeRoutes,
            onTrafficAnalysis: widget.onTrafficAnalysis,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final progress = _pulseCtrl.value;
          return SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Yayılan Halka (Pulse Effect)
                Container(
                  width: 60 + (progress * 20),
                  height: 60 + (progress * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withOpacity(1.0 - progress),
                      width: 2,
                    ),
                  ),
                ),
                // Ana Düğme
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: const Color(0xFFA855F7).withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Holografik Voice Assistant Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AIVoiceAssistantSheet extends StatefulWidget {
  const _AIVoiceAssistantSheet({super.key, required this.onOptimizeRoutes, required this.onTrafficAnalysis});
  final VoidCallback onOptimizeRoutes;
  final VoidCallback onTrafficAnalysis;

  @override
  State<_AIVoiceAssistantSheet> createState() => _AIVoiceAssistantSheetState();
}

class _AIVoiceAssistantSheetState extends State<_AIVoiceAssistantSheet> {
  String _spokenText = "";
  bool _isProcessing = false;
  bool _isOptimizing = false;
  bool _isAnalyzing = false;
  Timer? _typingTimer;
  int _charIndex = 0;
  final String _targetText = "Kurye Caner için alternatif rota oluştur...";

  @override
  void initState() {
    super.initState();
    _startSimulatedListening();
  }

  void _startSimulatedListening() {
    _typingTimer?.cancel();
    _charIndex = 0;
    _spokenText = "";
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || _isProcessing) return;
      _typingTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
        if (_charIndex < _targetText.length) {
          setState(() {
            _charIndex++;
            _spokenText = _targetText.substring(0, _charIndex);
          });
        } else {
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) _processCommand("Rota Optimizasyonu Başlatıldı", isTraffic: false);
          });
        }
      });
    });
  }

  void _typeCommand(String command, String successMsg, {bool isTraffic = false}) {
    _typingTimer?.cancel();
    setState(() {
      _spokenText = "";
      _isProcessing = false;
    });
    
    int charIdx = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (charIdx < command.length) {
        setState(() {
          charIdx++;
          _spokenText = command.substring(0, charIdx);
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _processCommand(successMsg, isTraffic: isTraffic);
        });
      }
    });
  }

  void _processCommand(String msg, {bool isTraffic = false}) {
    _typingTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
    });
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.pop(context);
      
      final double leftMargin = MediaQuery.of(context).size.width - 320;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isTraffic ? Icons.warning_rounded : Icons.check_circle_rounded, 
                color: isTraffic ? const Color(0xFFFF0055) : AppColors.neonTeal,
                size: 24,
                shadows: [
                  Shadow(color: (isTraffic ? const Color(0xFFFF0055) : AppColors.neonTeal).withAlpha(100), blurRadius: 10)
                ]
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg, 
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white, height: 1.3)
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF061525).withAlpha(240),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: (isTraffic ? const Color(0xFFFF0055) : AppColors.neonTeal).withAlpha(100), 
              width: 1
            )
          ),
          elevation: 20,
          margin: EdgeInsets.only(
            bottom: 250, 
            left: leftMargin > 16 ? leftMargin : 16, 
            right: 16
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        height: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF061525).withAlpha(200), // Daha premium dark glass
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: AppColors.neonBlue.withAlpha(50))),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _isOptimizing 
                  ? 'AI Rotaları Hesaplıyor...' 
                  : _isAnalyzing 
                      ? 'Trafik Ağı Taranıyor...' 
                      : _isProcessing 
                          ? 'AI Analiz Ediyor...' 
                          : 'Lojistik Asistanı Dinliyor...',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: (_isProcessing || _isOptimizing || _isAnalyzing) ? AppColors.neonTeal : const Color(0xFF00E5FF),
                shadows: [
                  Shadow(
                    color: ((_isProcessing || _isOptimizing || _isAnalyzing) ? AppColors.neonTeal : const Color(0xFF00E5FF)).withAlpha(100), 
                    blurRadius: 10
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            _VoiceWaves(isProcessing: _isProcessing),
            const SizedBox(height: 24),
            // Konuşulan metnin yazıldığı yer
            Container(
              height: 60,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _spokenText.isEmpty ? "..." : '"$_spokenText"',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withAlpha(220),
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _GlassCard(
                    icon: Icons.route_rounded,
                    text: 'Rotaları\nOptimize Et',
                    isLoading: _isOptimizing,
                    onTap: () {
                      if (!_isProcessing && !_isOptimizing && !_isAnalyzing) {
                        setState(() => _isOptimizing = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (!mounted) return;
                          setState(() => _isOptimizing = false);
                          widget.onOptimizeRoutes();
                          _typeCommand("Tüm filonun rotalarını anlık trafiğe göre optimize et.", "AI Rota Optimizasyonu Tamamlandı:\n%12 Zaman Kazancı sağlandı.", isTraffic: false);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _GlassCard(
                    icon: Icons.traffic_rounded,
                    text: 'Trafik Analizi\nBaşlat',
                    isLoading: _isAnalyzing,
                    onTap: () {
                      if (!_isProcessing && !_isOptimizing && !_isAnalyzing) {
                        setState(() => _isAnalyzing = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (!mounted) return;
                          setState(() => _isAnalyzing = false);
                          widget.onTrafficAnalysis();
                          _typeCommand("Bölge 3 için yoğunluk ve gecikme analizi başlat.", "Kritik Trafik Noktaları Tespit Edildi:\nAlternatif rotalar oluşturuluyor.", isTraffic: true);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _VoiceWaves extends StatefulWidget {
  const _VoiceWaves({super.key, this.isProcessing = false});
  final bool isProcessing;

  @override
  State<_VoiceWaves> createState() => _VoiceWavesState();
}

class _VoiceWavesState extends State<_VoiceWaves> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }
  
  @override
  void didUpdateWidget(covariant _VoiceWaves oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isProcessing != oldWidget.isProcessing) {
      if (widget.isProcessing) {
        _ctrl.duration = const Duration(milliseconds: 400); // Hızlandır
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.duration = const Duration(milliseconds: 1000); // Normal
        _ctrl.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final double baseHeight = 20.0;
            final double distance = (index - 3).abs().toDouble();
            final double maxHeight = 60.0 - (distance * 10);
            
            final double phase = index * 0.5;
            final double value = math.sin((_ctrl.value * math.pi * 2) + phase);
            final double currentHeight = baseHeight + ((value + 1) / 2) * maxHeight;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: currentHeight,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isProcessing 
                    ? [const Color(0xFF4DBFB0), const Color(0xFF00E5FF)] 
                    : [const Color(0xFF00E5FF), const Color(0xFFA855F7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isProcessing ? const Color(0xFF4DBFB0) : const Color(0xFF00E5FF)).withAlpha(100),
                    blurRadius: 8,
                  )
                ]
              ),
            );
          }),
        );
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.icon, required this.text, required this.onTap, this.isLoading = false});
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isLoading ? AppColors.neonTeal.withAlpha(20) : Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isLoading ? AppColors.neonTeal : Colors.white.withAlpha(40)),
          boxShadow: isLoading ? [
            BoxShadow(
              color: AppColors.neonTeal.withAlpha(50),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ] : null,
        ),
        child: Column(
          children: [
            if (isLoading)
              const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(color: AppColors.neonTeal, strokeWidth: 2.5),
              )
            else
              Icon(icon, color: Colors.white.withAlpha(200), size: 28),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLoading ? AppColors.neonTeal : Colors.white,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
