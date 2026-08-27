import 'dart:convert';
import 'dart:typed_data' show Uint8List;

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/activity_record.dart';
import '../models/bull_model.dart';
import '../models/report_export_data.dart';
import '../models/user_model.dart';

class PengambilanSampleReportTemplateService {
  const PengambilanSampleReportTemplateService();

  static const String _logoBib = 'assets/templates/bib_kalsel_logo.png';
  static const String _logoDisbunnak = 'assets/templates/logo_disbunnak.jpeg';

  Future<Uint8List> buildPdf({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    final pw.Document document = pw.Document(
      title: 'Formulir Pengambilan Sample',
      author: exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama,
      creator: 'BullCare',
    );

    final ByteData bibData = await rootBundle.load(_logoBib);
    final pw.MemoryImage bibLogo = pw.MemoryImage(bibData.buffer.asUint8List());
    final ByteData disbunnakData = await rootBundle.load(_logoDisbunnak);
    final pw.MemoryImage disbunnakLogo = pw.MemoryImage(disbunnakData.buffer.asUint8List());

    final List<_SampleBullRow> bulls = _bullSlots(data);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => _buildPdfPage(
          data: data,
          bulls: bulls,
          bibLogo: bibLogo,
          disbunnakLogo: disbunnakLogo,
        ),
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        maxPages: 100,
        margin: const pw.EdgeInsets.all(26),
        build: (context) => _pdfDetailSection(data),
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
    final Map<String, String> files = <String, String>{
      '[Content_Types].xml': _contentTypesXml,
      '_rels/.rels': _rootRelationshipsXml,
      'docProps/core.xml': _corePropertiesXml(exportedBy, now),
      'docProps/app.xml': _appPropertiesXml,
      'word/document.xml': _documentXml(data: data, exportedBy: exportedBy),
      'word/styles.xml': _stylesXml,
      'word/_rels/document.xml.rels': _documentRelationshipsXml,
    };
    for (final MapEntry<String, String> entry in files.entries) {
      archive.addFile(ArchiveFile.string(entry.key, entry.value));
    }
    return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
  }

  // ===== PDF Helpers =====
  pw.Widget _buildPdfPage({
    required ReportExportData data,
    required List<_SampleBullRow> bulls,
    required pw.MemoryImage bibLogo,
    required pw.MemoryImage disbunnakLogo,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Image(bibLogo, width: 50, height: 65),
            pw.Column(
              children: <pw.Widget>[
                pw.Text(
                  'FORMULIR PENGAMBILAN SAMPEL',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'WAKTU PELAKSANAAN : 6 BULAN SEKALI (minimal)',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Image(disbunnakLogo, width: 50, height: 65),
          ],
        ),
        pw.Divider(),
        pw.SizedBox(height: 6),
        pw.Text(
          'Periode: ${_formatDate(data.periodStart)} - ${_formatDate(data.periodEnd)}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.4),
          columnWidths: <int, pw.TableColumnWidth>{
            0: const pw.FixedColumnWidth(24),
            1: const pw.FlexColumnWidth(1.8),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FixedColumnWidth(30),
            4: const pw.FixedColumnWidth(30),
            5: const pw.FixedColumnWidth(30),
            6: const pw.FixedColumnWidth(30),
            7: const pw.FixedColumnWidth(30),
            8: const pw.FlexColumnWidth(2.0),
          },
          children: <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: <pw.Widget>[
                _pdfCell('No', bold: true),
                _pdfCell('Nama Bull', bold: true),
                _pdfCell('Bangsa', bold: true),
                _pdfCell('Darah', bold: true, align: pw.Alignment.center),
                _pdfCell('Serum', bold: true, align: pw.Alignment.center),
                _pdfCell('Ulas\nDarah', bold: true, align: pw.Alignment.center),
                _pdfCell('Swab', bold: true, align: pw.Alignment.center),
                _pdfCell('Feses', bold: true, align: pw.Alignment.center),
                _pdfCell('Keterangan', bold: true),
              ],
            ),
            for (int i = 0; i < bulls.length; i++) ..._buildDataRows(bulls[i], i + 1, data),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          children: <pw.Widget>[
            pw.Text('Paraf Petugas: ', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(_getPetugasNames(data), style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  List<pw.TableRow> _buildDataRows(_SampleBullRow bull, int no, ReportExportData data) {
    final ActivityRecord? record = bull.id.isEmpty ? null : _latestRecord(data, bull.id);
    return <pw.TableRow>[
      pw.TableRow(
        children: <pw.Widget>[
          _pdfCell('$no'),
          _pdfCell(bull.label),
          _pdfCell(bull.breed),
          _pdfCell(record != null && record.data['darah'] == true ? '✓' : ''),
          _pdfCell(record != null && record.data['serum'] == true ? '✓' : ''),
          _pdfCell(record != null && record.data['ulas_darah'] == true ? '✓' : ''),
          _pdfCell(record != null && record.data['swab'] == true ? '✓' : ''),
          _pdfCell(record != null && record.data['feses'] == true ? '✓' : ''),
          _pdfCell(record != null ? _plainValue(record.data['keterangan']) : ''),
        ],
      ),
    ];
  }

  pw.Widget _pdfCell(String text, {bool bold = false, pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Container(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 7, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        ),
      ),
    );
  }

  List<pw.Widget> _pdfDetailSection(ReportExportData data) {
    final records = data.records.where((r) => r.collectionName == 'pengambilan_sample').toList();
    records.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    final rows = <List<String>>[
      ['Tanggal', 'Bull', 'Bangsa', 'Darah', 'Serum', 'Ulas Darah', 'Swab', 'Feses', 'Keterangan', 'Petugas'],
      for (final r in records) [
        _formatDate(r.tanggal),
        _bullLabel(r, data),
        _breedForRecord(r, data),
        r.data['darah'] == true ? '✓' : '-',
        r.data['serum'] == true ? '✓' : '-',
        r.data['ulas_darah'] == true ? '✓' : '-',
        r.data['swab'] == true ? '✓' : '-',
        r.data['feses'] == true ? '✓' : '-',
        _plainValue(r.data['keterangan']),
        _plainValue(r.data['nama_petugas']),
      ]
    ];
    return [
      pw.Text('RINCIAN DATA PENGAMBILAN SAMPEL',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Text('Periode ${_formatDate(data.periodStart)} - ${_formatDate(data.periodEnd)}',
          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
      pw.SizedBox(height: 10),
      pw.TableHelper.fromTextArray(
        data: rows,
        headerCount: 1,
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.4),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
        headerStyle: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 5.8),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      ),
    ];
  }

  // ===== Word Helpers =====
  String _documentXml({required ReportExportData data, required UserModel exportedBy}) {
    final List<_SampleBullRow> bulls = _bullSlots(data);
    final StringBuffer body = StringBuffer()
      ..write(_wordParagraph('FORMULIR PENGAMBILAN SAMPEL', style: 'Title', center: true))
      ..write(_wordParagraph('WAKTU PELAKSANAAN : 6 BULAN SEKALI (minimal)', center: true, fontSize: 18))
      ..write(_wordParagraph(''))
      ..write(_wordParagraph(
          'Periode: ${_formatDate(data.periodStart)} - ${_formatDate(data.periodEnd)}', bold: true))
      ..write(_wordParagraph(''))
      ..write(_wordTable(data, bulls));

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
 <w:body>
 $body
 <w:sectPr><w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/><w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/></w:sectPr>
 </w:body>
</w:document>''';
  }

  String _wordTable(ReportExportData data, List<_SampleBullRow> bulls) {
    final StringBuffer buffer = StringBuffer()
      ..write('<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders>'
          '<w:top w:val="single" w:sz="4"/><w:left w:val="single" w:sz="4"/>'
          '<w:bottom w:val="single" w:sz="4"/><w:right w:val="single" w:sz="4"/>'
          '<w:insideH w:val="single" w:sz="4"/><w:insideV w:val="single" w:sz="4"/>'
          '</w:tblBorders></w:tblPr>');

    buffer.write(_wordTableRow(<String>['No', 'Nama Bull', 'Bangsa', 'Darah', 'Serum', 'Ulas Darah', 'Swab', 'Feses', 'Keterangan'],
        header: true));

    for (int i = 0; i < bulls.length; i++) {
      final record = bulls[i].id.isEmpty ? null : _latestRecord(data, bulls[i].id);
      buffer.write(_wordTableRow(<String>[
        '${i + 1}',
        bulls[i].label,
        bulls[i].breed,
        record != null && record.data['darah'] == true ? '✓' : '',
        record != null && record.data['serum'] == true ? '✓' : '',
        record != null && record.data['ulas_darah'] == true ? '✓' : '',
        record != null && record.data['swab'] == true ? '✓' : '',
        record != null && record.data['feses'] == true ? '✓' : '',
        record != null ? _plainValue(record.data['keterangan']) : '',
      ]));
    }
    buffer.write('</w:tbl>');
    return buffer.toString();
  }

  String _wordTableRow(List<String> cells, {bool header = false}) {
    final String cellColor = header ? 'EAF7EC' : 'FFFFFF';
    return '<w:tr>' +
        cells
            .map((value) => '''<w:tc><w:tcPr><w:shd w:val="clear" w:fill="$cellColor"/><w:tcMar><w:top w:w="40" w:type="dxa"/>
<w:left w:w="40" w:type="dxa"/><w:bottom w:w="40" w:type="dxa"/><w:right w:w="40" w:type="dxa"/></w:tcMar></w:tcPr>
${_wordParagraph(value, bold: header, fontSizeHalfPoints: 12)}</w:tc>''')
            .join() +
        '</w:tr>';
  }

  String _wordParagraph(String text,
      {String? style, bool bold = false, bool center = false, int fontSizeHalfPoints = 22}) {
    final String safe = _xmlEscape(text);
    final String align = center ? '<w:jc w:val="center"/>' : '';
    final String styleXml = style == null ? '' : '<w:pStyle w:val="$style"/>';
    final String boldXml = bold ? '<w:b/><w:bCs/>' : '';
    return '<w:p><w:pPr>$styleXml$align</w:pPr><w:r><w:rPr>$boldXml<w:sz w:val="$fontSizeHalfPoints"/><w:szCs w:val="$fontSizeHalfPoints"/></w:rPr><w:t xml:space="preserve">$safe</w:t></w:r></w:p>';
  }

  // ===== Utility =====
  List<_SampleBullRow> _bullSlots(ReportExportData data) {
    final Map<String, _SampleBullRow> map = {};
    for (final BullModel bull in data.bulls.values) {
      final name = bull.nama.trim().isNotEmpty ? bull.nama.trim() : bull.kode_bull.trim();
      map[bull.id] = _SampleBullRow(id: bull.id, label: name, breed: bull.bangsa.trim());
    }
    final values = map.values.toList();
    values.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return values;
  }

  ActivityRecord? _latestRecord(ReportExportData data, String bullId) {
    ActivityRecord? latest;
    for (final r in data.records) {
      if (r.collectionName == 'pengambilan_sample' && r.bull_id == bullId) {
        if (latest == null || r.tanggal.isAfter(latest.tanggal)) latest = r;
      }
    }
    return latest;
  }

  String _getPetugasNames(ReportExportData data) {
    final names = data.records
        .where((r) => r.collectionName == 'pengambilan_sample')
        .map((r) => r.data['nama_petugas']?.toString().trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toSet()
        .join(' / ');
    return names.isEmpty ? 'Petugas BullCare' : names;
  }

  String _bullLabel(ActivityRecord r, ReportExportData data) =>
      data.bulls[r.bull_id]?.nama.trim() ?? 'Bull ${r.bull_id.substring(0, 4)}';
  String _breedForRecord(ActivityRecord r, ReportExportData data) =>
      data.bulls[r.bull_id]?.bangsa.trim() ?? '-';
  String _plainValue(dynamic v) => v?.toString().trim() ?? '';
  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _xmlEscape(String v) => v.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

  static const String _contentTypesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
 <Default Extension="xml" ContentType="application/xml"/>
 <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
 <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
 <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
 <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';
  static const String _rootRelationshipsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
 <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
 <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
  static const String _documentRelationshipsXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';
  static const String _appPropertiesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
 <Application>BullCare</Application>
</Properties>''';
  static const String _stylesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
 <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:style>
 <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:bCs/><w:color w:val="087C32"/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr></w:style>
</w:styles>''';
  String _corePropertiesXml(UserModel user, DateTime now) => '''<?xml version="1.0" encoding="UTF-8"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties">
 <dc:title>Formulir Pengambilan Sample</dc:title>
 <dc:creator>${_xmlEscape(user.nama)}</dc:creator>
 <dcterms:created xsi:type="dcterms:W3CDTF">${now.toIso8601String()}</dcterms:created>
</cp:coreProperties>''';
}

class _SampleBullRow {
  final String id, label, breed;
  const _SampleBullRow({required this.id, required this.label, required this.breed});
}