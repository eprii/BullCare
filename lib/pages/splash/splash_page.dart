import 'package:flutter/material.dart';

import '../../widgets/bullcare_cow_mark.dart';
import '../auth/auth_gate.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _introComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _introComplete = true);
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFA),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const AuthGate(),
          if (!_introComplete)
            AbsorbPointer(
              absorbing: true,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return _SplashTransition(progress: _controller.value);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SplashTransition extends StatelessWidget {
  const _SplashTransition({required this.progress});

  final double progress;

  static const List<Color> _greenGradient = <Color>[
    Color.fromARGB(255, 44, 188, 51),
    Color.fromARGB(255, 121, 219, 139),
  ];

  static const String _brandText = 'BullCare';

  double _interval(
    double start,
    double end, {
    Curve curve = Curves.linear,
  }) {
    if (progress <= start) return 0;
    if (progress >= end) return 1;
    return curve.transform((progress - start) / (end - start));
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final double headerHeight = screen.width < 600 ? 188 : 205;

    // Ikon sapi outline muncul lembut di awal.
    final double markReveal = _interval(
      0.01,
      0.13,
      curve: Curves.easeOutCubic,
    );

    // BullCare diketik huruf demi huruf.
    final double typingProgress = _interval(
      0.13,
      0.35,
      curve: Curves.linear,
    );
    final int typedCharacterCount = (_brandText.length * typingProgress)
        .floor()
        .clamp(0, _brandText.length)
        .toInt();
    final String typedText = _brandText.substring(0, typedCharacterCount);
    final bool typingFinished = typedCharacterCount == _brandText.length;

    // Setelah teks selesai, splash diam sekitar 3 detik sebelum bidang hijau naik.
    final double sheetRise = _interval(
      0.68,
      0.96,
      curve: Curves.easeInOutCubic,
    );

    // Mark dan teks ikut naik, lalu menghilang dengan lembut menjelang login.
    final double contentExit = _interval(
      0.76,
      0.92,
      curve: Curves.easeInOutCubic,
    );

    // Overlay dilepas saat lengkungan sudah menyatu dengan header login.
    final double overlayExit = _interval(
      0.96,
      1.0,
      curve: Curves.easeOut,
    );

    final double sheetOffsetY = -screen.height * sheetRise;
    final double contentOpacity =
        (markReveal * (1 - contentExit)).clamp(0.0, 1.0).toDouble();
    final double markScale = 0.92 + (0.08 * markReveal) - (0.05 * contentExit);

    return Opacity(
      opacity: 1 - overlayExit,
      child: Transform.translate(
        offset: Offset(0, sheetOffsetY),
        child: SizedBox(
          width: screen.width,
          height: screen.height + headerHeight,
          child: ClipPath(
            clipper: _SplashToLoginHeaderClipper(headerHeight: headerHeight),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _greenGradient,
                ),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: (screen.height / 2) - 76,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: contentOpacity,
                      child: Transform.scale(
                        scale: markScale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const BullCareCowMark(
                              size: 98,
                              strokeColor: Colors.white,
                              showBadge: false,
                              shadow: false,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 34,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    typedText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 27,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  if (!typingFinished && typingProgress > 0)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 2),
                                      child: Text(
                                        '|',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 27,
                                          fontWeight: FontWeight.w500,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

/// Bidang splash dibuat setinggi layar + tinggi header login.
/// Pada posisi awal lengkungan berada di bawah layar. Setelah ikon sapi dan
/// animasi ketik BullCare selesai, bidang hijau menunggu sekitar tiga detik,
/// lalu naik sampai bagian lengkungnya menyatu dengan header LoginPage.
class _SplashToLoginHeaderClipper extends CustomClipper<Path> {
  const _SplashToLoginHeaderClipper({required this.headerHeight});

  final double headerHeight;

  @override
  Path getClip(Size size) {
    final double edgeY = size.height - (headerHeight * 0.44);
    final double centerY = size.height - (headerHeight * 0.14);

    final Path path = Path()
      ..lineTo(0, edgeY)
      ..quadraticBezierTo(
        size.width * 0.50,
        centerY,
        size.width,
        edgeY,
      )
      ..lineTo(size.width, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _SplashToLoginHeaderClipper oldClipper) {
    return oldClipper.headerHeight != headerHeight;
  }
}
