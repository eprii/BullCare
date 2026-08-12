import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BullVisual extends StatelessWidget {
  const BullVisual({
    super.key,
    this.height = 150,
    this.showLabel = false,
    this.compact = false,
  });

  final double height;
  final bool showLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 16 : 22),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFE8F7EC),
                    Color(0xFFCAEACF),
                    Color(0xFFF8EFD5),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -18,
              top: -22,
              child: Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: Color(0x66FFD166),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -42,
              right: 80,
              bottom: -44,
              child: Container(
                height: 110,
                decoration: const BoxDecoration(
                  color: Color(0xFF9ED5A7),
                  borderRadius: BorderRadius.all(Radius.elliptical(230, 105)),
                ),
              ),
            ),
            Positioned(
              left: 95,
              right: -55,
              bottom: -56,
              child: Container(
                height: 125,
                decoration: const BoxDecoration(
                  color: Color(0xFF65B778),
                  borderRadius: BorderRadius.all(Radius.elliptical(260, 115)),
                ),
              ),
            ),
            Positioned(
              right: compact ? 16 : 24,
              bottom: compact ? 12 : 18,
              child: Container(
                width: compact ? 64 : 94,
                height: compact ? 64 : 94,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.pets,
                  size: compact ? 34 : 52,
                  color: AppTheme.primary,
                ),
              ),
            ),
            if (showLabel)
              Positioned(
                left: 18,
                top: 18,
                right: compact ? 90 : 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Pemeliharaan bull\nlebih tertata',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            color: const Color(0xFF174E27),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Data, aktivitas, dan reminder dalam satu aplikasi.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF3D6C49),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
