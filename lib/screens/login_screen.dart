// lib/screens/login_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _auth = AuthService();

  bool   _loading      = false;
  String? _errorMessage;          // null = sin error; texto = mensaje a mostrar

  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _orbCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _fadeCtrl;

  late final Animation<double> _orbRotation;
  late final Animation<double> _pulse;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _orbRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _orbCtrl, curve: Curves.linear),
    );

    _pulse = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() { _loading = true; _errorMessage = null; });

    try {
      final user = await _auth.signInWithGoogle();

      if (!mounted) return;

      if (user == null) {
        // null sin excepción = usuario canceló el selector de Google
        // o no tiene el rol "admin" (auth_service ya hizo signOut).
        setState(() {
          _loading      = false;
          _errorMessage = 'No autorizado para este acceso';
        });
        return;
      }

      // Éxito: _AuthGate en main.dart reacciona a authStateChanges → navega sola.
      // No hacemos Navigator aquí para no duplicar la navegación.
      setState(() { _loading = false; });

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Mostrar el código de error real — ayuda mucho al depurar SHA-1 / OAuth
      setState(() {
        _loading      = false;
        _errorMessage = _friendlyFirebaseError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading      = false;
        // Mostramos el toString() en debug para no ocultar errores de configuración
        _errorMessage = 'Error inesperado: ${e.toString()}';
      });
    }
  }

  /// Convierte códigos de FirebaseAuthException en mensajes legibles.
  String _friendlyFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Sin conexión a internet';
      case 'invalid-credential':
      case 'invalid-verification-code':
        return 'Credencial inválida. Intenta de nuevo.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada';
      default:
        // En debug es útil ver el código exacto
        return 'Error de autenticación (${e.code})';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            // ── Background orbs ─────────────────────────────────────────────
            Positioned(
              top: -80,
              right: -80,
              child: _buildOrb(size: 320, opacity: 0.08),
            ),
            Positioned(
              bottom: -120,
              left: -60,
              child: _buildOrb(size: 280, opacity: 0.05, offset: math.pi),
            ),

            // ── Content ─────────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    ScaleTransition(
                      scale: _pulse,
                      child: _buildMainOrb(),
                    ),

                    const SizedBox(height: 40),

                    Text(
                      'Audit Log',
                      style: GoogleFonts.nunito(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF202124),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acceso restringido · Solo propietarios',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: const Color(0xFF5F6368),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Error message — ahora muestra el texto real
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE8E6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFEA4335).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFEA4335), size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFFEA4335),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _loading ? _buildLoadingButton() : _buildSignInButton(),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainOrb() {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        return SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _OrbPainter(angle: _orbRotation.value),
          ),
        );
      },
    );
  }

  Widget _buildOrb({
    required double size,
    required double opacity,
    double offset = 0,
  }) {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _OrbPainter(
              angle: _orbRotation.value + offset,
              opacity: opacity,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: Color(0xFFDADCE0)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleLogo(),
            const SizedBox(width: 12),
            Text(
              'Continuar con Google',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3C4043),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: Color(0xFFDADCE0)),
          ),
          elevation: 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Color(0xFF4285F4)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Verificando...',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5F6368),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google logo ───────────────────────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFFEA4335),
      const Color(0xFFFBBC04),
      const Color(0xFF34A853),
    ];

    final sweeps = [math.pi * 0.9, math.pi * 0.6, math.pi * 0.5, math.pi * 0.9];
    final starts = [
      -math.pi * 0.1,
      math.pi * 0.8,
      math.pi * 1.4,
      math.pi * 1.9,
    ];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.35
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.65),
        starts[i], sweeps[i], false, paint,
      );
    }

    canvas.drawCircle(c, r * 0.42, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill);

    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - r * 0.18, r * 0.9, r * 0.36),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Orb painter ───────────────────────────────────────────────────────────────

class _OrbPainter extends CustomPainter {
  const _OrbPainter({required this.angle, this.opacity = 1.0});
  final double angle;
  final double opacity;

  static const _colors = [
    Color(0xFF4285F4),
    Color(0xFF34A853),
    Color(0xFFFBBC04),
    Color(0xFFEA4335),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    for (int i = 0; i < 4; i++) {
      final a = angle + (i * math.pi / 2);
      final x = c.dx + math.cos(a) * r * 0.38;
      final y = c.dy + math.sin(a) * r * 0.38;

      canvas.drawCircle(
        Offset(x, y),
        r * 0.45,
        Paint()
          ..color = _colors[i].withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
    }

    canvas.drawCircle(
      c,
      r * 0.30,
      Paint()
        ..color = Colors.white.withOpacity(opacity > 0.5 ? 0.9 : opacity * 1.8),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.angle != angle;
}
