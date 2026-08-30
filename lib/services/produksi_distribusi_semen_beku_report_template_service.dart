import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity_record.dart';
import '../models/report_export_data.dart';
import '../models/user_model.dart';
import '../utils/bull_breed_name.dart';
import '../utils/bull_sni_status.dart';

class ProduksiDistribusiSemenBekuReportTemplateService {
  const ProduksiDistribusiSemenBekuReportTemplateService();

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
