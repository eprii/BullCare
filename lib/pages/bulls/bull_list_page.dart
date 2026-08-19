import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/bull_model.dart';
import '../../models/user_model.dart';
import '../../services/bull_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_feedback.dart';
import '../../utils/bull_sni_status.dart';
import '../../utils/bull_status.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'bull_form_page.dart';
import 'bull_profile_page.dart';

class BullListPage extends StatefulWidget {
  const BullListPage({
    super.key,
    required this.user,
    this.selectionMode = false,
    this.onDataChanged,
  });

  final UserModel user;
  final bool selectionMode;
  final VoidCallback? onDataChanged;

  @override
  State<BullListPage> createState() => _BullListPageState();
}

class _BullListPageState extends State<BullListPage> {
  final BullService _service = BullService();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = '';
  String _breedFilter = '';
  _BullSortMode _sortMode = _BullSortMode.none;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addBull() async {
    if (!widget.user.isPetugas) return;

    final String? id = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => BullFormPage(user: widget.user),
      ),
    );
    if (id != null && mounted) {
      widget.onDataChanged?.call();
      AppFeedback.showSuccess(context, 'Berhasil menambah bull.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFB),
      appBar: AppBar(
        toolbarHeight: 72,
        centerTitle: false,
        titleSpacing: widget.selectionMode ? 0 : 18,
        title: Text(
          widget.selectionMode ? 'Pilih Bull' : 'Data Bull',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.45,
          ),
        ),
        automaticallyImplyLeading: widget.selectionMode,
      ),
      body: SafeArea(
        top: false,
        child: AppPageContainer(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 2),
              _searchAndFilterRow(),
              const SizedBox(height: 14),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
      floatingActionButton: !widget.selectionMode && widget.user.isPetugas
          ? FloatingActionButton(
              onPressed: _addBull,
              tooltip: 'Tambah Bull',
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
    );
  }

  Widget _buildContent() {
    return StreamBuilder<List<BullModel>>(
      stream: _service.watchBulls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        if (snapshot.hasError) {
          return ErrorView(message: snapshot.error.toString());
        }

        final String normalizedQuery = _query.trim().toLowerCase();
        final String normalizedBreedFilter = _breedFilter.trim().toLowerCase();
        final List<BullModel> bulls = (snapshot.data ?? <BullModel>[])
            .where((bull) {
              final String haystack =
                  '${bull.nama} ${bull.kode_bull} ${bull.bangsa} ${bull.nomor_kandang} ${bull.umur}'
                      .toLowerCase();
              final bool matchesQuery = normalizedQuery.isEmpty ||
                  haystack.contains(normalizedQuery);
              final bool matchesStatus = _statusFilter.isEmpty ||
                  BullStatus.normalize(bull.status) == _statusFilter;
              final bool matchesBreed = normalizedBreedFilter.isEmpty ||
                  bull.bangsa.trim().toLowerCase() == normalizedBreedFilter;
              return matchesQuery && matchesStatus && matchesBreed;
            })
            .toList();

        _sortBulls(bulls);

        final bool noFilter = _query.isEmpty &&
            _statusFilter.isEmpty &&
            _breedFilter.isEmpty;

        if (bulls.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: noFilter ? 'Belum ada data bull' : 'Bull tidak ditemukan',
            message: noFilter
                ? widget.user.isPetugas
                    ? 'Tambahkan data bull pertama untuk mulai mencatat aktivitas pemeliharaan.'
                    : 'Belum ada data bull yang dapat ditampilkan.'
                : 'Ubah pencarian atau filter dan coba kembali.',
            action: widget.user.isPetugas && noFilter
                ? FilledButton.icon(
                    onPressed: _addBull,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Bull'),
                  )
                : null,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            0,
            0,
            0,
            widget.selectionMode || !widget.user.isPetugas ? 24 : 96,
          ),
          itemCount: bulls.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final BullModel bull = bulls[index];
            return _BullCard(
              bull: bull,
              imageIndex: _imageIndexForBull(bull),
              onTap: () => _openBull(bull),
            );
          },
        );
      },
    );
  }

  int _imageIndexForBull(BullModel bull) {
    final String seed = bull.id.isNotEmpty ? bull.id : bull.kode_bull;
    if (seed.isEmpty) return 1;
    int sum = 0;
    for (final int codeUnit in seed.codeUnits) {
      sum += codeUnit;
    }
    return (sum % 4) + 1;
  }

  Future<void> _openBull(BullModel bull) async {
    if (widget.selectionMode) {
      Navigator.of(context).pop(bull);
      return;
    }

    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => BullProfilePage(
          bullId: bull.id,
          user: widget.user,
          onDataChanged: widget.onDataChanged,
        ),
      ),
    );
    if (result == 'deleted' && mounted) {
      AppFeedback.showSuccess(context, 'Berhasil menghapus bull.');
    }
  }

  Widget _searchAndFilterRow() {
    return Row(
      children: <Widget>[
        Expanded(child: _searchField()),
        const SizedBox(width: 10),
        _filterButton(),
      ],
    );
  }

  Widget _searchField() {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Cari bull...',
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          prefixIconConstraints: const BoxConstraints(minWidth: 42),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          fillColor: const Color(0xFFF6F6F5),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _filterButton() {
    final int activeCount = (_statusFilter.isNotEmpty ? 1 : 0) +
        (_breedFilter.isNotEmpty ? 1 : 0) +
        (_sortMode != _BullSortMode.none ? 1 : 0);
    final bool filterActive = activeCount > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _openFilterSheet,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: filterActive ? AppTheme.primarySoft : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: filterActive
                    ? AppTheme.primary.withValues(alpha: 0.35)
                    : const Color(0xFFE2E4E1),
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 22,
              color: filterActive
                  ? AppTheme.primary
                  : const Color(0xFF4E5650),
            ),
          ),
          if (filterActive)
            Positioned(
              right: -4,
              top: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _sortBulls(List<BullModel> bulls) {
    switch (_sortMode) {
      case _BullSortMode.nameAsc:
        bulls.sort((a, b) => _compareNames(a, b));
        break;
      case _BullSortMode.nameDesc:
        bulls.sort((a, b) => _compareNames(b, a));
        break;
      case _BullSortMode.ageAsc:
        bulls.sort((a, b) => _compareAges(a, b, ascending: true));
        break;
      case _BullSortMode.ageDesc:
        bulls.sort((a, b) => _compareAges(a, b, ascending: false));
        break;
      case _BullSortMode.none:
        break;
    }
  }

  int _compareNames(BullModel a, BullModel b) {
    final String nameA = a.nama.trim().toLowerCase();
    final String nameB = b.nama.trim().toLowerCase();
    final int nameResult = nameA.compareTo(nameB);
    if (nameResult != 0) return nameResult;
    return a.kode_bull.trim().toLowerCase().compareTo(
          b.kode_bull.trim().toLowerCase(),
        );
  }

  int _compareAges(
    BullModel a,
    BullModel b, {
    required bool ascending,
  }) {
    final double? ageA = _parseAge(a.umur);
    final double? ageB = _parseAge(b.umur);

    if (ageA == null && ageB == null) return _compareNames(a, b);
    if (ageA == null) return 1;
    if (ageB == null) return -1;

    final int result = ageA.compareTo(ageB);
    if (result == 0) return _compareNames(a, b);
    return ascending ? result : -result;
  }

  double? _parseAge(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  Future<void> _openFilterSheet() async {
    String tempStatus = _statusFilter;
    String tempBreed = _breedFilter;
    _BullSortMode tempSort = _sortMode;

    final _BullFilterResult? result =
        await showModalBottomSheet<_BullFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Align(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD8DAD7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            const Expanded(
                              child: Text(
                                'Filter Data Bull',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.35,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Tutup',
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Urutkan data',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 9,
                          runSpacing: 9,
                          children: <Widget>[
                            _FilterOptionChip(
                              label: 'Default',
                              selected: tempSort == _BullSortMode.none,
                              onTap: () => setSheetState(
                                () => tempSort = _BullSortMode.none,
                              ),
                            ),
                            _FilterOptionChip(
                              label: 'Nama A–Z',
                              selected: tempSort == _BullSortMode.nameAsc,
                              onTap: () => setSheetState(
                                () => tempSort = _BullSortMode.nameAsc,
                              ),
                            ),
                            _FilterOptionChip(
                              label: 'Nama Z–A',
                              selected: tempSort == _BullSortMode.nameDesc,
                              onTap: () => setSheetState(
                                () => tempSort = _BullSortMode.nameDesc,
                              ),
                            ),
                            _FilterOptionChip(
                              label: 'Umur termuda',
                              selected: tempSort == _BullSortMode.ageAsc,
                              onTap: () => setSheetState(
                                () => tempSort = _BullSortMode.ageAsc,
                              ),
                            ),
                            _FilterOptionChip(
                              label: 'Umur tertua',
                              selected: tempSort == _BullSortMode.ageDesc,
                              onTap: () => setSheetState(
                                () => tempSort = _BullSortMode.ageDesc,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Bangsa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<List<BullModel>>(
                          stream: _service.watchBulls(),
                          builder: (context, snapshot) {
                            final List<String> breeds = (snapshot.data ?? <BullModel>[])
                                .map((bull) => bull.bangsa.trim())
                                .where((breed) => breed.isNotEmpty)
                                .toSet()
                                .toList()
                              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                            if (tempBreed.isNotEmpty && !breeds.contains(tempBreed)) {
                              breeds.add(tempBreed);
                              breeds.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                            }

                            return DropdownButtonFormField<String>(
                              initialValue: tempBreed,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.category_outlined),
                                filled: true,
                                fillColor: Color(0xFFF7F7F5),
                              ),
                              items: <DropdownMenuItem<String>>[
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('Semua bangsa'),
                                ),
                                ...breeds.map(
                                  (breed) => DropdownMenuItem<String>(
                                    value: breed,
                                    child: Text(breed),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setSheetState(() => tempBreed = value ?? '');
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Status kesehatan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 9,
                          runSpacing: 9,
                          children: <Widget>[
                            _FilterOptionChip(
                              label: 'Semua',
                              selected: tempStatus.isEmpty,
                              onTap: () => setSheetState(() => tempStatus = ''),
                            ),
                            ...BullStatus.values.map(
                              (String status) => _FilterOptionChip(
                                label: status,
                                selected: tempStatus == status,
                                onTap: () => setSheetState(
                                  () => tempStatus = status,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop(
                                    const _BullFilterResult(
                                      status: '',
                                      breed: '',
                                      sortMode: _BullSortMode.none,
                                    ),
                                  );
                                },
                                child: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(sheetContext).pop(
                                    _BullFilterResult(
                                      status: tempStatus,
                                      breed: tempBreed,
                                      sortMode: tempSort,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Terapkan Filter'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      _statusFilter = result.status;
      _breedFilter = result.breed;
      _sortMode = result.sortMode;
    });
  }

}

enum _BullSortMode { none, nameAsc, nameDesc, ageAsc, ageDesc }

class _BullFilterResult {
  const _BullFilterResult({
    required this.status,
    required this.breed,
    required this.sortMode,
  });

  final String status;
  final String breed;
  final _BullSortMode sortMode;
}

class _FilterOptionChip extends StatelessWidget {
  const _FilterOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primarySoft : const Color(0xFFF7F7F5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.38)
                : const Color(0xFFE4E6E2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (selected) ...<Widget>[
              const Icon(
                Icons.check_circle_rounded,
                size: 17,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppTheme.primaryDark
                    : const Color(0xFF454A46),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BullCard extends StatelessWidget {
  const _BullCard({
    required this.bull,
    required this.imageIndex,
    required this.onTap,
  });

  final BullModel bull;
  final int imageIndex;
  final VoidCallback onTap;

  String _bullDisplayName(BullModel bull, String fallbackName) {
    final String name = bull.nama.trim();
    final String code = bull.kode_bull.trim();
    if (name.isEmpty) return code.isEmpty ? fallbackName : code;
    if (code.isEmpty) return name;
    return '$name ($code)';
  }

  @override
  Widget build(BuildContext context) {
    final String breed = bull.bangsa.trim().isEmpty ? '-' : bull.bangsa.trim();
    final String name = bull.nama.trim().isEmpty ? 'Bull' : bull.nama.trim();
    final String cage = bull.nomor_kandang.trim().isEmpty
        ? 'Kandang -'
        : 'Kandang ${bull.nomor_kandang.trim()}';
    final String age = bull.umur.trim().isEmpty
        ? 'Umur -'
        : '${bull.umur.trim()} Tahun';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 122,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0F0EE)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(7),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 92,
                    height: 108,
                    child: _BullPhoto(
                      photoBase64: bull.foto_base64,
                      fallbackAsset: 'assets/bulls/bull_$imageIndex.jpg',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 13, 2, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _bullDisplayName(bull, name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF242724),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        breed,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF60665F),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$age  •  $cage',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4D534E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: <Widget>[
                          _StatusBadge(status: bull.status),
                          _SniStatusBadge(statusSni: bull.status_sni),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF555B56),
                  size: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SniStatusBadge extends StatelessWidget {
  const _SniStatusBadge({required this.statusSni});

  final String statusSni;

  @override
  Widget build(BuildContext context) {
    final String normalized = BullSniStatus.normalize(statusSni);
    final bool certified = normalized == BullSniStatus.bersertifikasi;
    final bool hasStatus = normalized.isNotEmpty;

    final Color foreground = certified
        ? const Color(0xFF176B3A)
        : hasStatus
            ? const Color(0xFF8A5A00)
            : const Color(0xFF69716B);
    final Color background = certified
        ? const Color(0xFFE4F6EA)
        : hasStatus
            ? const Color(0xFFFFF4D8)
            : const Color(0xFFF0F2F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        BullSniStatus.label(statusSni),
        style: TextStyle(
          color: foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BullPhoto extends StatelessWidget {
  const _BullPhoto({required this.photoBase64, required this.fallbackAsset});

  final String photoBase64;
  final String fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final String encoded = photoBase64.trim();
    if (encoded.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(encoded),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        );
      } catch (_) {
        // Jika data foto lama/rusak, gunakan aset bawaan agar daftar tetap aman.
      }
    }

    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final String normalizedStatus = BullStatus.normalize(status);
    final Color foreground;
    final Color background;

    switch (normalizedStatus) {
      case BullStatus.butuhVaksin:
        foreground = const Color(0xFFE66D00);
        background = const Color(0xFFFFF0DF);
        break;
      case BullStatus.tidakSehat:
        foreground = const Color(0xFFB2392F);
        background = const Color(0xFFFFE8E5);
        break;
      default:
        foreground = const Color(0xFF24753A);
        background = const Color(0xFFE9F7EA);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalizedStatus,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          height: 1,
          color: foreground,
        ),
      ),
    );
  }
}
