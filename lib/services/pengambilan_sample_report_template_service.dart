import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity_record.dart';
import '../models/bull_model.dart';
import '../models/report_export_data.dart';
import '../models/user_model.dart';

/// Export khusus aktivitas Pengambilan Sample.
///
/// Project saat ini belum memiliki template DOCX resmi untuk aktivitas ini.
/// Karena itu service hanya membangun formulir dari field yang memang sudah
/// tersedia di Firestore: darah, serum, ulas_darah, swab, feses, dan
/// keterangan. Aset logo Disbunnak bersifat opsional agar export tidak gagal
/// ketika aset tersebut belum tersedia atau masih kosong.
class PengambilanSampleReportTemplateService {
  const PengambilanSampleReportTemplateService();

  static const String _logoKalsel = 'assets/templates/bib_kalsel_logo.png';
  static const String _logoDisbunnak =
      'assets/templates/logo_disbunnak.jpeg';

  Future<Uint8List> buildPdf({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    final pw.MemoryImage? kalselLogo = await _tryLoadImage(_logoKalsel);
    final pw.MemoryImage? disbunnakLogo =
        await _tryLoadImage(_logoDisbunnak);
    final List<_SampleBullRow> bulls = _bullSlots(data);

    final pw.Document document = pw.Document(
      title: 'Formulir Pengambilan Sample',
      author:
          exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama,
      creator: 'BullCare',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        maxPages: 100,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => <pw.Widget>[
          _buildPdfHeader(
            kalselLogo: kalselLogo,
            disbunnakLogo: disbunnakLogo,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Periode: ${_formatDate(data.periodStart)} - ${_formatDate(data.periodEnd)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 10),
          _buildPdfSummaryTable(data, bulls),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                'Petugas pelaksana: ',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Expanded(
                child: pw.Text(
                  _getPetugasNames(data),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'RINCIAN DATA PENGAMBILAN SAMPLE',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildPdfDetailTable(data),
        ],
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
      'word/document.xml': _documentXml(
        data: data,
        exportedBy: exportedBy,
      ),
      'word/styles.xml': _stylesXml,
      'word/_rels/document.xml.rels': _documentRelationshipsXml,
    };

    for (final MapEntry<String, String> entry in files.entries) {
      archive.addFile(ArchiveFile.string(entry.key, entry.value));
    }

    return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
  }

  Future<pw.MemoryImage?> _tryLoadImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      if (data.lengthInBytes == 0) return null;
      final Uint8List bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (bytes.isEmpty) return null;
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  pw.Widget _buildPdfHeader({
    required pw.MemoryImage? kalselLogo,
    required pw.MemoryImage? disbunnakLogo,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: <pw.Widget>[
            pw.SizedBox(
              width: 72,
              child: kalselLogo == null
                  ? pw.SizedBox()
                  : pw.Center(
                      child: pw.Image(kalselLogo, width: 46, height: 58),
                    ),
            ),
            pw.Expanded(
              child: pw.Column(
                children: <pw.Widget>[
                  pw.Text(
                    'DINAS PERKEBUNAN DAN PETERNAKAN',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'BALAI INSEMINASI BUATAN',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'FORMULIR PENGAMBILAN SAMPLE',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Waktu pelaksanaan: 6 bulan sekali (minimal)',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(
              width: 72,
              child: disbunnakLogo == null
                  ? pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey500,
                          width: 0.5,
                        ),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'DISBUNNAK\nKALSEL',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    )
                  : pw.Center(
                      child: pw.Image(disbunnakLogo, width: 58, height: 58),
                    ),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Divider(thickness: 0.8),
      ],
    );
  }

  pw.Widget _buildPdfSummaryTable(
    ReportExportData data,
    List<_SampleBullRow> bulls,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.4),
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(1.8),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FixedColumnWidth(34),
        4: const pw.FixedColumnWidth(34),
        5: const pw.FixedColumnWidth(38),
        6: const pw.FixedColumnWidth(34),
        7: const pw.FixedColumnWidth(34),
        8: const pw.FlexColumnWidth(2.0),
      },
      children: <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: <pw.Widget>[
            _pdfCell('No', bold: true, center: true),
            _pdfCell('Nama Bull', bold: true, center: true),
            _pdfCell('Bangsa', bold: true, center: true),
            _pdfCell('Darah', bold: true, center: true),
            _pdfCell('Serum', bold: true, center: true),
            _pdfCell('Ulas Darah', bold: true, center: true),
            _pdfCell('Swab', bold: true, center: true),
            _pdfCell('Feses', bold: true, center: true),
            _pdfCell('Keterangan', bold: true, center: true),
          ],
        ),
        for (int index = 0; index < bulls.length; index++)
          _buildPdfSummaryRow(
            data: data,
            bull: bulls[index],
            number: index + 1,
          ),
      ],
    );
  }

  pw.TableRow _buildPdfSummaryRow({
    required ReportExportData data,
    required _SampleBullRow bull,
    required int number,
  }) {
    final ActivityRecord? record =
        bull.id.isEmpty ? null : _latestRecord(data, bull.id);
    return pw.TableRow(
      children: <pw.Widget>[
        _pdfCell('$number', center: true),
        _pdfCell(bull.label),
        _pdfCell(bull.breed),
        _pdfCell(_checkValue(record, 'darah'), center: true),
        _pdfCell(_checkValue(record, 'serum'), center: true),
        _pdfCell(_checkValue(record, 'ulas_darah'), center: true),
        _pdfCell(_checkValue(record, 'swab'), center: true),
        _pdfCell(_checkValue(record, 'feses'), center: true),
        _pdfCell(record == null ? '' : _plainValue(record.data['keterangan'])),
      ],
    );
  }

  pw.Widget _buildPdfDetailTable(ReportExportData data) {
    final List<ActivityRecord> records = _sampleRecords(data);
    final List<List<String>> rows = <List<String>>[
      <String>[
        'Tanggal',
        'Bull',
        'Bangsa',
        'Darah',
        'Serum',
        'Ulas Darah',
        'Swab',
        'Feses',
        'Keterangan',
        'Petugas',
      ],
      for (final ActivityRecord record in records)
        <String>[
          _formatDate(record.tanggal),
          _bullLabel(record, data),
          _breedForRecord(record, data),
          _checkValue(record, 'darah', emptyValue: '-'),
          _checkValue(record, 'serum', emptyValue: '-'),
          _checkValue(record, 'ulas_darah', emptyValue: '-'),
          _checkValue(record, 'swab', emptyValue: '-'),
          _checkValue(record, 'feses', emptyValue: '-'),
          _plainValue(record.data['keterangan']),
          _plainValue(record.data['nama_petugas']),
        ],
    ];

    return pw.TableHelper.fromTextArray(
      data: rows,
      headerCount: 1,
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.4),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
      headerStyle: pw.TextStyle(
        fontSize: 6,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 5.8),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      cellAlignment: pw.Alignment.topLeft,
    );
  }

  pw.Widget _pdfCell(
    String text, {
    bool bold = false,
    bool center = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _documentXml({
    required ReportExportData data,
    required UserModel exportedBy,
  }) {
    final List<_SampleBullRow> bulls = _bullSlots(data);
    final List<ActivityRecord> records = _sampleRecords(data);
    final String exportedName = exportedBy.nama.trim().isEmpty
        ? exportedBy.email
        : exportedBy.nama.trim();

    final StringBuffer body = StringBuffer()
      ..write(_wordParagraph(
        'DINAS PERKEBUNAN DAN PETERNAKAN',
        center: true,
        bold: true,
        fontSizeHalfPoints: 20,
      ))
      ..write(_wordParagraph(
        'BALAI INSEMINASI BUATAN',
        center: true,
        bold: true,
        fontSizeHalfPoints: 20,
      ))
      ..write(_wordParagraph(
        'FORMULIR PENGAMBILAN SAMPLE',
        style: 'Title',
        center: true,
      ))
      ..write(_wordParagraph(
        'Waktu pelaksanaan: 6 bulan sekali (minimal)',
        center: true,
        fontSizeHalfPoints: 17,
      ))
      ..write(_wordParagraph(''))
      ..write(_wordParagraph(
        'Periode: ${_formatDate(data.periodStart)} - ${_formatDate(data.periodEnd)}',
        bold: true,
        fontSizeHalfPoints: 18,
      ))
      ..write(_wordParagraph(
        'Petugas pelaksana: ${_getPetugasNames(data)}',
        fontSizeHalfPoints: 18,
      ))
      ..write(_wordParagraph(
        'Diekspor oleh: $exportedName',
        fontSizeHalfPoints: 18,
      ))
      ..write(_wordParagraph(''))
      ..write(_wordSummaryTable(data, bulls))
      ..write(_wordParagraph(''))
      ..write(_wordParagraph(
        'RINCIAN DATA PENGAMBILAN SAMPLE',
        style: 'Heading1',
        bold: true,
      ))
      ..write(_wordDetailTable(data, records));

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
 <w:body>
 $body
 <w:sectPr>
  <w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/>
  <w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/>
 </w:sectPr>
 </w:body>
</w:document>''';
  }

  String _wordSummaryTable(
    ReportExportData data,
    List<_SampleBullRow> bulls,
  ) {
    final StringBuffer buffer = StringBuffer()
      ..write(_wordTableStart())
      ..write(_wordTableRow(
        <String>[
          'No',
          'Nama Bull',
          'Bangsa',
          'Darah',
          'Serum',
          'Ulas Darah',
          'Swab',
          'Feses',
          'Keterangan',
        ],
        header: true,
      ));

    for (int index = 0; index < bulls.length; index++) {
      final _SampleBullRow bull = bulls[index];
      final ActivityRecord? record =
          bull.id.isEmpty ? null : _latestRecord(data, bull.id);
      buffer.write(_wordTableRow(<String>[
        '${index + 1}',
        bull.label,
        bull.breed,
        _checkValue(record, 'darah'),
        _checkValue(record, 'serum'),
        _checkValue(record, 'ulas_darah'),
        _checkValue(record, 'swab'),
        _checkValue(record, 'feses'),
        record == null ? '' : _plainValue(record.data['keterangan']),
      ]));
    }

    buffer.write('</w:tbl>');
    return buffer.toString();
  }

  String _wordDetailTable(
    ReportExportData data,
    List<ActivityRecord> records,
  ) {
    final StringBuffer buffer = StringBuffer()
      ..write(_wordTableStart())
      ..write(_wordTableRow(
        <String>[
          'Tanggal',
          'Bull',
          'Bangsa',
          'Darah',
          'Serum',
          'Ulas Darah',
          'Swab',
          'Feses',
          'Keterangan',
          'Petugas',
        ],
        header: true,
      ));

    for (final ActivityRecord record in records) {
      buffer.write(_wordTableRow(<String>[
        _formatDate(record.tanggal),
        _bullLabel(record, data),
        _breedForRecord(record, data),
        _checkValue(record, 'darah', emptyValue: '-'),
        _checkValue(record, 'serum', emptyValue: '-'),
        _checkValue(record, 'ulas_darah', emptyValue: '-'),
        _checkValue(record, 'swab', emptyValue: '-'),
        _checkValue(record, 'feses', emptyValue: '-'),
        _plainValue(record.data['keterangan']),
        _plainValue(record.data['nama_petugas']),
      ]));
    }

    buffer.write('</w:tbl>');
    return buffer.toString();
  }

  String _wordTableStart() {
    return '<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders>'
        '<w:top w:val="single" w:sz="4"/><w:left w:val="single" w:sz="4"/>'
        '<w:bottom w:val="single" w:sz="4"/><w:right w:val="single" w:sz="4"/>'
        '<w:insideH w:val="single" w:sz="4"/><w:insideV w:val="single" w:sz="4"/>'
        '</w:tblBorders></w:tblPr>';
  }

  String _wordTableRow(List<String> cells, {bool header = false}) {
    final String cellColor = header ? 'EAF7EC' : 'FFFFFF';
    final StringBuffer row = StringBuffer('<w:tr>');
    for (final String value in cells) {
      row
        ..write('<w:tc><w:tcPr>')
        ..write('<w:shd w:val="clear" w:fill="$cellColor"/>')
        ..write('<w:tcMar>')
        ..write('<w:top w:w="40" w:type="dxa"/>')
        ..write('<w:left w:w="40" w:type="dxa"/>')
        ..write('<w:bottom w:w="40" w:type="dxa"/>')
        ..write('<w:right w:w="40" w:type="dxa"/>')
        ..write('</w:tcMar></w:tcPr>')
        ..write(_wordParagraph(
          value,
          bold: header,
          fontSizeHalfPoints: 12,
        ))
        ..write('</w:tc>');
    }
    row.write('</w:tr>');
    return row.toString();
  }

  String _wordParagraph(
    String text, {
    String? style,
    bool bold = false,
    bool center = false,
    int fontSizeHalfPoints = 22,
  }) {
    final String safe = _xmlEscape(text);
    final String align = center ? '<w:jc w:val="center"/>' : '';
    final String styleXml =
        style == null ? '' : '<w:pStyle w:val="$style"/>';
    final String boldXml = bold ? '<w:b/><w:bCs/>' : '';
    return '<w:p><w:pPr>$styleXml$align</w:pPr>'
        '<w:r><w:rPr>$boldXml<w:sz w:val="$fontSizeHalfPoints"/>'
        '<w:szCs w:val="$fontSizeHalfPoints"/></w:rPr>'
        '<w:t xml:space="preserve">$safe</w:t></w:r></w:p>';
  }

  List<_SampleBullRow> _bullSlots(ReportExportData data) {
    final Map<String, _SampleBullRow> map = <String, _SampleBullRow>{};
    for (final BullModel bull in data.bulls.values) {
      final String name = bull.nama.trim().isNotEmpty
          ? bull.nama.trim()
          : bull.kode_bull.trim();
      map[bull.id] = _SampleBullRow(
        id: bull.id,
        label: name,
        breed: bull.bangsa.trim(),
      );
    }
    final List<_SampleBullRow> values = map.values.toList();
    values.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return values;
  }

  List<ActivityRecord> _sampleRecords(ReportExportData data) {
    final List<ActivityRecord> records = data.records
        .where((record) => record.collectionName == 'pengambilan_sample')
        .toList();
    records.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    return records;
  }

  ActivityRecord? _latestRecord(ReportExportData data, String bullId) {
    ActivityRecord? latest;
    for (final ActivityRecord record in data.records) {
      if (record.collectionName != 'pengambilan_sample' ||
          record.bull_id != bullId) {
        continue;
      }
      if (latest == null || record.tanggal.isAfter(latest.tanggal)) {
        latest = record;
      }
    }
    return latest;
  }

  String _getPetugasNames(ReportExportData data) {
    final Set<String> names = data.records
        .where((record) => record.collectionName == 'pengambilan_sample')
        .map((record) => _plainValue(record.data['nama_petugas']))
        .where((name) => name.isNotEmpty)
        .toSet();
    return names.isEmpty ? '-' : names.join(' / ');
  }

  String _checkValue(
    ActivityRecord? record,
    String field, {
    String emptyValue = '',
  }) {
    return record != null && record.data[field] == true ? '✓' : emptyValue;
  }

  String _bullLabel(ActivityRecord record, ReportExportData data) {
    final BullModel? bull = data.bulls[record.bull_id];
    if (bull != null) {
      if (bull.nama.trim().isNotEmpty) return bull.nama.trim();
      if (bull.kode_bull.trim().isNotEmpty) return bull.kode_bull.trim();
    }
    final String id = record.bull_id.trim();
    if (id.isEmpty) return '-';
    final String shortId = id.length <= 4 ? id : id.substring(0, 4);
    return 'Bull $shortId';
  }

  String _breedForRecord(ActivityRecord record, ReportExportData data) {
    final String? breed = data.bulls[record.bull_id]?.bangsa.trim();
    return breed == null || breed.isEmpty ? '-' : breed;
  }

  String _plainValue(dynamic value) => value?.toString().trim() ?? '';

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static const String _contentTypesXml =
      '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
 <Default Extension="xml" ContentType="application/xml"/>
 <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
 <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
 <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
 <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';

  static const String _rootRelationshipsXml =
      '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
 <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
 <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';

  static const String _documentRelationshipsXml =
      '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

  static const String _appPropertiesXml =
      '''<?xml version="1.0" encoding="UTF-8"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
 xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
 <Application>BullCare</Application>
</Properties>''';

  static const String _stylesXml =
      '''<?xml version="1.0" encoding="UTF-8"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
 <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
  <w:name w:val="Normal"/>
  <w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr>
 </w:style>
 <w:style w:type="paragraph" w:styleId="Title">
  <w:name w:val="Title"/><w:basedOn w:val="Normal"/>
  <w:rPr><w:b/><w:bCs/><w:sz w:val="30"/><w:szCs w:val="30"/></w:rPr>
 </w:style>
 <w:style w:type="paragraph" w:styleId="Heading1">
  <w:name w:val="heading 1"/><w:basedOn w:val="Normal"/>
  <w:rPr><w:b/><w:bCs/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>
 </w:style>
</w:styles>''';

  String _corePropertiesXml(UserModel user, DateTime now) {
    final String creator =
        user.nama.trim().isEmpty ? user.email.trim() : user.nama.trim();
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties
 xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:dcterms="http://purl.org/dc/terms/"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 <dc:title>Formulir Pengambilan Sample</dc:title>
 <dc:creator>${_xmlEscape(creator)}</dc:creator>
 <dcterms:created xsi:type="dcterms:W3CDTF">${now.toIso8601String()}</dcterms:created>
</cp:coreProperties>''';
  }
}

class _SampleBullRow {
  const _SampleBullRow({
    required this.id,
    required this.label,
    required this.breed,
  });

  final String id;
  final String label;
  final String breed;
}
