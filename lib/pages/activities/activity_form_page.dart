import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/activity_definition.dart';
import '../../models/activity_record.dart';
import '../../models/bull_model.dart';
import '../../models/user_model.dart';
import '../../services/activity_service_registry.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_date_utils.dart';
import '../../utils/app_feedback.dart';
import '../../utils/confirmation_dialog.dart';
import '../../utils/validators.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/bull_avatar.dart';

class ActivityFormPage extends StatefulWidget {
  const ActivityFormPage({
    super.key,
    required this.bull,
    required this.user,
    required this.definition,
    this.existing,
    this.initialValues = const <String, dynamic>{},
  });

  final BullModel bull;
  final UserModel user;
  final ActivityDefinition definition;
  final ActivityRecord? existing;
  final Map<String, dynamic> initialValues;

  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  final Map<String, bool> _booleanValues = <String, bool>{};
  final Map<String, String?> _healthCheckValues = <String, String?>{
    'feses': null,
    'pakan': null,
    'fisik': null,
  };
  late final TextEditingController _petugasController;
  late DateTime _date;
  bool _loading = false;
  String? _booleanError;

  bool get _editing => widget.existing != null;
  bool get _isHealthCheck =>
      widget.definition.collectionName == 'pemeriksaan_kesehatan';

  String? _initialHealthCheckValue(String key) {
    final Map<String, dynamic>? existing = widget.existing?.data;
    final dynamic explicit = existing?['${key}_status'] ??
        widget.initialValues['${key}_status'];
    final String explicitText = explicit?.toString().trim().toLowerCase() ?? '';
    if (explicitText == 'normal' || explicitText == 'abnormal') {
      return explicitText;
    }

    final dynamic normal = existing?['${key}_normal'] ??
        widget.initialValues['${key}_normal'];
    final dynamic abnormal = existing?['${key}_abn'] ??
        widget.initialValues['${key}_abn'];
    if (_truthy(normal)) return 'normal';
    if (_truthy(abnormal)) return 'abnormal';
    return null;
  }

  bool _truthy(dynamic value) {
    if (value == true) return true;
    final String text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'ya' || text == 'x';
  }

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.tanggal ?? DateTime.now();
    final String existingPetugas =
        widget.existing?.data['nama_petugas']?.toString().trim() ?? '';
    _petugasController = TextEditingController(
      text: existingPetugas.isNotEmpty ? existingPetugas : widget.user.nama,
    );
    for (final ActivityFieldDefinition field in widget.definition.fields) {
      final dynamic initialValue = widget.existing?.data[field.key] ??
          widget.initialValues[field.key];
      if (field.type == ActivityFieldType.boolean) {
        _booleanValues[field.key] = initialValue == true;
      } else {
        _controllers[field.key] = TextEditingController(
          text: initialValue?.toString() ?? '',
        );
      }
    }
    if (_isHealthCheck) {
      _healthCheckValues['feses'] = _initialHealthCheckValue('feses');
      _healthCheckValues['pakan'] = _initialHealthCheckValue('pakan');
      _healthCheckValues['fisik'] = _initialHealthCheckValue('fisik');
    }
  }

  @override
  void dispose() {
    _petugasController.dispose();
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _date.isAfter(now) ? now : _date;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  bool _validateBooleanFields() {
    final List<ActivityFieldDefinition> booleanFields = widget.definition.fields
        .where((field) => field.type == ActivityFieldType.boolean)
        .toList(growable: false);

    if (booleanFields.isEmpty) {
      _booleanError = null;
      return true;
    }

    final bool hasSelectedAction = booleanFields.any(
      (field) => _booleanValues[field.key] == true,
    );
    setState(() {
      _booleanError = hasSelectedAction
          ? null
          : 'Pilih minimal satu tindakan yang telah dilakukan.';
    });
    return hasSelectedAction;
  }

  bool _validateDate() {
    final DateTime now = DateTime.now();
    final DateTime selectedDay = DateTime(_date.year, _date.month, _date.day);
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (selectedDay.isAfter(today)) {
      AppFeedback.showError(
        context,
        'Tanggal aktivitas tidak boleh melewati hari ini.',
      );
      return false;
    }
    return true;
  }

  Map<String, dynamic> _collectValues() {
    final Map<String, dynamic> values = <String, dynamic>{
      'nama_petugas': _petugasController.text.trim(),
    };
    for (final ActivityFieldDefinition field in widget.definition.fields) {
      if (field.type == ActivityFieldType.boolean) {
        values[field.key] = _booleanValues[field.key] ?? false;
      } else {
        final String text = _controllers[field.key]!.text.trim();
        values[field.key] = field.type == ActivityFieldType.decimal
            ? double.parse(text.replaceAll(',', '.'))
            : text;
      }
    }

    if (_isHealthCheck) {
      for (final String key in const <String>['feses', 'pakan', 'fisik']) {
        final String? status = _healthCheckValues[key];
        values['${key}_status'] = status ?? '';
        values['${key}_normal'] = status == 'normal';
        values['${key}_abn'] = status == 'abnormal';
      }
    }
    return values;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final bool validForm = _formKey.currentState!.validate();
    final bool validBoolean = _validateBooleanFields();
    final bool validDate = _validateDate();

    if (!validForm || !validBoolean || !validDate) {
      AppFeedback.showError(
        context,
        'Periksa kembali data aktivitas sebelum disimpan.',
      );
      return;
    }

    final bool confirmed = await showConfirmationDialog(
      context,
      title: _editing ? 'Perbarui aktivitas?' : 'Simpan aktivitas?',
      message:
          '${widget.definition.label} untuk ${widget.bull.nama} pada ${AppDateUtils.formatDate(_date)} oleh ${_petugasController.text.trim()} sudah benar?',
      confirmLabel: _editing ? 'Ya, perbarui' : 'Ya, simpan',
    );
    if (!confirmed || !mounted) return;

    setState(() => _loading = true);
    final Map<String, dynamic> values = _collectValues();

    try {
      final service = ActivityServiceRegistry.serviceFor(
        widget.definition.collectionName,
      );
      if (_editing) {
        await service.updateActivity(
          id: widget.existing!.id,
          tanggal: _date,
          values: values,
        );
      } else {
        await service.addActivity(
          bullId: widget.bull.id,
          petugasUid: widget.user.uid,
          tanggal: _date,
          values: values,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(
          context,
          _editing
              ? 'Gagal memperbarui aktivitas ${widget.definition.label}: $error'
              : 'Gagal menambahkan aktivitas ${widget.definition.label}: $error',
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
      appBar: AppBar(
        title: Text(
          _editing ? 'Edit ${widget.definition.label}' : widget.definition.label,
        ),
      ),
      body: SafeArea(
        top: false,
        child: AppPageContainer(
          maxWidth: 680,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
              children: <Widget>[
                _BullHeader(
                  bull: widget.bull,
                  icon: widget.definition.icon,
                ),
                const SizedBox(height: 14),
                _FormSection(
                  title: 'Informasi Aktivitas',
                  children: <Widget>[
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal aktivitas',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          AppDateUtils.formatDate(_date),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _petugasController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 120,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Nama petugas pelaksana',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        suffixIcon: _petugasController.text.trim().isNotEmpty
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primary,
                              )
                            : null,
                        helperText:
                            'Isi nama petugas yang menjalankan aktivitas ini.',
                        counterText: '',
                      ),
                      validator: (value) => Validators.requiredText(
                        value,
                        label: 'Nama petugas pelaksana',
                        maxLength: 120,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _FormSection(
                  title: 'Data ${widget.definition.label}',
                  children: <Widget>[
                    if (_isHealthCheck) ...<Widget>[
                      _buildHealthCheckDropdown(
                        keyName: 'feses',
                        label: 'Pemeriksaan Feses',
                      ),
                      _buildHealthCheckDropdown(
                        keyName: 'pakan',
                        label: 'Pemeriksaan Pakan',
                      ),
                      _buildHealthCheckDropdown(
                        keyName: 'fisik',
                        label: 'Pemeriksaan Fisik',
                      ),
                    ],
                    ...widget.definition.fields.map(_buildField),
                    if (_booleanError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _booleanError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _loading ? null : _save,
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
                    _editing ? 'Simpan Perubahan' : 'Simpan Aktivitas',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHealthCheckDropdown({
    required String keyName,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: _healthCheckValues[keyName],
        isExpanded: true,
        borderRadius: BorderRadius.circular(16),
        dropdownColor: Colors.white,
        menuMaxHeight: 280,
        focusColor: AppTheme.primarySoft,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppTheme.primary,
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.fact_check_outlined),
        ),
        hint: Text(
          'Pilih hasil pemeriksaan',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        items: const <DropdownMenuItem<String>>[
          DropdownMenuItem<String>(
            value: 'normal',
            child: Text('Normal'),
          ),
          DropdownMenuItem<String>(
            value: 'abnormal',
            child: Text('Abnormal'),
          ),
        ],
        onChanged: (String? value) {
          setState(() => _healthCheckValues[keyName] = value);
        },
        validator: (String? value) {
          if (value == null || value.isEmpty) {
            return '$label wajib dipilih.';
          }
          return null;
        },
      ),
    );
  }

  bool _isFieldCurrentlyValid(ActivityFieldDefinition field) {
    if (field.type == ActivityFieldType.boolean) {
      return _booleanValues[field.key] == true;
    }
    final String text = _controllers[field.key]?.text.trim() ?? '';
    if (text.isEmpty) return false;
    if (field.type == ActivityFieldType.decimal) {
      return Validators.positiveDecimal(text, label: field.label) == null;
    }
    return Validators.requiredText(
          text,
          label: field.label,
          maxLength: field.type == ActivityFieldType.multiline ? 1000 : 250,
        ) ==
        null;
  }

  Widget _buildField(ActivityFieldDefinition field) {
    if (field.type == ActivityFieldType.boolean) {
      final bool selected = _booleanValues[field.key] ?? false;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primarySoft : AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFB9DFC1) : Colors.transparent,
          ),
        ),
        child: SwitchListTile(
          title: Text(
            field.label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(selected ? 'Sudah dilakukan' : 'Belum dipilih'),
          value: selected,
          activeThumbColor: AppTheme.primary,
          activeTrackColor: const Color(0xFFBCE6C5),
          onChanged: (value) {
            setState(() {
              _booleanValues[field.key] = value;
              _booleanError = null;
            });
          },
        ),
      );
    }

    final bool decimal = field.type == ActivityFieldType.decimal;
    final bool multiline = field.type == ActivityFieldType.multiline;
    final int maxLength = multiline ? 1000 : 250;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _controllers[field.key],
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : multiline
                ? TextInputType.multiline
                : TextInputType.text,
        inputFormatters: decimal
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ]
            : null,
        minLines: multiline ? 3 : 1,
        maxLines: multiline ? 5 : 1,
        maxLength: maxLength,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: field.label,
          suffixText: field.suffix,
          suffixIcon: _isFieldCurrentlyValid(field)
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primary,
                )
              : null,
          counterText: '',
        ),
        validator: (value) {
          if (!field.required && (value == null || value.trim().isEmpty)) {
            return null;
          }
          return decimal
              ? Validators.positiveDecimal(value, label: field.label)
              : Validators.requiredText(
                  value,
                  label: field.label,
                  maxLength: maxLength,
                );
        },
      ),
    );
  }
}

class _BullHeader extends StatelessWidget {
  const _BullHeader({
    required this.bull,
    required this.icon,
  });

  final BullModel bull;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: <Widget>[
          BullAvatar(name: bull.nama, size: 62),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  bull.kode_bull,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${bull.nama} • Kandang ${bull.nomor_kandang}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
