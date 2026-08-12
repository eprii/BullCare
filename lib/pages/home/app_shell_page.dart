import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../activities/activity_list_page.dart';
import '../bulls/bull_list_page.dart';
import '../dashboard/dashboard_page.dart';
import '../reminders/reminder_page.dart';
import '../reports/report_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key, required this.firebaseUser});

  final User firebaseUser;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  final UserService _userService = UserService();
  int _index = 0;
  int _dashboardRevision = 0;
  int _activityRevision = 0;
  int _reminderRevision = 0;

  void _notifyDataChanged() {
    if (!mounted) return;
    setState(() {
      _dashboardRevision++;
      _activityRevision++;
      _reminderRevision++;
    });
  }

  void _selectPage(int value) {
    setState(() {
      _index = value;
      if (value == 0) _dashboardRevision++;
      if (value == 2) _activityRevision++;
      if (value == 3) _reminderRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _userService.watchUser(widget.firebaseUser.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: ErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: LoadingView(message: 'Memuat profil pengguna...'),
          );
        }

        final UserModel user = snapshot.data!;
        final List<Widget> pages = <Widget>[
          DashboardPage(
            user: user,
            revision: _dashboardRevision,
            onOpenBulls: () => _selectPage(1),
            onOpenActivities: () => _selectPage(2),
            onOpenReminders: () => _selectPage(3),
          ),
          BullListPage(user: user, onDataChanged: _notifyDataChanged),
          ActivityListPage(
            user: user,
            revision: _activityRevision,
            onDataChanged: _notifyDataChanged,
          ),
          ReminderPage(
            user: user,
            revision: _reminderRevision,
            onDataChanged: _notifyDataChanged,
          ),
          ReportPage(user: user),
        ];

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: _BullCareBottomNavigation(
            selectedIndex: _index,
            onDestinationSelected: _selectPage,
          ),
        );
      },
    );
  }
}

class _BullCareBottomNavigation extends StatefulWidget {
  const _BullCareBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<_BullCareBottomNavigation> createState() =>
      _BullCareBottomNavigationState();
}

class _BullCareBottomNavigationState extends State<_BullCareBottomNavigation>
    with SingleTickerProviderStateMixin {
  static const List<_BullCareNavigationItem> _items =
      <_BullCareNavigationItem>[
    _BullCareNavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _BullCareNavigationItem(
      label: 'Bull',
      icon: Icons.pets_outlined,
      selectedIcon: Icons.pets_rounded,
    ),
    _BullCareNavigationItem(
      label: 'Aktivitas',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
    ),
    _BullCareNavigationItem(
      label: 'Reminder',
      icon: Icons.notifications_none_rounded,
      selectedIcon: Icons.notifications_rounded,
    ),
    _BullCareNavigationItem(
      label: 'Laporan',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
    ),
  ];

  late final AnimationController _controller;
  late double _fromIndex;
  late double _toIndex;
  late int _fromIconIndex;
  late int _toIconIndex;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.selectedIndex.toDouble();
    _toIndex = widget.selectedIndex.toDouble();
    _fromIconIndex = widget.selectedIndex;
    _toIconIndex = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _BullCareBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex == widget.selectedIndex) return;

    // Mulai animasi dari posisi indikator saat ini supaya perpindahan cepat
    // berturut-turut tidak pernah meloncat.
    final double currentIndex = _indicatorIndex(_controller.value);
    final int currentIconIndex = _movingIconIndex(_controller.value);
    _fromIndex = currentIndex;
    _toIndex = widget.selectedIndex.toDouble();
    _fromIconIndex = currentIconIndex;
    _toIconIndex = widget.selectedIndex;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _slideProgress(double value) {
    // Fase pertama murni swap kanan-kiri. Gerakan selesai sedikit lebih
    // cepat supaya ada waktu khusus untuk bounce singkat saat mendarat.
    final double raw = (value / 0.72).clamp(0.0, 1.0);
    return Curves.easeInOutCubic.transform(raw);
  }

  double _indicatorIndex(double value) {
    final double progress = _slideProgress(value);
    return _fromIndex + ((_toIndex - _fromIndex) * progress);
  }

  double _indicatorLift(double value) {
    // Saat berpindah indikator hampir tetap pada garis horizontal. Begitu
    // sampai tujuan, indikator melakukan quick bounce kecil lalu stabil.
    if (value <= 0.72) {
      final double moveT = (value / 0.72).clamp(0.0, 1.0);
      return -1.4 * math.sin(math.pi * moveT);
    }

    final double landingT = ((value - 0.72) / 0.28).clamp(0.0, 1.0);
    return 4.6 * math.sin(2 * math.pi * landingT) * (1 - landingT);
  }

  double _indicatorScale(double value) {
    if (value <= 0.72) {
      final double moveT = (value / 0.72).clamp(0.0, 1.0);
      return 1 - (0.035 * math.sin(math.pi * moveT));
    }

    final double landingT = ((value - 0.72) / 0.28).clamp(0.0, 1.0);
    final double bounced = Curves.elasticOut.transform(landingT);
    return 0.965 + (0.035 * bounced);
  }

  int _movingIconIndex(double value) {
    if (_fromIconIndex == _toIconIndex) return _toIconIndex;
    return value < 0.46 ? _fromIconIndex : _toIconIndex;
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color pageColor = Theme.of(context).scaffoldBackgroundColor;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 6),
        child: SizedBox(
          height: 102,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double horizontalInset = 12;
              final double usableWidth =
                  constraints.maxWidth - (horizontalInset * 2);
              final double itemWidth = usableWidth / _items.length;

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final double value = _controller.value;
                  final double movingIndex = _indicatorIndex(value);
                  final double indicatorCenterX = horizontalInset +
                      (itemWidth * (movingIndex + 0.5));
                  final double lift = _indicatorLift(value);
                  final double scale = _indicatorScale(value);
                  final int movingIconIndex = _movingIconIndex(value);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      // Base navbar tetap satu pill halus. Indikator aktif
                      // sengaja tidak menyatu dengan base agar terlihat
                      // benar-benar mengambang/terpisah seperti referensi.
                      Positioned.fill(
                        child: CustomPaint(
                          painter: const _BullCareNavSurfacePainter(
                            surfaceColor: Colors.white,
                          ),
                        ),
                      ),

                      // Item tidak aktif tetap berada di dalam pill. Saat
                      // indikator lewat, icon di bawahnya memudar agar swap
                      // kanan-kiri terasa bersih.
                      Positioned(
                        left: horizontalInset,
                        right: horizontalInset,
                        top: 0,
                        bottom: 0,
                        child: Row(
                          children: List<Widget>.generate(_items.length,
                              (int index) {
                            final double distance =
                                (movingIndex - index).abs();
                            final double selectionAmount =
                                (1 - distance).clamp(0.0, 1.0);
                            return Expanded(
                              child: _BullCareNavigationButton(
                                item: _items[index],
                                selectionAmount: selectionAmount,
                                hoverEnabled: !_controller.isAnimating,
                                onTap: () =>
                                    widget.onDestinationSelected(index),
                              ),
                            );
                          }),
                        ),
                      ),

                      // Lingkaran aktif diletakkan paling depan. Halo dengan
                      // warna halaman memisahkan fill aktif dari navbar di
                      // bawahnya sehingga efek floating tetap jelas.
                      Positioned(
                        left: indicatorCenterX - 33,
                        top: -2 + lift,
                        child: IgnorePointer(
                          child: Transform.scale(
                            scale: scale,
                            child: _BullCareMovingIndicator(
                              backgroundColor: pageColor,
                              primary: primary,
                              item: _items[movingIconIndex],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BullCareNavigationButton extends StatefulWidget {
  const _BullCareNavigationButton({
    required this.item,
    required this.selectionAmount,
    required this.hoverEnabled,
    required this.onTap,
  });

  final _BullCareNavigationItem item;
  final double selectionAmount;
  final bool hoverEnabled;
  final VoidCallback onTap;

  @override
  State<_BullCareNavigationButton> createState() =>
      _BullCareNavigationButtonState();
}

class _BullCareNavigationButtonState
    extends State<_BullCareNavigationButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    const Color inactive = Color(0xFF252925);
    final Color labelColor = Color.lerp(
          inactive.withValues(alpha: 0.82),
          primary,
          widget.selectionAmount,
        ) ??
        inactive;
    final bool showHover =
        widget.hoverEnabled && _hovered && widget.selectionAmount < 0.55;

    return Semantics(
      button: true,
      selected: widget.selectionAmount > 0.75,
      label: widget.item.label,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(26),
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              Positioned(
                top: 30,
                // Hover sengaja hanya aktif pada area icon, bukan seluruh
                // kolom menu. Ukurannya tetap sehingga shadow tidak mengubah
                // hit-test area dan tidak menyebabkan hover flicker.
                child: MouseRegion(
                  onEnter: (_) {
                    if (!_hovered) setState(() => _hovered = true);
                  },
                  onExit: (_) {
                    if (_hovered) setState(() => _hovered = false);
                  },
                  cursor: SystemMouseCursors.click,
                  opaque: true,
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: showHover
                              ? const Color(0xFFF9FAF9)
                              : Colors.transparent,
                          boxShadow: showHover
                              ? const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x1A000000),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : const <BoxShadow>[],
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: (1 - widget.selectionAmount)
                                .clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale:
                                  1 - (widget.selectionAmount * 0.12),
                              child: Icon(
                                widget.item.icon,
                                size: 25,
                                color: inactive.withValues(alpha: 0.76),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 72,
                left: 2,
                right: 2,
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 11.5,
                    height: 1,
                    fontWeight: widget.selectionAmount > 0.55
                        ? FontWeight.w800
                        : FontWeight.w500,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BullCareMovingIndicator extends StatelessWidget {
  const _BullCareMovingIndicator({
    required this.backgroundColor,
    required this.primary,
    required this.item,
  });

  final Color backgroundColor;
  final Color primary;
  final _BullCareNavigationItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 66,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Halo luar memakai warna halaman. Karena indikator berada di depan
          // base navbar, halo ini membentuk jarak nyata sehingga bubble aktif
          // tampak mengambang dan tidak menempel pada fill di bawahnya.
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE8ECE9),
                width: 1,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.72, end: 1).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Icon(
                item.selectedIcon,
                key: ValueKey<String>(item.label),
                size: 27,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BullCareNavSurfacePainter extends CustomPainter {
  const _BullCareNavSurfacePainter({
    required this.surfaceColor,
  });

  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    const double left = 12;
    const double rightInset = 12;
    const double top = 22;
    const double cornerRadius = 30;
    final double right = size.width - rightInset;
    final double bottom = size.height - 5;

    // Base dibuat sebagai pill utuh tanpa notch. Bubble aktif yang berada di
    // atasnya memiliki halo sendiri sehingga pemisahan terlihat lembut dan
    // tidak menghasilkan lengkungan tajam.
    final RRect navRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      const Radius.circular(cornerRadius),
    );
    final Path path = Path()..addRRect(navRRect);

    canvas.drawShadow(
      path,
      const Color(0x22000000),
      12,
      false,
    );
    canvas.drawRRect(navRRect, Paint()..color = surfaceColor);

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xFFEFF1EF);
    canvas.drawRRect(navRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BullCareNavSurfacePainter oldDelegate) {
    return oldDelegate.surfaceColor != surfaceColor;
  }
}

class _BullCareNavigationItem {
  const _BullCareNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
