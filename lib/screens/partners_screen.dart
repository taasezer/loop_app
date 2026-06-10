import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import 'api_details_placeholder.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Veri Modeli
// ─────────────────────────────────────────────────────────────────────────────

class _PartnerData {
  const _PartnerData({
    required this.name,
    required this.subtitle,
    required this.desc,
    required this.badge,
    required this.tags,
    required this.headerColor,
    required this.accentColor,
    required this.icon,
  });

  final String name;
  final String subtitle;
  final String desc;
  final String badge;
  final List<String> tags;
  final Color headerColor;
  final Color accentColor;
  final IconData icon;
}

// ─────────────────────────────────────────────────────────────────────────────
// Partner Verileri
// ─────────────────────────────────────────────────────────────────────────────

const List<_PartnerData> _kPartners = [];

// ─────────────────────────────────────────────────────────────────────────────
// Ana Ekran
// ─────────────────────────────────────────────────────────────────────────────

/// LOOP Partner Ağı — B2B SaaS entegrasyon kataloğu.
class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});

  // ── Custom Toast ────────────────────────────────────────────────────────────
  static void _showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _LoopToast(
        message: message,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ── Contact BottomSheet ─────────────────────────────────────────────────────
  static void _showContactSheet(BuildContext context, _PartnerData partner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ContactSheet(partner: partner),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.backgroundDeep : const Color(0xFFF2ECE0);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Back bar ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 13,
                    color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                  ),
                  label: Text(
                    'Ana Sayfaya Dön',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),

            // ── Hero ──────────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _HeroSection(isDark: isDark)),

            // ── Partner kartları ──────────────────────────────────────────────
            if (_kPartners.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.handshake_rounded, size: 64, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(height: 16),
                      Text('Ortaklarımız Çok Yakında Burada!', 
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black87)
                      ),
                      const SizedBox(height: 8),
                      Text('Sisteme entegre edilecek iş ortaklarımızı listelemeye hazırlanıyoruz.',
                        style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54),
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final p = _kPartners[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PartnerCard(
                          data: p,
                          isDark: isDark,
                          onTeklifAl: () =>
                              _showToast(ctx, '${p.name} ile görüşme talebiniz iletildi!'),
                          onIletisim: () => _showContactSheet(ctx, p),
                          onApiBadge: () => Navigator.push(
                            ctx,
                            PageRouteBuilder(
                              pageBuilder: (ctx2, anim1, sec) =>
                                  const ApiDetailsPlaceholder(),
                              transitionsBuilder: (ctx2, anim, sec, child) =>
                                  SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                    parent: anim, curve: Curves.easeInOut)),
                                child: child,
                              ),
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _kPartners.length,
                  ),
                ),
              ),

            // ── Alt banner ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                child: _CustomSolutionBanner(
                  onTap: () => _showToast(
                      context, 'Çözüm ekibimiz en kısa sürede sizinle iletişime geçecek!'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Bölümü
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tp = isDark ? AppColors.textPrimary      : AppColors.lightTextPrimary;
    final ts = isDark ? AppColors.textSecondary    : AppColors.lightTextSecondary;
    final tl = isDark ? AppColors.textLabel        : AppColors.lightTextLabel;
    final cardBg = isDark ? AppColors.cardBackground : Colors.white;
    final border = isDark ? AppColors.cardBorder    : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'B2B LOJİSTİK EKOSİSTEMİ',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: tl),
            ),
          ),
          const SizedBox(height: 14),

          // Başlık
          Text(
            'Partner Ağı',
            style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: tp,
                height: 1.1,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),

          // Açıklama
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: ts, height: 1.65),
              children: [
                const TextSpan(
                    text: 'Türkiye\'nin ve dünyanın önde gelen lojistik operatörleriyle tek '),
                TextSpan(
                    text: 'API',
                    style: GoogleFonts.inter(
                        color: AppColors.primaryButton,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const TextSpan(
                    text:
                        ' üzerinden entegre olun. Kara, hava, deniz ve soğuk zincir çözümlerini LOOP platformundan yönetin.'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // İstatistikler
          Row(
            children: [
              _StatBox(value: '6+',    label: 'AKTİF PARTNER', cardBg: cardBg, border: border, tp: tp, ts: ts),
              const SizedBox(width: 8),
              _StatBox(value: '40+',   label: 'ÜLKE AĞI',      cardBg: cardBg, border: border, tp: tp, ts: ts),
              const SizedBox(width: 8),
              _StatBox(value: '2.000+',label: 'ARAÇ FİLOSU',   cardBg: cardBg, border: border, tp: tp, ts: ts),
              const SizedBox(width: 8),
              _StatBox(value: '7/24',  label: 'API ERİŞİMİ',   cardBg: cardBg, border: border, tp: tp, ts: ts),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.cardBg,
    required this.border,
    required this.tp,
    required this.ts,
  });
  final String value;
  final String label;
  final Color cardBg;
  final Color border;
  final Color tp;
  final Color ts;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: tp)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: ts)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Partner Kartı — Animasyonlu Lift Efekti
// ─────────────────────────────────────────────────────────────────────────────

class _PartnerCard extends StatefulWidget {
  const _PartnerCard({
    required this.data,
    required this.isDark,
    required this.onTeklifAl,
    required this.onIletisim,
    required this.onApiBadge,
  });

  final _PartnerData data;
  final bool isDark;
  final VoidCallback onTeklifAl;
  final VoidCallback onIletisim;
  final VoidCallback onApiBadge;

  @override
  State<_PartnerCard> createState() => _PartnerCardState();
}

class _PartnerCardState extends State<_PartnerCard>
    with SingleTickerProviderStateMixin {
  bool _lifted = false;

  void _lift()   => setState(() => _lifted = true);
  void _lower()  => setState(() => _lifted = false);

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isDark = widget.isDark;
    final cardBg = isDark ? AppColors.cardBackground : Colors.white;
    final border = isDark ? AppColors.cardBorder : AppColors.lightBorder;
    final tp = isDark ? AppColors.textPrimary   : AppColors.lightTextPrimary;
    final ts = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return MouseRegion(
      onEnter: (_) => _lift(),
      onExit:  (_) => _lower(),
      child: GestureDetector(
        onTapDown:   (_) => _lift(),
        onTapUp:     (_) => _lower(),
        onTapCancel: ()  => _lower(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _lifted ? -6.0 : 0.0, 0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1),
            boxShadow: _lifted
                ? [
                    BoxShadow(
                      color: d.headerColor.withAlpha(isDark ? 80 : 50),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 40 : 12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Renkli başlık bölümü ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  color: d.headerColor,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(d.icon, size: 34, color: Colors.white.withAlpha(200)),
                      const Spacer(),
                      // API badge
                      GestureDetector(
                        onTap: widget.onApiBadge,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withAlpha(60), width: 1),
                          ),
                          child: Text(
                            d.badge,
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Kart gövdesi ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İsim
                      Text(d.name,
                          style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: tp,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 3),

                      // Kategori
                      Text(d.subtitle,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: d.accentColor)),
                      const SizedBox(height: 10),

                      // Açıklama
                      Text(d.desc,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: ts,
                              height: 1.6)),
                      const SizedBox(height: 12),

                      // Etiketler
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: d.tags
                            .map((t) => _TagChip(
                                label: t, accentColor: d.accentColor, isDark: isDark))
                            .toList(),
                      ),
                      const SizedBox(height: 16),

                      // Butonlar
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onIletisim,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: isDark
                                        ? AppColors.cardBorder
                                        : AppColors.lightBorder,
                                    width: 1.5),
                                foregroundColor: tp,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                textStyle: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                                minimumSize: Size.zero,
                              ),
                              child: Text('İletişim Bilgileri',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: tp)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onTeklifAl,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: d.accentColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                minimumSize: Size.zero,
                                elevation: 0,
                                textStyle: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Teklif Al'),
                            ),
                          ),
                        ],
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
// Etiket Chip
// ─────────────────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  const _TagChip(
      {required this.label,
      required this.accentColor,
      required this.isDark});
  final String label;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(isDark ? 25 : 15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withAlpha(60), width: 1),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: accentColor)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Özel Çözüm Alt Banner
// ─────────────────────────────────────────────────────────────────────────────

class _CustomSolutionBanner extends StatelessWidget {
  const _CustomSolutionBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E2A1E), Color(0xFF3D3520)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Özel Entegrasyon mu İstiyorsunuz?',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mevcut partnerlerimizin dışında özel bir taşıyıcıyla entegrasyon için '
                  'çözüm ekibimizle görüşün.',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withAlpha(160),
                      height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Buton
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4833E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                minimumSize: Size.zero,
                textStyle: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              child: const Text('Özel Çözüm Talep Et'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// İletişim BottomSheet
// ─────────────────────────────────────────────────────────────────────────────

class _ContactSheet extends StatelessWidget {
  const _ContactSheet({required this.partner});
  final _PartnerData partner;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardBackground : Colors.white;
    final tp = isDark ? AppColors.textPrimary    : AppColors.lightTextPrimary;
    final ts = isDark ? AppColors.textSecondary  : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Partner header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: partner.headerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(partner.icon, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partner.name,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: tp)),
                  Text(partner.subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: partner.accentColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contact rows
          _ContactRow(
            icon: Icons.email_outlined,
            label: 'E-posta',
            value: 'partner@${partner.name.toLowerCase().replaceAll(' ', '')}.com',
            tp: tp, ts: ts, accent: partner.accentColor,
          ),
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.phone_outlined,
            label: 'Telefon',
            value: '+90 212 555 00 ${(_kPartners.indexOf(partner) + 10).toString().padLeft(2, '0')}',
            tp: tp, ts: ts, accent: partner.accentColor,
          ),
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.language_rounded,
            label: 'Web Sitesi',
            value: 'www.${partner.name.toLowerCase().replaceAll(' ', '-')}.com',
            tp: tp, ts: ts, accent: partner.accentColor,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: partner.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: Size.zero,
                textStyle:
                    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              child: const Text('Kapat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.tp,
    required this.ts,
    required this.accent,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color tp;
  final Color ts;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: accent.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w600, color: ts)),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600, color: tp)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Toast — Sağ Alt Köşe
// ─────────────────────────────────────────────────────────────────────────────

class _LoopToast extends StatefulWidget {
  const _LoopToast({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  State<_LoopToast> createState() => _LoopToastState();
}

class _LoopToastState extends State<_LoopToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 28,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2A3A),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primaryButton.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 13, color: AppColors.primaryButton),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(widget.message,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Color(0xFF7A9CC0)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
