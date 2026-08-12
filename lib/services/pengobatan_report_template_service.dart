import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity_record.dart';
import '../models/bull_model.dart';
import '../models/report_export_data.dart';
import '../models/user_model.dart';

/// Export khusus aktivitas Pengobatan menggunakan formulir SOP-6.3e.
///
/// Service ini hanya dipanggil ketika seluruh record yang diekspor berasal
/// dari collection `pengobatan`. Formulir utama mengikuti dokumen sumber
/// FORMULIR PENGOBATAN PEJANTAN (BULL), sedangkan halaman rincian menjaga
/// agar data tanggal, keterangan, dan petugas tetap tersedia bila pada
/// periode yang dipilih terdapat lebih dari satu pengobatan untuk bull
/// yang sama. CRUD, Firestore, dan modul aktivitas lain tidak disentuh.
class PengobatanReportTemplateService {
  const PengobatanReportTemplateService();

  static const String _wordTemplateAsset =
      'assets/templates/form_pengobatan_pejantan_sop_6_3e.docx';
  static const String _pdfTemplateAssetPage1 =
      'assets/templates/form_pengobatan_pejantan_sop_6_3e_page_1.png';
  static const String _pdfTemplateAssetPage2 =
      'assets/templates/form_pengobatan_pejantan_sop_6_3e_page_2.png';

  static const int _bullSlotCount = 30;
  static const double _backgroundWidthPx = 1602;
  static const double _backgroundHeightPx = 1133;

  // Batas kolom: No, Nama Bull, Bangsa, Gejala Klinis, Diagnosa, Terapi,
  // Keterangan. Template SOP-6.3e dirender lanskap.
  static const List<double> _columnBoundsPx = <double>[
    69.0,
    122.0,
    297.0,
    500.0,
    796.0,
    1012.0,
    1295.0,
    1533.0,
  ];

  // Halaman 1 memuat bull 1-17.
  static const List<double> _page1RowBoundsPx = <double>[
    378.0, 417.0, 456.0, 494.0, 533.0, 572.0, 610.0, 649.0, 688.0,
    727.0, 765.0, 804.0, 843.0, 882.0, 920.0, 959.0, 998.0, 1036.0,
  ];

  // Halaman 2 memuat bull 18-30.
  static const List<double> _page2RowBoundsPx = <double>[
    69.0, 107.0, 146.0, 185.0, 223.0, 262.0, 301.0, 340.0, 378.0,
    417.0, 456.0, 495.0, 533.0, 572.0,
  ];

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
    'Pasifica',
    'Sampang',
    'Bangkalan',
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
    final List<ByteData> imageData = await Future.wait<ByteData>(<Future<ByteData>>[
      rootBundle.load(_pdfTemplateAssetPage1),
      rootBundle.load(_pdfTemplateAssetPage2),
    ]);
    final List<pw.MemoryImage> backgrounds = imageData
        .map((bytes) => pw.MemoryImage(bytes.buffer.asUint8List(
              bytes.offsetInBytes,
              bytes.lengthInBytes,
            )))
        .toList(growable: false);

    final pw.Document document = pw.Document(
      title: 'Formulir Pengobatan Pejantan (Bull) SOP-6.3e',
      author: exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama,
      creator: 'BullCare',
    );
    final List<_PengobatanBullRow> bulls = _bullSlots(data);
    final PdfPageFormat format = PdfPageFormat.a4.landscape;

    document.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (context) => _buildPdfTemplatePage(
          data: data,
          bulls: bulls,
          background: backgrounds[0],
          pageNumber: 1,
        ),
      ),
    );
    document.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (context) => _buildPdfTemplatePage(
          data: data,
          bulls: bulls,
          background: backgrounds[1],
          pageNumber: 2,
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

  String _patchWordTemplate(String xml, ReportExportData data) {
    final List<_PengobatanBullRow> bulls = _bullSlots(data);
    String result = _replaceTimeLabel(xml, _periodLabel(data));

    final List<RegExpMatch> tableMatches =
        RegExp(r'<w:tbl>.*?</w:tbl>', dotAll: true).allMatches(result).toList();
    if (tableMatches.length < 3) {
      throw StateError(
        'Template pengobatan tidak valid: struktur tabel SOP-6.3e tidak lengkap.',
      );
    }

    final RegExpMatch tableMatch = tableMatches[2];
    final String patchedTable = _patchWordDataTable(
      tableMatch.group(0)!,
      data: data,
      bulls: bulls,
    );
    return result.replaceRange(tableMatch.start, tableMatch.end, patchedTable);
  }

  String _replaceTimeLabel(String xml, String label) {
    final RegExp timeRegex = RegExp(
      r'<w:t(?:\s[^>]*)?>Waktu\s*:</w:t>',
      caseSensitive: false,
    );
    final RegExpMatch? match = timeRegex.firstMatch(xml);
    if (match == null) {
      throw StateError(
        'Template pengobatan tidak valid: label Waktu tidak ditemukan.',
      );
    }
    return xml.replaceRange(
      match.start,
      match.end,
      '<w:t xml:space="preserve">Waktu : ${_xmlEscape(label)}</w:t>',
    );
  }

  String _patchWordDataTable(
    String tableXml, {
    required ReportExportData data,
    required List<_PengobatanBullRow> bulls,
  }) {
    final List<RegExpMatch> rowMatches = RegExp(
      r'<w:tr(?:\s[^>]*)?>.*?</w:tr>',
      dotAll: true,
    ).allMatches(tableXml).toList();
    if (rowMatches.length < 31) {
      throw StateError(
        'Template pengobatan tidak valid: 30 baris bull tidak lengkap.',
      );
    }

    final List<String> patchedRows = <String>[
      for (final RegExpMatch row in rowMatches) row.group(0)!,
    ];
    for (int bullIndex = 0; bullIndex < _bullSlotCount; bullIndex++) {
      final _PengobatanBullRow bull = bulls[bullIndex];
      final ActivityRecord? record =
          bull.id.isEmpty ? null : _latestTreatment(data, bull.id);
      final List<String> values = <String>[
        '${bullIndex + 1}',
        bull.label,
        bull.breed,
        record == null ? '' : _plainValue(record.data['gejala_klinis']),
        record == null ? '' : _plainValue(record.data['diagnosa']),
        record == null ? '' : _plainValue(record.data['terapi']),
        record == null ? '' : _plainValue(record.data['keterangan']),
      ];
      patchedRows[bullIndex + 1] = _replaceRowCellTexts(
        patchedRows[bullIndex + 1],
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
        'Template pengobatan tidak valid: jumlah kolom ${cellMatches.length}, '
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
          '<w:r><w:rPr><w:sz w:val="11"/><w:szCs w:val="11"/></w:rPr>'
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
        .where((record) => record.collectionName == 'pengobatan')
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
          'RINCIAN DATA PENGOBATAN PEJANTAN',
          bold: true,
          center: true,
          fontSize: 20,
          pageBreakBefore: true,
        ),
      )
      ..write(
        _wordParagraph(
          'Periode ${_formatWordDate(data.periodStart)} - ${_formatWordDate(data.periodEnd)}',
          center: true,
          fontSize: 16,
        ),
      )
      ..write(_wordParagraph('', fontSize: 8));

    final List<List<String>> rows = <List<String>>[
      <String>[
        'Tanggal',
        'Bull',
        'Bangsa',
        'Gejala Klinis',
        'Diagnosa',
        'Terapi',
        'Keterangan',
        'Nama Petugas',
      ],
      for (final ActivityRecord record in records)
        <String>[
          _formatWordDate(record.tanggal),
          _bullLabelForRecord(record, data),
          _breedForRecord(record, data),
          _detailValue(record.data['gejala_klinis']),
          _detailValue(record.data['diagnosa']),
          _detailValue(record.data['terapi']),
          _detailValue(record.data['keterangan']),
          _detailValue(record.data['nama_petugas']),
        ],
    ];
    appendix.write(_wordDetailTable(rows));

    final int sectionIndex = xml.lastIndexOf('<w:sectPr');
    if (sectionIndex < 0) {
      throw StateError(
        'Template pengobatan tidak valid: section Word tidak ditemukan.',
      );
    }
    return xml.replaceRange(sectionIndex, sectionIndex, appendix.toString());
  }

  String _wordParagraph(
    String text, {
    bool bold = false,
    bool center = false,
    int fontSize = 16,
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
    const List<int> widths = <int>[
      850,
      1150,
      950,
      1800,
      1400,
      1800,
      1800,
      1200,
    ];
    final StringBuffer xml = StringBuffer()
      ..write(
        '<w:tbl><w:tblPr><w:tblStyle w:val="TableGrid"/>'
        '<w:tblW w:w="0" w:type="auto"/><w:tblLayout w:type="fixed"/>'
        '</w:tblPr><w:tblGrid>',
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
          '$bold<w:sz w:val="10"/><w:szCs w:val="10"/></w:rPr>'
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
    required List<_PengobatanBullRow> bulls,
    required pw.MemoryImage background,
    required int pageNumber,
  }) {
    final PdfPageFormat format = PdfPageFormat.a4.landscape;
    final List<pw.Widget> children = <pw.Widget>[
      pw.Image(
        background,
        width: format.width,
        height: format.height,
        fit: pw.BoxFit.fill,
      ),
    ];
    if (pageNumber == 1) {
      children.add(
        _pdfTextBox(
          text: _periodLabel(data),
          leftPx: 135,
          topPx: 310,
          widthPx: 570,
          heightPx: 30,
          fontSize: 6.0,
          align: pw.Alignment.centerLeft,
        ),
      );
    }

    final int firstBullIndex = pageNumber == 1 ? 0 : 17;
    final List<double> bounds =
        pageNumber == 1 ? _page1RowBoundsPx : _page2RowBoundsPx;
    final int rowCount = pageNumber == 1 ? 17 : 13;

    for (int localIndex = 0; localIndex < rowCount; localIndex++) {
      final int bullIndex = firstBullIndex + localIndex;
      final _PengobatanBullRow bull = bulls[bullIndex];
      final double top = bounds[localIndex] + 1;
      final double bottom = bounds[localIndex + 1] - 1;
      final double height = bottom - top;

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
            leftPx: _columnBoundsPx[1] + 5,
            topPx: top,
            widthPx: (_columnBoundsPx[2] - _columnBoundsPx[1]) - 10,
            heightPx: height,
            fontSize: 5.3,
            align: pw.Alignment.centerLeft,
          ),
        );
      }
      if (bull.breed.isNotEmpty) {
        children.add(
          _pdfTextBox(
            text: bull.breed,
            leftPx: _columnBoundsPx[2] + 5,
            topPx: top,
            widthPx: (_columnBoundsPx[3] - _columnBoundsPx[2]) - 10,
            heightPx: height,
            fontSize: 5.0,
            align: pw.Alignment.centerLeft,
          ),
        );
      }

      if (bull.id.isEmpty) continue;
      final ActivityRecord? record = _latestTreatment(data, bull.id);
      if (record == null) continue;
      final List<String> values = <String>[
        _plainValue(record.data['gejala_klinis']),
        _plainValue(record.data['diagnosa']),
        _plainValue(record.data['terapi']),
        _plainValue(record.data['keterangan']),
      ];
      for (int i = 0; i < values.length; i++) {
        if (values[i].isEmpty) continue;
        final int columnIndex = i + 3;
        children.add(
          _pdfTextBox(
            text: values[i],
            leftPx: _columnBoundsPx[columnIndex] + 4,
            topPx: top,
            widthPx:
                (_columnBoundsPx[columnIndex + 1] - _columnBoundsPx[columnIndex]) -
                    8,
            heightPx: height,
            fontSize: 4.5,
            align: pw.Alignment.centerLeft,
          ),
        );
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
          padding: const pw.EdgeInsets.symmetric(horizontal: 0.5),
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
        .where((record) => record.collectionName == 'pengobatan')
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
        'Gejala Klinis',
        'Diagnosa',
        'Terapi',
        'Keterangan',
        'Nama Petugas',
      ],
      for (final ActivityRecord record in records)
        <String>[
          _formatWordDate(record.tanggal),
          _bullLabelForRecord(record, data),
          _breedForRecord(record, data),
          _detailValue(record.data['gejala_klinis']),
          _detailValue(record.data['diagnosa']),
          _detailValue(record.data['terapi']),
          _detailValue(record.data['keterangan']),
          _detailValue(record.data['nama_petugas']),
        ],
    ];

    return <pw.Widget>[
      pw.Text(
        'RINCIAN DATA PENGOBATAN PEJANTAN',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Periode ${_formatWordDate(data.periodStart)} - ${_formatWordDate(data.periodEnd)}',
        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 10),
      pw.TableHelper.fromTextArray(
        data: rows,
        headerCount: 1,
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.4),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
        headerStyle: pw.TextStyle(fontSize: 5.7, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 5.4),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 3),
        columnWidths: <int, pw.TableColumnWidth>{
          0: const pw.FlexColumnWidth(0.9),
          1: const pw.FlexColumnWidth(1.1),
          2: const pw.FlexColumnWidth(0.9),
          3: const pw.FlexColumnWidth(1.7),
          4: const pw.FlexColumnWidth(1.3),
          5: const pw.FlexColumnWidth(1.7),
          6: const pw.FlexColumnWidth(1.7),
          7: const pw.FlexColumnWidth(1.1),
        },
      ),
    ];
  }

  List<_PengobatanBullRow> _bullSlots(ReportExportData data) {
    final List<_PengobatanBullRow> real = _bullRows(data);
    final List<_PengobatanBullRow> result = real.take(_bullSlotCount).toList();
    while (result.length < _bullSlotCount) {
      result.add(const _PengobatanBullRow(id: '', label: '', breed: ''));
    }
    return result;
  }

  List<_PengobatanBullRow> _bullRows(ReportExportData data) {
    final Map<String, _PengobatanBullRow> byId = <String, _PengobatanBullRow>{};
    for (final BullModel bull in data.bulls.values) {
      final String name = bull.nama.trim().isNotEmpty
          ? bull.nama.trim()
          : bull.kode_bull.trim().isNotEmpty
              ? bull.kode_bull.trim()
              : 'Bull';
      byId[bull.id] = _PengobatanBullRow(
        id: bull.id,
        label: name,
        breed: bull.bangsa.trim(),
      );
    }
    for (final ActivityRecord record in data.records) {
      if (record.collectionName != 'pengobatan') continue;
      byId.putIfAbsent(
        record.bull_id,
        () => _PengobatanBullRow(
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
    // Nama ini pernah muncul sebagai "Pacifica" di data/aplikasi, sedangkan
    // formulir SOP-6.3e menuliskan "Pasifica". Keduanya ditempatkan di slot
    // resmi yang sama tanpa mengubah nama yang tersimpan di database.
    order[_normalizeName('Pacifica')] = _officialBullOrder.indexOf('Pasifica');

    final List<_PengobatanBullRow> values = byId.values.toList();
    values.sort((a, b) {
      final int ai = order[_normalizeName(a.label)] ?? 9999;
      final int bi = order[_normalizeName(b.label)] ?? 9999;
      if (ai != bi) return ai.compareTo(bi);
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return values;
  }

  ActivityRecord? _latestTreatment(ReportExportData data, String bullId) {
    ActivityRecord? latest;
    for (final ActivityRecord record in data.records) {
      if (record.collectionName != 'pengobatan' || record.bull_id != bullId) {
        continue;
      }
      if (latest == null || _isLater(record, latest)) {
        latest = record;
      }
    }
    return latest;
  }

  bool _isLater(ActivityRecord candidate, ActivityRecord current) {
    final int dateCompare = candidate.tanggal.compareTo(current.tanggal);
    if (dateCompare != 0) return dateCompare > 0;
    return candidate.updated_at.isAfter(current.updated_at);
  }



  String _periodLabel(ReportExportData data) {
    if (_sameDay(data.periodStart, data.periodEnd)) {
      return _formatWordDate(data.periodStart);
    }
    return '${_formatWordDate(data.periodStart)} - ${_formatWordDate(data.periodEnd)}';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }


  String _plainValue(dynamic value) {
    return value?.toString().trim() ?? '';
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

class _PengobatanBullRow {
  const _PengobatanBullRow({
    required this.id,
    required this.label,
    required this.breed,
  });

  final String id;
  final String label;
  final String breed;
}
