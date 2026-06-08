import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../theme/theme.dart';
import '../widgets/scale_tap.dart';
import '../services/websocket_service.dart';

// ── Senaryo Veri Modeli ──
class _MockRouteData {
  final String id;
  final List<LatLng> points;
  final int etaMinutes;
  final double speed;
  final double distanceKm;
  final LatLng trafficPoint;
  final List<String> locationTexts;

  _MockRouteData({
    required this.id,
    required this.points,
    required this.etaMinutes,
    required this.speed,
    required this.distanceKm,
    required this.trafficPoint,
    required this.locationTexts,
  });
}

class ClientTrackingScreen extends StatefulWidget {
  final String trackingNumber;

  const ClientTrackingScreen({super.key, required this.trackingNumber});

  @override
  State<ClientTrackingScreen> createState() => _ClientTrackingScreenState();
}

class _ClientTrackingScreenState extends State<ClientTrackingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _vehicleCtrl;
  late Animation<double> _vehicleAnim;
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();

  // ── Mock Veritabanı (Senaryolar) ──
  static final List<_MockRouteData> _scenarios = [
    _MockRouteData(
      id: "LOOP-101",
      points: [
        const LatLng(40.9903, 29.0203), // Kadıköy
        const LatLng(40.9920, 29.0220),
        const LatLng(40.9945, 29.0210),
        const LatLng(40.9980, 29.0180),
        const LatLng(41.0005, 29.0160), // Haydarpaşa
        const LatLng(41.0035, 29.0145), // Harem
        const LatLng(41.0060, 29.0130), 
        const LatLng(41.0100, 29.0125), 
        const LatLng(41.0135, 29.0120),
        const LatLng(41.0170, 29.0130), // Salacak
        const LatLng(41.0200, 29.0135),
        const LatLng(41.0225, 29.0140),
        const LatLng(41.0250, 29.0145),
        const LatLng(41.0263, 29.0153), // Üsküdar
      ],
      etaMinutes: 34,
      speed: 42.0,
      distanceKm: 8.4,
      trafficPoint: const LatLng(41.0060, 29.0130),
      locationTexts: ["Kadıköy", "Harem Sahil Yolu", "Salacak, Üsküdar"],
    ),
    _MockRouteData(
      id: "LOOP-102",
      points: [
        const LatLng(41.0422, 29.0060), // Beşiktaş
        const LatLng(41.0450, 29.0050),
        const LatLng(41.0480, 29.0060),
        const LatLng(41.0520, 29.0075),
        const LatLng(41.0560, 29.0085),
        const LatLng(41.0600, 29.0100),
        const LatLng(41.0640, 29.0110),
        const LatLng(41.0680, 29.0125),
        const LatLng(41.0720, 29.0135),
        const LatLng(41.0760, 29.0140), // Levent
      ],
      etaMinutes: 18,
      speed: 35.0,
      distanceKm: 4.2,
      trafficPoint: const LatLng(41.0560, 29.0085),
      locationTexts: ["Beşiktaş Meydan", "Barbaros Bulvarı", "Levent, Zincirlikuyu"],
    ),
    _MockRouteData(
      id: "LOOP-103",
      points: [
        const LatLng(40.9780, 28.8730), // Bakırköy
        const LatLng(40.9800, 28.8780),
        const LatLng(40.9820, 28.8830),
        const LatLng(40.9840, 28.8880),
        const LatLng(40.9860, 28.8930),
        const LatLng(40.9880, 28.8980),
        const LatLng(40.9890, 28.9030), // Zeytinburnu
      ],
      etaMinutes: 24,
      speed: 50.0,
      distanceKm: 5.8,
      trafficPoint: const LatLng(40.9840, 28.8880),
      locationTexts: ["Bakırköy Sahil", "Veliefendi Yolu", "Zeytinburnu"],
    ),
  ];

  late _MockRouteData _currentScenario;
  late List<LatLng> _routePoints;
  final List<double> _cumulativeDistances = [];
  double _totalDistance = 0.0;
  
  bool _isDroneMode = false;
  bool _hasNotifiedTraffic = false;
  bool _hasNotifiedWeather = false;
  bool _hasNotifiedArrival = false;
  bool _showArrivalCard = false;

  @override
  void initState() {
    super.initState();

    // Gerçek zamanlı WebSocket bağlantısı
    wsService.connect(widget.trackingNumber); // Order ID or User ID
    wsService.onMessageReceived = (data) {
      if (data['type'] == 'location_update') {
        // Gerçek koordinatlar geldiğinde UI güncellenecek
        print("Real location received: ${data['lat']}, ${data['lon']}");
        // TODO: _currentPos = LatLng(data['lat'], data['lon']);
        // TODO: setState(() {});
      }
    };

    // Dinamik Senaryo Seçimi
    try {
      _currentScenario = _scenarios.firstWhere((s) => s.id == widget.trackingNumber);
    } catch (e) {
      // Eğer geçersiz/random bir numara girildiyse rastgele bir senaryo seç
      _currentScenario = _scenarios[math.Random().nextInt(_scenarios.length)];
    }
    
    _routePoints = _currentScenario.points;
    
    // Rota mesafelerini hesapla
    double currentDist = 0.0;
    _cumulativeDistances.add(0.0);
    const distanceCalc = Distance();
    for (int i = 0; i < _routePoints.length - 1; i++) {
      double dist = distanceCalc.as(LengthUnit.Meter, _routePoints[i], _routePoints[i + 1]);
      currentDist += dist;
      _cumulativeDistances.add(currentDist);
    }
    _totalDistance = currentDist;

    // Uzun soluklu pürüzsüz animasyon (sanki yavaş ilerliyormuş gibi 150 saniye / 2.5 dakika)
    _vehicleCtrl = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 150)
    )..forward();
    
    _vehicleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _vehicleCtrl, curve: Curves.easeInOutCubic)
    );

    // Animasyon dinleyicisi: Dinamik harita olayları ve Toast/Snackbar bildirimleri
    _vehicleCtrl.addListener(() {
      final double v = _vehicleAnim.value;
      
      // %30 ilerlemede yol çalışması / AI rota bildirimi
      if (v > 0.3 && !_hasNotifiedTraffic) {
        _hasNotifiedTraffic = true;
        _showSituationalToast("⚠️ İlerideki yol çalışması algılandı. AI alternatif rotayı kullanıyor.");
      }
      
      // %60 ilerlemede hava durumu bildirimi
      if (v > 0.6 && !_hasNotifiedWeather) {
        _hasNotifiedWeather = true;
        _showSituationalToast("⛈️ Hafif yağış tespit edildi. Paket koruma kalkanı aktif.");
      }
      
      // %85 ilerlemede Yakınlık Bildirimi (Proximity Alert)
      if (v > 0.85 && !_hasNotifiedArrival) {
        _hasNotifiedArrival = true;
        setState(() {
          _showArrivalCard = true;
        });
        // 5 saniye sonra bildirimi otomatik gizle
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showArrivalCard = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    wsService.disconnect();
    _vehicleCtrl.dispose();
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
            child: AnimatedBuilder(
              animation: _vehicleAnim,
              builder: (context, child) {
                final double fraction = _vehicleAnim.value;
                final double targetDist = fraction * _totalDistance;
                
                int segmentIndex = 0;
                for (int i = 0; i < _cumulativeDistances.length - 1; i++) {
                  if (targetDist >= _cumulativeDistances[i] && targetDist <= _cumulativeDistances[i + 1]) {
                    segmentIndex = i;
                    break;
                  }
                }
                if (targetDist > _totalDistance) segmentIndex = _routePoints.length - 2;

                final double segLen = _cumulativeDistances[segmentIndex + 1] - _cumulativeDistances[segmentIndex];
                final double segmentFraction = segLen == 0 ? 0 : (targetDist - _cumulativeDistances[segmentIndex]) / segLen;
                
                final LatLng startP = _routePoints[segmentIndex];
                final LatLng endP = _routePoints[segmentIndex + 1];

                final double lat = startP.latitude + (endP.latitude - startP.latitude) * segmentFraction;
                final double lng = startP.longitude + (endP.longitude - startP.longitude) * segmentFraction;
                final LatLng currentPos = LatLng(lat, lng);

                final double bearing = const Distance().bearing(startP, endP);
                final double angle = bearing * math.pi / 180.0;

                final List<LatLng> passedRoute = [];
                for (int i = 0; i <= segmentIndex; i++) {
                  passedRoute.add(_routePoints[i]);
                }
                passedRoute.add(currentPos);

                final List<LatLng> remainingRoute = [currentPos];
                for (int i = segmentIndex + 1; i < _routePoints.length; i++) {
                  remainingRoute.add(_routePoints[i]);
                }

                // Dinamik marker pozisyonları hesapla
                final LatLng constructionMarker1 = _routePoints[(_routePoints.length * 0.5).toInt()];
                final LatLng constructionMarker2 = _routePoints[(_routePoints.length * 0.6).toInt()];
                
                // Başlangıç merkezi olarak rotanın ortasını kullan
                final LatLng mapCenter = _routePoints[(_routePoints.length ~/ 2)];

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: mapCenter, // Dinamik orta nokta
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
                    
                    // Yoğun Trafik Bölgesi (Kırmızı CircleLayer) - Dinamik Senaryoya Göre
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _currentScenario.trafficPoint,
                          color: const Color(0xFFFF0000).withOpacity(0.3),
                          borderColor: const Color(0xFFFF0000).withOpacity(0.6),
                          borderStrokeWidth: 1.5,
                          radius: 350,
                          useRadiusInMeter: true,
                        ),
                      ],
                    ),

                    // Gelecek Rota (Gri ve ince)
                    PolylineLayer(
                      polylines: <Polyline>[
                        Polyline(
                          points: remainingRoute,
                          color: Colors.grey.withOpacity(0.4),
                          strokeWidth: 3.0,
                        ),
                      ],
                    ),
                    
                    // Geçilmiş Rota (Neon Turkuaz ve kalın)
                    PolylineLayer(
                      polylines: <Polyline>[
                        Polyline(
                          points: passedRoute,
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

                        // Yol Çalışması Marker 1
                        Marker(
                          point: constructionMarker1,
                          width: 80,
                          height: 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: Colors.orange.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)
                                  ],
                                ),
                                child: const Icon(Icons.construction_rounded, color: Colors.black, size: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Yol Çalışması",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                                ),
                              )
                            ],
                          ),
                        ),

                        // Yol Çalışması Marker 2 (Biraz ilerde uyarı)
                        Marker(
                          point: constructionMarker2,
                          width: 40,
                          height: 40,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: [
                                BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)
                              ],
                            ),
                            child: const Icon(Icons.warning_rounded, color: Colors.black, size: 14),
                          ),
                        ),

                        // Araç Marker'ı
                        Marker(
                          point: currentPos,
                          width: 60,
                          height: 60,
                          child: Transform.rotate(
                            angle: angle,
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
          AnimatedBuilder(
            animation: _vehicleAnim,
            builder: (context, child) {
              final double fraction = _vehicleAnim.value;
              
              // Dinamik hesaplamalar
              final int baseEta = _currentScenario.etaMinutes;
              final double baseSpeed = _currentScenario.speed;
              final double baseDistance = _currentScenario.distanceKm;
              
              // Kalan süre ve mesafe hesaplamaları (Drone Modu optimizasyonu ile)
              final int minutesRemaining = ((1.0 - fraction) * (_isDroneMode ? baseEta * 0.75 : baseEta)).ceil();
              final double kmRemaining = ((1.0 - fraction) * baseDistance);
              final double speed = _isDroneMode ? baseSpeed * 1.5 : baseSpeed;
              
              // Canlı Konum metni (İlerlemeye göre değişir)
              final String currentLocation = fraction < 0.33 
                  ? _currentScenario.locationTexts[0] 
                  : fraction < 0.66 
                      ? _currentScenario.locationTexts[1] 
                      : _currentScenario.locationTexts[2];

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
