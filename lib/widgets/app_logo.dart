import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final Color foreground = light ? Colors.white : AppTheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: compact ? 36 : 58,
          height: compact ? 36 : 58,
          decoration: BoxDecoration(
            color: light ? Colors.white.withValues(alpha: 0.18) : AppTheme.primarySoft,
            borderRadius: BorderRadius.circular(compact ? 12 : 18),
          ),
          child: Icon(
            Icons.pets,
            color: foreground,
            size: compact ? 21 : 32,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: foreground,
                    letterSpacing: -0.5,
                  ),
            ),
            if (!compact)
              Text(
                AppConstants.appSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: light ? Colors.white70 : AppTheme.textSecondary,
                    ),
              ),
          ],
        ),
      ],
    );
  }
}
