import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../theme/theme.dart';
import '../widgets/scale_tap.dart';
import '../services/websocket_service.dart';

import '../models/tracking_model.dart';
import '../services/tracking_service.dart';
import '../services/maps_service.dart';

class ClientTrackingScreen extends StatefulWidget {
  final String trackingNumber;

  const ClientTrackingScreen({super.key, required this.trackingNumber});

  @override
  State<ClientTrackingScreen> createState() => _ClientTrackingScreenState();
}

class _ClientTrackingScreenState extends State<ClientTrackingScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();

  ActiveOrderModel? _order;
  List<LatLng> _routePoints = [];
  LatLng? _currentPos;
  double _fraction = 0.0;
  double _totalDistance = 1.0;
  
  bool _isDroneMode = false;
  bool _hasNotifiedTraffic = false;
  bool _hasNotifiedWeather = false;
  bool _hasNotifiedArrival = false;
  bool _showArrivalCard = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // Fetch active couriers to find our order
    final couriers = await trackingService.getActiveCouriers();
    ActiveOrderModel? targetOrder;
    
    for (var c in couriers) {
      for (var o in c.activeOrders) {
        if (o.orderId.toString() == widget.trackingNumber) {
          targetOrder = o;
          break;
        }
      }
      if (targetOrder != null) break;
    }
    
    // Fallback if not found (for dev/testing)
    if (targetOrder == null && couriers.isNotEmpty && couriers.first.activeOrders.isNotEmpty) {
      targetOrder = couriers.first.activeOrders.first;
    }

    if (targetOrder != null) {
      _order = targetOrder;
      _currentPos = LatLng(targetOrder.pickupLatitude, targetOrder.pickupLongitude);
      
      // Fetch real route from maps_service
      final route = await mapsService.getRoutePoints(
        _currentPos!,
        LatLng(targetOrder.deliveryLatitude, targetOrder.deliveryLongitude)
      );
      
      setState(() {
        _routePoints = route;
        if (route.isNotEmpty) {
          const distanceCalc = Distance();
          _totalDistance = 0.0;
          for (int i = 0; i < route.length - 1; i++) {
            _totalDistance += distanceCalc.as(LengthUnit.Meter, route[i], route[i + 1]);
          }
          if (_totalDistance == 0) _totalDistance = 1.0;
        }
      });
      
      // Start WebSocket
      wsService.connect(targetOrder.orderId.toString());
      wsService.onMessageReceived = (data) {
        if (data['type'] == 'location_update' && data['order_id'].toString() == targetOrder!.orderId.toString()) {
          setState(() {
            _currentPos = LatLng(data['lat'], data['lon']);
            
            // Calculate fraction
            if (_routePoints.isNotEmpty) {
              final distRemaining = const Distance().as(LengthUnit.Meter, _currentPos!, _routePoints.last).toDouble();
              _fraction = (1.0 - (distRemaining / _totalDistance)).clamp(0.0, 1.0);
            }
          });
        }
      };
    }
  }

  @override
  void dispose() {
    wsService.disconnect();
    _mapController.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  void _showSituationalToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        backgroundColor: const Color(0xFF061525).withAlpha(240),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.neonTeal.withAlpha(50)),
        ),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _zoomIn() {
    final double zoom = _mapController.camera.zoom + 1;
    _mapController.move(_mapController.camera.center, zoom);
  }

  void _zoomOut() {
    final double zoom = _mapController.camera.zoom - 1;
    _mapController.move(_mapController.camera.center, zoom);
  }

  void _toggleDroneMode() {
    setState(() {
      _isDroneMode = !_isDroneMode;
    });
    if (_isDroneMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.airplanemode_active, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Dron Modu Aktif Ediliyor: Havadan Teslimata Geçiliyor",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.neonTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        ),
      );
    }
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF061525).withAlpha(240),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.neonTeal.withAlpha(50)),
        ),
        title: Row(
          children: [
            const Icon(Icons.camera_alt_rounded, color: AppColors.neonTeal),
            const SizedBox(width: 12),
            Text("Kamera İzni Gerekli", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          "AR (Artırılmış Gerçeklik) görünümünü başlatabilmek için kamera erişimine izin vermeniz gerekiyor.",
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("İptal", style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("AR Kamera başlatılıyor...", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)), 
                  backgroundColor: AppColors.neonTeal,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                ),
              );
            },
            child: Text("İzin Ver", style: GoogleFonts.inter(color: const Color(0xFF061525), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061525), // Deep Navy
      body: Stack(
        children: [
          // ── Harita (OSM TileLayer) ──
          Positioned.fill(
            child: Builder(
              builder: (context) {
                if (_routePoints.isEmpty || _currentPos == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.neonTeal),
                  );
                }
                
                final double fraction = _fraction;
                final LatLng currentPos = _currentPos!;
                
                // Başlangıç merkezi olarak kuryenin anlık konumunu veya pickup
                final LatLng mapCenter = currentPos;

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: mapCenter,

                    initialZoom: 13.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.loop.app',
                    ),
                    ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        -0.8, 0, 0, 0, 255,
                        0, -0.8, 0, 0, 255,
                        0, 0, -0.8, 0, 255,
                        0, 0, 0, 1, 0,
                      ]),
                      child: Container(
                        color: const Color(0xFF061525).withAlpha(150),
                      ),
                    ),
                    // Geçilmiş ve Gelecek Rotayı basitçe göster (Şimdilik tek renk)
                    PolylineLayer(
                      polylines: <Polyline>[
                        Polyline(
                          points: _routePoints,
                          color: AppColors.neonTeal,
                          strokeWidth: 5.0,
                        ),
                      ],
                    ),

                    MarkerLayer(
                      markers: [

                        // Başlangıç Noktası
                        Marker(
                          point: _routePoints.first,
                          width: 16,
                          height: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.neonTeal, width: 4),
                            ),
                          ),
                        ),
                        
                        // Bitiş Noktası
                        Marker(
                          point: _routePoints.last,
                          width: 16,
                          height: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF0055),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                          ),
                        ),
                        // Araç Marker'ı
                        Marker(
                          point: currentPos,
                          width: 60,
                          height: 60,
                          child: Transform.rotate(
                            angle: 0, // Rotation could be calculated if we have old pos
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF061525),
                                border: Border.all(color: _isDroneMode ? AppColors.neonTeal : Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isDroneMode ? AppColors.neonTeal : Colors.white).withAlpha(120),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  )
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  _isDroneMode ? Icons.airplanemode_active_rounded : Icons.local_shipping_rounded, 
                                  color: _isDroneMode ? AppColors.neonTeal : Colors.white, 
                                  size: 24
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            ),
          ),

          // ── Harita Kontrolleri (+/-) ──
          Positioned(
            top: 150,
            right: 20,
            child: Column(
              children: [
                ScaleTap(
                  onTap: _zoomIn,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF061525).withAlpha(180),
                          border: Border.all(color: Colors.white.withAlpha(30)),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
                ScaleTap(
                  onTap: _zoomOut,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF061525).withAlpha(180),
                          border: Border.all(color: Colors.white.withAlpha(30)),
                        ),
                        child: const Icon(Icons.remove_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Üst Bar (Sipariş Takip No) ──
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                ScaleTap(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF061525).withAlpha(200),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF061525).withAlpha(180),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(30)),
                      ),
                      child: Text(
                        'Sipariş: ${widget.trackingNumber.isEmpty ? "LOOP-9284" : widget.trackingNumber}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Proximity Alert (Yakınlık Bildirimi) ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            top: _showArrivalCard ? 130 : -150, // SafeArea altından gelir
            left: 20,
            right: 20,
            child: ScaleTap(
              onTap: () {
                setState(() => _showArrivalCard = false);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF061525).withAlpha(220),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.neonTeal.withAlpha(80), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: AppColors.neonTeal.withAlpha(50), blurRadius: 25, spreadRadius: 5)
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.neonTeal.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: AppColors.neonTeal, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Siparişiniz Kapıda! 📦",
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Kurye sokağınıza giriş yaptı, lütfen teslimat için hazırlanın.",
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.3),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── AI Chat Butonu (Floating) ──
          Positioned(
            bottom: 350, 
            right: 20,
            child: ScaleTap(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("AI Lojistik Asistanı başlatılıyor...", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)), 
                    backgroundColor: AppColors.neonTeal,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF9933FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withAlpha(100),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ]
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),

          // ── Gerçek Zamanlı Müşteri Paneli (DraggableScrollableSheet) ──
          Builder(
            builder: (context) {
              final double fraction = _fraction;
              
              // Dinamik hesaplamalar
              final int baseEta = 30; // Varsayılan 30 dk
              final double baseDistance = _totalDistance / 1000.0;
              final double baseSpeed = 40.0; // Varsayılan hız
              
              // Kalan süre ve mesafe hesaplamaları
              final int minutesRemaining = ((1.0 - fraction) * (_isDroneMode ? baseEta * 0.75 : baseEta)).ceil();
              final double kmRemaining = ((1.0 - fraction) * baseDistance);
              final double speed = _isDroneMode ? baseSpeed * 1.5 : baseSpeed;
              
              // Canlı Konum metni (İlerlemeye göre değişir)
              final String currentLocation = _order != null ? _order!.deliveryAddress.split(',').first : "Bilinmeyen Konum";

              return DraggableScrollableSheet(
                controller: _sheetCtrl,
                initialChildSize: 0.40,
                minChildSize: 0.08,
                maxChildSize: 0.75,
                builder: (context, scrollController) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF061525).withAlpha(190), // Deep Navy
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          border: Border(top: BorderSide(color: AppColors.neonTeal.withAlpha(40), width: 1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(100),
                              blurRadius: 30,
                              offset: const Offset(0, -10),
                            ),
                          ],
                        ),
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          children: [
                            // Drag Handle
                            Center(
                              child: ScaleTap(
                                onTap: () {
                                  if (_sheetCtrl.isAttached) {
                                    if (_sheetCtrl.size > 0.15) {
                                      _sheetCtrl.animateTo(0.08, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
                                    } else {
                                      _sheetCtrl.animateTo(0.40, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
                                    }
                                  }
                                },
                                child: Container(
                                  width: 100,
                                  height: 24,
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(150),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Progress Timeline
                            _TimelineBar(progress: fraction),
                            const SizedBox(height: 24),

                            // Büyük ETA
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "⏳ $minutesRemaining Dakika Kaldı",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonTeal.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.neonTeal.withAlpha(100)),
                                  ),
                                  child: Text(
                                    "Yolda",
                                    style: GoogleFonts.inter(
                                      color: AppColors.neonTeal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Mesafe ve Hız
                            Text(
                              "📏 ${kmRemaining.toStringAsFixed(1)} km | ${_isDroneMode ? '🚁' : '🚐'} Hız: ${speed.toStringAsFixed(0)} km/h",
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Canlı Konum Metni
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: AppColors.neonTeal, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Şu an: $currentLocation",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Son Konum Güncellemesi: 5 sn önce",
                              style: GoogleFonts.inter(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Badges (IoT Çipler)
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                const _ChipBadge(
                                  icon: Icons.battery_charging_full_rounded,
                                  label: "Batarya: %84",
                                  color: Color(0xFF4DBFB0),
                                ),
                                ScaleTap(
                                  onTap: _showCameraPermissionDialog,
                                  child: const _ChipBadge(
                                    icon: Icons.view_in_ar_rounded,
                                    label: "AR Görünümü Hazır",
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Genişletilebilir Detaylar (IoT / Güvenlik / Çevre)
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                childrenPadding: const EdgeInsets.only(bottom: 12),
                                collapsedIconColor: AppColors.neonTeal,
                                iconColor: AppColors.neonTeal,
                                title: Text(
                                  "Lojistik Detayları & Güvenlik",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withAlpha(15)),
                                    ),
                                    child: Column(
                                      children: [
                                        const _InfoRow(
                                          icon: Icons.sensors_rounded,
                                          title: "IoT Sensörleri",
                                          value: "Durum: Stabil | Sicaklik: 22°C 🌡️",
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          child: Divider(color: Colors.white10, height: 1),
                                        ),
                                        const _InfoRow(
                                          icon: Icons.lock_outline_rounded,
                                          title: "Güvenlik",
                                          value: "Teslimat PIN: 8492",
                                          valueColor: Color(0xFF00E5FF),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          child: Divider(color: Colors.white10, height: 1),
                                        ),
                                        const _InfoRow(
                                          icon: Icons.eco_rounded,
                                          title: "Çevre (Karbon Nötr)",
                                          value: "Önlenen CO2: 2.1kg 🌱",
                                          valueColor: Color(0xFF4DBFB0),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Aksiyonlar
                            Row(
                              children: [
                                Expanded(
                                  child: ScaleTap(
                                    onTap: _toggleDroneMode,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: _isDroneMode ? AppColors.neonTeal.withAlpha(20) : const Color(0xFF061525),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _isDroneMode ? AppColors.neonTeal : Colors.white.withAlpha(20)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Otonom Drone Modu",
                                            style: GoogleFonts.inter(
                                              color: _isDroneMode ? AppColors.neonTeal : Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Icon(
                                            _isDroneMode ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, 
                                            color: _isDroneMode ? AppColors.neonTeal : Colors.white54, 
                                            size: 32
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF0055).withAlpha(20),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFF0055).withAlpha(100)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const _BlinkingDot(),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Canlı Kamera",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFFFF0055),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          ),
        ],
      ),
    );
  }
}

// ── Timeline Bar ──
class _TimelineBar extends StatelessWidget {
  final double progress;

  const _TimelineBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _TimelineStep(title: "Sipariş\nAlındı", state: _StepState.completed)),
        Expanded(child: _TimelineStep(title: "Kuryede", state: _StepState.completed)),
        Expanded(child: _TimelineStep(title: "Yolda", state: _StepState.active)),
        Expanded(child: _TimelineStep(title: "Teslim\nEdildi", state: progress > 0.95 ? _StepState.completed : _StepState.pending, isLast: true)),
      ],
    );
  }
}

enum _StepState { completed, active, pending }

class _TimelineStep extends StatelessWidget {
  final String title;
  final _StepState state;
  final bool isLast;

  const _TimelineStep({required this.title, required this.state, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Line Before
            Expanded(
              child: Container(
                height: 2,
                color: state == _StepState.completed || state == _StepState.active 
                    ? AppColors.neonTeal : Colors.white10,
              ),
            ),
            // Dot
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: state == _StepState.active ? const Color(0xFF061525) : 
                       (state == _StepState.completed ? AppColors.neonTeal : const Color(0xFF061525)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: state == _StepState.pending ? Colors.white38 : AppColors.neonTeal, 
                  width: state == _StepState.active ? 4 : 2
                ),
                boxShadow: state == _StepState.active ? [
                  BoxShadow(color: AppColors.neonTeal.withAlpha(150), blurRadius: 10, spreadRadius: 2)
                ] : null,
              ),
              child: state == _StepState.completed 
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 10) 
                : null,
            ),
            // Line After
            Expanded(
              child: Container(
                height: 2,
                color: state == _StepState.completed && !isLast 
                    ? AppColors.neonTeal : Colors.transparent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: state == _StepState.active ? Colors.white : Colors.white54,
            fontSize: 10,
            fontWeight: state == _StepState.active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Badges & Utility Widgets ──
class _ChipBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ChipBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFFFF0055),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF0055).withAlpha(150),
              blurRadius: 6,
              spreadRadius: 2,
            )
          ]
        ),
      ),
    );
  }
}
