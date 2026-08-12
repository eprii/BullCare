import 'package:flutter/material.dart';

/// Logo BullCare menggunakan aset gambar bull yang diberikan pengguna.
///
/// Parameter lama tetap dipertahankan agar pemanggilan yang sudah ada tidak
/// perlu diubah dan tidak memengaruhi alur sistem lain.
class BullCareCowMark extends StatelessWidget {
  const BullCareCowMark({
    super.key,
    this.size = 64,
    this.strokeColor = const Color.fromARGB(255, 44, 188, 51),
    this.badgeColor = Colors.white,
    this.showBadge = true,
    this.shadow = true,
  });

  final double size;

  // Dipertahankan untuk kompatibilitas dengan pemanggilan lama. Logo sekarang
  // menggunakan warna hitam asli dari aset gambar sesuai permintaan pengguna.
  final Color strokeColor;
  final Color badgeColor;
  final bool showBadge;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final Widget mark = Image.asset(
      'assets/branding/bull_logo_black.png',
      width: size * 0.88,
      height: size * 0.88,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'BullCare',
    );

    if (!showBadge) {
      return SizedBox.square(
        dimension: size,
        child: Center(child: mark),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        boxShadow: shadow
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: mark,
    );
  }
}
