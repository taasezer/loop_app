import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

/// Siparişler sekmesi — filtreli sipariş listesi.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _tabs = ['Aktif', 'Beklemede', 'Tamamlanan'];

  List<OrderModel> _myOrders = [];
  bool _isLoading = true;

  int get _activeCount => _myOrders.where((o) => ['picked_up', 'in_transit'].contains(o.status)).length;
  int get _pendingCount => _myOrders.where((o) => ['assigned'].contains(o.status)).length;
  int get _completedCount => _myOrders.where((o) => ['delivered'].contains(o.status)).length;
  double get _dailyRevenue => _myOrders
      .where((o) => ['delivered'].contains(o.status))
      .fold(0.0, (sum, o) => sum + (o.totalAmount ?? 0.0));

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final orders = await orderService.getMyOrders();
    setState(() {
      _myOrders = orders;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<OrderModel> get _currentOrders {
    switch (_tabCtrl.index) {
      case 0:
        return _myOrders.where((o) => ['picked_up', 'in_transit'].contains(o.status)).toList();
      case 1:
        return _myOrders.where((o) => ['assigned'].contains(o.status)).toList();
      default:
        return _myOrders.where((o) => ['delivered', 'cancelled'].contains(o.status)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Siparişler',
                          style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                              letterSpacing: -0.3)),
                      Text('Bugün ${_myOrders.length} sipariş',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: cs.onSurface.withAlpha(130))),
                    ],
                  ),
                  const Spacer(),
                  // Arama butonu
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outline, width: 1),
                    ),
                    child: Icon(Icons.search_rounded,
                        color: cs.onSurface.withAlpha(150), size: 18),
                  ),
                  const SizedBox(width: 8),
                  // Filtre butonu
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outline, width: 1),
                    ),
                    child: Icon(Icons.filter_list_rounded,
                        color: cs.onSurface.withAlpha(150), size: 18),
                  ),
                ],
              ),
            ),

            // ── Özet metrikler ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  _MetricBox(value: '$_activeCount', label: 'Aktif',
                      color: AppColors.textAccent),
                  const SizedBox(width: 8),
                  _MetricBox(value: '$_pendingCount', label: 'Beklemede',
                      color: const Color(0xFF9B7FFF)),
                  const SizedBox(width: 8),
                  _MetricBox(value: '$_completedCount', label: 'Tamamlanan',
                      color: const Color(0xFFFFAA00)),
                  const SizedBox(width: 8),
                  _MetricBox(value: '₺${_dailyRevenue.toStringAsFixed(2)}', label: 'Günlük Ciro',
                      color: AppColors.textAccent),
                ],
              ),
            ),

            // ── Tab bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _LoopTabBar(
                tabs: _tabs,
                controller: _tabCtrl,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 10),

            // ── Sipariş listesi ──────────────────────────────────────────────
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : AnimatedBuilder(
                    animation: _tabCtrl,
                    builder: (context, child) {
                      final currentList = _currentOrders;
                      if (currentList.isEmpty) {
                        return Center(
                          child: Text("Bu kategoride sipariş bulunamadı.", 
                            style: GoogleFonts.inter(color: cs.onSurface.withAlpha(150)))
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _fetchOrders,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          itemCount: currentList.length,
                          separatorBuilder: (context, idx) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _OrderCard(
                            order: currentList[i],
                            onRefresh: _fetchOrders,
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Özel Tab Bar
// ─────────────────────────────────────────────────────────────────────────────

class _LoopTabBar extends StatelessWidget {
  const _LoopTabBar({
    required this.tabs,
    required this.controller,
    required this.onChanged,
  });
  final List<String> tabs;
  final TabController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline, width: 1),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                controller.animateTo(i);
                onChanged(i);
              },
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final sel = controller.index == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: sel
                          ? cs.primary.withAlpha(20)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: sel
                          ? Border.all(
                              color: cs.primary.withAlpha(60),
                              width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(tabs[i],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: sel
                                ? AppColors.textAccent
                                : AppColors.textSecondary,
                          )),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metrik kutusu
// ─────────────────────────────────────────────────────────────────────────────

class _MetricBox extends StatelessWidget {
  const _MetricBox(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outline, width: 1),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9, color: cs.onSurface.withAlpha(130))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sipariş kartı
// ─────────────────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onRefresh});
  final OrderModel order;
  final VoidCallback onRefresh;

  Color _getStatusColor() {
    switch (order.status) {
      case 'assigned':
        return const Color(0xFF9B7FFF);
      case 'picked_up':
      case 'in_transit':
        return const Color(0xFFFFAA00);
      case 'delivered':
        return const Color(0xFF4DBFB0);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (order.status) {
      case 'assigned': return 'Beklemede';
      case 'picked_up': return 'Teslim Alındı';
      case 'in_transit': return 'Yolda';
      case 'delivered': return 'Teslim Edildi';
      case 'cancelled': return 'İptal Edildi';
      default: return order.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline, width: 1),
        boxShadow: [
          BoxShadow(
              color: isDark
                  ? Colors.black.withAlpha(40)
                  : const Color(0xFF102A43).withAlpha(12),
              blurRadius: isDark ? 12 : 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withAlpha(60), width: 1),
                ),
                child: Text(_getStatusText(),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
              const Spacer(),
              Text('ID: ${order.id}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: cs.onSurface.withAlpha(120))),
            ],
          ),
          const SizedBox(height: 10),
          Text(order.customerName ?? 'İsimsiz Müşteri',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 12, color: cs.onSurface.withAlpha(100)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(order.deliveryAddress ?? 'Adres belirtilmemiş',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: cs.onSurface.withAlpha(150))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.phone,
                  size: 12, color: cs.onSurface.withAlpha(100)),
              const SizedBox(width: 4),
              Text(order.customerPhone ?? '-',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: cs.onSurface.withAlpha(150))),
              const Spacer(),
              Text(order.totalAmount != null ? '₺${order.totalAmount!.toStringAsFixed(2)}' : '-',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: statusColor)),
            ],
          ),
          if (order.status == 'assigned') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withAlpha(20),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final success = await orderService.rejectOrder(order.id.toString());
                      if (success) {
                        onRefresh();
                      }
                    },
                    child: Text('Reddet', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B7FFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final success = await orderService.acceptOrder(order.id.toString());
                      if (success) {
                        onRefresh();
                      }
                    },
                    child: Text('Kabul Et', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

