import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppFeedbackType { success, error, info, warning }

class AppFeedback {
  AppFeedback._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      type: AppFeedbackType.success,
      title: _successTitle(message),
      message: message,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      type: AppFeedbackType.error,
      title: _errorTitle(message),
      message: message,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String title = 'Informasi',
  }) {
    _show(
      context,
      type: AppFeedbackType.info,
      title: title,
      message: message,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String title = 'Peringatan',
  }) {
    _show(
      context,
      type: AppFeedbackType.warning,
      title: title,
      message: message,
    );
  }

  static void showGlobalSuccess(String message) {
    final BuildContext? context = messengerKey.currentContext;
    if (context == null) return;
    showSuccess(context, message);
  }

  static void showGlobalError(String message) {
    final BuildContext? context = messengerKey.currentContext;
    if (context == null) return;
    showError(context, message);
  }

  static String _successTitle(String message) {
    final String lower = message.toLowerCase();
    if (lower.contains('menambah') || lower.contains('ditambahkan')) {
      return 'Create Berhasil';
    }
    if (lower.contains('memperbarui') ||
        lower.contains('diperbarui') ||
        lower.contains('update')) {
      return 'Update Berhasil';
    }
    if (lower.contains('menghapus') || lower.contains('dihapus')) {
      return 'Delete Berhasil';
    }
    if (lower.contains('ekspor') || lower.contains('export')) {
      return 'Export Berhasil';
    }
    if (lower.contains('keluar')) return 'Keluar Berhasil';
    if (lower.contains('disimpan') || lower.contains('simpan')) {
      return 'Data Disimpan';
    }
    return 'Berhasil';
  }

  static String _errorTitle(String message) {
    final String lower = message.toLowerCase();
    if (lower.contains('hapus') || lower.contains('penghapusan')) {
      return 'Gagal Menghapus';
    }
    if (lower.contains('memperbarui') ||
        lower.contains('update') ||
        lower.contains('perbarui')) {
      return 'Gagal Memperbarui';
    }
    if (lower.contains('menambah') || lower.contains('tambahkan')) {
      return 'Gagal Menambahkan';
    }
    if (lower.contains('ekspor') || lower.contains('export')) {
      return 'Export Gagal';
    }
    if (lower.contains('koneksi') ||
        lower.contains('network') ||
        lower.contains('internet')) {
      return 'Koneksi Gagal';
    }
    if (lower.contains('validasi') ||
        lower.contains('periksa') ||
        lower.contains('wajib') ||
        lower.contains('harus') ||
        lower.startsWith('pilih ') ||
        lower.contains('tidak boleh')) {
      return 'Validasi Gagal';
    }
    return 'Terjadi Kesalahan';
  }

  static void _show(
    BuildContext context, {
    required AppFeedbackType type,
    required String title,
    required String message,
  }) {
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    _dismissTimer?.cancel();
    _activeEntry?.remove();
    _activeEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        final _FeedbackPalette palette = _FeedbackPalette.forType(type);
        return Positioned(
          top: MediaQuery.paddingOf(overlayContext).top + 12,
          left: 16,
          right: 16,
          child: IgnorePointer(
            ignoring: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Material(
                  type: MaterialType.transparency,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, -14 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      decoration: BoxDecoration(
                        color: palette.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: palette.border),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 22,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: palette.iconBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              palette.icon,
                              size: 21,
                              color: palette.foreground,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: palette.foreground,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  message,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tutup notifikasi',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _dismiss(entry),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: palette.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(const Duration(seconds: 4), () => _dismiss(entry));
  }

  static void _dismiss(OverlayEntry entry) {
    if (_activeEntry != entry) return;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    entry.remove();
    _activeEntry = null;
  }
}

class _FeedbackPalette {
  const _FeedbackPalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.iconBackground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final Color iconBackground;
  final IconData icon;

  static _FeedbackPalette forType(AppFeedbackType type) {
    switch (type) {
      case AppFeedbackType.success:
        return const _FeedbackPalette(
          background: Color(0xFFF0F9F1),
          border: Color(0xFFB9DFC1),
          foreground: Color(0xFF087A2C),
          iconBackground: Color(0xFFDDF3E2),
          icon: Icons.check_circle_rounded,
        );
      case AppFeedbackType.error:
        return const _FeedbackPalette(
          background: Color(0xFFFFF1F0),
          border: Color(0xFFF4B8B2),
          foreground: Color(0xFFC6281C),
          iconBackground: Color(0xFFFFDEDA),
          icon: Icons.cancel_rounded,
        );
      case AppFeedbackType.info:
        return const _FeedbackPalette(
          background: Color(0xFFF0F6FF),
          border: Color(0xFFBCD6FA),
          foreground: Color(0xFF1664C0),
          iconBackground: Color(0xFFDCEBFF),
          icon: Icons.info_rounded,
        );
      case AppFeedbackType.warning:
        return const _FeedbackPalette(
          background: Color(0xFFFFF7ED),
          border: Color(0xFFF2C690),
          foreground: Color(0xFFC76B08),
          iconBackground: Color(0xFFFFE8C9),
          icon: Icons.warning_rounded,
        );
    }
  }
}
