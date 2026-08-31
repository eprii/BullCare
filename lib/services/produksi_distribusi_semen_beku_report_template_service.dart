import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity_record.dart';
import '../models/report_export_data.dart';
import '../models/user_model.dart';
import '../utils/bull_breed_name.dart';
import '../utils/bull_sni_status.dart';

class ProduksiDistribusiSemenBekuReportTemplateService {
  const ProduksiDistribusiSemenBekuReportTemplateService();

  static const String _excelTemplateAsset =
      'assets/templates/form_produksi_distribusi_semen_beku.xlsx';

  static const List<String> _categoryOrder = <String>[
    'Sapi Potong',
    'Kerbau',
    'Sexing',
    'Non-LSPro',
  ];

  Future<Uint8List> buildPdf({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    final pw.Document document = pw.Document(
      title: 'Laporan Produksi dan Distribusi Semen Beku',
      author: exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama,
      creator: 'BullCare',
    );
    final List<_PeriodGroup> periods = _periodGroups(data.records);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 26),
        maxPages: 200,
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ),
        build: (context) {
          final List<pw.Widget> widgets = <pw.Widget>[];
          for (int index = 0; index < periods.length; index++) {
            final _PeriodGroup period = periods[index];
            if (index > 0) widgets.add(pw.NewPage());
            widgets.addAll(_pdfPeriod(period));
          }
          return widgets;
        },
      ),
    );

    return document.save();
  }

  Future<Uint8List> buildDocx({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    final Archive archive = Archive();
    final DateTime now = DateTime.now().toUtc();
    final List<_PeriodGroup> periods = _periodGroups(data.records);

    final Map<String, String> files = <String, String>{
      '[Content_Types].xml': _contentTypesXml,
      '_rels/.rels': _rootRelationshipsXml,
      'docProps/core.xml': _corePropertiesXml(exportedBy, now),
      'docProps/app.xml': _appPropertiesXml,
      'word/document.xml': _documentXml(periods, exportedBy),
      'word/styles.xml': _stylesXml,
      'word/_rels/document.xml.rels': _documentRelationshipsXml,
    };

    for (final MapEntry<String, String> entry in files.entries) {
      archive.addFile(ArchiveFile.string(entry.key, entry.value));
    }
    return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
  }

  Future<Uint8List> buildXlsx({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    final List<_PeriodGroup> periods = _periodGroups(data.records);
    if (periods.length != 1) {
      throw StateError(
        'Laporan Excel Produksi & Distribusi Semen Beku harus dibuat untuk satu bulan dan satu tahun.',
      );
    }

    final _PeriodGroup period = periods.single;
    final _ExcelSheetBuild sheetBuild = _buildExcelSheet(period);
    final ByteData templateData = await rootBundle.load(_excelTemplateAsset);
    final Uint8List templateBytes = templateData.buffer.asUint8List(
      templateData.offsetInBytes,
      templateData.lengthInBytes,
    );
    final Archive sourceArchive = ZipDecoder().decodeBytes(templateBytes);
    final Archive outputArchive = Archive();

    for (final ArchiveFile file in sourceArchive) {
      if (!file.isFile || file.name == 'xl/calcChain.xml') continue;
      final Uint8List content = file.readBytes() ?? Uint8List(0);
      Uint8List patched = content;

      if (file.name == 'xl/worksheets/sheet1.xml') {
        patched = Uint8List.fromList(utf8.encode(sheetBuild.xml));
      } else if (file.name == 'xl/workbook.xml') {
        patched = Uint8List.fromList(
          utf8.encode(
            _patchExcelWorkbookXml(
              utf8.decode(content),
              sheetBuild.printEndRow,
            ),
          ),
        );
      } else if (file.name == 'xl/_rels/workbook.xml.rels') {
        patched = Uint8List.fromList(
          utf8.encode(_removeCalcChainRelationship(utf8.decode(content))),
        );
      } else if (file.name == '[Content_Types].xml') {
        patched = Uint8List.fromList(
          utf8.encode(_removeCalcChainContentType(utf8.decode(content))),
        );
      } else if (file.name == 'docProps/core.xml') {
        patched = Uint8List.fromList(
          utf8.encode(_patchExcelCoreProperties(utf8.decode(content), exportedBy)),
        );
      }

      outputArchive.addFile(ArchiveFile(file.name, patched.length, patched));
    }

    return Uint8List.fromList(ZipEncoder().encodeBytes(outputArchive));
  }

  _ExcelSheetBuild _buildExcelSheet(_PeriodGroup period) {
    final StringBuffer rows = StringBuffer();
    rows
      ..write(_excelRow(1, <String>[
        _excelEmptyCell('A1', 1),
        _excelEmptyCell('B1', 1),
        _excelEmptyCell('C1', 1),
        _excelEmptyCell('D1', 2),
        _excelEmptyCell('E1', 2),
        _excelEmptyCell('F1', 2),
      ], height: 17.4))
      ..write(_excelRow(2, <String>[
        _excelEmptyCell('A2', 1),
        _excelEmptyCell('B2', 1),
        _excelEmptyCell('C2', 1),
        _excelEmptyCell('D2', 52),
        _excelEmptyCell('E2', 52),
        _excelEmptyCell('F2', 52),
        _excelEmptyCell('G2', 52),
        _excelEmptyCell('H2', 52),
        _excelEmptyCell('I2', 52),
        _excelEmptyCell('J2', 53),
        _excelEmptyCell('K2', 53),
        _excelEmptyCell('L2', 53),
        _excelEmptyCell('M2', 53),
        _excelEmptyCell('N2', 53),
        _excelEmptyCell('O2', 53),
      ], height: 17.4))
      ..write(_excelRow(3, <String>[
        _excelEmptyCell('A3', 54),
        _excelInlineCell('B3', 54, 'RUMPUN'),
        _excelInlineCell('C3', 55, 'JUMLAH PEJANTAN'),
        _excelInlineCell('D3', 58, 'STOCK ${period.year}'),
        _excelInlineCell(
          'E3',
          59,
          'BULAN ${_monthName(period.month).toUpperCase()} ${period.year}',
        ),
        _excelEmptyCell('F3', 60),
        _excelEmptyCell('G3', 60),
        _excelEmptyCell('H3', 60),
        _excelEmptyCell('I3', 60),
        _excelEmptyCell('J3', 60),
        _excelEmptyCell('K3', 60),
        _excelEmptyCell('L3', 60),
        _excelEmptyCell('M3', 60),
        _excelEmptyCell('N3', 61),
        _excelInlineCell('O3', 62, 'STOCK'),
      ], height: 25.2))
      ..write(_excelRow(4, <String>[
        _excelEmptyCell('A4', 54),
        _excelEmptyCell('B4', 54),
        _excelEmptyCell('C4', 56),
        _excelEmptyCell('D4', 58),
        _excelInlineCell('E4', 65, 'PRODUKSI MINGGUAN'),
        _excelEmptyCell('F4', 66),
        _excelEmptyCell('G4', 66),
        _excelEmptyCell('H4', 66),
        _excelEmptyCell('I4', 66),
        _excelEmptyCell('J4', 67),
        _excelInlineCell('K4', 68, 'AFKIR'),
        _excelInlineCell('L4', 70, 'DISTRIBUSI BULANAN'),
        _excelEmptyCell('M4', 70),
        _excelEmptyCell('N4', 70),
        _excelEmptyCell('O4', 63),
      ], height: 25.2))
      ..write(_excelRow(5, <String>[
        _excelEmptyCell('A5', 54),
        _excelEmptyCell('B5', 54),
        _excelEmptyCell('C5', 57),
        _excelEmptyCell('D5', 58),
        _excelInlineCell('E5', 38, 'I'),
        _excelInlineCell('F5', 38, 'II'),
        _excelInlineCell('G5', 38, 'III'),
        _excelInlineCell('H5', 38, 'IV'),
        _excelInlineCell('I5', 38, 'V'),
        _excelInlineCell('J5', 25, 'JUMLAH'),
        _excelEmptyCell('K5', 69),
        _excelInlineCell('L5', 3, 'KOMANDAN'),
        _excelInlineCell('M5', 3, 'NON SIKOMANDAN'),
        _excelInlineCell('N5', 39, 'JUMLAH'),
        _excelEmptyCell('O5', 64),
      ], height: 37.2));

    int row = 6;
    final List<int> dataRows = <int>[];
    final List<ActivityRecord> allRecords = <ActivityRecord>[];

    for (final _CategoryRows category in period.categories) {
      if (category.records.isEmpty && !_categoryOrder.contains(category.category)) {
        continue;
      }
      rows.write(_excelCategoryRow(row, category.category.toUpperCase()));
      row++;

      if (_isSexing(category.category)) {
        final List<ActivityRecord> sexing = List<ActivityRecord>.from(category.records)
          ..sort((a, b) {
            final String breedA =
                BullBreedName.canonical(a.data['bangsa']?.toString());
            final String breedB =
                BullBreedName.canonical(b.data['bangsa']?.toString());
            final int breedCompare =
                breedA.toLowerCase().compareTo(breedB.toLowerCase());
            if (breedCompare != 0) return breedCompare;
            return _sexingStatusRank(a).compareTo(_sexingStatusRank(b));
          });
        String previousBreed = '';
        int number = 0;
        for (final ActivityRecord record in sexing) {
          final String breed =
              BullBreedName.canonical(record.data['bangsa']?.toString());
          final String normalizedBreed = _normalize(breed);
          final bool firstForBreed = normalizedBreed != previousBreed;
          if (firstForBreed) {
            number++;
            previousBreed = normalizedBreed;
          }
          final String status =
              BullSniStatus.normalize(record.data['status_sni']?.toString());
          final String suffix = status == BullSniStatus.belumBersertifikasi
              ? ' (NON SNI)'
              : status.isEmpty
                  ? ' (BELUM TERKLASIFIKASI)'
                  : '';
          rows.write(
            _excelDataRow(
              row,
              record,
              number: firstForBreed ? number : null,
              breedLabel: '${breed.toUpperCase()} Sexing$suffix',
            ),
          );
          dataRows.add(row);
          allRecords.add(record);
          row++;
        }
      } else {
        int number = 1;
        for (final ActivityRecord record in category.records) {
          final String breed =
              BullBreedName.canonical(record.data['bangsa']?.toString());
          rows.write(
            _excelDataRow(
              row,
              record,
              number: number,
              breedLabel: breed.toUpperCase(),
            ),
          );
          dataRows.add(row);
          allRecords.add(record);
          row++;
          number++;
        }
      }
    }

    final int totalRow = row;
    final int firstDataRow = dataRows.isEmpty ? 7 : dataRows.first;
    final int lastDataRow = dataRows.isEmpty ? firstDataRow : dataRows.last;
    rows.write(
      _excelTotalRow(
        totalRow,
        firstDataRow: firstDataRow,
        lastDataRow: lastDataRow,
        records: allRecords,
      ),
    );

    final int knowingRow = totalRow + 2;
    final int titleRow = totalRow + 3;
    final int nameRow = totalRow + 7;
    final int nipRow = totalRow + 8;
    rows
      ..write(_excelSignatureRow(
        knowingRow,
        left: 'Mengetahui, ',
        right:
            'Banjarbaru,${DateTime(period.year, period.month + 1, 0).day} ${_monthName(period.month)} ${period.year}',
      ))
      ..write(_excelSignatureRow(
        titleRow,
        left: 'Kepala Balai Inseminasi Buatan',
        right: 'Kepala Seksi Produksi dan Distribusi',
      ))
      ..write(_excelSignatureRow(
        nameRow,
        left: 'drh. Sasongko Nugroho',
        right: 'Nelly Yanur, S.Pt',
      ))
      ..write(_excelSignatureRow(
        nipRow,
        left: 'NIP. 19790523 200803 1 002',
        right: 'NIP. 19830105 200604 2 012',
      ));

    final int dimensionEndRow = nipRow > 45 ? nipRow : 45;
    final String xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac" xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac">
<dimension ref="A1:O$dimensionEndRow"/>
<sheetViews><sheetView tabSelected="1" view="pageBreakPreview" zoomScale="60" zoomScaleNormal="60" workbookViewId="0"><selection activeCell="A1" sqref="A1"/></sheetView></sheetViews>
<sheetFormatPr defaultRowHeight="14.4" x14ac:dyDescent="0.3"/>
<cols><col min="2" max="2" width="47" customWidth="1"/><col min="3" max="3" width="16.33203125" customWidth="1"/><col min="4" max="4" width="17" customWidth="1"/><col min="5" max="6" width="10.88671875" customWidth="1"/><col min="7" max="8" width="10.44140625" customWidth="1"/><col min="9" max="9" width="10.5546875" customWidth="1"/><col min="10" max="10" width="14.33203125" customWidth="1"/><col min="11" max="11" width="14.5546875" customWidth="1"/><col min="12" max="12" width="17.6640625" customWidth="1"/><col min="13" max="13" width="20.5546875" customWidth="1"/><col min="14" max="14" width="13.6640625" customWidth="1"/><col min="15" max="15" width="16" customWidth="1"/></cols>
<sheetData>$rows</sheetData>
<mergeCells count="11"><mergeCell ref="A$totalRow:B$totalRow"/><mergeCell ref="D2:O2"/><mergeCell ref="A3:A5"/><mergeCell ref="B3:B5"/><mergeCell ref="C3:C5"/><mergeCell ref="D3:D5"/><mergeCell ref="E3:N3"/><mergeCell ref="O3:O5"/><mergeCell ref="E4:J4"/><mergeCell ref="K4:K5"/><mergeCell ref="L4:N4"/></mergeCells>
<pageMargins left="0.70866141732283472" right="0.70866141732283472" top="0.74803149606299213" bottom="0.74803149606299213" header="0.31496062992125984" footer="0.31496062992125984"/>
<pageSetup paperSize="9" scale="55" orientation="landscape" horizontalDpi="4294967293" r:id="rId1"/>
</worksheet>''';

    return _ExcelSheetBuild(xml: xml, printEndRow: nipRow);
  }

  String _excelCategoryRow(int row, String label) => _excelRow(
        row,
        <String>[
          _excelEmptyCell('A$row', 4),
          _excelInlineCell('B$row', 33, label),
          _excelEmptyCell('C$row', 5),
          _excelEmptyCell('D$row', 6),
          _excelEmptyCell('E$row', 6),
          _excelEmptyCell('F$row', 6),
          _excelEmptyCell('G$row', 6),
          _excelEmptyCell('H$row', 6),
          _excelEmptyCell('I$row', 6),
          _excelEmptyCell('J$row', 7),
          _excelEmptyCell('K$row', 37),
          _excelEmptyCell('L$row', 8),
          _excelEmptyCell('M$row', 13),
          _excelEmptyCell('N$row', 13),
          _excelEmptyCell('O$row', 9),
        ],
        height: 17.4,
      );

  String _excelDataRow(
    int row,
    ActivityRecord record, {
    required int? number,
    required String breedLabel,
  }) {
    final int? stock = _excelOptionalInt(_stockRawValue(record));
    final List<int?> weekly = <int?>[
      _excelOptionalInt(record.data['produksi_minggu_i']),
      _excelOptionalInt(record.data['produksi_minggu_ii']),
      _excelOptionalInt(record.data['produksi_minggu_iii']),
      _excelOptionalInt(record.data['produksi_minggu_iv']),
      _excelOptionalInt(record.data['produksi_minggu_v']),
    ];
    final int? afkir = _excelOptionalInt(record.data['afkir']);
    final int? komandan =
        _excelOptionalInt(record.data['distribusi_komandan']);
    final int? nonSikomandan =
        _excelOptionalInt(record.data['distribusi_non_sikomandan']);
    final bool hasProduction = weekly.any((value) => value != null);
    final int productionTotal =
        weekly.fold<int>(0, (total, value) => total + (value ?? 0));
    final bool hasDistribution = komandan != null || nonSikomandan != null;
    final int distributionTotal = (komandan ?? 0) + (nonSikomandan ?? 0);
    final bool hasStockResult =
        stock != null || hasProduction || afkir != null || hasDistribution;
    final int stockResult =
        (stock ?? 0) + productionTotal - (afkir ?? 0) - distributionTotal;

    return _excelRow(
      row,
      <String>[
        number == null
            ? _excelEmptyCell('A$row', 26)
            : _excelNumberCell('A$row', 26, number),
        _excelInlineCell('B$row', 19, breedLabel),
        _excelNumberOrDashCell(
          'C$row',
          23,
          _excelOptionalInt(record.data['jumlah_pejantan']),
        ),
        _excelNumberOrDashCell('D$row', 11, stock),
        _excelNumberOrDashCell('E$row', 36, weekly[0]),
        _excelNumberOrDashCell('F$row', 36, weekly[1]),
        _excelNumberOrDashCell('G$row', 36, weekly[2]),
        _excelNumberOrDashCell('H$row', 36, weekly[3]),
        _excelNumberOrDashCell('I$row', 36, weekly[4]),
        _excelFormulaOrDashCell(
          'J$row',
          31,
          'IF(COUNT(E$row:I$row)=0,"-",SUM(E$row:I$row))',
          hasProduction ? productionTotal : null,
        ),
        _excelNumberOrDashCell('K$row', 36, afkir),
        _excelNumberOrDashCell('L$row', 36, komandan),
        _excelNumberOrDashCell('M$row', 36, nonSikomandan),
        _excelFormulaOrDashCell(
          'N$row',
          36,
          'IF(COUNT(L$row:M$row)=0,"-",SUM(L$row:M$row))',
          hasDistribution ? distributionTotal : null,
        ),
        _excelFormulaOrDashCell(
          'O$row',
          11,
          'IF(COUNT(D$row,J$row,K$row,N$row)=0,"-",SUM(D$row,J$row)-SUM(K$row,N$row))',
          hasStockResult ? stockResult : null,
        ),
      ],
      height: 17.4,
    );
  }

  String _excelTotalRow(
    int row, {
    required int firstDataRow,
    required int lastDataRow,
    required List<ActivityRecord> records,
  }) {
    int sum(String key) => records.fold<int>(
          0,
          (total, record) =>
              total + (_excelOptionalInt(record.data[key]) ?? 0),
        );
    int stockSum() => records.fold<int>(
          0,
          (total, record) =>
              total + (_excelOptionalInt(_stockRawValue(record)) ?? 0),
        );
    bool has(String key) => records.any(
          (record) => _excelOptionalInt(record.data[key]) != null,
        );
    final bool hasStock = records.any(
      (record) => _excelOptionalInt(_stockRawValue(record)) != null,
    );

    final Map<String, int> totals = <String, int>{
      'C': sum('jumlah_pejantan'),
      'D': stockSum(),
      'E': sum('produksi_minggu_i'),
      'F': sum('produksi_minggu_ii'),
      'G': sum('produksi_minggu_iii'),
      'H': sum('produksi_minggu_iv'),
      'I': sum('produksi_minggu_v'),
      'J': records.fold<int>(
        0,
        (total, record) =>
            total +
            <String>[
              'produksi_minggu_i',
              'produksi_minggu_ii',
              'produksi_minggu_iii',
              'produksi_minggu_iv',
              'produksi_minggu_v',
            ].fold<int>(
              0,
              (weeklyTotal, key) =>
                  weeklyTotal + (_excelOptionalInt(record.data[key]) ?? 0),
            ),
      ),
      'K': sum('afkir'),
      'L': sum('distribusi_komandan'),
      'M': sum('distribusi_non_sikomandan'),
      'N': records.fold<int>(
        0,
        (total, record) =>
            total +
            (_excelOptionalInt(record.data['distribusi_komandan']) ?? 0) +
            (_excelOptionalInt(record.data['distribusi_non_sikomandan']) ?? 0),
      ),
      'O': records.fold<int>(
        0,
        (total, record) =>
            total + (_excelOptionalInt(record.data['stock_akhir']) ?? 0),
      ),
    };
    final Map<String, bool> present = <String, bool>{
      'C': records.isNotEmpty,
      'D': hasStock,
      'E': has('produksi_minggu_i'),
      'F': has('produksi_minggu_ii'),
      'G': has('produksi_minggu_iii'),
      'H': has('produksi_minggu_iv'),
      'I': has('produksi_minggu_v'),
      'J': records.any(
        (record) => <String>[
          'produksi_minggu_i',
          'produksi_minggu_ii',
          'produksi_minggu_iii',
          'produksi_minggu_iv',
          'produksi_minggu_v',
        ].any((key) => _excelOptionalInt(record.data[key]) != null),
      ),
      'K': has('afkir'),
      'L': has('distribusi_komandan'),
      'M': has('distribusi_non_sikomandan'),
      'N': records.any(
        (record) =>
            _excelOptionalInt(record.data['distribusi_komandan']) != null ||
            _excelOptionalInt(record.data['distribusi_non_sikomandan']) != null,
      ),
      'O': records.isNotEmpty,
    };

    String totalCell(String column, int style) {
      final String range = '$column$firstDataRow:$column$lastDataRow';
      return _excelFormulaOrDashCell(
        '$column$row',
        style,
        'IF(COUNT($range)=0,"-",SUM($range))',
        present[column]! ? totals[column] : null,
      );
    }

    return _excelRow(
      row,
      <String>[
        _excelInlineCell('A$row', 50, 'Total'),
        _excelEmptyCell('B$row', 51),
        totalCell('C', 22),
        totalCell('D', 22),
        totalCell('E', 30),
        totalCell('F', 22),
        totalCell('G', 22),
        totalCell('H', 22),
        totalCell('I', 22),
        totalCell('J', 22),
        totalCell('K', 46),
        totalCell('L', 46),
        totalCell('M', 22),
        totalCell('N', 22),
        totalCell('O', 22),
      ],
      height: 17.4,
    );
  }

  String _excelSignatureRow(
    int row, {
    required String left,
    required String right,
  }) {
    return _excelRow(
      row,
      <String>[
        _excelEmptyCell('A$row', 47),
        _excelInlineCell('B$row', 49, left),
        _excelEmptyCell('C$row', 41),
        _excelEmptyCell('D$row', 41),
        _excelEmptyCell('E$row', 41),
        _excelEmptyCell('F$row', 41),
        _excelEmptyCell('G$row', 41),
        _excelEmptyCell('H$row', 41),
        _excelEmptyCell('I$row', 41),
        _excelEmptyCell('J$row', 41),
        _excelEmptyCell('K$row', 41),
        _excelEmptyCell('L$row', 41),
        _excelInlineCell('M$row', 1, right),
        _excelEmptyCell('N$row', 41),
        _excelEmptyCell('O$row', 41),
      ],
      height: 17.4,
    );
  }

  String _excelRow(int row, List<String> cells, {double? height}) {
    final String heightXml = height == null
        ? ''
        : ' ht="${height.toStringAsFixed(1)}" customHeight="1"';
    return '<row r="$row" spans="1:15"$heightXml x14ac:dyDescent="0.3">${cells.join()}</row>';
  }

  String _excelEmptyCell(String reference, int style) =>
      '<c r="$reference" s="$style"/>';

  String _excelInlineCell(String reference, int style, String value) =>
      '<c r="$reference" s="$style" t="inlineStr"><is><t xml:space="preserve">${_xmlEscape(value)}</t></is></c>';

  String _excelNumberCell(String reference, int style, int value) =>
      '<c r="$reference" s="$style"><v>$value</v></c>';

  String _excelNumberOrDashCell(String reference, int style, int? value) =>
      value == null
          ? _excelInlineCell(reference, style, '-')
          : _excelNumberCell(reference, style, value);

  String _excelFormulaOrDashCell(
    String reference,
    int style,
    String formula,
    int? cachedValue,
  ) {
    if (cachedValue == null) {
      return '<c r="$reference" s="$style" t="str"><f>${_xmlEscape(formula)}</f><v>-</v></c>';
    }
    return '<c r="$reference" s="$style"><f>${_xmlEscape(formula)}</f><v>$cachedValue</v></c>';
  }

  int? _excelOptionalInt(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return _asInt(value);
  }

  int _sexingStatusRank(ActivityRecord record) {
    final String status =
        BullSniStatus.normalize(record.data['status_sni']?.toString());
    if (status == BullSniStatus.bersertifikasi) return 0;
    if (status == BullSniStatus.belumBersertifikasi) return 1;
    return 2;
  }

  String _patchExcelWorkbookXml(String xml, int printEndRow) {
    String patched = xml.replaceAll(
      RegExp(
        r'<definedName name="_xlnm.Print_Area" localSheetId="0">.*?</definedName>',
      ),
      '<definedName name="_xlnm.Print_Area" localSheetId="0">data!\$A\$3:\$O\$$printEndRow</definedName>',
    );
    patched = patched.replaceAll(
      RegExp(r'<calcPr[^>]*/>'),
      '<calcPr calcId="191029" calcMode="auto" fullCalcOnLoad="1" forceFullCalc="1"/>',
    );
    return patched;
  }

  String _removeCalcChainRelationship(String xml) => xml.replaceAll(
        RegExp(
          r'<Relationship[^>]*Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/calcChain"[^>]*/>',
        ),
        '',
      );

  String _removeCalcChainContentType(String xml) => xml.replaceAll(
        RegExp(r'<Override PartName="/xl/calcChain.xml"[^>]*/>'),
        '',
      );

  String _patchExcelCoreProperties(String xml, UserModel exportedBy) {
    final String author = exportedBy.nama.trim().isEmpty
        ? exportedBy.email
        : exportedBy.nama.trim();
    String patched = xml.replaceAll(
      RegExp(r'<dc:creator>.*?</dc:creator>'),
      '<dc:creator>${_xmlEscape(author)}</dc:creator>',
    );
    patched = patched.replaceAll(
      RegExp(r'<cp:lastModifiedBy>.*?</cp:lastModifiedBy>'),
      '<cp:lastModifiedBy>${_xmlEscape(author)}</cp:lastModifiedBy>',
    );
    return patched;
  }

  List<pw.Widget> _pdfPeriod(_PeriodGroup period) {
    final List<pw.Widget> widgets = <pw.Widget>[
      pw.Center(
        child: pw.Text(
          'DATA PRODUKSI DAN DISTRIBUSI SEMEN BEKU BIB',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Center(
        child: pw.Text(
          'BULAN ${_monthName(period.month).toUpperCase()} ${period.year}',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 12),
    ];

    for (final _CategoryRows category in period.categories) {
      if (category.records.isEmpty) continue;
      widgets.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          color: PdfColors.grey200,
          child: pw.Text(
            category.category,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
          ),
        ),
      );
      if (_isSexing(category.category)) {
        for (final _SniRows section in _sexingRows(category.records)) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(4, 5, 4, 3),
              child: pw.Text(
                section.label,
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
          widgets.add(_pdfTable(section.records, period.year));
        }
      } else {
        widgets.add(_pdfTable(category.records, period.year));
      }
      widgets.add(pw.SizedBox(height: 8));
    }
    return widgets;
  }

  pw.Widget _pdfTable(List<ActivityRecord> records, int year) {
    final List<List<String>> rows = <List<String>>[
      <String>[
        'RUMPUN',
        'JML PEJANTAN',
        'STOCK $year',
        'I',
        'II',
        'III',
        'IV',
        'V',
        'JML PRODUKSI',
        'AFKIR',
        'KOMANDAN',
        'NON SIKOMANDAN',
        'JML DISTRIBUSI',
        'STOCK AKHIR',
      ],
      ...records.map(_rowValues),
      _totalRow(records),
    ];

    return pw.TableHelper.fromTextArray(
      data: rows,
      headerCount: 1,
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.45),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontSize: 5.3, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 5.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      cellAlignment: pw.Alignment.center,
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(0.75),
        2: pw.FlexColumnWidth(0.95),
        3: pw.FlexColumnWidth(0.5),
        4: pw.FlexColumnWidth(0.5),
        5: pw.FlexColumnWidth(0.5),
        6: pw.FlexColumnWidth(0.5),
        7: pw.FlexColumnWidth(0.5),
        8: pw.FlexColumnWidth(0.85),
        9: pw.FlexColumnWidth(0.55),
        10: pw.FlexColumnWidth(0.75),
        11: pw.FlexColumnWidth(0.95),
        12: pw.FlexColumnWidth(0.85),
        13: pw.FlexColumnWidth(0.95),
      },
    );
  }

  List<String> _rowValues(ActivityRecord record) => <String>[
        BullBreedName.canonical(record.data['bangsa']?.toString()).isEmpty
            ? '-'
            : BullBreedName.canonical(record.data['bangsa']?.toString()),
        _formatNumber(_asInt(record.data['jumlah_pejantan'])),
        _formatOptionalNumber(_stockRawValue(record)),
        _formatOptionalNumber(record.data['produksi_minggu_i']),
        _formatOptionalNumber(record.data['produksi_minggu_ii']),
        _formatOptionalNumber(record.data['produksi_minggu_iii']),
        _formatOptionalNumber(record.data['produksi_minggu_iv']),
        _formatOptionalNumber(record.data['produksi_minggu_v']),
        _formatOptionalNumber(record.data['jumlah_produksi']),
        _formatOptionalNumber(record.data['afkir']),
        _formatOptionalNumber(record.data['distribusi_komandan']),
        _formatOptionalNumber(record.data['distribusi_non_sikomandan']),
        _formatOptionalNumber(record.data['jumlah_distribusi']),
        _formatOptionalNumber(record.data['stock_akhir']),
      ];

  List<String> _totalRow(List<ActivityRecord> records) {
    int sum(String key) => records.fold<int>(
          0,
          (total, record) => total + _asInt(record.data[key]),
        );

    String optionalSum(String key) {
      final List<dynamic> values = records
          .map((record) => record.data[key])
          .where((value) => value != null && value.toString().trim().isNotEmpty)
          .toList(growable: false);
      if (values.isEmpty) return '-';
      return _formatNumber(
        values.fold<int>(0, (total, value) => total + _asInt(value)),
      );
    }

    return <String>[
      'TOTAL',
      _formatNumber(sum('jumlah_pejantan')),
      _optionalStockSum(records),
      optionalSum('produksi_minggu_i'),
      optionalSum('produksi_minggu_ii'),
      optionalSum('produksi_minggu_iii'),
      optionalSum('produksi_minggu_iv'),
      optionalSum('produksi_minggu_v'),
      optionalSum('jumlah_produksi'),
      optionalSum('afkir'),
      optionalSum('distribusi_komandan'),
      optionalSum('distribusi_non_sikomandan'),
      optionalSum('jumlah_distribusi'),
      optionalSum('stock_akhir'),
    ];
  }

  List<_PeriodGroup> _periodGroups(List<ActivityRecord> records) {
    final Map<String, List<ActivityRecord>> byPeriod =
        <String, List<ActivityRecord>>{};
    for (final ActivityRecord record in records) {
      final int year = _asInt(record.data['tahun']);
      final int month = _asInt(record.data['bulan']);
      if (year <= 0 || month < 1 || month > 12) continue;
      byPeriod.putIfAbsent('$year-${month.toString().padLeft(2, '0')}',
          () => <ActivityRecord>[]).add(record);
    }

    final List<String> keys = byPeriod.keys.toList()..sort();
    return keys.map((key) {
      final List<ActivityRecord> periodRecords = byPeriod[key]!;
      final int year = _asInt(periodRecords.first.data['tahun']);
      final int month = _asInt(periodRecords.first.data['bulan']);
      final List<_CategoryRows> categories = <_CategoryRows>[];
      final Set<ActivityRecord> assigned = <ActivityRecord>{};

      for (final String category in _categoryOrder) {
        final List<ActivityRecord> rows = periodRecords.where((record) {
          return _normalize(_canonicalCategory(
                    record.data['kategori']?.toString() ?? '',
                  )) ==
                  _normalize(category);
        }).toList()
          ..sort(_compareBreed);
        assigned.addAll(rows);
        categories.add(_CategoryRows(category: category, records: rows));
      }

      final List<ActivityRecord> extra = periodRecords
          .where((record) => !assigned.contains(record))
          .toList()
        ..sort(_compareBreed);
      if (extra.isNotEmpty) {
        final Map<String, List<ActivityRecord>> extraByCategory =
            <String, List<ActivityRecord>>{};
        for (final ActivityRecord record in extra) {
          final String category =
              record.data['kategori']?.toString().trim() ?? 'Lainnya';
          extraByCategory.putIfAbsent(category, () => <ActivityRecord>[])
              .add(record);
        }
        final List<String> labels = extraByCategory.keys.toList()..sort();
        for (final String label in labels) {
          categories.add(
            _CategoryRows(category: label, records: extraByCategory[label]!),
          );
        }
      }

      return _PeriodGroup(year: year, month: month, categories: categories);
    }).toList(growable: false);
  }

  int _compareBreed(ActivityRecord a, ActivityRecord b) =>
      BullBreedName.canonical(a.data['bangsa']?.toString())
          .toLowerCase()
          .compareTo(
            BullBreedName.canonical(b.data['bangsa']?.toString()).toLowerCase(),
          );

  bool _isSexing(String category) =>
      _normalize(_canonicalCategory(category)) == 'sexing';

  List<_SniRows> _sexingRows(List<ActivityRecord> records) {
    final List<_SniRows> groups = <_SniRows>[];
    final List<MapEntry<String, String>> statuses =
        <MapEntry<String, String>>[
      const MapEntry<String, String>(
        BullSniStatus.bersertifikasi,
        'SNI',
      ),
      const MapEntry<String, String>(
        BullSniStatus.belumBersertifikasi,
        'NON SNI',
      ),
      const MapEntry<String, String>('', 'BELUM TERKLASIFIKASI'),
    ];
    for (final MapEntry<String, String> status in statuses) {
      final List<ActivityRecord> rows = records.where((record) {
        return BullSniStatus.normalize(record.data['status_sni']?.toString()) ==
            status.key;
      }).toList()
        ..sort(_compareBreed);
      if (rows.isNotEmpty) {
        groups.add(_SniRows(label: status.value, records: rows));
      }
    }
    return groups;
  }

  String _documentXml(List<_PeriodGroup> periods, UserModel exportedBy) {
    final StringBuffer body = StringBuffer()
      ..write(_wordParagraph(
        'DATA PRODUKSI DAN DISTRIBUSI SEMEN BEKU BIB',
        bold: true,
        size: 24,
        align: 'center',
      ));

    for (int p = 0; p < periods.length; p++) {
      final _PeriodGroup period = periods[p];
      if (p > 0) body.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      body
        ..write(_wordParagraph(
          'BULAN ${_monthName(period.month).toUpperCase()} ${period.year}',
          bold: true,
          size: 22,
          align: 'center',
        ))
        ..write(_wordParagraph(''));
      for (final _CategoryRows category in period.categories) {
        if (category.records.isEmpty) continue;
        body.write(_wordParagraph(category.category, bold: true, size: 18));
        if (_isSexing(category.category)) {
          for (final _SniRows section in _sexingRows(category.records)) {
            body
              ..write(_wordParagraph(section.label, bold: true, size: 15))
              ..write(_wordTable(section.records, period.year))
              ..write(_wordParagraph(''));
          }
        } else {
          body
            ..write(_wordTable(category.records, period.year))
            ..write(_wordParagraph(''));
        }
      }
    }

    final String who = exportedBy.nama.trim().isEmpty
        ? exportedBy.email
        : exportedBy.nama.trim();
    body
      ..write(_wordParagraph(''))
      ..write(_wordParagraph('Diekspor oleh: $who', size: 16));

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
 <w:body>
 $body
 <w:sectPr>
  <w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/>
  <w:pgMar w:top="500" w:right="420" w:bottom="500" w:left="420" w:header="300" w:footer="300" w:gutter="0"/>
 </w:sectPr>
 </w:body>
</w:document>''';
  }

  String _wordTable(List<ActivityRecord> records, int year) {
    final List<List<String>> rows = <List<String>>[
      <String>[
        'RUMPUN', 'JML PEJANTAN', 'STOCK $year', 'I', 'II', 'III', 'IV', 'V',
        'JML PRODUKSI', 'AFKIR', 'KOMANDAN', 'NON SIKOMANDAN',
        'JML DISTRIBUSI', 'STOCK AKHIR'
      ],
      ...records.map(_rowValues),
      _totalRow(records),
    ];
    final StringBuffer xml = StringBuffer('''<w:tbl><w:tblPr>
<w:tblW w:w="0" w:type="auto"/>
<w:tblBorders><w:top w:val="single" w:sz="4" w:color="000000"/>
<w:left w:val="single" w:sz="4" w:color="000000"/>
<w:bottom w:val="single" w:sz="4" w:color="000000"/>
<w:right w:val="single" w:sz="4" w:color="000000"/>
<w:insideH w:val="single" w:sz="4" w:color="000000"/>
<w:insideV w:val="single" w:sz="4" w:color="000000"/></w:tblBorders>
</w:tblPr>''');
    for (int index = 0; index < rows.length; index++) {
      xml.write(_wordTableRow(rows[index], header: index == 0));
    }
    xml.write('</w:tbl>');
    return xml.toString();
  }

  String _wordTableRow(List<String> cells, {bool header = false}) {
    final String fill = header ? 'D9D9D9' : 'FFFFFF';
    final StringBuffer row = StringBuffer('<w:tr>');
    for (final String cell in cells) {
      row
        ..write('<w:tc>')
        ..write('<w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="$fill"/>')
        ..write('<w:tcMar><w:top w:w="50" w:type="dxa"/>')
        ..write('<w:left w:w="50" w:type="dxa"/>')
        ..write('<w:bottom w:w="50" w:type="dxa"/>')
        ..write('<w:right w:w="50" w:type="dxa"/></w:tcMar></w:tcPr>')
        ..write(_wordParagraph(cell, bold: header, size: 11, align: 'center'))
        ..write('</w:tc>');
    }
    row.write('</w:tr>');
    return row.toString();
  }

  String _wordParagraph(
    String value, {
    bool bold = false,
    int size = 18,
    String? align,
  }) {
    final String alignXml = align == null ? '' : '<w:jc w:val="$align"/>';
    final String boldXml = bold ? '<w:b/><w:bCs/>' : '';
    return '''<w:p><w:pPr>$alignXml</w:pPr><w:r><w:rPr>$boldXml<w:sz w:val="$size"/><w:szCs w:val="$size"/></w:rPr><w:t xml:space="preserve">${_xmlEscape(value)}</w:t></w:r></w:p>''';
  }

  String _corePropertiesXml(UserModel exportedBy, DateTime now) {
    final String author = exportedBy.nama.trim().isEmpty
        ? exportedBy.email
        : exportedBy.nama.trim();
    final String timestamp = now.toIso8601String();
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<dc:title>Produksi dan Distribusi Semen Beku</dc:title><dc:creator>${_xmlEscape(author)}</dc:creator>
<dcterms:created xsi:type="dcterms:W3CDTF">$timestamp</dcterms:created>
<dcterms:modified xsi:type="dcterms:W3CDTF">$timestamp</dcterms:modified></cp:coreProperties>''';
  }

  String _formatOptionalNumber(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    return _formatNumber(_asInt(value));
  }

  dynamic _stockRawValue(ActivityRecord record) {
    final dynamic stockTahun = record.data['stock_tahun'];
    if (stockTahun != null && stockTahun.toString().trim().isNotEmpty) {
      return stockTahun;
    }
    final dynamic legacy = record.data['stock_awal'];
    if (legacy != null && legacy.toString().trim().isNotEmpty) return legacy;
    return null;
  }

  String _optionalStockSum(List<ActivityRecord> records) {
    final List<dynamic> values = records
        .map(_stockRawValue)
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .toList(growable: false);
    if (values.isEmpty) return '-';
    return _formatNumber(
      values.fold<int>(0, (total, value) => total + _asInt(value)),
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _normalize(dynamic value) =>
      value?.toString().trim().toLowerCase() ?? '';

  String _canonicalCategory(String value) {
    final String normalized = _normalize(value);
    if (normalized == 'sapi potong') return 'Sapi Potong';
    if (normalized == 'kerbau') return 'Kerbau';
    if (normalized == 'sexing') return 'Sexing';
    if (normalized == 'non-lspro') return 'Non-LSPro';
    return value.trim();
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
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month < 1 || month > 12) return 'Bulan';
    return months[month - 1];
  }

  String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static const String _contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';

  static const String _rootRelationshipsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';

  static const String _documentRelationshipsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

  static const String _appPropertiesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
<Application>BullCare</Application><AppVersion>1.0</AppVersion></Properties>''';

  static const String _stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/><w:rPr><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr></w:style>
</w:styles>''';
}

class _PeriodGroup {
  const _PeriodGroup({
    required this.year,
    required this.month,
    required this.categories,
  });
  final int year;
  final int month;
  final List<_CategoryRows> categories;
}

class _CategoryRows {
  const _CategoryRows({required this.category, required this.records});
  final String category;
  final List<ActivityRecord> records;
}

class _SniRows {
  const _SniRows({required this.label, required this.records});
  final String label;
  final List<ActivityRecord> records;
}


class _ExcelSheetBuild {
  const _ExcelSheetBuild({required this.xml, required this.printEndRow});

  final String xml;
  final int printEndRow;
}
