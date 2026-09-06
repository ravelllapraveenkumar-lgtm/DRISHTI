import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/api_endpoints.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';

// =====================================================================
// DRISHTI Mobile App: Official MoSJE Inspector Login Screen
// Supports live FastAPI authentication and rapid evaluation personas
// =====================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'inspector.verma@drishti.gov.in');
  final _passwordController = TextEditingController(text: 'drishti2026');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  Future<void> _handleDemoLogin(String personaName) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.demoLogin();

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        title: const Text(
          'DRISHTI FIELD CLIENT',
          style: TextStyle(fontSize: 14, letterSpacing: 1.2, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Server Settings',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // Emblem & Header
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.saffronAccent, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.verified, size: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'DRISHTI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Digital Record & Inspection Surveillance with Hybrid Tactical Intelligence',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ministry of Social Justice and Empowerment (MoSJE)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.saffronAccent,
              ),
            ),
            const SizedBox(height: 24),

            // Server connection banner (Tappable to configure)
            InkWell(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                if (mounted) setState(() {});
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.dns, size: 14, color: AppColors.primaryNavy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Target Host: ${ApiEndpoints.baseUrl}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      'CONFIGURE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.circle, size: 8, color: AppColors.statusSuccess),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (auth.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusCriticalBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.statusCritical),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.statusCritical, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppColors.statusCritical),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Login Form Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inspector Portal Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Official Email ID',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Secure Password',
                      prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'LOGIN TO FIELD CLIENT',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Demo Personas Section for Rapid Evaluation
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'ONE-CLICK DEMO ACCESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 14),

            OutlinedButton.icon(
              onPressed: auth.isLoading ? null : () => _handleDemoLogin('Field Inspector'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.saffronAccent, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                foregroundColor: AppColors.textPrimary,
              ),
              icon: const Icon(Icons.badge, color: AppColors.saffronAccent, size: 20),
              label: const Text(
                'Demo Inspector Login (MoSJE North Zone)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            // Security Notice
            const Center(
              child: Text(
                'Authorized Personnel Only • Govt. of India • Ministry of Social Justice',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
