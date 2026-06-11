import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../state/app_state_provider.dart';
import 'onboarding_screen.dart';
import 'settings_detail_screen.dart';
import '../services/profile_service.dart';

/// Profil sekmesi — kullanıcı bilgileri ve ayarlar.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _name;
  late String _email;
  PerformanceStats? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final stats = await profileService.getPerformance();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateProvider.of(context);
    _name = state.name.isNotEmpty ? state.name : 'Arif Yılmaz';
    _email = state.email.isNotEmpty ? state.email : 'arif@looplojistik.com';
  }

  static const _menuItems = [
    _MenuItem(icon: Icons.person_outline_rounded,
        label: 'Hesap Bilgileri', sub: 'Ad, e-posta, iletişim'),
    _MenuItem(icon: Icons.notifications_outlined,
        label: 'Bildirimler', sub: 'Push, e-posta tercihleri'),
    _MenuItem(icon: Icons.security_rounded,
        label: 'Güvenlik', sub: 'Şifre, 2FA, oturum'),
    _MenuItem(icon: Icons.bar_chart_rounded,
        label: 'Performans Raporu', sub: 'Aylık ve haftalık özet'),
    _MenuItem(icon: Icons.business_rounded,
        label: 'Şirket Bilgileri', sub: 'Profil, logo, bilgiler'),
    _MenuItem(icon: Icons.help_outline_rounded,
        label: 'Yardım & Destek', sub: 'SSS, canlı destek'),
  ];

  void _showEditModal() {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1828),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.cardBorder.withAlpha(80), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tutma Çubuğu
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profili Düzenle',
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _EditProfileField(label: 'Ad Soyad', controller: nameCtrl),
                      const SizedBox(height: 16),
                      _EditProfileField(label: 'E-Posta', controller: emailCtrl),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryButton,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            setState(() {
                              _name = nameCtrl.text;
                              _email = emailCtrl.text;
                            });
                            AppStateProvider.read(context).updateProfile(
                              name: nameCtrl.text,
                              email: emailCtrl.text,
                            );
                            Navigator.pop(ctx);
                          },
                          child: Text('Kaydet',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textOnButton)),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Gradient header ───────────────────────────────────────────────
            _ProfileHeader(
              name: _name,
              email: _email,
              onEdit: _showEditModal,
            ),

            // ── İstatistikler ─────────────────────────────────────────────────
            _isLoadingStats 
                ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                : _StatsRow(stats: _stats),

            // ── Menü ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ayarlar',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLabel,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.cardBorder, width: 1),
                    ),
                    child: Column(
                      children: List.generate(_menuItems.length, (i) {
                        final isLast = i == _menuItems.length - 1;
                        return _MenuTile(
                            item: _menuItems[i], showDivider: !isLast);
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Çıkış yap butonu
                  _LogoutButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profil header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final String name;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // Initial harflerini hesapla
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2035), Color(0xFF0A1628)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3ECFCE), Color(0xFF4DBFB0)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryButton.withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(initials,
                      style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 16),
              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(email,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    // Rol rozeti
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryButton.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primaryButton.withAlpha(60),
                            width: 1),
                      ),
                      child: Text('Operasyon Yöneticisi',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAccent)),
                    ),
                  ],
                ),
              ),
              // Düzenle butonu
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(10),
                  splashColor: AppColors.primaryButton.withAlpha(20),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder, width: 1),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: AppColors.textSecondary, size: 16),
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

// ─────────────────────────────────────────────────────────────────────────────
// İstatistikler satırı
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({this.stats});
  final PerformanceStats? stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Row(
          children: [
            _StatCell(
                value: stats?.completedDeliveries.toString() ?? '0',
                label: 'Toplam\nTeslimat',
                color: AppColors.textAccent),
            _divider(),
            _StatCell(
                value: stats?.averageRating.toStringAsFixed(1) ?? '0.0',
                label: 'Ortalama\nPuan',
                color: const Color(0xFFFFAA00)),
            _divider(),
            _StatCell(
                value: '%${stats?.successRate.toInt() ?? 0}',
                label: 'Başarı\nOranı',
                color: const Color(0xFF9B7FFF)),
            _divider(),
            _StatCell(
                value: '${stats?.membershipMonths ?? 1} ay',
                label: 'Üyelik\nSüresi',
                color: AppColors.textAccent),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 40,
        color: AppColors.cardBorder,
      );
}

class _StatCell extends StatelessWidget {
  const _StatCell(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  height: 1.3)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menü öğesi
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItem {
  const _MenuItem(
      {required this.icon, required this.label, required this.sub});
  final IconData icon;
  final String label;
  final String sub;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, required this.showDivider});
  final _MenuItem item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsDetailScreen(title: item.label),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            splashColor: AppColors.primaryButton.withAlpha(15),
            highlightColor: AppColors.primaryButton.withAlpha(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDeep,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: AppColors.cardBorder, width: 1),
                    ),
                    child: Icon(item.icon,
                        color: AppColors.textSecondary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(item.sub,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textLabel, size: 18),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 64,
            color: AppColors.cardBorder,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Çıkış yap butonu
// ─────────────────────────────────────────────────────────────────────────────

class _LogoutButton extends StatefulWidget {
  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFF3D0A0A)
              : const Color(0xFF1A0808),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _pressed
                ? const Color(0xFFFF4444)
                : const Color(0xFF5A1A1A),
            width: 1,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                      color: const Color(0xFFFF4444).withAlpha(50),
                      blurRadius: 14)
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded,
                  color: _pressed
                      ? const Color(0xFFFF6666)
                      : const Color(0xFFCC3333),
                  size: 18),
              const SizedBox(width: 8),
              Text('Çıkış Yap',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _pressed
                          ? const Color(0xFFFF6666)
                          : const Color(0xFFCC3333))),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileField extends StatelessWidget {
  const _EditProfileField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.cardBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primaryButton.withAlpha(80), width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
