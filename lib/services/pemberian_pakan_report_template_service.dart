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

/// Export khusus aktivitas Pemberian Pakan menggunakan formulir SOP-6.3a.
///
/// Tiga halaman utama tetap mengikuti dokumen sumber:
/// 1. Pemberian Pakan Hijauan
/// 2. Pemberian Konsentrat
/// 3. Pemberian Kecambah
///
/// Sistem CRUD, Firestore, reminder, dan export aktivitas lain tidak diubah.
class PemberianPakanReportTemplateService {
  const PemberianPakanReportTemplateService();

  static const String _wordTemplateAsset =
      'assets/templates/form_pemberian_pakan_sop_6_3a.docx';
  static const List<String> _pdfTemplateAssets = <String>[
    'assets/templates/form_pemberian_pakan_sop_6_3a_page_1.png',
    'assets/templates/form_pemberian_pakan_sop_6_3a_page_2.png',
    'assets/templates/form_pemberian_pakan_sop_6_3a_page_3.png',
  ];

  static const int _bullSlotCount = 30;
  static const double _backgroundWidthPx = 1602;
  static const double _backgroundHeightPx = 1133;

  // Batas kolom tabel pada hasil render template asli (piksel).
  // Kolom: No/Tgl, 30 bull, Total, Paraf.
  static const List<double> _columnBoundsPx = <double>[
    15.5,
    69.0,
    117.0,
    164.0,
    211.5,
    259.0,
    306.0,
    354.0,
    401.0,
    448.0,
    496.0,
    543.0,
    590.5,
    638.0,
    685.0,
    733.0,
    780.0,
    827.0,
    875.0,
    922.0,
    969.5,
    1017.0,
    1064.0,
    1112.0,
    1159.0,
    1206.5,
    1254.0,
    1301.0,
    1348.5,
    1396.0,
    1443.0,
    1491.0,
    1538.0,
    1585.5,
  ];

  // Batas vertikal baris tanggal 1-31 pada hasil render template asli.
  // Elemen pertama adalah bagian atas tanggal 1, berikutnya batas bawah
  // masing-masing baris sampai tanggal 31.
  static const List<double> _dayRowBoundsPx = <double>[
    444.5,
    461.0,
    477.0,
    494.0,
    510.0,
    526.0,
    543.0,
    559.0,
    575.5,
    592.0,
    608.0,
    624.5,
    641.0,
    657.0,
    674.0,
    690.0,
    706.0,
    723.0,
    739.0,
    755.5,
    772.0,
    788.0,
    804.5,
    821.0,
    837.0,
    854.0,
    870.0,
    886.0,
    903.0,
    919.0,
    935.5,
    952.0,
  ];

  static const List<_PakanPageDefinition> _pageDefinitions =
      <_PakanPageDefinition>[
    _PakanPageDefinition(fieldKey: 'hijauan'),
    _PakanPageDefinition(fieldKey: 'konsentrat'),
    _PakanPageDefinition(fieldKey: 'kecambah'),
  ];

  Future<Uint8List> buildDocx({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    _validateSingleMonth(data);

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
    _validateSingleMonth(data);

    final List<pw.MemoryImage> backgrounds = <pw.MemoryImage>[];
    for (final String asset in _pdfTemplateAssets) {
      final ByteData imageData = await rootBundle.load(asset);
      final Uint8List imageBytes = imageData.buffer.asUint8List(
        imageData.offsetInBytes,
        imageData.lengthInBytes,
      );
      backgrounds.add(pw.MemoryImage(imageBytes));
    }

    final pw.Document document = pw.Document(
      title: 'Formulir Pemberian Pakan SOP-6.3a',
      author: exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama,
      creator: 'BullCare',
    );
    final DateTime month = DateTime(data.periodStart.year, data.periodStart.month, 1);
    final List<_PakanBullColumn> bulls = _bullSlots(data);

    for (int index = 0; index < _pageDefinitions.length; index++) {
      final _PakanPageDefinition page = _pageDefinitions[index];
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (context) => _buildPdfTemplatePage(
            data: data,
            month: month,
            bulls: bulls,
            background: backgrounds[index],
            fieldKey: page.fieldKey,
          ),
        ),
      );
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        maxPages: 100,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => _pdfDetailSection(data),
      ),
    );

    return document.save();
  }

  String _patchWordTemplate(String xml, ReportExportData data) {
    final DateTime month = DateTime(data.periodStart.year, data.periodStart.month, 1);
    final List<_PakanBullColumn> bulls = _bullSlots(data);

    String result = _replaceMonthLabels(xml, month);
    final List<RegExpMatch> tableMatches =
        RegExp(r'<w:tbl>.*?</w:tbl>', dotAll: true).allMatches(result).toList();
    if (tableMatches.length < 9) {
      throw StateError(
        'Template pemberian pakan tidak valid: struktur tabel SOP-6.3a tidak lengkap.',
      );
    }

    // Tabel data utama berada pada indeks 2, 5, dan 8. Patch dari belakang
    // agar indeks karakter tabel sebelumnya tidak berubah.
    for (int pageIndex = _pageDefinitions.length - 1; pageIndex >= 0; pageIndex--) {
      final int tableIndex = 2 + (pageIndex * 3);
      final RegExpMatch tableMatch = tableMatches[tableIndex];
      final String patchedTable = _patchWordDataTable(
        tableMatch.group(0)!,
        data: data,
        month: month,
        bulls: bulls,
        fieldKey: _pageDefinitions[pageIndex].fieldKey,
      );
      result = result.replaceRange(tableMatch.start, tableMatch.end, patchedTable);
    }

    return result;
  }

  String _replaceMonthLabels(String xml, DateTime month) {
    const String marker = '<w:t xml:space="preserve"> :</w:t>';
    if (!xml.contains(marker)) {
      throw StateError(
        'Template pemberian pakan tidak valid: label bulan tidak ditemukan.',
      );
    }
    final String replacement =
        '<w:t xml:space="preserve"> : ${_xmlEscape(_formatMonth(month))}</w:t>';
    return xml.replaceAll(marker, replacement);
  }

  String _patchWordDataTable(
    String tableXml, {
    required ReportExportData data,
    required DateTime month,
    required List<_PakanBullColumn> bulls,
    required String fieldKey,
  }) {
    final List<RegExpMatch> rowMatches = RegExp(
      r'<w:tr(?:\s[^>]*)?>.*?</w:tr>',
      dotAll: true,
    ).allMatches(tableXml).toList();
    if (rowMatches.length < 35) {
      throw StateError(
        'Template pemberian pakan tidak valid: baris tanggal 1-31 tidak lengkap.',
      );
    }

    final List<ActivityRecord> records = _recordsForMonth(data, month);
    final List<String> patchedRows = <String>[
      for (final RegExpMatch row in rowMatches) row.group(0)!,
    ];

    // Baris nama bull berada pada row ke-3 (indeks 2).
    patchedRows[2] = _replaceRowCellTexts(
      patchedRows[2],
      <String>[
        '',
        for (final _PakanBullColumn bull in bulls) bull.label,
        '',
        '',
      ],
    );

    for (int day = 1; day <= 31; day++) {
      final bool validDay = day <= _daysInMonth(month);
      final List<ActivityRecord> dayRecords = validDay
          ? records.where((record) => record.tanggal.day == day).toList()
          : <ActivityRecord>[];
      final List<String> values = <String>[
        '$day',
        for (final _PakanBullColumn bull in bulls)
          validDay && bull.id.isNotEmpty
              ? _cellValue(dayRecords, bull.id, fieldKey)
              : '',
        validDay ? _totalForDay(dayRecords, fieldKey) : '',
        validDay ? _petugasForDay(dayRecords, fieldKey: fieldKey) : '',
      ];
      patchedRows[day + 2] = _replaceRowCellTexts(
        patchedRows[day + 2],
        values,
      );
    }

    String patchedTable = tableXml;
    for (int i = rowMatches.length - 1; i >= 0; i--) {
      patchedTable = patchedTable.replaceRange(
        rowMatches[i].start,
        rowMatches[i].end,
        patchedRows[i],
      );
    }
    return patchedTable;
  }

  String _replaceRowCellTexts(String rowXml, List<String> values) {
    final List<RegExpMatch> cellMatches =
        RegExp(r'<w:tc>.*?</w:tc>', dotAll: true).allMatches(rowXml).toList();
    if (cellMatches.length != values.length) {
      throw StateError(
        'Template pemberian pakan tidak valid: jumlah kolom ${cellMatches.length}, '
        'seharusnya ${values.length}.',
      );
    }

    String result = rowXml;
    for (int i = cellMatches.length - 1; i >= 0; i--) {
      final RegExpMatch match = cellMatches[i];
      result = result.replaceRange(
        match.start,
        match.end,
        _replaceCellText(match.group(0)!, values[i]),
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
      // Sel data kosong pada template tidak mempunyai run. Paksa font 5 pt
      // supaya data masuk ke sel sempit tanpa mengubah tinggi baris SOP.
      final String run =
          '<w:r><w:rPr><w:sz w:val="10"/><w:szCs w:val="10"/></w:rPr>'
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
        .where((record) => record.collectionName == 'pemberian_pakan')
        .toList(growable: false)
      ..sort((a, b) {
        final int dateCompare = a.tanggal.compareTo(b.tanggal);
        if (dateCompare != 0) return dateCompare;
        return _bullLabelForRecord(a, data)
            .toLowerCase()
            .compareTo(_bullLabelForRecord(b, data).toLowerCase());
      });
    if (records.isEmpty) return xml;

    final StringBuffer appendix = StringBuffer()
      ..write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
      ..write(
        _wordParagraph(
          'RINCIAN DATA PEMBERIAN PAKAN',
          bold: true,
          center: true,
          fontSize: 22,
        ),
      )
      ..write(
        _wordParagraph(
          'Periode ${_formatWordDate(data.periodStart)} - ${_formatWordDate(data.periodEnd)}',
          center: true,
          fontSize: 18,
        ),
      )
      ..write(_wordParagraph('', fontSize: 10));

    final List<List<String>> rows = <List<String>>[
      <String>[
        'Tanggal',
        'Bull',
        'Hijauan (Kg)',
        'Konsentrat (Kg)',
        'Kecambah (Kg)',
        'Keterangan',
        'Nama Petugas',
      ],
      for (final ActivityRecord record in records)
        <String>[
          _formatWordDate(record.tanggal),
          _bullLabelForRecord(record, data),
          _detailValue(record.data['hijauan']),
          _detailValue(record.data['konsentrat']),
          _detailValue(record.data['kecambah']),
          _detailValue(record.data['keterangan']),
          _detailValue(record.data['nama_petugas']),
        ],
    ];
    appendix.write(_wordDetailTable(rows));

    final int sectionIndex = xml.lastIndexOf('<w:sectPr');
    if (sectionIndex < 0) {
      throw StateError(
        'Template pemberian pakan tidak valid: section Word tidak ditemukan.',
      );
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
    const List<int> widths = <int>[1150, 1350, 1200, 1350, 1200, 2300, 1600];
    final StringBuffer xml = StringBuffer()
      ..write(
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
        final String shade =
            header ? '<w:shd w:val="clear" w:fill="E2F0D9"/>' : '';
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

  pw.Widget _buildPdfTemplatePage({
    required ReportExportData data,
    required DateTime month,
    required List<_PakanBullColumn> bulls,
    required pw.MemoryImage background,
    required String fieldKey,
  }) {
    final PdfPageFormat format = PdfPageFormat.a4.landscape;
    final List<ActivityRecord> records = _recordsForMonth(data, month);
    final List<pw.Widget> children = <pw.Widget>[
      pw.Image(
        background,
        width: format.width,
        height: format.height,
        fit: pw.BoxFit.fill,
      ),
      _pdfTextBox(
        text: _formatMonth(month),
        leftPx: 110,
        topPx: 300,
        widthPx: 165,
        heightPx: 16,
        fontSize: 6,
        align: pw.Alignment.centerLeft,
      ),
    ];

    // Tutup nama bull bawaan template, lalu isi dengan bull dari database.
    for (int bullIndex = 0; bullIndex < _bullSlotCount; bullIndex++) {
      final double left = _columnBoundsPx[bullIndex + 1];
      final double right = _columnBoundsPx[bullIndex + 2];
      children.add(
        _pdfWhiteBox(
          leftPx: left + 1.5,
          topPx: 357,
          widthPx: (right - left) - 3,
          heightPx: 85,
        ),
      );
      final String label = bulls[bullIndex].label;
      if (label.trim().isNotEmpty) {
        children.add(
          _pdfVerticalTextBox(
            text: _shortBullName(label),
            leftPx: left + 2,
            topPx: 357,
            widthPx: (right - left) - 4,
            heightPx: 85,
          ),
        );
      }
    }

    for (int day = 1; day <= 31; day++) {
      final bool validDay = day <= _daysInMonth(month);
      final List<ActivityRecord> dayRecords = validDay
          ? records.where((record) => record.tanggal.day == day).toList()
          : <ActivityRecord>[];
      final double top = _dayRowBoundsPx[day - 1] + 1;
      final double bottom = _dayRowBoundsPx[day] - 1;
      final double height = math.max(4.0, bottom - top);

      for (int bullIndex = 0; bullIndex < _bullSlotCount; bullIndex++) {
        final _PakanBullColumn bull = bulls[bullIndex];
        if (!validDay || bull.id.isEmpty) continue;
        final String value = _cellValue(dayRecords, bull.id, fieldKey);
        if (value.isEmpty) continue;
        final double left = _columnBoundsPx[bullIndex + 1];
        final double right = _columnBoundsPx[bullIndex + 2];
        children.add(
          _pdfTextBox(
            text: value,
            leftPx: left + 1,
            topPx: top,
            widthPx: (right - left) - 2,
            heightPx: height,
            fontSize: 5,
          ),
        );
      }

      if (validDay) {
        final String total = _totalForDay(dayRecords, fieldKey);
        if (total.isNotEmpty) {
          final double left = _columnBoundsPx[31];
          final double right = _columnBoundsPx[32];
          children.add(
            _pdfTextBox(
              text: total,
              leftPx: left + 1,
              topPx: top,
              widthPx: (right - left) - 2,
              heightPx: height,
              fontSize: 5,
            ),
          );
        }

        final String petugas = _petugasForDay(dayRecords, fieldKey: fieldKey);
        if (petugas.isNotEmpty && petugas != '-') {
          final double left = _columnBoundsPx[32];
          final double right = _columnBoundsPx[33];
          children.add(
            _pdfTextBox(
              text: petugas,
              leftPx: left + 1,
              topPx: top,
              widthPx: (right - left) - 2,
              heightPx: height,
              fontSize: 4.2,
            ),
          );
        }
      }
    }

    return pw.Stack(children: children);
  }

  pw.Widget _pdfWhiteBox({
    required double leftPx,
    required double topPx,
    required double widthPx,
    required double heightPx,
  }) {
    return pw.Positioned(
      left: _pxX(leftPx),
      top: _pxY(topPx),
      child: pw.SizedBox(
        width: _pxX(widthPx),
        height: _pxY(heightPx),
        child: pw.Container(color: PdfColors.white),
      ),
    );
  }

  pw.Widget _pdfVerticalTextBox({
    required String text,
    required double leftPx,
    required double topPx,
    required double widthPx,
    required double heightPx,
  }) {
    return pw.Positioned(
      left: _pxX(leftPx),
      top: _pxY(topPx),
      child: pw.SizedBox(
        width: _pxX(widthPx),
        height: _pxY(heightPx),
        child: pw.Center(
          child: pw.Transform.rotate(
            angle: math.pi / 2,
            child: pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              child: pw.Text(
                text,
                maxLines: 1,
                style: pw.TextStyle(
                  fontSize: 6,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  pw.Widget _pdfTextBox({
    required String text,
    required double leftPx,
    required double topPx,
    required double widthPx,
    required double heightPx,
    required double fontSize,
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Positioned(
      left: _pxX(leftPx),
      top: _pxY(topPx),
      child: pw.SizedBox(
        width: _pxX(widthPx),
        height: _pxY(heightPx),
        child: pw.Container(
          alignment: align,
          padding: const pw.EdgeInsets.symmetric(horizontal: 0.6),
          child: pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            child: pw.Text(
              text,
              maxLines: 1,
              style: pw.TextStyle(fontSize: fontSize),
            ),
          ),
        ),
      ),
    );
  }

  List<pw.Widget> _pdfDetailSection(ReportExportData data) {
    final List<ActivityRecord> records = data.records
        .where((record) => record.collectionName == 'pemberian_pakan')
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
        'Hijauan (Kg)',
        'Konsentrat (Kg)',
        'Kecambah (Kg)',
        'Keterangan',
        'Nama Petugas',
      ],
      for (final ActivityRecord record in records)
        <String>[
          _formatWordDate(record.tanggal),
          _bullLabelForRecord(record, data),
          _detailValue(record.data['hijauan']),
          _detailValue(record.data['konsentrat']),
          _detailValue(record.data['kecambah']),
          _detailValue(record.data['keterangan']),
          _detailValue(record.data['nama_petugas']),
        ],
    ];

    return <pw.Widget>[
      pw.Text(
        'RINCIAN DATA PEMBERIAN PAKAN',
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
          3: const pw.FlexColumnWidth(1.1),
          4: const pw.FlexColumnWidth(1.0),
          5: const pw.FlexColumnWidth(2.2),
          6: const pw.FlexColumnWidth(1.6),
        },
      ),
    ];
  }

  List<_PakanBullColumn> _bullSlots(ReportExportData data) {
    final List<_PakanBullColumn> real = _bullColumns(data);
    final List<_PakanBullColumn> result = real.take(_bullSlotCount).toList();
    while (result.length < _bullSlotCount) {
      result.add(const _PakanBullColumn(id: '', label: ''));
    }
    return result;
  }

  List<_PakanBullColumn> _bullColumns(ReportExportData data) {
    final Map<String, _PakanBullColumn> result = <String, _PakanBullColumn>{};
    for (final BullModel bull in data.bulls.values) {
      final String name = bull.nama.trim().isNotEmpty
          ? bull.nama.trim()
          : bull.kode_bull.trim().isNotEmpty
              ? bull.kode_bull.trim()
              : 'Bull';
      result[bull.id] = _PakanBullColumn(id: bull.id, label: name);
    }
    for (final ActivityRecord record in data.records) {
      result.putIfAbsent(
        record.bull_id,
        () => _PakanBullColumn(
          id: record.bull_id,
          label: 'Bull ${_shortId(record.bull_id)}',
        ),
      );
    }
    final List<_PakanBullColumn> values = result.values.toList();
    values.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return values;
  }

  List<ActivityRecord> _recordsForMonth(ReportExportData data, DateTime month) {
    return data.records.where((record) {
      return record.collectionName == 'pemberian_pakan' &&
          record.tanggal.year == month.year &&
          record.tanggal.month == month.month;
    }).toList(growable: false);
  }

  String _cellValue(
    List<ActivityRecord> dayRecords,
    String bullId,
    String fieldKey,
  ) {
    final List<String> values = dayRecords
        .where((record) => record.bull_id == bullId)
        .map((record) => _cleanCellValue(record.data[fieldKey]))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (values.isEmpty) return '';
    if (values.length == 1) return values.first;

    final List<double?> parsed = values.map(_parseNumber).toList(growable: false);
    if (parsed.every((value) => value != null)) {
      return _formatNumber(
        parsed.fold<double>(0, (sum, value) => sum + (value ?? 0)),
      );
    }

    final Set<String> unique = <String>{...values};
    return unique.join('/');
  }

  String _totalForDay(List<ActivityRecord> dayRecords, String fieldKey) {
    double total = 0;
    bool found = false;
    for (final ActivityRecord record in dayRecords) {
      final double? value = _parseNumber(record.data[fieldKey]);
      if (value == null) continue;
      total += value;
      found = true;
    }
    return found ? _formatNumber(total) : '';
  }

  String _petugasForDay(
    List<ActivityRecord> dayRecords, {
    required String fieldKey,
  }) {
    final Set<String> actualNames = <String>{};
    final Set<String> fallbackNames = <String>{};
    for (final ActivityRecord record in dayRecords) {
      if (_cleanCellValue(record.data[fieldKey]).isEmpty) continue;
      final String name = record.data['nama_petugas']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      if (_isDefaultPetugasName(name)) {
        fallbackNames.add(name);
      } else {
        actualNames.add(name);
      }
    }
    if (actualNames.isNotEmpty) return actualNames.join('/');
    if (fallbackNames.isNotEmpty) return fallbackNames.join('/');
    return '';
  }

  bool _isDefaultPetugasName(String value) {
    final String normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
    return normalized == 'petugas bullcare';
  }

  double? _parseNumber(dynamic value) {
    final String text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final RegExpMatch? match = RegExp(r'-?\d+(?:[\.,]\d+)?').firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '')
        .replaceAll('.', ',');
  }

  String _cleanCellValue(dynamic value) {
    return value?.toString().trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
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

  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  void _validateSingleMonth(ReportExportData data) {
    if (data.periodStart.year != data.periodEnd.year ||
        data.periodStart.month != data.periodEnd.month) {
      throw StateError(
        'Formulir pemberian pakan SOP-6.3a dibuat per bulan. '
        'Pilih periode dalam bulan yang sama.',
      );
    }
  }

  String _formatMonth(DateTime value) {
    return '${_monthName(value.month)} ${value.year}';
  }

  String _formatWordDate(DateTime value) {
    return '${value.day} ${_monthName(value.month)} ${value.year}';
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
    return months[month - 1];
  }

  String _shortBullName(String value) {
    final String compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 13) return compact;
    return '${compact.substring(0, 12)}.';
  }

  String _shortId(String value) {
    return value.length <= 6 ? value : value.substring(0, 6);
  }

  double _pxX(double value) {
    return value * PdfPageFormat.a4.landscape.width / _backgroundWidthPx;
  }

  double _pxY(double value) {
    return value * PdfPageFormat.a4.landscape.height / _backgroundHeightPx;
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

class _PakanPageDefinition {
  const _PakanPageDefinition({required this.fieldKey});

  final String fieldKey;
}

class _PakanBullColumn {
  const _PakanBullColumn({required this.id, required this.label});

  final String id;
  final String label;
}
