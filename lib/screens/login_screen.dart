import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import '../layouts/main_layout.dart';
import 'onboarding_screen.dart';
import 'register_screen.dart';
import '../services/api_service.dart';
import '../state/app_state_provider.dart';
/// Giriş ekranı — tasarımda görülen modal kartı ve arka planı içerir.
///
/// Yapı:
/// ```
/// Scaffold (koyu lacivert arka plan)
///   └─ Stack
///        ├─ Arka plan bokeh/degrade katmanı
///        └─ Center → LoginCard
///              ├─ Başlık + açıklama
///              ├─ EmailField
///              ├─ PasswordField
///              ├─ LoginButton
///              └─ "Demo talep edin" linki
/// ```
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // Kart giriş animasyonu
  late AnimationController _cardAnimController;
  late Animation<double> _cardFadeIn;
  late Animation<Offset> _cardSlideIn;

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _cardFadeIn = CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOut,
    );
    _cardSlideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOut,
    ));
    _cardAnimController.forward();
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    
    try {
      final user = await apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        // Set user in AppState
        AppStateProvider.of(context).setUser(user);
        
        debugPrint('Giriş başarılı, ana sayfaya geçilecek');
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (ctx, anim, secAnim) => const MainLayout(),
            transitionsBuilder: (ctx, animation, secAnim, child) => FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Giriş başarısız. Lütfen bilgilerinizi kontrol edin.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'Bir hata oluştu: $e',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    }
  }

  /// "Demo talep edin" linkine basıldığında açılan iletişim modalı.
  void _showDemoModal(BuildContext context) {
    final nameCtrl    = TextEditingController();
    final companyCtrl = TextEditingController();
    final emailCtrl   = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1828),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                    color: AppColors.cardBorder.withAlpha(80), width: 1),
              ),
              child: Column(
                children: [
                  // Tutma çubuğu
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      children: [
                        // Başlık
                        Text('Demo Talep Et',
                            style: GoogleFonts.inter(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Text(
                          'Sistemi kendi firmanıza uyarlamak,\n'
                          'maliyetlerinizi düşürmek için bize yazın.',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5),
                        ),
                        const SizedBox(height: 28),

                        // Ad Soyad
                        _ModalField(
                            ctrl: nameCtrl,
                            label: 'Ad Soyad',
                            icon: Icons.person_outline_rounded),
                        const SizedBox(height: 14),

                        // Şirket
                        _ModalField(
                            ctrl: companyCtrl,
                            label: 'Şirket Adı',
                            icon: Icons.business_rounded),
                        const SizedBox(height: 14),

                        // E-posta
                        _ModalField(
                            ctrl: emailCtrl,
                            label: 'E-posta Adresi',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 28),

                        // Gönder butonu
                        LoopButton(
                          label: 'Talebi Gönder',
                          icon: Icons.send_rounded,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.primaryButton,
                                content: Text(
                                  'Talebiniz alındı! En kısa sürede dönüş yapacağız.',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textOnButton,
                                      fontWeight: FontWeight.w600),
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Gizlilik notu
                        Center(
                          child: Text(
                            '🔒  Bilgileriniz gizli tutulur.',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: Stack(
        children: [
          // ── Arka plan degrade / ışık efekti ──────────────────────────────
          _BackgroundGlow(),

          // ── Login kartı ───────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _cardFadeIn,
                  child: SlideTransition(
                    position: _cardSlideIn,
                    child: _LoginCard(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isLoading: _isLoading,
                      onLogin: _handleLogin,
                      onDemoTap: () => _showDemoModal(context),
                    ),
                  ),
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
// Arka plan ışık efekti
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned.fill(
      child: Stack(
        children: [
          // Sol üst loş mavi ışık hâlesi
          Positioned(
            left: -size.width * 0.3,
            top: -size.height * 0.1,
            child: Container(
              width: size.width * 0.8,
              height: size.height * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E4080).withAlpha(60),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Sağ alt loş teal ışık hâlesi
          Positioned(
            right: -size.width * 0.2,
            bottom: -size.height * 0.05,
            child: Container(
              width: size.width * 0.6,
              height: size.height * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4DBFB0).withAlpha(30),
                    Colors.transparent,
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
// Login Kartı
// ─────────────────────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onLogin,
    required this.onDemoTap,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onDemoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Kart içeriği ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 36),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık
                  Text(
                    'GİRİŞ YAP',
                    style: GoogleFonts.inter(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Açıklama
                  Text(
                    'Kurumsal yönetim panelinize erişmek için giriş yapın.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // E-posta alanı
                  EmailField(controller: emailController),
                  const SizedBox(height: 20),

                  // Şifre alanı
                  PasswordField(controller: passwordController),
                  const SizedBox(height: 28),

                  // Giriş Yap butonu
                  LoginButton(
                    onPressed: onLogin,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Demo linki
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Sistemi denemek mi istiyorsunuz? ',
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => onDemoTap(),
                              child: Text(
                                'Demo talep edin',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textAccent,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Kayıt Ol linki
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Kurye misiniz? ',
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegisterScreen())
                                );
                              },
                              child: Text(
                                'Hemen Kayıt Olun',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.neonTeal,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                              ),
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

          // ── Kapat (×) butonu ─────────────────────────────────────────────
          Positioned(
            top: 16,
            right: 16,
            child: _CloseButton(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kapat Butonu
// ─────────────────────────────────────────────────────────────────────────────

class _CloseButton extends StatefulWidget {
  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          // Kullanıcıyı Onboarding ekranına geri götür.
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (ctx, anim, secAnim) => const OnboardingScreen(),
              transitionsBuilder: (ctx, animation, secAnim, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.inputBorder.withAlpha(180)
                : AppColors.inputBorder.withAlpha(80),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: _hovered ? AppColors.textPrimary : AppColors.textLabel,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modal form alanı (Demo talep modal'ında kullanılır)
// ─────────────────────────────────────────────────────────────────────────────

class _ModalField extends StatelessWidget {
  const _ModalField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
          fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textLabel, size: 18),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
        ),
      ),
    );
  }
}
