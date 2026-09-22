import 'package:flutter/material.dart';

import '../../models/activity_record.dart';
import '../../models/bull_model.dart';
import '../../models/user_model.dart';
import '../../services/bull_service.dart';
import '../../services/produksi_distribusi_semen_beku_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/bull_breed_name.dart';
import '../../utils/bull_sni_status.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'produksi_distribusi_semen_beku_detail_page.dart';
import 'produksi_distribusi_semen_beku_register_page.dart';

class ProduksiDistribusiSemenBekuPage extends StatefulWidget {
  const ProduksiDistribusiSemenBekuPage({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  State<ProduksiDistribusiSemenBekuPage> createState() =>
      _ProduksiDistribusiSemenBekuPageState();
}

class _ProduksiDistribusiSemenBekuPageState
    extends State<ProduksiDistribusiSemenBekuPage> {
  final BullService _bullService = BullService();
  final ProduksiDistribusiSemenBekuService _service =
      ProduksiDistribusiSemenBekuService();

  int? _selectedMonth;
  int? _selectedYear;

  static const List<String> _categoryOrder = <String>[
    'Sapi Potong',
    'Kerbau',
    'Sexing',
    'Non-LSPro',
  ];

  bool get _hasPeriod => _selectedMonth != null && _selectedYear != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Produksi & Distribusi Semen Beku'),
      ),
      body: AppPageContainer(
        maxWidth: 940,
        child: StreamBuilder<List<BullModel>>(
          stream: _bullService.watchBulls(),
          builder: (context, bullSnapshot) {
            if (bullSnapshot.connectionState == ConnectionState.waiting &&
                !bullSnapshot.hasData) {
              return const LoadingView(message: 'Memuat data pejantan...');
            }
            if (bullSnapshot.hasError) {
              return ErrorView(message: bullSnapshot.error.toString());
            }
            final List<BullModel> bulls = bullSnapshot.data ?? <BullModel>[];

            return StreamBuilder<List<ActivityRecord>>(
              stream: _service.watchMonthlyRecords(),
              builder: (context, productionSnapshot) {
                if (productionSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !productionSnapshot.hasData) {
                  return const LoadingView(message: 'Memuat data produksi...');
                }
                if (productionSnapshot.hasError) {
                  return ErrorView(message: productionSnapshot.error.toString());
                }

                final List<ActivityRecord> allRecords =
                    productionSnapshot.data ?? <ActivityRecord>[];
                final List<int> years = _yearOptions(allRecords);
                final List<ActivityRecord> periodRecords = !_hasPeriod
                    ? <ActivityRecord>[]
                    : allRecords.where((record) {
                        return _asInt(record.data['bulan']) == _selectedMonth &&
                            _asInt(record.data['tahun']) == _selectedYear;
                      }).toList(growable: false);
                final List<_CategoryGroup> groups =
                    _buildGroups(bulls: bulls, records: periodRecords);
                final _PeriodTotals totals = _PeriodTotals.fromRecords(
                  records: periodRecords,
                  year: _selectedYear,
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
                  children: <Widget>[
                    _PeriodHeaderCard(
                      selectedMonth: _selectedMonth,
                      selectedYear: _selectedYear,
                      years: years,
                      onMonthChanged: (value) {
                        setState(() => _selectedMonth = value);
                        _syncActivePeriod();
                      },
                      onYearChanged: (value) {
                        setState(() => _selectedYear = value);
                        _syncActivePeriod();
                      },
                    ),
                    const SizedBox(height: 16),
                    if (!_hasPeriod)
                      const Card(
                        child: EmptyState(
                          icon: Icons.date_range_outlined,
                          title: 'Pilih bulan dan tahun',
                          message:
                              'Tentukan periode terlebih dahulu untuk melihat dan memasukkan data produksi semen beku.',
                        ),
                      )
                    else if (periodRecords.isEmpty)
                      Card(
                        child: EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'Belum ada data produksi',
                          message:
                              'Belum ada bangsa yang didaftarkan untuk ${_monthName(_selectedMonth!)} $_selectedYear.',
                        ),
                      )
                    else ...<Widget>[
                      ...groups.where((group) => group.records.isNotEmpty).map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _CategorySection(
                                group: group,
                                onOpen: (item) => _openRecord(item.record),
                              ),
                            ),
                          ),
                      _TotalsCard(
                        totals: totals,
                        month: _selectedMonth!,
                        year: _selectedYear!,
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: widget.user.canManageActivity && _hasPeriod
          ? FloatingActionButton(
              heroTag: null,
              onPressed: _addProduction,
              tooltip: 'Tambah data produksi',
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
    );
  }

  void _syncActivePeriod() {
    final int? month = _selectedMonth;
    final int? year = _selectedYear;
    if (month == null || year == null) return;
    _service.setActivePeriod(tahun: year, bulan: month);
  }

  Future<void> _addProduction() async {
    final int? month = _selectedMonth;
    final int? year = _selectedYear;
    if (month == null || year == null || !widget.user.canManageActivity) return;

    await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ProduksiDistribusiSemenBekuRegisterPage(
          user: widget.user,
          tahun: year,
          bulan: month,
        ),
      ),
    );
  }

  Future<void> _openRecord(ActivityRecord record) async {
    await _openRecordById(record.id);
  }

  Future<void> _openRecordById(String id) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProduksiDistribusiSemenBekuDetailPage(
          user: widget.user,
          recordId: id,
        ),
      ),
    );
  }

  List<int> _yearOptions(List<ActivityRecord> records) {
    final int currentYear = DateTime.now().year;
    final Set<int> years = <int>{
      for (int offset = -3; offset <= 3; offset++) currentYear + offset,
    };
    for (final ActivityRecord record in records) {
      final int year = _asInt(record.data['tahun']);
      if (year >= 2000 && year <= 2100) years.add(year);
    }
    final List<int> result = years.toList()..sort((a, b) => b.compareTo(a));
    return result;
  }

  List<_CategoryGroup> _buildGroups({
    required List<BullModel> bulls,
    required List<ActivityRecord> records,
  }) {
    final Map<String, String> labels = <String, String>{};
    for (final ActivityRecord record in records) {
      final String category =
          _canonicalCategory(record.data['kategori']?.toString() ?? '');
      if (category.isEmpty) continue;
      labels.putIfAbsent(_normalize(category), () => category);
    }

    final List<String> categories = <String>[];
    for (final String category in _categoryOrder) {
      if (labels.containsKey(_normalize(category))) categories.add(category);
    }
    final List<String> extras = labels.values
        .where(
          (value) => !_categoryOrder.any(
            (known) => _normalize(known) == _normalize(value),
          ),
        )
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    categories.addAll(extras);

    return categories.map((category) {
      final String normalizedCategory = _normalize(category);
      final List<ActivityRecord> categoryRecords = records.where((record) {
        return _normalize(
              _canonicalCategory(record.data['kategori']?.toString() ?? ''),
            ) ==
            normalizedCategory;
      }).toList()
        ..sort((a, b) {
          if (_isSexingCategory(category)) {
            final int bySni = _sniSortOrder(a.data['status_sni'])
                .compareTo(_sniSortOrder(b.data['status_sni']));
            if (bySni != 0) return bySni;
          }
          return BullBreedName.canonical(a.data['bangsa']?.toString())
              .toLowerCase()
              .compareTo(BullBreedName.canonical(b.data['bangsa']?.toString()).toLowerCase());
        });

      final List<_ProductionOverview> items = categoryRecords.map((record) {
        final String breed =
            BullBreedName.canonical(record.data['bangsa']?.toString());
        final String statusSni = _isSexingCategory(category)
            ? BullSniStatus.normalize(record.data['status_sni']?.toString())
            : '';
        final int availableBulls = bulls.where((bull) {
          if (!BullBreedName.same(bull.bangsa, breed)) return false;
          if (!_isSexingCategory(category)) return true;
          return BullSniStatus.normalize(bull.status_sni) == statusSni;
        }).length;
        return _ProductionOverview(
          record: record,
          breed: breed,
          statusSni: statusSni,
          productionBulls: _asInt(record.data['jumlah_pejantan']),
          availableBulls: availableBulls,
          stock: _hasValue(record.data['stock_akhir'])
              ? _asInt(record.data['stock_akhir'])
              : null,
        );
      }).toList(growable: false);

      return _CategoryGroup(category: category, records: items);
    }).toList(growable: false);
  }
}

class _PeriodHeaderCard extends StatelessWidget {
  const _PeriodHeaderCard({
    required this.selectedMonth,
    required this.selectedYear,
    required this.years,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  final int? selectedMonth;
  final int? selectedYear;
  final List<int> years;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Data Produksi Semen Beku',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pilih bulan dan tahun terlebih dahulu. Semua data yang tampil dan ditambahkan akan mengikuti periode tersebut.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 15),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stacked = constraints.maxWidth < 500;
              final Widget month = _PeriodDropdown(
                label: 'Bulan',
                icon: Icons.calendar_month_outlined,
                value: selectedMonth,
                hint: 'Pilih bulan',
                items: List<DropdownMenuItem<int>>.generate(
                  12,
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text(_monthName(index + 1)),
                  ),
                ),
                onChanged: onMonthChanged,
              );
              final Widget year = _PeriodDropdown(
                label: 'Tahun',
                icon: Icons.event_outlined,
                value: selectedYear,
                hint: 'Pilih tahun',
                items: years
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onYearChanged,
              );
              if (stacked) {
                return Column(
                  children: <Widget>[
                    month,
                    const SizedBox(height: 10),
                    year,
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  Expanded(child: month),
                  const SizedBox(width: 12),
                  Expanded(child: year),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final int? value;
  final String hint;
  final List<DropdownMenuItem<int>> items;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.group, required this.onOpen});

  final _CategoryGroup group;
  final ValueChanged<_ProductionOverview> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 9),
          child: Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                group.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.35,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.divider),
          ),
          child: _isSexingCategory(group.category)
              ? _SexingRows(group: group, onOpen: onOpen)
              : _ProductionRows(records: group.records, onOpen: onOpen),
        ),
      ],
    );
  }
}

class _SexingRows extends StatelessWidget {
  const _SexingRows({required this.group, required this.onOpen});

  final _CategoryGroup group;
  final ValueChanged<_ProductionOverview> onOpen;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    final List<String> statuses = <String>[
      BullSniStatus.bersertifikasi,
      BullSniStatus.belumBersertifikasi,
      '',
    ];
    for (final String status in statuses) {
      final List<_ProductionOverview> records = group.records
          .where((item) => item.statusSni == status)
          .toList(growable: false);
      if (records.isEmpty) continue;
      if (children.isNotEmpty) {
        children.add(const Divider(height: 1));
      }
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 5),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.verified_outlined,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 7),
              Text(
                _sniGroupLabel(status),
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
      children.add(
        _ProductionRows(records: records, onOpen: onOpen),
      );
    }
    return Column(children: children);
  }
}

class _ProductionRows extends StatelessWidget {
  const _ProductionRows({required this.records, required this.onOpen});

  final List<_ProductionOverview> records;
  final ValueChanged<_ProductionOverview> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < records.length; i++) ...<Widget>[
          _ProductionRow(
            item: records[i],
            onTap: () => onOpen(records[i]),
          ),
          if (i != records.length - 1)
            const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ],
    );
  }
}

class _ProductionRow extends StatelessWidget {
  const _ProductionRow({required this.item, required this.onTap});

  final _ProductionOverview item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.breed,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.productionBulls} Pejantan produksi • ${item.availableBulls} tersedia',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  const Text(
                    'Total Stock',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.stock == null ? '-' : _formatNumber(item.stock!),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 23),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.totals,
    required this.month,
    required this.year,
  });

  final _PeriodTotals totals;
  final int month;
  final int year;

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
          Text(
            'TOTAL ${_monthName(month).toUpperCase()} $year',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _TotalRow(label: 'Jumlah Pejantan', value: totals.pejantan),
          _TotalRow(label: 'Stock $year', value: totals.stockTahun),
          const Divider(height: 24),
          const Text(
            'Produksi Mingguan',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _TotalRow(label: 'Minggu I', value: totals.weekI),
          _TotalRow(label: 'Minggu II', value: totals.weekII),
          _TotalRow(label: 'Minggu III', value: totals.weekIII),
          _TotalRow(label: 'Minggu IV', value: totals.weekIV),
          _TotalRow(label: 'Minggu V', value: totals.weekV),
          _TotalRow(
            label: 'Jumlah Produksi',
            value: totals.jumlahProduksi,
            emphasized: true,
          ),
          const Divider(height: 24),
          const Text(
            'Distribusi Bulanan',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _TotalRow(label: 'Komandan', value: totals.komandan),
          _TotalRow(label: 'Non Sikomandan', value: totals.nonSikomandan),
          _TotalRow(
            label: 'Jumlah Distribusi',
            value: totals.jumlahDistribusi,
            emphasized: true,
          ),
          const SizedBox(height: 6),
          _TotalRow(
            label: 'TOTAL STOCK',
            value: totals.stockAkhir,
            emphasized: true,
            primary: true,
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.primary = false,
  });

  final String label;
  final int? value;
  final bool emphasized;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: emphasized
          ? BoxDecoration(
              color: primary ? AppTheme.primarySoft : AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(11),
            )
          : null,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
                color: emphasized
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value == null ? '-' : _formatNumber(value!),
            style: TextStyle(
              fontSize: primary ? 18 : 14,
              fontWeight: FontWeight.w900,
              color: primary ? AppTheme.primaryDark : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGroup {
  const _CategoryGroup({required this.category, required this.records});

  final String category;
  final List<_ProductionOverview> records;
}

class _ProductionOverview {
  const _ProductionOverview({
    required this.record,
    required this.breed,
    required this.statusSni,
    required this.productionBulls,
    required this.availableBulls,
    required this.stock,
  });

  final ActivityRecord record;
  final String breed;
  final String statusSni;
  final int productionBulls;
  final int availableBulls;
  final int? stock;
}

class _PeriodTotals {
  const _PeriodTotals({
    required this.pejantan,
    required this.stockTahun,
    required this.weekI,
    required this.weekII,
    required this.weekIII,
    required this.weekIV,
    required this.weekV,
    required this.jumlahProduksi,
    required this.afkir,
    required this.komandan,
    required this.nonSikomandan,
    required this.jumlahDistribusi,
    required this.stockAkhir,
  });

  final int? pejantan;
  final int? stockTahun;
  final int? weekI;
  final int? weekII;
  final int? weekIII;
  final int? weekIV;
  final int? weekV;
  final int? jumlahProduksi;
  final int? afkir;
  final int? komandan;
  final int? nonSikomandan;
  final int? jumlahDistribusi;
  final int? stockAkhir;

  factory _PeriodTotals.fromRecords({
    required List<ActivityRecord> records,
    required int? year,
  }) {
    int? sumKey(String key, {String? fallbackKey}) {
      final List<dynamic> values = records
          .map((record) {
            final dynamic primary = record.data[key];
            if (_hasValue(primary)) return primary;
            if (fallbackKey != null) return record.data[fallbackKey];
            return null;
          })
          .where(_hasValue)
          .toList(growable: false);
      if (values.isEmpty) return null;
      return values.fold<int>(0, (sum, value) => sum + _asInt(value));
    }

    return _PeriodTotals(
      pejantan: records.isEmpty
          ? null
          : records.fold<int>(
              0,
              (sum, record) => sum + _asInt(record.data['jumlah_pejantan']),
            ),
      stockTahun: sumKey('stock_tahun', fallbackKey: 'stock_awal'),
      weekI: sumKey('produksi_minggu_i'),
      weekII: sumKey('produksi_minggu_ii'),
      weekIII: sumKey('produksi_minggu_iii'),
      weekIV: sumKey('produksi_minggu_iv'),
      weekV: sumKey('produksi_minggu_v'),
      jumlahProduksi: sumKey('jumlah_produksi'),
      afkir: sumKey('afkir'),
      komandan: sumKey('distribusi_komandan'),
      nonSikomandan: sumKey('distribusi_non_sikomandan'),
      jumlahDistribusi: sumKey('jumlah_distribusi'),
      stockAkhir: sumKey('stock_akhir'),
    );
  }
}

bool _isSexingCategory(String value) =>
    _normalize(_canonicalCategory(value)) == 'sexing';

int _sniSortOrder(dynamic value) {
  final String normalized = BullSniStatus.normalize(value?.toString());
  if (normalized == BullSniStatus.bersertifikasi) return 0;
  if (normalized == BullSniStatus.belumBersertifikasi) return 1;
  return 2;
}

String _sniGroupLabel(String status) {
  if (status == BullSniStatus.bersertifikasi) return 'SNI';
  if (status == BullSniStatus.belumBersertifikasi) return 'NON SNI';
  return 'BELUM TERKLASIFIKASI';
}

String _canonicalCategory(String value) {
  final String normalized = _normalize(value);
  if (normalized == 'sapi potong') return 'Sapi Potong';
  if (normalized == 'kerbau') return 'Kerbau';
  if (normalized == 'sexing') return 'Sexing';
  if (normalized == 'non-lspro') return 'Non-LSPro';
  return value.trim();
}

bool _hasValue(dynamic value) =>
    value != null && value.toString().trim().isNotEmpty;

String _normalize(dynamic value) =>
    value?.toString().trim().toLowerCase() ?? '';

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatNumber(int value) {
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

String _monthName(int month) {
  const List<String> months = <String>[
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  if (month < 1 || month > 12) return 'Bulan';
  return months[month - 1];
}
