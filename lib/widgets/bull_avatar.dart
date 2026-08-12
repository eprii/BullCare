import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BullAvatar extends StatelessWidget {
  const BullAvatar({super.key, required this.name, this.size = 58});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String initial = name.trim().isEmpty ? 'B' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFDCF4E1),
            Color(0xFFBCE6C5),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Icon(
            Icons.pets,
            color: AppTheme.primary.withValues(alpha: 0.22),
            size: size * 0.68,
          ),
          Positioned(
            right: size * 0.10,
            bottom: size * 0.07,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: TextStyle(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
