import 'package:flutter/material.dart';

class StrawVisual extends StatelessWidget {
  const StrawVisual({super.key, required this.colorName});

  final String colorName;

  Color get _color {
    switch (colorName.toLowerCase().trim()) {
      case 'merah':
        return Colors.red;
      case 'kuning':
        return Colors.amber;
      case 'hijau':
        return Colors.green;
      case 'biru':
        return Colors.blue;
      case 'putih':
        return Colors.white;
      case 'ungu':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}
