import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/bull_model.dart';
import '../../services/bull_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_feedback.dart';
import '../../utils/bull_status.dart';
import '../../utils/confirmation_dialog.dart';
import '../../utils/validators.dart';
import '../../widgets/app_page_container.dart';

class BullFormPage extends StatefulWidget {
  const BullFormPage({super.key, this.bull});

  final BullModel? bull;

  @override
  State<BullFormPage> createState() => _BullFormPageState();
}

class _BullFormPageState extends State<BullFormPage> {
  static const int _maxPhotoBytes = 450 * 1024;
  static const int _maxBackgroundPhotoBytes = 220 * 1024;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final BullService _service = BullService();
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _age;
  late final TextEditingController _cage;
  late final TextEditingController _strawColor;
  late String _status;
  String _photoBase64 = '';
  String _backgroundPhotoBase64 = '';
  bool _loading = false;
  bool _pickingPhoto = false;
  bool _pickingBackgroundPhoto = false;
  String? _codeError;

  bool get _editing => widget.bull != null;
  bool get _pickingAnyPhoto => _pickingPhoto || _pickingBackgroundPhoto;

  @override
  void initState() {
    super.initState();
    final BullModel? bull = widget.bull;
    _code = TextEditingController(text: bull?.kode_bull ?? '');
    _name = TextEditingController(text: bull?.nama ?? '');
    _breed = TextEditingController(text: bull?.bangsa ?? '');
    _age = TextEditingController(text: bull?.umur ?? '');
    _cage = TextEditingController(text: bull?.nomor_kandang ?? '');
    _strawColor = TextEditingController(text: bull?.warna_straw ?? '');
    _photoBase64 = bull?.foto_base64 ?? '';
    _backgroundPhotoBase64 = bull?.foto_background_base64 ?? '';
    _status = BullStatus.normalize(bull?.status);
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _cage.dispose();
    _strawColor.dispose();
    super.dispose();
  }

  Future<String?> _pickEncodedPhoto({
    required int maxBytes,
    required double maxWidth,
    required double maxHeight,
    required int imageQuality,
    required String label,
  }) async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    if (picked == null || !mounted) return null;

    final bytes = await picked.readAsBytes();
    if (!mounted) return null;

    if (bytes.lengthInBytes > maxBytes) {
      AppFeedback.showError(
        context,
        'Ukuran $label masih terlalu besar. Pilih gambar lain dengan ukuran lebih kecil.',
      );
      return null;
    }

    return base64Encode(bytes);
  }

  Future<void> _pickPhoto() async {
    if (_pickingPhoto) return;
    setState(() => _pickingPhoto = true);

    try {
      final String? encoded = await _pickEncodedPhoto(
        maxBytes: _maxPhotoBytes,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 65,
        label: 'foto bull',
      );
      if (encoded != null && mounted) {
        setState(() => _photoBase64 = encoded);
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(context, 'Gagal memilih foto bull: $error');
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _pickBackgroundPhoto() async {
    if (_pickingBackgroundPhoto) return;
    setState(() => _pickingBackgroundPhoto = true);

    try {
      final String? encoded = await _pickEncodedPhoto(
        maxBytes: _maxBackgroundPhotoBytes,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 45,
        label: 'foto background',
      );
      if (encoded != null && mounted) {
        setState(() => _backgroundPhotoBase64 = encoded);
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(context, 'Gagal memilih foto background: $error');
      }
    } finally {
      if (mounted) setState(() => _pickingBackgroundPhoto = false);
    }
  }

  void _removePhoto() {
    setState(() => _photoBase64 = '');
  }

  void _removeBackgroundPhoto() {
    setState(() => _backgroundPhotoBase64 = '');
  }

  String? _validateAge(String? value) {
    final String text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return null;

    final double? age = double.tryParse(text);
    if (age == null) return 'Umur harus berupa angka, misalnya 2 atau 1.5.';
    if (age <= 0 || age > 30) return 'Umur harus lebih dari 0 dan maksimal 30 tahun.';
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _codeError = null);

    if (!_formKey.currentState!.validate()) {
      AppFeedback.showError(
        context,
        'Periksa kembali data bull yang wajib diisi.',
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final bool duplicateCode = await _service.isKodeBullInUse(
        _code.text,
        excludeBullId: widget.bull?.id,
      );
      if (!mounted) return;

      if (duplicateCode) {
        setState(() {
          _loading = false;
          _codeError = 'Kode bull sudah digunakan oleh bull lain.';
        });
        _formKey.currentState!.validate();
        AppFeedback.showError(context, 'Kode bull harus unik.');
        return;
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppFeedback.showError(context, 'Validasi kode bull gagal: $error');
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);

    final bool confirmed = await showConfirmationDialog(
      context,
      title: _editing ? 'Perbarui data bull?' : 'Tambahkan bull baru?',
      message: _editing
          ? 'Pastikan perubahan data ${_name.text.trim()} sudah benar sebelum disimpan.'
          : 'Pastikan identitas ${_name.text.trim()} sudah benar sebelum ditambahkan.',
      confirmLabel: _editing ? 'Ya, perbarui' : 'Ya, tambahkan',
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    try {
      final String normalizedAge = _age.text.trim().replaceAll(',', '.');

      if (_editing) {
        await _service.updateBull(
          widget.bull!.copyWith(
            kode_bull: _code.text.trim(),
            nama: _name.text.trim(),
            bangsa: _breed.text.trim(),
            umur: normalizedAge,
            nomor_kandang: _cage.text.trim(),
            warna_straw: _strawColor.text.trim(),
            foto_base64: _photoBase64,
            foto_background_base64: _backgroundPhotoBase64,
            status: _status,
            updated_at: DateTime.now(),
          ),
        );
        if (mounted) Navigator.of(context).pop(widget.bull!.id);
      } else {
        final String id = await _service.addBull(
          kodeBull: _code.text,
          nama: _name.text,
          bangsa: _breed.text,
          umur: normalizedAge,
          nomorKandang: _cage.text,
          warnaStraw: _strawColor.text,
          fotoBase64: _photoBase64,
          fotoBackgroundBase64: _backgroundPhotoBase64,
          status: _status,
        );
        if (mounted) Navigator.of(context).pop(id);
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(
          context,
          _editing
              ? 'Gagal memperbarui data bull: $error'
              : 'Gagal menambahkan data bull: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(_editing ? 'Edit Data Bull' : 'Tambah Bull')),
      body: SafeArea(
        top: false,
        child: AppPageContainer(
          maxWidth: 680,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 28),
              children: <Widget>[
                _PhotoCard(
                  title: 'Foto Bull',
                  emptyText: 'Pilih foto utama bull dari galeri perangkat.',
                  filledText: 'Foto ini digunakan pada kartu Data Bull dan foto profil di Detail Bull.',
                  photoBase64: _photoBase64,
                  loading: _pickingPhoto,
                  onPick: _pickPhoto,
                  onRemove: _photoBase64.isEmpty ? null : _removePhoto,
                ),
                const SizedBox(height: 12),
                _PhotoCard(
                  title: 'Foto Background Detail',
                  emptyText: 'Pilih foto landscape untuk background header Detail Bull.',
                  filledText: 'Foto ini digunakan khusus sebagai background pada halaman Detail Bull.',
                  photoBase64: _backgroundPhotoBase64,
                  loading: _pickingBackgroundPhoto,
                  onPick: _pickBackgroundPhoto,
                  onRemove: _backgroundPhotoBase64.isEmpty
                      ? null
                      : _removeBackgroundPhoto,
                  previewWidth: 132,
                  previewHeight: 92,
                  placeholderIcon: Icons.landscape_outlined,
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Informasi Dasar',
                  subtitle: 'Lengkapi identitas bull dengan data yang benar.',
                  children: <Widget>[
                    _field(
                      _code,
                      'Kode bull',
                      Icons.qr_code_2_rounded,
                      next: true,
                      maxLength: 30,
                      validator: (value) {
                        return _codeError ??
                            Validators.requiredText(
                              value,
                              label: 'Kode bull',
                              maxLength: 30,
                            );
                      },
                      onChanged: (_) {
                        if (_codeError != null) {
                          setState(() => _codeError = null);
                        }
                      },
                    ),
                    _field(
                      _name,
                      'Nama bull',
                      Icons.badge_outlined,
                      next: true,
                      maxLength: 80,
                    ),
                    _field(
                      _breed,
                      'Bangsa',
                      Icons.category_outlined,
                      next: true,
                      maxLength: 80,
                    ),
                    _field(
                      _age,
                      'Umur (tahun)',
                      Icons.cake_outlined,
                      next: true,
                      maxLength: 5,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _validateAge,
                    ),
                    _field(
                      _cage,
                      'Nomor kandang',
                      Icons.home_work_outlined,
                      next: true,
                      maxLength: 30,
                    ),
                    _field(
                      _strawColor,
                      'Warna straw',
                      Icons.color_lens_outlined,
                      maxLength: 50,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: Colors.white,
                      menuMaxHeight: 320,
                      focusColor: AppTheme.primarySoft,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.primary,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                      decoration: const InputDecoration(
                        labelText: 'Kondisi kesehatan',
                        prefixIcon: Icon(Icons.info_outline_rounded),
                        suffixIcon: Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: BullStatus.sehat,
                          child: Text(BullStatus.sehat),
                        ),
                        DropdownMenuItem(
                          value: BullStatus.tidakSehat,
                          child: Text(BullStatus.tidakSehat),
                        ),
                        DropdownMenuItem(
                          value: BullStatus.butuhVaksin,
                          child: Text(BullStatus.butuhVaksin),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _status = value ?? BullStatus.sehat);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.verified_user_outlined, color: AppTheme.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Data akan divalidasi terlebih dahulu sebelum disimpan ke database BullCare.',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _loading || _pickingAnyPhoto ? null : _save,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _editing ? 'Simpan Perubahan' : 'Simpan Data Bull',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool next = false,
    int? maxLength,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
  }) {
    final FormFieldValidator<String> resolvedValidator = validator ??
        (value) => Validators.requiredText(
              value,
              label: label,
              maxLength: maxLength,
            );
    final String currentValue = controller.text.trim();
    final bool validNow =
        currentValue.isNotEmpty && resolvedValidator(currentValue) == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: next ? TextInputAction.next : TextInputAction.done,
        maxLength: maxLength,
        onChanged: (value) {
          onChanged?.call(value);
          if (mounted) setState(() {});
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: validNow
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primary,
                )
              : null,
          counterText: '',
        ),
        validator: resolvedValidator,
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.title,
    required this.emptyText,
    required this.filledText,
    required this.photoBase64,
    required this.loading,
    required this.onPick,
    required this.onRemove,
    this.previewWidth = 104,
    this.previewHeight = 104,
    this.placeholderIcon = Icons.photo_camera_back_outlined,
  });

  final String title;
  final String emptyText;
  final String filledText;
  final String photoBase64;
  final bool loading;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final double previewWidth;
  final double previewHeight;
  final IconData placeholderIcon;

  Widget _photo() {
    if (photoBase64.trim().isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(photoBase64),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        );
      } catch (_) {
        // Gunakan placeholder jika data gambar lama tidak valid.
      }
    }

    return ColoredBox(
      color: const Color(0xFFF2F5F1),
      child: Center(
        child: Icon(
          placeholderIcon,
          size: 44,
          color: Color(0xFF889189),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = photoBase64.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: previewWidth,
              height: previewHeight,
              child: _photo(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasPhoto ? filledText : emptyText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: loading ? null : onPick,
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              hasPhoto
                                  ? Icons.edit_outlined
                                  : Icons.add_photo_alternate_outlined,
                            ),
                      label: Text(hasPhoto ? 'Ganti Foto' : 'Pilih Foto'),
                    ),
                    if (hasPhoto)
                      TextButton.icon(
                        onPressed: loading ? null : onRemove,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Hapus'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
