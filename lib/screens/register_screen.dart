import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';
import '../layouts/main_layout.dart';
import '../services/api_service.dart';
import '../state/app_state_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supplierCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _supplierCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = await apiService.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        supplierCode: _supplierCodeController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        AppStateProvider.of(context).setUser(user);
        
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
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      String errorMsg = 'Kayıt başarısız.';
      if (e.response != null && e.response?.data != null) {
        errorMsg = e.response?.data['detail'] ?? errorMsg;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(errorMsg, style: GoogleFonts.inter(color: Colors.white)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Bir hata oluştu: $e', style: GoogleFonts.inter(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061525),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonTeal.withAlpha(20),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_rounded, size: 48, color: AppColors.neonTeal),
                    const SizedBox(height: 16),
                    Text(
                      'Kurye Kaydı',
                      style: GoogleFonts.barlow(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aramıza katılmak için bilgilerinizi girin.',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Ad Soyad
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Adınız ve Soyadınız',
                      icon: Icons.person_rounded,
                      validator: (val) => val!.isEmpty ? 'Ad Soyad gerekli' : null,
                    ),
                    const SizedBox(height: 16),

                    // E-posta
                    _buildTextField(
                      controller: _emailController,
                      hint: 'E-posta Adresiniz',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val!.contains('@') ? null : 'Geçerli bir e-posta girin',
                    ),
                    const SizedBox(height: 16),

                    // Telefon
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'Telefon Numarası',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (val) => val!.length > 9 ? null : 'Geçerli bir telefon girin',
                    ),
                    const SizedBox(height: 16),

                    // Şifre
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Şifreniz',
                      icon: Icons.lock_rounded,
                      obscureText: _obscurePassword,
                      validator: (val) => val!.length >= 6 ? null : 'Şifre en az 6 karakter olmalı',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tedarikçi Kodu
                    _buildTextField(
                      controller: _supplierCodeController,
                      hint: 'Tedarikçi Kodu (Opsiyonel)',
                      icon: Icons.business_rounded,
                      helperText: 'Bir kurye firmasına bağlıysanız kodunuzu girin.',
                    ),
                    const SizedBox(height: 32),

                    // Kayıt Ol Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonTeal,
                          foregroundColor: const Color(0xFF061525),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF061525)),
                                ),
                              )
                            : Text(
                                'Kayıt Ol',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Geri Dön Linki
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Zaten hesabınız var mı? Giriş Yap',
                        style: GoogleFonts.inter(
                          color: AppColors.neonTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        helperText: helperText,
        helperStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
        hintStyle: GoogleFonts.inter(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF061525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withAlpha(10), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.neonTeal.withAlpha(50), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error.withAlpha(50), width: 1),
        ),
      ),
    );
  }
}
