import 'package:flutter/material.dart';

/// Fades and slides its child in, with a stagger based on [index].
class StaggerIn extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggerIn({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    const stepMs = 55.0;
    const durMs = 380.0;
    final delayMs = stepMs * index.clamp(0, 10);
    final totalMs = delayMs + durMs;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs.round()),
      curve: Curves.linear,
      builder: (context, t, child) {
        final local = ((t * totalMs - delayMs) / durMs).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(local);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
