import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ya, lanjutkan',
  String cancelLabel = 'Periksa kembali',
  IconData icon = Icons.fact_check_outlined,
}) async {
  final String keyword = '$title $confirmLabel'.toLowerCase();
  final bool destructive = keyword.contains('hapus');
  final bool logout = keyword.contains('keluar');
  final bool updating = keyword.contains('perbarui') || keyword.contains('ubah');

  final Color accent = destructive
      ? const Color(0xFFD92D20)
      : logout
          ? const Color(0xFFF57C00)
          : updating
              ? const Color(0xFF2563D9)
              : AppTheme.primary;

  final Color soft = destructive
      ? const Color(0xFFFFEEEB)
      : logout
          ? const Color(0xFFFFF1DE)
          : updating
              ? const Color(0xFFEAF2FF)
              : AppTheme.primarySoft;

  final IconData resolvedIcon = destructive
      ? Icons.warning_amber_rounded
      : logout
          ? Icons.logout_rounded
          : updating
              ? Icons.edit_note_rounded
              : icon;

  final bool? confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
        actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
              child: Icon(resolvedIcon, color: accent, size: 30),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
        ),
        actions: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  return confirmed == true;
}
