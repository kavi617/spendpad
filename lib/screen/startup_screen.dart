import 'package:flutter/material.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, required this.onComplete});

  static const navy = Color(0xFF0D1830);
  final VoidCallback onComplete;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _copyOpacity;
  late final Animation<Offset> _copyOffset;
  late final Animation<double> _chartProgress;
  bool _started = false;
  bool _completionSent = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    )..addStatusListener(_handleStatus);
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .42, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: .84, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, .62, curve: Curves.easeOutCubic),
      ),
    );
    _copyOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.18, .62, curve: Curves.easeOut),
    );
    _copyOffset = Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(.18, .64, curve: Curves.easeOutCubic),
          ),
        );
    _chartProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.34, .91, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _controller.forward();
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish();
  }

  void _finish() {
    if (!mounted || _completionSent) return;
    _completionSent = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: StartupScreen.navy,
      body: Stack(
        children: [
          const Positioned(top: -170, right: -120, child: _AmbientGlow()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: reducedMotion
                            ? const AlwaysStoppedAnimation(1)
                            : _logoOpacity,
                        child: ScaleTransition(
                          scale: reducedMotion
                              ? const AlwaysStoppedAnimation(1)
                              : _logoScale,
                          child: const StartupBrandMark(size: 92),
                        ),
                      ),
                      const SizedBox(height: 22),
                      FadeTransition(
                        opacity: reducedMotion
                            ? const AlwaysStoppedAnimation(1)
                            : _copyOpacity,
                        child: SlideTransition(
                          position: reducedMotion
                              ? const AlwaysStoppedAnimation(Offset.zero)
                              : _copyOffset,
                          child: Column(
                            children: [
                              const Text(
                                'SpendPad',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 31,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.7,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your Money, Made Clear',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .68),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: .15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 38),
                      Container(
                        height: 166,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF142441).withValues(alpha: .88),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .08),
                          ),
                        ),
                        child: Semantics(
                          label: 'A simple animated spending chart',
                          child: AnimatedBuilder(
                            animation: _chartProgress,
                            builder: (context, child) => CustomPaint(
                              painter: _SpendingChartPainter(
                                progress: reducedMotion
                                    ? 1
                                    : _chartProgress.value,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 34,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: reducedMotion ? 1 : _chartProgress.value,
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(
                              alpha: .12,
                            ),
                            color: const Color(0xFF69B5FF),
                          ),
                        ),
                      ),
                    ],
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

class StartupBrandMark extends StatelessWidget {
  const StartupBrandMark({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * .28),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4F9EFF).withValues(alpha: .18),
          blurRadius: 28,
          spreadRadius: 1,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .28),
      child: Image.asset(
        'assets/images/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'SpendPad app icon',
      ),
    ),
  );
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) => Container(
    width: 330,
    height: 330,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          const Color(0xFF2E73BB).withValues(alpha: .15),
          StartupScreen.navy.withValues(alpha: 0),
        ],
      ),
    ),
  );
}

class _SpendingChartPainter extends CustomPainter {
  const _SpendingChartPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 13;
    final values = [0.34, 0.48, 0.39, 0.72, 0.59, 0.92];
    final gap = size.width / (values.length * 2 + 1);
    final barWidth = gap * .72;
    final bars = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final reveal = ((progress - i * .085) / .48).clamp(0.0, 1.0);
      final height = size.height * values[i] * reveal;
      final x = gap + i * (barWidth + gap);
      final top = baseline - height;
      bars.add(Offset(x + barWidth / 2, top - 2));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barWidth, height),
          const Radius.circular(5),
        ),
        Paint()
          ..color = i == values.length - 1
              ? const Color(0xFF54A5FF).withValues(alpha: .9)
              : const Color(0xFF78C8DB).withValues(alpha: .48),
      );
    }
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      Paint()
        ..color = Colors.white.withValues(alpha: .12)
        ..strokeWidth = 1,
    );

    if (progress > .12) {
      final path = Path()..moveTo(bars.first.dx, bars.first.dy);
      for (var i = 1; i < bars.length; i++) {
        final previous = bars[i - 1];
        final current = bars[i];
        final middle = (previous.dx + current.dx) / 2;
        path.cubicTo(
          middle,
          previous.dy,
          middle,
          current.dy,
          current.dx,
          current.dy,
        );
      }
      final metric = path.computeMetrics().first;
      final progressPath = metric.extractPath(
        0,
        metric.length * progress.clamp(0, 1),
      );
      canvas.drawPath(
        progressPath,
        Paint()
          ..color = const Color(0xFFB9E8FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      final last = bars.last;
      if (progress >= .8) {
        canvas.drawCircle(last, 4, Paint()..color = const Color(0xFFB9E8FF));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpendingChartPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
