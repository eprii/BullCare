import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity_record.dart';
import '../models/bull_model.dart';
import '../models/report_export_data.dart';
import '../models/user_model.dart';

/// Export khusus aktivitas Penimbangan menggunakan formulir SOP-6.3b.
///
/// Formulir utama tetap mengikuti dokumen sumber FORMULIR PENIMBANGAN
/// PEJANTAN. Data berat badan dipetakan per bull dan per bulan, kemudian
/// dilengkapi halaman rincian agar tanggal, keterangan, dan nama petugas
/// tetap terbaca tanpa mengubah CRUD, Firestore, atau modul aktivitas lain.
class PenimbanganReportTemplateService {
  const PenimbanganReportTemplateService();

  static const String _wordTemplateAsset =
      'assets/templates/form_penimbangan_pejantan_sop_6_3b.docx';
  static const String _pdfTemplateAsset =
      'assets/templates/form_penimbangan_pejantan_sop_6_3b_page_1.png';

  static const int _bullSlotCount = 30;
  static const double _backgroundWidthPx = 1602;
  static const double _backgroundHeightPx = 1133;

  // Batas kolom tabel pada hasil render template SOP-6.3b (piksel).
  // No, Nama Bull, Bangsa, lalu Januari-Desember.
  static const List<double> _columnBoundsPx = <double>[
    54.0,
    97.0,
    219.0,
    337.0,
    438.0,
    539.0,
    640.0,
    741.0,
    842.0,
    942.0,
    1043.0,
    1144.0,
    1245.0,
    1346.0,
    1447.0,
    1547.0,
  ];

  // Batas vertikal 30 baris bull, mulai setelah dua baris header.
  static const List<double> _dataRowBoundsPx = <double>[
    378.0,
    398.5,
    419.0,
    439.5,
    460.0,
    480.5,
    501.0,
    521.5,
    542.0,
    562.5,
    582.5,
    603.0,
    623.5,
    644.0,
    664.5,
    685.0,
    705.5,
    726.0,
    746.5,
    767.0,
    787.0,
    808.0,
    828.0,
    848.5,
    869.0,
    889.5,
    910.0,
    930.5,
    951.0,
    971.5,
    992.0,
  ];

  static const double _signatureTopPx = 992.0;
  static const double _signatureBottomPx = 1014.5;

  // Urutan pada formulir SOP. Bull yang masih ada di database diprioritaskan
  // mengikuti urutan ini; bull baru yang tidak ada di daftar akan ditambahkan
  // setelahnya secara alfabetis.
  static const List<String> _officialBullOrder = <String>[
    'Agatis',
    'Akasia',
    'Pinus',
    'Kemuning',
    'Mandiangin',
    'Idaman',
    'Ramin',
    'Balau',
    'Kecubung',
    'Rubi',
    'Bacan',
    'Safir',
    'Yakut',
    'Zamrud',
    'Char',
    'Obi',
    'T. Julian',
    'C. Navarin',
    'A. Monde',
    'Lembiru',
    'Swarangan',
    'Brown Eye',
    'Pulai',
    'Nyatoh',
    'Batakan',
    'Sapala',
    'Mahakam',
    'Pacifica',
    'Sampang',
    'Bangkalan',
  ];

  Future<Uint8List> buildDocx({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    _validateSingleYear(data);

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
    _validateSingleYear(data);

    final ByteData imageData = await rootBundle.load(_pdfTemplateAsset);
    final Uint8List imageBytes = imageData.buffer.asUint8List(
      imageData.offsetInBytes,
      imageData.lengthInBytes,
    );
    final pw.MemoryImage background = pw.MemoryImage(imageBytes);

    final pw.Document document = pw.Document(
      title: 'Formulir Penimbangan Pejantan SOP-6.3b',
      author: exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama,
      creator: 'BullCare',
    );
    final List<_PenimbanganBullRow> bulls = _bullSlots(data);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (context) => _buildPdfTemplatePage(
          data: data,
          bulls: bulls,
          background: background,
        ),
      ),
    );

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
    final int year = data.periodStart.year;
    final List<_PenimbanganBullRow> bulls = _bullSlots(data);

    String result = _replaceYearLabel(xml, year);
    final List<RegExpMatch> tableMatches =
        RegExp(r'<w:tbl>.*?</w:tbl>', dotAll: true).allMatches(result).toList();
    if (tableMatches.length < 3) {
      throw StateError(
        'Template penimbangan tidak valid: struktur tabel SOP-6.3b tidak lengkap.',
      );
    }

    final RegExpMatch tableMatch = tableMatches[2];
    final String patchedTable = _patchWordDataTable(
      tableMatch.group(0)!,
      data: data,
      bulls: bulls,
      year: year,
    );
    return result.replaceRange(tableMatch.start, tableMatch.end, patchedTable);
  }

  String _replaceYearLabel(String xml, int year) {
    final RegExp yearRegex = RegExp(
      r'(<w:t>TAHUN</w:t>.*?<w:t(?:\s[^>]*)?>\s*)\d{4}(</w:t>)',
      dotAll: true,
    );
    final RegExpMatch? match = yearRegex.firstMatch(xml);
    if (match == null) {
      throw StateError(
        'Template penimbangan tidak valid: label tahun tidak ditemukan.',
      );
    }
    return xml.replaceRange(
      match.start,
      match.end,
      '${match.group(1)}$year${match.group(2)}',
    );
  }

  String _patchWordDataTable(
    String tableXml, {
    required ReportExportData data,
    required List<_PenimbanganBullRow> bulls,
    required int year,
  }) {
    final List<RegExpMatch> rowMatches = RegExp(
      r'<w:tr(?:\s[^>]*)?>.*?</w:tr>',
      dotAll: true,
    ).allMatches(tableXml).toList();
    if (rowMatches.length < 33) {
      throw StateError(
        'Template penimbangan tidak valid: 30 baris bull tidak lengkap.',
      );
    }

    final List<String> patchedRows = <String>[
      for (final RegExpMatch row in rowMatches) row.group(0)!,
    ];

    for (int bullIndex = 0; bullIndex < _bullSlotCount; bullIndex++) {
      final _PenimbanganBullRow bull = bulls[bullIndex];
      final List<String> values = <String>[
        '${bullIndex + 1}',
        bull.label,
        bull.breed,
        for (int month = 1; month <= 12; month++)
          bull.id.isEmpty ? '' : _monthlyWeight(data, bull.id, year, month),
      ];
      patchedRows[bullIndex + 2] = _replaceRowCellTexts(
        patchedRows[bullIndex + 2],
        values,
      );
    }

    patchedRows[32] = _replaceRowCellTexts(
      patchedRows[32],
      <String>[
        'Paraf Petugas',
        for (int month = 1; month <= 12; month++)
          _petugasForMonth(data, year, month),
      ],
    );

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
        'Template penimbangan tidak valid: jumlah kolom ${cellMatches.length}, '
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
        .where((record) => record.collectionName == 'penimbangan')
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
      ..write(
        _wordParagraph(
          'RINCIAN DATA PENIMBANGAN PEJANTAN',
          bold: true,
          center: true,
          fontSize: 22,
          pageBreakBefore: true,
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
        'Bangsa',
        'Berat Badan (Kg)',
        'Keterangan',
        'Nama Petugas',
      ],
      for (final ActivityRecord record in records)
        <String>[
          _formatWordDate(record.tanggal),
          _bullLabelForRecord(record, data),
          _breedForRecord(record, data),
          _detailValue(record.data['berat_badan']),
          _detailValue(record.data['keterangan']),
          _detailValue(record.data['nama_petugas']),
        ],
    ];
    appendix.write(_wordDetailTable(rows));

    final int sectionIndex = xml.lastIndexOf('<w:sectPr');
    if (sectionIndex < 0) {
      throw StateError(
        'Template penimbangan tidak valid: section Word tidak ditemukan.',
      );
    }
    return xml.replaceRange(sectionIndex, sectionIndex, appendix.toString());
  }

  String _wordParagraph(
    String text, {
    bool bold = false,
    bool center = false,
    int fontSize = 18,
    bool pageBreakBefore = false,
  }) {
    final String escaped = _xmlEscape(text);
    final String alignment = center ? '<w:jc w:val="center"/>' : '';
    final String pageBreak = pageBreakBefore ? '<w:pageBreakBefore/>' : '';
    final String boldXml = bold ? '<w:b/>' : '';
    return '<w:p><w:pPr>$pageBreak$alignment</w:pPr><w:r><w:rPr>'
        '$boldXml<w:sz w:val="$fontSize"/><w:szCs w:val="$fontSize"/>'
        '</w:rPr><w:t xml:space="preserve">$escaped</w:t></w:r></w:p>';
  }

  String _wordDetailTable(List<List<String>> rows) {
    const List<int> widths = <int>[1300, 1700, 1500, 1400, 2800, 1800];
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
    required List<_PenimbanganBullRow> bulls,
    required pw.MemoryImage background,
  }) {
    final PdfPageFormat format = PdfPageFormat.a4.landscape;
    final int year = data.periodStart.year;
    final List<pw.Widget> children = <pw.Widget>[
      pw.Image(
        background,
        width: format.width,
        height: format.height,
        fit: pw.BoxFit.fill,
      ),
      _pdfWhiteBox(
        leftPx: 660,
        topPx: 268,
        widthPx: 285,
        heightPx: 31,
      ),
      _pdfTextBox(
        text: 'TAHUN $year',
        leftPx: 660,
        topPx: 268,
        widthPx: 285,
        heightPx: 31,
        fontSize: 9,
        bold: true,
      ),
    ];

    for (int bullIndex = 0; bullIndex < _bullSlotCount; bullIndex++) {
      final _PenimbanganBullRow bull = bulls[bullIndex];
      final double top = _dataRowBoundsPx[bullIndex] + 1;
      final double bottom = _dataRowBoundsPx[bullIndex + 1] - 1;
      final double height = bottom - top;

      // Tutup nama/bangsa bawaan formulir per sel agar garis pemisah tabel
      // tetap utuh dan data selalu mengikuti database.
      children.add(
        _pdfWhiteBox(
          leftPx: _columnBoundsPx[1] + 1,
          topPx: top,
          widthPx: (_columnBoundsPx[2] - _columnBoundsPx[1]) - 2,
          heightPx: height,
        ),
      );
      children.add(
        _pdfWhiteBox(
          leftPx: _columnBoundsPx[2] + 1,
          topPx: top,
          widthPx: (_columnBoundsPx[3] - _columnBoundsPx[2]) - 2,
          heightPx: height,
        ),
      );
      if (bull.label.isNotEmpty) {
        children.add(
          _pdfTextBox(
            text: bull.label,
            leftPx: _columnBoundsPx[1] + 2,
            topPx: top,
            widthPx: (_columnBoundsPx[2] - _columnBoundsPx[1]) - 4,
            heightPx: height,
            fontSize: 5.4,
            align: pw.Alignment.centerLeft,
          ),
        );
      }
      if (bull.breed.isNotEmpty) {
        children.add(
          _pdfTextBox(
            text: bull.breed,
            leftPx: _columnBoundsPx[2] + 2,
            topPx: top,
            widthPx: (_columnBoundsPx[3] - _columnBoundsPx[2]) - 4,
            heightPx: height,
            fontSize: 5.0,
          ),
        );
      }

      if (bull.id.isEmpty) continue;
      for (int month = 1; month <= 12; month++) {
        final String weight = _monthlyWeight(data, bull.id, year, month);
        if (weight.isEmpty) continue;
        final int columnIndex = month + 2;
        children.add(
          _pdfTextBox(
            text: weight,
            leftPx: _columnBoundsPx[columnIndex] + 1,
            topPx: top,
            widthPx:
                (_columnBoundsPx[columnIndex + 1] - _columnBoundsPx[columnIndex]) -
                    2,
            heightPx: height,
            fontSize: 5.4,
          ),
        );
      }
    }

    for (int month = 1; month <= 12; month++) {
      final String petugas = _petugasForMonth(data, year, month);
      if (petugas.isEmpty) continue;
      final int columnIndex = month + 2;
      children.add(
        _pdfTextBox(
          text: petugas,
          leftPx: _columnBoundsPx[columnIndex] + 1,
          topPx: _signatureTopPx + 1,
          widthPx:
              (_columnBoundsPx[columnIndex + 1] - _columnBoundsPx[columnIndex]) -
                  2,
          heightPx: (_signatureBottomPx - _signatureTopPx) - 2,
          fontSize: 4.2,
        ),
      );
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

  pw.Widget _pdfTextBox({
    required String text,
    required double leftPx,
    required double topPx,
    required double widthPx,
    required double heightPx,
    required double fontSize,
    bool bold = false,
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
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: bold ? pw.FontWeight.bold : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<pw.Widget> _pdfDetailSection(ReportExportData data) {
    final List<ActivityRecord> records = data.records
        .where((record) => record.collectionName == 'penimbangan')
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
        'Bangsa',
        'Berat Badan (Kg)',
        'Keterangan',
        'Nama Petugas',
      ],
      for (final ActivityRecord record in records)
        <String>[
          _formatWordDate(record.tanggal),
          _bullLabelForRecord(record, data),
          _breedForRecord(record, data),
          _detailValue(record.data['berat_badan']),
          _detailValue(record.data['keterangan']),
          _detailValue(record.data['nama_petugas']),
        ],
    ];

    return <pw.Widget>[
      pw.Text(
        'RINCIAN DATA PENIMBANGAN PEJANTAN',
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
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(1.4),
          3: const pw.FlexColumnWidth(1.2),
          4: const pw.FlexColumnWidth(2.5),
          5: const pw.FlexColumnWidth(1.7),
        },
      ),
    ];
  }

  List<_PenimbanganBullRow> _bullSlots(ReportExportData data) {
    final List<_PenimbanganBullRow> real = _bullRows(data);
    final List<_PenimbanganBullRow> result = real.take(_bullSlotCount).toList();
    while (result.length < _bullSlotCount) {
      result.add(const _PenimbanganBullRow(id: '', label: '', breed: ''));
    }
    return result;
  }

  List<_PenimbanganBullRow> _bullRows(ReportExportData data) {
    final Map<String, _PenimbanganBullRow> byId = <String, _PenimbanganBullRow>{};
    for (final BullModel bull in data.bulls.values) {
      final String name = bull.nama.trim().isNotEmpty
          ? bull.nama.trim()
          : bull.kode_bull.trim().isNotEmpty
              ? bull.kode_bull.trim()
              : 'Bull';
      byId[bull.id] = _PenimbanganBullRow(
        id: bull.id,
        label: name,
        breed: bull.bangsa.trim(),
      );
    }
    for (final ActivityRecord record in data.records) {
      byId.putIfAbsent(
        record.bull_id,
        () => _PenimbanganBullRow(
          id: record.bull_id,
          label: 'Bull ${_shortId(record.bull_id)}',
          breed: '',
        ),
      );
    }

    final Map<String, int> order = <String, int>{
      for (int index = 0; index < _officialBullOrder.length; index++)
        _normalizeName(_officialBullOrder[index]): index,
    };
    final List<_PenimbanganBullRow> values = byId.values.toList();
    values.sort((a, b) {
      final int ai = order[_normalizeName(a.label)] ?? 9999;
      final int bi = order[_normalizeName(b.label)] ?? 9999;
      if (ai != bi) return ai.compareTo(bi);
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return values;
  }

  String _monthlyWeight(
    ReportExportData data,
    String bullId,
    int year,
    int month,
  ) {
    ActivityRecord? latest;
    for (final ActivityRecord record in data.records) {
      if (record.collectionName != 'penimbangan' ||
          record.bull_id != bullId ||
          record.tanggal.year != year ||
          record.tanggal.month != month) {
        continue;
      }
      final double? weight = _parseNumber(record.data['berat_badan']);
      if (weight == null) continue;
      if (latest == null || _isLater(record, latest)) {
        latest = record;
      }
    }
    if (latest == null) return '';
    final double? weight = _parseNumber(latest.data['berat_badan']);
    return weight == null ? '' : _formatNumber(weight);
  }

  bool _isLater(ActivityRecord candidate, ActivityRecord current) {
    final int dateCompare = candidate.tanggal.compareTo(current.tanggal);
    if (dateCompare != 0) return dateCompare > 0;
    return candidate.updated_at.isAfter(current.updated_at);
  }

  String _petugasForMonth(ReportExportData data, int year, int month) {
    final Set<String> actualNames = <String>{};
    final Set<String> fallbackNames = <String>{};
    for (final ActivityRecord record in data.records) {
      if (record.collectionName != 'penimbangan' ||
          record.tanggal.year != year ||
          record.tanggal.month != month ||
          _parseNumber(record.data['berat_badan']) == null) {
        continue;
      }
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

  String _breedForRecord(ActivityRecord record, ReportExportData data) {
    final String breed = data.bulls[record.bull_id]?.bangsa.trim() ?? '';
    return breed.isEmpty ? '-' : breed;
  }

  void _validateSingleYear(ReportExportData data) {
    if (data.periodStart.year != data.periodEnd.year) {
      throw StateError(
        'Formulir penimbangan pejantan SOP-6.3b dibuat per tahun. '
        'Pilih periode dalam tahun yang sama.',
      );
    }
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

  String _normalizeName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
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

class _PenimbanganBullRow {
  const _PenimbanganBullRow({
    required this.id,
    required this.label,
    required this.breed,
  });

  final String id;
  final String label;
  final String breed;
}
