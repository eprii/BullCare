import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity_record.dart';
import '../models/bull_model.dart';
import '../models/report_export_data.dart';
import '../models/user_model.dart';

/// Export khusus aktivitas Penampungan Semen menggunakan SOP-7.5.1f.
///
/// Service ini hanya dipanggil ketika seluruh record yang diekspor berasal
/// dari collection `penampungan_semen`. Template lain dan alur ekspor umum
/// tidak diubah. Setiap Hari/Tanggal dibuat pada lembar formulir tersendiri.
/// Satu lembar menampung maksimal 15 record; bila pada tanggal yang sama jumlah
/// record lebih banyak, formulir diulang pada halaman berikutnya sehingga
/// seluruh data tetap ikut diekspor.
class PenampunganSemenReportTemplateService {
  const PenampunganSemenReportTemplateService();

  static const String _wordTemplateAsset =
      'assets/templates/form_penampungan_semen_sop_7_5_1f.docx';
  static const String _pdfTemplateAsset =
      'assets/templates/form_penampungan_semen_sop_7_5_1f_page_1.png';

  static const int _rowsPerPage = 15;
  static const double _backgroundWidthPx = 1602;
  static const double _backgroundHeightPx = 1133;

  static const List<double> _columnBoundsPx = <double>[
    67,
    137,
    440,
    769,
    915,
    1064,
    1235,
    1373,
    1487,
  ];

  static const List<double> _rowBoundsPx = <double>[
    400,
    440,
    481,
    523,
    564,
    605,
    646,
    687,
    728,
    769,
    810,
    852,
    893,
    934,
    975,
    1016,
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

    final List<_SemenPage> pages = _pages(data);

    for (final ArchiveFile file in sourceArchive) {
      if (!file.isFile) continue;
      final Uint8List content = file.readBytes() ?? Uint8List(0);
      if (file.name == 'word/document.xml') {
        final String xml = utf8.decode(content);
        final String patchedXml = _buildPagedWordXml(
          xml,
          pages: pages,
        );
        final Uint8List patchedBytes = Uint8List.fromList(
          utf8.encode(patchedXml),
        );
        outputArchive.addFile(
          ArchiveFile(file.name, patchedBytes.length, patchedBytes),
        );
      } else {
        outputArchive.addFile(
          ArchiveFile(file.name, content.length, content),
        );
      }
    }

    return Uint8List.fromList(ZipEncoder().encodeBytes(outputArchive));
  }

  Future<Uint8List> buildPdf({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    final ByteData imageData = await rootBundle.load(_pdfTemplateAsset);
    final Uint8List imageBytes = imageData.buffer.asUint8List(
      imageData.offsetInBytes,
      imageData.lengthInBytes,
    );
    final pw.MemoryImage background = pw.MemoryImage(imageBytes);
    final List<_SemenPage> pages = _pages(data);

    final pw.Document document = pw.Document(
      title: 'Formulir Penampungan Semen SOP-7.5.1f',
      author: exportedBy.nama.trim().isEmpty
          ? exportedBy.email
          : exportedBy.nama,
      creator: 'BullCare',
    );

    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (context) => _buildPdfPage(
            page: pages[pageIndex],
            pageIndex: pageIndex,
            pageCount: pages.length,
            background: background,
          ),
        ),
      );
    }

    return document.save();
  }

  String _buildPagedWordXml(
    String xml, {
    required List<_SemenPage> pages,
  }) {
    final RegExp bodyRegex = RegExp(
      r'<w:body>(.*?)(<w:sectPr\b.*?</w:sectPr>)</w:body>',
      dotAll: true,
    );
    final RegExpMatch? bodyMatch = bodyRegex.firstMatch(xml);
    if (bodyMatch == null) {
      throw StateError(
        'Template penampungan semen tidak valid: body/section tidak ditemukan.',
      );
    }

    final String templateBody = bodyMatch.group(1)!;
    final String sectionProperties = bodyMatch.group(2)!;
    final List<String> patchedBodies = <String>[];

    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      String body = _patchWordPage(
        templateBody,
        page: pages[pageIndex],
        pageIndex: pageIndex,
        pageCount: pages.length,
      );
      patchedBodies.add(body);
    }

    final String replacement =
        '<w:body>${patchedBodies.join()}$sectionProperties</w:body>';
    return xml.replaceRange(bodyMatch.start, bodyMatch.end, replacement);
  }

  String _patchWordPage(
    String bodyXml, {
    required _SemenPage page,
    required int pageIndex,
    required int pageCount,
  }) {
    String result = bodyXml;
    result = _replaceFirstText(
      result,
      'Hari/Tanggal :',
      'Hari/Tanggal : ${_dateLabel(page.date)}',
    );
    result = _replaceFirstText(
      result,
      '1 dari 1',
      '${pageIndex + 1} dari $pageCount',
    );

    if (page.layout == _SemenLayout.current) {
      result = _patchCurrentWordHeader(result);
    }

    final List<RegExpMatch> tableMatches = RegExp(
      r'<w:tbl>.*?</w:tbl>',
      dotAll: true,
    ).allMatches(result).toList();
    if (tableMatches.length < 3) {
      throw StateError(
        'Template penampungan semen tidak valid: tabel utama tidak ditemukan.',
      );
    }

    final RegExpMatch dataTableMatch = tableMatches.last;
    final String patchedTable = _patchWordDataTable(
      dataTableMatch.group(0)!,
      page.records,
      firstRowNumber: page.firstRowNumber,
    );
    return result.replaceRange(
      dataTableMatch.start,
      dataTableMatch.end,
      patchedTable,
    );
  }

  String _patchWordDataTable(
    String tableXml,
    List<_SemenRow> records, {
    required int firstRowNumber,
  }) {
    final List<RegExpMatch> rowMatches = RegExp(
      r'<w:tr(?:\s[^>]*)?>.*?</w:tr>',
      dotAll: true,
    ).allMatches(tableXml).toList();
    if (rowMatches.length < 17) {
      throw StateError(
        'Template penampungan semen tidak valid: 15 baris data tidak lengkap.',
      );
    }

    final List<String> patchedRows = <String>[
      for (final RegExpMatch row in rowMatches) row.group(0)!,
    ];

    for (int rowIndex = 0; rowIndex < _rowsPerPage; rowIndex++) {
      final _SemenRow? record = rowIndex < records.length
          ? records[rowIndex]
          : null;
      final List<String> values = record == null
          ? <String>['', '', '', '', '', '', '', '']
          : <String>[
              '${firstRowNumber + rowIndex}',
              record.breed,
              record.bull,
              record.field4,
              record.field5,
              record.field6,
              record.field7,
              record.officer,
            ];
      patchedRows[rowIndex + 2] = _replaceRowCellTexts(
        patchedRows[rowIndex + 2],
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

  String _patchCurrentWordHeader(String xml) {
    String result = xml;
    result = _replaceFirstText(
      result,
      'PERSIAPAN VAGINA BUATAN',
      'DATA PENAMPUNGAN SEMEN',
    );
    // Header VOLUME SEMEN pada template Word tersimpan sebagai dua text run.
    // Untuk schema baru, sel yang sama digunakan untuk JUMLAH STRAW.
    result = _replaceFirstText(result, 'VOLUME', 'JUMLAH');
    result = _replaceFirstText(result, 'SEMEN', 'STRAW');
    result = _replaceFirstText(result, 'AV', 'KOLEKTOR');
    result = _replaceFirstText(result, 'VASELIN', 'VOLUME');
    result = _replaceFirstText(result, 'SUHU', 'P/TP');
    return result;
  }

  String _replaceFirstText(String xml, String oldText, String newText) {
    final String escapedOld = RegExp.escape(oldText);
    final RegExp regex = RegExp(
      '<w:t(?:\\s[^>]*)?>$escapedOld</w:t>',
      caseSensitive: false,
    );
    final RegExpMatch? match = regex.firstMatch(xml);
    if (match == null) return xml;
    return xml.replaceRange(
      match.start,
      match.end,
      '<w:t xml:space="preserve">${_xmlEscape(newText)}</w:t>',
    );
  }

  String _replaceRowCellTexts(String rowXml, List<String> values) {
    final List<RegExpMatch> cellMatches = RegExp(
      r'<w:tc>.*?</w:tc>',
      dotAll: true,
    ).allMatches(rowXml).toList();
    if (cellMatches.length != values.length) {
      throw StateError(
        'Template penampungan semen tidak valid: jumlah kolom '
        '${cellMatches.length}, seharusnya ${values.length}.',
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
          '<w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>'
          '<w:sz w:val="16"/><w:szCs w:val="16"/></w:rPr>'
          '<w:t xml:space="preserve">$escaped</w:t></w:r>';
      final int paragraphEnd = cellXml.lastIndexOf('</w:p>');
      if (paragraphEnd >= 0) {
        return cellXml.replaceRange(paragraphEnd, paragraphEnd, run);
      }
      return cellXml;
    }

    String result = cellXml;
    for (int i = matches.length - 1; i >= 0; i--) {
      final RegExpMatch match = matches[i];
      result = result.replaceRange(
        match.start,
        match.end,
        i == 0
            ? '<w:t xml:space="preserve">$escaped</w:t>'
            : '<w:t></w:t>',
      );
    }
    return result;
  }

  pw.Widget _buildPdfPage({
    required _SemenPage page,
    required int pageIndex,
    required int pageCount,
    required pw.MemoryImage background,
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

    if (page.layout == _SemenLayout.current) {
      children.addAll(_currentPdfHeader());
    }

    for (int rowIndex = 0; rowIndex < page.records.length; rowIndex++) {
      final _SemenRow row = page.records[rowIndex];
      final List<String> values = <String>[
        '${page.firstRowNumber + rowIndex}',
        row.breed,
        row.bull,
        row.field4,
        row.field5,
        row.field6,
        row.field7,
        row.officer,
      ];
      for (int colIndex = 0; colIndex < values.length; colIndex++) {
        children.add(
          _pdfCell(
            text: values[colIndex],
            leftPx: _columnBoundsPx[colIndex],
            rightPx: _columnBoundsPx[colIndex + 1],
            topPx: _rowBoundsPx[rowIndex],
            bottomPx: _rowBoundsPx[rowIndex + 1],
            alignLeft: colIndex == 1 || colIndex == 2,
            fontSize: colIndex == 7 ? 6.3 : 7.2,
          ),
        );
      }
    }

    children.add(
      _pdfTextBox(
        text: _dateLabel(page.date),
        leftPx: 185,
        topPx: 1018,
        widthPx: 280,
        heightPx: 28,
        fontSize: 8.2,
        alignment: pw.Alignment.centerLeft,
      ),
    );

    if (pageCount > 1) {
      children.add(
        _pdfWhiteBox(
          leftPx: 1268,
          topPx: 198,
          widthPx: 120,
          heightPx: 24,
        ),
      );
      children.add(
        _pdfTextBox(
          text: '${pageIndex + 1} dari $pageCount',
          leftPx: 1274,
          topPx: 198,
          widthPx: 110,
          heightPx: 24,
          fontSize: 8.0,
          alignment: pw.Alignment.centerLeft,
        ),
      );
    }

    return pw.Stack(children: children);
  }

  List<pw.Widget> _currentPdfHeader() {
    const double headerTop = 310;
    const double headerMiddle = 357;
    const double headerBottom = 399;

    final List<pw.Widget> widgets = <pw.Widget>[];

    void replaceHeaderCell({
      required double left,
      required double right,
      required double top,
      required double bottom,
      required String text,
      double fontSize = 7.2,
    }) {
      // Sisakan garis border template asli agar bentuk SOP tetap dipertahankan.
      widgets.add(
        _pdfWhiteBox(
          leftPx: left + 1.5,
          topPx: top + 1.5,
          widthPx: (right - left) - 3,
          heightPx: (bottom - top) - 3,
        ),
      );
      widgets.add(
        _pdfTextBox(
          text: text,
          leftPx: left + 4,
          topPx: top + 3,
          widthPx: (right - left) - 8,
          heightPx: (bottom - top) - 6,
          fontSize: fontSize,
          alignment: pw.Alignment.center,
        ),
      );
    }

    replaceHeaderCell(
      left: _columnBoundsPx[3],
      right: _columnBoundsPx[6],
      top: headerTop,
      bottom: headerMiddle,
      text: 'DATA PENAMPUNGAN SEMEN',
      fontSize: 7.0,
    );
    replaceHeaderCell(
      left: _columnBoundsPx[3],
      right: _columnBoundsPx[4],
      top: headerMiddle,
      bottom: headerBottom,
      text: 'KOLEKTOR',
    );
    replaceHeaderCell(
      left: _columnBoundsPx[4],
      right: _columnBoundsPx[5],
      top: headerMiddle,
      bottom: headerBottom,
      text: 'VOLUME',
    );
    replaceHeaderCell(
      left: _columnBoundsPx[5],
      right: _columnBoundsPx[6],
      top: headerMiddle,
      bottom: headerBottom,
      text: 'P/TP',
    );
    replaceHeaderCell(
      left: _columnBoundsPx[6],
      right: _columnBoundsPx[7],
      top: headerTop,
      bottom: headerBottom,
      text: 'JUMLAH STRAW',
      fontSize: 6.6,
    );

    return widgets;
  }

  pw.Widget _pdfCell({
    required String text,
    required double leftPx,
    required double rightPx,
    required double topPx,
    required double bottomPx,
    required bool alignLeft,
    required double fontSize,
  }) {
    return _pdfTextBox(
      text: text,
      leftPx: leftPx + 3,
      topPx: topPx + 2,
      widthPx: (rightPx - leftPx) - 6,
      heightPx: (bottomPx - topPx) - 4,
      fontSize: fontSize,
      alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
    );
  }

  pw.Widget _pdfTextBox({
    required String text,
    required double leftPx,
    required double topPx,
    required double widthPx,
    required double heightPx,
    required double fontSize,
    required pw.Alignment alignment,
  }) {
    return pw.Positioned(
      left: _pxX(leftPx),
      top: _pxY(topPx),
      child: pw.SizedBox(
        width: _pxX(widthPx),
        height: _pxY(heightPx),
        child: pw.Container(
          alignment: alignment,
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

  double _pxX(double value) {
    return value / _backgroundWidthPx * PdfPageFormat.a4.landscape.width;
  }

  double _pxY(double value) {
    return value / _backgroundHeightPx * PdfPageFormat.a4.landscape.height;
  }

  List<_SemenRow> _rows(ReportExportData data) {
    final List<_SemenRow> rows = data.records.map((record) {
      final BullModel? bull = data.bulls[record.bull_id];
      final String breed = bull?.bangsa.trim() ?? '';
      final String bullName = bull?.nama.trim() ?? '';
      final bool isCurrent = _usesCurrentSchema(record);

      return _SemenRow(
        record: record,
        breed: breed,
        bull: bullName.isNotEmpty ? bullName : record.bull_id,
        layout: isCurrent ? _SemenLayout.current : _SemenLayout.legacy,
        field4: isCurrent
            ? _plainValue(record.data['kolektor'])
            : _plainValue(record.data['av']),
        field5: isCurrent
            ? _plainValue(record.data['volume'])
            : _plainValue(record.data['vaselin']),
        field6: isCurrent
            ? _plainValue(record.data['p_tp'])
            : _numberValue(record.data['suhu_av']),
        field7: isCurrent
            ? _plainValue(record.data['jumlah_straw_yang_dihasilkan'])
            : _numberValue(record.data['volume_semen']),
        officer: _plainValue(record.data['nama_petugas']),
      );
    }).toList();

    rows.sort((a, b) {
      final DateTime aDate = DateTime(
        a.record.tanggal.year,
        a.record.tanggal.month,
        a.record.tanggal.day,
      );
      final DateTime bDate = DateTime(
        b.record.tanggal.year,
        b.record.tanggal.month,
        b.record.tanggal.day,
      );
      final int dateCompare = aDate.compareTo(bDate);
      if (dateCompare != 0) return dateCompare;
      final int layoutCompare = a.layout.index.compareTo(b.layout.index);
      if (layoutCompare != 0) return layoutCompare;
      final int bullCompare = a.bull.toLowerCase().compareTo(
            b.bull.toLowerCase(),
          );
      if (bullCompare != 0) return bullCompare;
      return a.record.created_at.compareTo(b.record.created_at);
    });
    return rows;
  }

  bool _usesCurrentSchema(ActivityRecord record) {
    return record.data.containsKey('kolektor') ||
        record.data.containsKey('volume') ||
        record.data.containsKey('p_tp') ||
        record.data.containsKey('jumlah_straw_yang_dihasilkan');
  }

  List<_SemenPage> _pages(ReportExportData data) {
    final List<_SemenRow> rows = _rows(data);
    if (rows.isEmpty) {
      return <_SemenPage>[
        _SemenPage(
          date: DateTime(
            data.periodStart.year,
            data.periodStart.month,
            data.periodStart.day,
          ),
          layout: _SemenLayout.current,
          records: const <_SemenRow>[],
          firstRowNumber: 1,
        ),
      ];
    }

    final Map<DateTime, Map<_SemenLayout, List<_SemenRow>>> rowsByDate =
        <DateTime, Map<_SemenLayout, List<_SemenRow>>>{};
    for (final _SemenRow row in rows) {
      final DateTime date = DateTime(
        row.record.tanggal.year,
        row.record.tanggal.month,
        row.record.tanggal.day,
      );
      rowsByDate
          .putIfAbsent(
            date,
            () => <_SemenLayout, List<_SemenRow>>{},
          )
          .putIfAbsent(row.layout, () => <_SemenRow>[])
          .add(row);
    }

    final List<DateTime> dates = rowsByDate.keys.toList()..sort();
    final List<_SemenPage> pages = <_SemenPage>[];
    for (final DateTime date in dates) {
      final Map<_SemenLayout, List<_SemenRow>> layoutGroups =
          rowsByDate[date]!;
      for (final _SemenLayout layout in _SemenLayout.values) {
        final List<_SemenRow>? dateRows = layoutGroups[layout];
        if (dateRows == null || dateRows.isEmpty) continue;

        for (int start = 0; start < dateRows.length; start += _rowsPerPage) {
          final int end = (start + _rowsPerPage) > dateRows.length
              ? dateRows.length
              : start + _rowsPerPage;
          pages.add(
            _SemenPage(
              date: date,
              layout: layout,
              records: dateRows.sublist(start, end),
              firstRowNumber: start + 1,
            ),
          );
        }
      }
    }
    return pages;
  }

  String _plainValue(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  String _numberValue(dynamic value) {
    if (value == null) return '';
    final double? parsed = double.tryParse(value.toString().replaceAll(',', '.'));
    if (parsed == null) return value.toString().trim();
    if (parsed == parsed.roundToDouble()) return parsed.toInt().toString();
    return parsed.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  String _dateLabel(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
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

enum _SemenLayout { current, legacy }

class _SemenPage {
  const _SemenPage({
    required this.date,
    required this.layout,
    required this.records,
    required this.firstRowNumber,
  });

  final DateTime date;
  final _SemenLayout layout;
  final List<_SemenRow> records;
  final int firstRowNumber;
}

class _SemenRow {
  const _SemenRow({
    required this.record,
    required this.breed,
    required this.bull,
    required this.layout,
    required this.field4,
    required this.field5,
    required this.field6,
    required this.field7,
    required this.officer,
  });

  final ActivityRecord record;
  final String breed;
  final String bull;
  final _SemenLayout layout;
  final String field4;
  final String field5;
  final String field6;
  final String field7;
  final String officer;
}
