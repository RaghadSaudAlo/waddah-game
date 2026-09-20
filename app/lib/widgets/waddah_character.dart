import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Animates the full [Image.asset] — no drawn eyes; glow + float + breathe + tilt.
class WaddahCharacter extends StatefulWidget {
  const WaddahCharacter({
    super.key,
    this.size = 160,
    this.bottomOffset = 0,
  });

  final double size;
  final double bottomOffset;

  @override
  State<WaddahCharacter> createState() => _WaddahCharacterState();
}

class _WaddahCharacterState extends State<WaddahCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * math.pi * 2;
        final floatY = math.sin(t) * 9;
        final rot = math.sin(t * 0.65) * 0.07;
        final breath = 1 + math.sin(t * 1.15) * 0.045;
        return Transform.translate(
          offset: Offset(0, floatY + widget.bottomOffset),
          child: Transform.rotate(
            angle: rot,
            child: Transform.scale(
              scale: breath * (widget.size / 160),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mint.withValues(alpha: 0.65),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppColors.sky.withValues(alpha: 0.35),
                      blurRadius: 36,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/waddah.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.pets_rounded,
                    size: widget.size * 0.55,
                    color: AppColors.deepMint,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
