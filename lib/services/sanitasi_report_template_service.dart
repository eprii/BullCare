import 'dart:convert';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity_record.dart';
import '../models/bull_model.dart';
import '../models/report_export_data.dart';
import '../models/user_model.dart';

/// Export khusus aktivitas Sanitasi.
///
/// Sanitasi kandang, tempat makan, dan pejantan digabung dalam satu laporan.
/// Untuk Word, dokumen SOP asli digunakan sebagai template dan hanya isi tabel
/// yang diisi dari Firestore sehingga layout sumber tetap dipertahankan.
class SanitasiReportTemplateService {
  const SanitasiReportTemplateService();

  static const String _logoAsset = 'assets/templates/bib_kalsel_logo.png';
  static const String _wordTemplateAsset =
      'assets/templates/form_sanitasi_sop_6_3_l.docx';
  static const int _bullSlotCount = 30;

  // Lebar tabel asli dari SOP-6.3.l dalam twip.
  static const List<int> _wordGridWidths = <int>[
    437,
    440, 440, 441, 441, 441, 441, 441, 441, 441, 441,
    441, 442, 442, 442, 442, 442, 442, 442, 442, 442,
    442, 442, 442, 442, 442, 442, 442, 442, 442, 442,
    972,
    732,
  ];

  Future<Uint8List> buildDocx({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    final ByteData templateData = await rootBundle.load(_wordTemplateAsset);
    final Uint8List templateBytes = templateData.buffer.asUint8List(
      templateData.offsetInBytes,
      templateData.lengthInBytes,
    );
    final Archive sourceArchive = ZipDecoder().decodeBytes(templateBytes);
    final Archive outputArchive = Archive();

    for (final ArchiveFile file in sourceArchive) {
      if (!file.isFile) continue;
      final Uint8List content = file.readBytes() ?? Uint8List(0);
      if (file.name == 'word/document.xml') {
        final String xml = utf8.decode(content);
        final String patchedTemplateXml = _patchWordTemplate(xml, data);
        final String patchedXml = _appendWordDetailSection(
          patchedTemplateXml,
          data,
        );
        final Uint8List patchedBytes = Uint8List.fromList(utf8.encode(patchedXml));
        outputArchive.addFile(
          ArchiveFile(file.name, patchedBytes.length, patchedBytes),
        );
      } else {
        outputArchive.addFile(ArchiveFile(file.name, content.length, content));
      }
    }

    return Uint8List.fromList(ZipEncoder().encodeBytes(outputArchive));
  }

  Future<Uint8List> buildPdf({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    final ByteData logoData = await rootBundle.load(_logoAsset);
    final Uint8List logoBytes = logoData.buffer.asUint8List(
      logoData.offsetInBytes,
      logoData.lengthInBytes,
    );
    final pw.MemoryImage logo = pw.MemoryImage(logoBytes);
    final pw.Document document = pw.Document(
      title: 'Formulir Sanitasi Kandang dan Pejantan',
      author: exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama,
      creator: 'BullCare',
    );

    final DateTime month = DateTime(data.periodStart.year, data.periodStart.month, 1);
    final List<_SanitasiBullColumn> bulls = _bullSlots(data);

    // Template sumber terbagi menjadi dua halaman: 1-18 dan 19-31.
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => _pdfFirstPage(
          data: data,
          month: month,
          bulls: bulls,
          logo: logo,
        ),
      ),
    );
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => _pdfContinuationPage(
          data: data,
          month: month,
          bulls: bulls,
        ),
      ),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        maxPages: 100,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => _pdfDetailSection(data),
      ),
    );

    return document.save();
  }

  String _patchWordTemplate(String xml, ReportExportData data) {
    final List<RegExpMatch> tableMatches =
        RegExp(r'<w:tbl>.*?</w:tbl>', dotAll: true).allMatches(xml).toList();
    if (tableMatches.length < 3) {
      throw StateError('Template sanitasi tidak valid: tabel utama tidak ditemukan.');
    }

    final RegExpMatch mainTableMatch = tableMatches[2];
    final String tableXml = mainTableMatch.group(0)!;
    final List<RegExpMatch> rowMatches = RegExp(
      r'<w:tr(?:\s[^>]*)?>.*?</w:tr>',
      dotAll: true,
    ).allMatches(tableXml).toList();
    if (rowMatches.length < 33) {
      throw StateError('Template sanitasi tidak valid: baris tanggal tidak lengkap.');
    }

    final DateTime month = DateTime(data.periodStart.year, data.periodStart.month, 1);
    final List<_SanitasiBullColumn> bulls = _bullSlots(data);
    final List<ActivityRecord> records = _recordsForMonth(data, month);
    final Map<String, bool> marks = <String, bool>{};
    for (final ActivityRecord record in records) {
      marks['${record.tanggal.day}|${record.bull_id}'] = true;
    }

    String patchedTable = tableXml;
    final List<String> patchedRows = <String>[];

    // Baris nomor 1-30 tetap dipertahankan dari template.
    patchedRows.add(rowMatches[0].group(0)!);

    // Baris nama bull. Nama bawaan template diganti dengan data bull aktif.
    final List<String> nameValues = <String>[
      'Tgl',
      for (final _SanitasiBullColumn bull in bulls) bull.label,
      '',
      '',
    ];
    patchedRows.add(_replaceRowCellTexts(rowMatches[1].group(0)!, nameValues));

    // Tanggal 1-31.
    for (int day = 1; day <= 31; day++) {
      final bool validDay = day <= _daysInMonth(month);
      final List<ActivityRecord> dayRecords = validDay
          ? records.where((record) => record.tanggal.day == day).toList()
          : <ActivityRecord>[];
      final List<String> values = <String>[
        '$day',
        for (final _SanitasiBullColumn bull in bulls)
          validDay &&
                  bull.id.isNotEmpty &&
                  marks['$day|${bull.id}'] == true
              ? '✓'
              : '',
        _notesForDay(dayRecords),
        _petugasForDay(dayRecords),
      ];
      patchedRows.add(
        _replaceRowCellTexts(rowMatches[day + 1].group(0)!, values),
      );
    }

    // Ganti semua row pada tabel utama sambil mempertahankan tblPr/tblGrid.
    for (int i = rowMatches.length - 1; i >= 0; i--) {
      final RegExpMatch match = rowMatches[i];
      patchedTable = patchedTable.replaceRange(
        match.start,
        match.end,
        patchedRows[i],
      );
    }

    return xml.replaceRange(
      mainTableMatch.start,
      mainTableMatch.end,
      patchedTable,
    );
  }

  String _replaceRowCellTexts(String rowXml, List<String> values) {
    final List<RegExpMatch> cellMatches =
        RegExp(r'<w:tc>.*?</w:tc>', dotAll: true).allMatches(rowXml).toList();
    if (cellMatches.length != values.length) {
      throw StateError(
        'Template sanitasi tidak valid: jumlah kolom ${cellMatches.length}, '
        'seharusnya ${values.length}.',
      );
    }

    String result = rowXml;
    for (int i = cellMatches.length - 1; i >= 0; i--) {
      final RegExpMatch match = cellMatches[i];
      final String cell = match.group(0)!;
      result = result.replaceRange(
        match.start,
        match.end,
        _replaceCellText(cell, values[i]),
      );
    }
    return result;
  }

  String _replaceCellText(String cellXml, String value) {
    final RegExp textRegex = RegExp(
      r'<w:t(?:\s[^>]*)?>.*?</w:t>',
      dotAll: true,
    );
    final List<RegExpMatch> matches = textRegex.allMatches(cellXml).toList();
    final String escaped = _xmlEscape(value);

    if (matches.isEmpty) {
      // 6 pt di OOXML Word = 12 half-points. Sel yang awalnya kosong
      // tidak memiliki run formatting, sehingga tanpa rPr Word akan jatuh
      // kembali ke ukuran Normal (umumnya 12 pt). Paksa run baru menjadi 6 pt.
      final String run =
          '<w:r><w:rPr><w:sz w:val="12"/><w:szCs w:val="12"/></w:rPr>'
          '<w:t xml:space="preserve">$escaped</w:t></w:r>';
      final int paragraphEnd = cellXml.lastIndexOf('</w:p>');
      if (paragraphEnd >= 0) {
        return cellXml.replaceRange(paragraphEnd, paragraphEnd, run);
      }

      final RegExp selfClosingParagraph = RegExp(r'<w:p([^>]*)/>');
      final RegExpMatch? paragraphMatch = selfClosingParagraph.firstMatch(cellXml);
      if (paragraphMatch != null) {
        final String replacement =
            '<w:p${paragraphMatch.group(1) ?? ''}>$run</w:p>';
        return cellXml.replaceRange(
          paragraphMatch.start,
          paragraphMatch.end,
          replacement,
        );
      }
      return cellXml;
    }

    String result = cellXml;
    for (int i = matches.length - 1; i >= 0; i--) {
      final RegExpMatch match = matches[i];
      final String replacement = i == 0
          ? '<w:t xml:space="preserve">$escaped</w:t>'
          : '<w:t></w:t>';
      result = result.replaceRange(match.start, match.end, replacement);
    }
    return result;
  }

  String _appendWordDetailSection(String xml, ReportExportData data) {
    final List<ActivityRecord> records = data.records
        .where(_hasAnySanitasi)
        .toList(growable: false)
      ..sort((a, b) {
        final int dateCompare = a.tanggal.compareTo(b.tanggal);
        if (dateCompare != 0) return dateCompare;
        return _bullLabelForRecord(a, data)
            .toLowerCase()
            .compareTo(_bullLabelForRecord(b, data).toLowerCase());
      });
    if (records.isEmpty) return xml;

    final StringBuffer appendix = StringBuffer();
    appendix.write(
      '<w:p><w:r><w:br w:type="page"/></w:r></w:p>',
    );
    appendix.write(
      _wordParagraph(
        'RINCIAN DATA SANITASI',
        bold: true,
        center: true,
        fontSize: 22,
      ),
    );
    appendix.write(
      _wordParagraph(
        'Periode ${_formatWordDate(data.periodStart)} - ${_formatWordDate(data.periodEnd)}',
        center: true,
        fontSize: 18,
      ),
    );
    appendix.write(_wordParagraph('', fontSize: 10));

    final List<List<String>> rows = <List<String>>[
      <String>[
        'Tanggal',
        'Bull',
        'Sanitasi Kandang',
        'Sanitasi Tempat Makan',
        'Sanitasi Pejantan',
        'Keterangan',
        'Nama Petugas',
      ],
      for (final ActivityRecord record in records)
        <String>[
          _formatWordDate(record.tanggal),
          _bullLabelForRecord(record, data),
          record.data['sanitasi_kandang'] == true ? 'Ya' : '-',
          record.data['sanitasi_tempat_pakan'] == true ? 'Ya' : '-',
          record.data['sanitasi_pejantan'] == true ? 'Ya' : '-',
          _detailValue(record.data['keterangan']),
          _detailValue(record.data['nama_petugas']),
        ],
    ];
    appendix.write(_wordDetailTable(rows));

    final int sectionIndex = xml.lastIndexOf('<w:sectPr');
    if (sectionIndex < 0) {
      throw StateError('Template sanitasi tidak valid: section Word tidak ditemukan.');
    }
    return xml.replaceRange(sectionIndex, sectionIndex, appendix.toString());
  }

  String _wordParagraph(
    String text, {
    bool bold = false,
    bool center = false,
    int fontSize = 18,
  }) {
    final String escaped = _xmlEscape(text);
    final String alignment = center ? '<w:jc w:val="center"/>' : '';
    final String boldXml = bold ? '<w:b/>' : '';
    return '<w:p><w:pPr>$alignment</w:pPr><w:r><w:rPr>'
        '$boldXml<w:sz w:val="$fontSize"/><w:szCs w:val="$fontSize"/>'
        '</w:rPr><w:t xml:space="preserve">$escaped</w:t></w:r></w:p>';
  }

  String _wordDetailTable(List<List<String>> rows) {
    const List<int> widths = <int>[1150, 1350, 1250, 1500, 1250, 2200, 1600];
    final StringBuffer xml = StringBuffer();
    xml.write(
      '<w:tbl><w:tblPr><w:tblStyle w:val="TableGrid"/>'
      '<w:tblW w:w="0" w:type="auto"/></w:tblPr><w:tblGrid>',
    );
    for (final int width in widths) {
      xml.write('<w:gridCol w:w="$width"/>');
    }
    xml.write('</w:tblGrid>');
    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final bool header = rowIndex == 0;
      xml.write('<w:tr>');
      for (int col = 0; col < rows[rowIndex].length; col++) {
        final String value = _xmlEscape(rows[rowIndex][col]);
        final String shade = header ? '<w:shd w:val="clear" w:fill="E2F0D9"/>' : '';
        final String bold = header ? '<w:b/>' : '';
        xml.write(
          '<w:tc><w:tcPr><w:tcW w:w="${widths[col]}" w:type="dxa"/>'
          '$shade<w:vAlign w:val="center"/></w:tcPr>'
          '<w:p><w:pPr><w:spacing w:after="0"/></w:pPr><w:r><w:rPr>'
          '$bold<w:sz w:val="12"/><w:szCs w:val="12"/></w:rPr>'
          '<w:t xml:space="preserve">$value</w:t></w:r></w:p></w:tc>',
        );
      }
      xml.write('</w:tr>');
    }
    xml.write('</w:tbl>');
    return xml.toString();
  }

  List<pw.Widget> _pdfDetailSection(ReportExportData data) {
    final List<ActivityRecord> records = data.records
        .where(_hasAnySanitasi)
        .toList(growable: false)
      ..sort((a, b) {
        final int dateCompare = a.tanggal.compareTo(b.tanggal);
        if (dateCompare != 0) return dateCompare;
        return _bullLabelForRecord(a, data)
            .toLowerCase()
            .compareTo(_bullLabelForRecord(b, data).toLowerCase());
      });

    final List<List<String>> rows = <List<String>>[
      <String>[
        'Tanggal',
        'Bull',
        'Kandang',
        'Tempat Makan',
        'Pejantan',
        'Keterangan',
        'Nama Petugas',
      ],
      for (final ActivityRecord record in records)
        <String>[
          _formatWordDate(record.tanggal),
          _bullLabelForRecord(record, data),
          record.data['sanitasi_kandang'] == true ? 'Ya' : '-',
          record.data['sanitasi_tempat_pakan'] == true ? 'Ya' : '-',
          record.data['sanitasi_pejantan'] == true ? 'Ya' : '-',
          _detailValue(record.data['keterangan']),
          _detailValue(record.data['nama_petugas']),
        ],
    ];

    return <pw.Widget>[
      pw.Text(
        'RINCIAN DATA SANITASI',
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Periode ${_formatWordDate(data.periodStart)} - ${_formatWordDate(data.periodEnd)}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 12),
      pw.TableHelper.fromTextArray(
        data: rows,
        headerCount: 1,
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.45),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
        headerStyle: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 6),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        columnWidths: <int, pw.TableColumnWidth>{
          0: const pw.FlexColumnWidth(1.1),
          1: const pw.FlexColumnWidth(1.3),
          2: const pw.FlexColumnWidth(1.0),
          3: const pw.FlexColumnWidth(1.2),
          4: const pw.FlexColumnWidth(1.0),
          5: const pw.FlexColumnWidth(2.2),
          6: const pw.FlexColumnWidth(1.6),
        },
      ),
    ];
  }

  String _detailValue(dynamic value) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  String _bullLabelForRecord(ActivityRecord record, ReportExportData data) {
    final BullModel? bull = data.bulls[record.bull_id];
    if (bull != null) {
      final String name = bull.nama.trim();
      final String code = bull.kode_bull.trim();
      if (name.isNotEmpty && code.isNotEmpty) return '$name ($code)';
      if (name.isNotEmpty) return name;
      if (code.isNotEmpty) return code;
    }
    return 'Bull ${_shortId(record.bull_id)}';
  }

  String _formatWordDate(DateTime value) {
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
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  pw.Widget _pdfFirstPage({
    required ReportExportData data,
    required DateTime month,
    required List<_SanitasiBullColumn> bulls,
    required pw.MemoryImage logo,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        _pdfHeader(logo),
        pw.SizedBox(height: 8),
        pw.Text(
          '(Pembersihan Lantai Kandang, Tempat Pakan dan Tempat Minum dan Memandikan Pejantan)',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'WAKTU PELAKSANAAN : SETIAP HARI',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text('Waktu :', style: const pw.TextStyle(fontSize: 7)),
        pw.SizedBox(height: 5),
        _pdfSanitasiTable(
          data: data,
          month: month,
          bulls: bulls,
          startDay: 1,
          endDay: 18,
          includeHeader: true,
        ),
      ],
    );
  }

  pw.Widget _pdfContinuationPage({
    required ReportExportData data,
    required DateTime month,
    required List<_SanitasiBullColumn> bulls,
  }) {
    return pw.Align(
      alignment: pw.Alignment.topCenter,
      child: _pdfSanitasiTable(
        data: data,
        month: month,
        bulls: bulls,
        startDay: 19,
        endDay: 31,
        includeHeader: false,
      ),
    );
  }

  pw.Widget _pdfHeader(pw.MemoryImage logo) {
    return pw.SizedBox(
      height: 108,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.SizedBox(
            width: 92,
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Image(logo, width: 49, height: 67),
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              children: <pw.Widget>[
                pw.SizedBox(height: 8),
                pw.Text(
                  'BALAI INSEMINASI BUATAN',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'PROVINSI KALIMANTAN SELATAN',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 23),
                pw.Text(
                  'FORMULIR SANITASI KANDANG DAN PEJANTAN',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(
            width: 118,
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(top: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  _pdfMetaRow('No. Dok', 'SOP-6.3.l'),
                  _pdfMetaRow('Revisi', '3'),
                  _pdfMetaRow('Tgl Berlaku', '1 April 2019'),
                  _pdfMetaRow('Halaman', '     dari 12'),
                  _pdfMetaRow('Paraf', ''),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: <pw.Widget>[
          pw.SizedBox(
            width: 45,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 6)),
          ),
          pw.Text(':', style: const pw.TextStyle(fontSize: 6)),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 6)),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSanitasiTable({
    required ReportExportData data,
    required DateTime month,
    required List<_SanitasiBullColumn> bulls,
    required int startDay,
    required int endDay,
    required bool includeHeader,
  }) {
    final List<ActivityRecord> records = _recordsForMonth(data, month);
    final Map<String, bool> marks = <String, bool>{};
    for (final ActivityRecord record in records) {
      marks['${record.tanggal.day}|${record.bull_id}'] = true;
    }

    final List<pw.TableRow> rows = <pw.TableRow>[];
    if (includeHeader) {
      rows.add(
        pw.TableRow(
          children: <pw.Widget>[
            _pdfFixedCell('', height: 9.95, fontSize: 6),
            for (int i = 0; i < _bullSlotCount; i++)
              _pdfFixedCell(
                '${i + 1}',
                height: 9.95,
                fontSize: 6,
                bold: true,
              ),
            _pdfFixedCell(
              'KETERANGAN',
              height: 9.95,
              fontSize: 6,
              bold: true,
            ),
            _pdfFixedCell(
              'PARAF\nPETUGAS',
              height: 9.95,
              fontSize: 6,
              bold: true,
            ),
          ],
        ),
      );
      rows.add(
        pw.TableRow(
          children: <pw.Widget>[
            _pdfFixedCell('Tgl', height: 45.4, fontSize: 6, bold: true),
            for (final _SanitasiBullColumn bull in bulls)
              _pdfVerticalBullCell(bull.label),
            _pdfFixedCell('', height: 45.4, fontSize: 6),
            _pdfFixedCell('', height: 45.4, fontSize: 6),
          ],
        ),
      );
    }

    for (int day = startDay; day <= endDay; day++) {
      final bool validDay = day <= _daysInMonth(month);
      final List<ActivityRecord> dayRecords = validDay
          ? records.where((record) => record.tanggal.day == day).toList()
          : <ActivityRecord>[];
      rows.add(
        pw.TableRow(
          children: <pw.Widget>[
            _pdfFixedCell(
              '$day',
              height: 11.35,
              fontSize: 6,
              alignLeft: true,
            ),
            for (final _SanitasiBullColumn bull in bulls)
              validDay &&
                      bull.id.isNotEmpty &&
                      marks['$day|${bull.id}'] == true
                  ? _pdfCheckCell(height: 11.35)
                  : _pdfFixedCell(
                      '',
                      height: 11.35,
                      fontSize: 6,
                    ),
            _pdfNotesCell(
              _notesForDay(dayRecords),
              height: 11.35,
            ),
            _pdfPetugasCell(
              _petugasForDay(dayRecords),
              height: 11.35,
            ),
          ],
        ),
      );
    }

    final Map<int, pw.TableColumnWidth> widths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < _wordGridWidths.length; i++) {
      widths[i] = pw.FixedColumnWidth(_wordGridWidths[i] * 0.05);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.45),
      columnWidths: widths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  pw.Widget _pdfNotesCell(String value, {required double height}) {
    return pw.Container(
      height: height,
      alignment: pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 1),
      child: pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        alignment: pw.Alignment.centerLeft,
        child: pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 6),
        ),
      ),
    );
  }

  pw.Widget _pdfPetugasCell(String value, {required double height}) {
    return pw.Container(
      height: height,
      alignment: pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 1),
      child: value.trim().isEmpty
          ? pw.SizedBox()
          : pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                value,
                style: const pw.TextStyle(fontSize: 6),
              ),
            ),
    );
  }

  pw.Widget _pdfCheckCell({required double height}) {
    return pw.Container(
      height: height,
      alignment: pw.Alignment.center,
      child: pw.CustomPaint(
        size: const PdfPoint(7, 5.5),
        painter: (canvas, size) {
          canvas
            ..setStrokeColor(PdfColors.black)
            ..setLineWidth(1.1)
            ..drawLine(
              size.x * 0.08,
              size.y * 0.52,
              size.x * 0.36,
              size.y * 0.18,
            )
            ..drawLine(
              size.x * 0.36,
              size.y * 0.18,
              size.x * 0.92,
              size.y * 0.86,
            );
        },
      ),
    );
  }

  pw.Widget _pdfVerticalBullCell(String value) {
    if (value.trim().isEmpty) {
      return _pdfFixedCell('', height: 45.4, fontSize: 6);
    }
    return pw.Container(
      height: 45.4,
      alignment: pw.Alignment.center,
      child: pw.Transform.rotate(
        angle: math.pi / 2,
        child: pw.Text(
          _shortBullName(value),
          maxLines: 1,
          style: pw.TextStyle(
            fontSize: 6,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _pdfFixedCell(
    String value, {
    required double height,
    required double fontSize,
    bool bold = false,
    bool alignLeft = false,
  }) {
    return pw.Container(
      height: height,
      alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 1),
      child: pw.Text(
        value,
        maxLines: value.contains('\n') ? 2 : 1,
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  List<_SanitasiBullColumn> _bullSlots(ReportExportData data) {
    final List<_SanitasiBullColumn> real = _bullColumns(data);
    final List<_SanitasiBullColumn> result = real.take(_bullSlotCount).toList();
    while (result.length < _bullSlotCount) {
      result.add(const _SanitasiBullColumn(id: '', label: ''));
    }
    return result;
  }

  List<_SanitasiBullColumn> _bullColumns(ReportExportData data) {
    final Map<String, _SanitasiBullColumn> result = <String, _SanitasiBullColumn>{};
    for (final BullModel bull in data.bulls.values) {
      final String name = bull.nama.trim().isNotEmpty
          ? bull.nama.trim()
          : bull.kode_bull.trim().isNotEmpty
              ? bull.kode_bull.trim()
              : 'Bull';
      result[bull.id] = _SanitasiBullColumn(id: bull.id, label: name);
    }
    for (final ActivityRecord record in data.records) {
      result.putIfAbsent(
        record.bull_id,
        () => _SanitasiBullColumn(
          id: record.bull_id,
          label: 'Bull ${_shortId(record.bull_id)}',
        ),
      );
    }
    final List<_SanitasiBullColumn> values = result.values.toList();
    values.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return values;
  }

  List<ActivityRecord> _recordsForMonth(ReportExportData data, DateTime month) {
    return data.records.where((record) {
      return record.tanggal.year == month.year &&
          record.tanggal.month == month.month &&
          _hasAnySanitasi(record);
    }).toList(growable: false);
  }

  bool _hasAnySanitasi(ActivityRecord record) {
    return record.data['sanitasi_kandang'] == true ||
        record.data['sanitasi_tempat_pakan'] == true ||
        record.data['sanitasi_pejantan'] == true;
  }

  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  String _notesForDay(List<ActivityRecord> records) {
    // Kolom KETERANGAN hanya menampilkan isi keterangan yang benar-benar
    // ditulis pada aktivitas. Kode P/K/TM tidak perlu ditampilkan karena jenis
    // sanitasi sudah direpresentasikan oleh tanda centang pada kolom bull.
    final Set<String> notes = <String>{};
    for (final ActivityRecord record in records) {
      final String note = record.data['keterangan']?.toString().trim() ?? '';
      if (note.isNotEmpty) notes.add(note);
    }

    if (notes.isEmpty) return '-';
    return notes.join(' / ');
  }

  String _petugasForDay(List<ActivityRecord> records) {
    // Prioritaskan nama petugas pelaksana yang benar-benar diisi pada aktivitas.
    // "Petugas BullCare" adalah nama default/fallback akun. Jika pada tanggal
    // yang sama ada nama petugas lain, fallback tersebut tidak ikut ditampilkan.
    // Fallback baru dipakai apabila memang tidak ada nama petugas asli.
    final Set<String> actualNames = <String>{};
    final Set<String> fallbackNames = <String>{};

    for (final ActivityRecord record in records) {
      final String name = record.data['nama_petugas']?.toString().trim() ?? '';
      if (name.isEmpty) continue;

      if (_isDefaultPetugasName(name)) {
        fallbackNames.add(name);
      } else {
        actualNames.add(name);
      }
    }

    if (actualNames.isNotEmpty) return actualNames.join(' / ');
    if (fallbackNames.isNotEmpty) return fallbackNames.join(' / ');
    return '-';
  }

  bool _isDefaultPetugasName(String value) {
    final String normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
    return normalized == 'petugas bullcare';
  }


  String _shortBullName(String value) {
    final String compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 13) return compact;
    return '${compact.substring(0, 12)}.';
  }

  String _shortId(String value) {
    return value.length <= 6 ? value : value.substring(0, 6);
  }

  String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _SanitasiBullColumn {
  const _SanitasiBullColumn({required this.id, required this.label});

  final String id;
  final String label;
}
