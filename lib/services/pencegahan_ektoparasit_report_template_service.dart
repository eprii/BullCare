import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity_record.dart';
import '../models/bull_model.dart';
import '../models/report_export_data.dart';
import '../models/user_model.dart';

/// Export khusus aktivitas Pencegahan Ektoparasit.
///
/// Template dibangun berdasarkan formulir kantor yang berisi kolom:
/// No, Nama Bull, Bangsa, Bahan, Alat, Tindakan, dan Keterangan
/// dengan waktu pelaksanaan 3 bulan sekali.
///
/// Karena pada project belum tersedia DOCX template resmi untuk aktivitas ini,
/// generator disusun langsung di code agar tetap konsisten dan dapat diekspor
/// ke PDF maupun Word tanpa mengubah schema database atau fitur lain.
class PencegahanEktoparasitReportTemplateService {
  const PencegahanEktoparasitReportTemplateService();

  static const int _rowsPerPage = 14;
  static const String _logoDisbunnakAsset =
      'assets/branding/kalsel_logo.png';

  Future<Uint8List> buildPdf({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    final List<_EktoparasitPage> pages = _buildPages(data);
    final ByteData logoData = await rootBundle.load(_logoDisbunnakAsset);
    final Uint8List logoBytes = logoData.buffer.asUint8List(
      logoData.offsetInBytes,
      logoData.lengthInBytes,
    );
    final pw.MemoryImage disbunnakLogo = pw.MemoryImage(logoBytes);
    final pw.Document document = pw.Document(
      title: 'Formulir Pencegahan Ektoparasit',
      author:
          exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama,
      creator: 'BullCare',
    );

    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 20),
          build: (pw.Context context) => _buildPdfPage(
            page: pages[pageIndex],
            pageNumber: pageIndex + 1,
            totalPages: pages.length,
            disbunnakLogo: disbunnakLogo,
          ),
        ),
      );
    }

    return document.save();
  }

  Future<Uint8List> buildDocx({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    final Archive archive = Archive();
    final ByteData logoData = await rootBundle.load(_logoDisbunnakAsset);
    final Uint8List logoBytes = logoData.buffer.asUint8List(
      logoData.offsetInBytes,
      logoData.lengthInBytes,
    );
    final DateTime now = DateTime.now().toUtc();
    final Map<String, String> files = <String, String>{
      '[Content_Types].xml': _contentTypesXml,
      '_rels/.rels': _rootRelationshipsXml,
      'docProps/core.xml': _corePropertiesXml(exportedBy, now),
      'docProps/app.xml': _appPropertiesXml,
      'word/document.xml': _documentXml(data: data),
      'word/styles.xml': _stylesXml,
      'word/_rels/document.xml.rels': _documentRelationshipsXml,
    };

    for (final MapEntry<String, String> entry in files.entries) {
      archive.addFile(ArchiveFile.string(entry.key, entry.value));
    }
    archive.addFile(
      ArchiveFile(
        'word/media/logo_disbunnak.png',
        logoBytes.length,
        logoBytes,
      ),
    );

    return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
  }

  pw.Widget _buildPdfPage({
    required _EktoparasitPage page,
    required int pageNumber,
    required int totalPages,
    required pw.MemoryImage disbunnakLogo,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.SizedBox(
              width: 54,
              height: 62,
              child: pw.Center(
                child: pw.Image(
                  disbunnakLogo,
                  width: 38,
                  height: 56,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              flex: 7,
              child: pw.Column(
                children: <pw.Widget>[
                  pw.Text(
                    'FORMULIR PENCEGAHAN EKTOPARASIT',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'WAKTU PELAKSANAAN : 3 BULAN SEKALI',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.SizedBox(
              width: 180,
              child: _pdfMetaTable(
                pageNumber: pageNumber,
                totalPages: totalPages,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Waktu : ${_formatLongDate(page.date)}',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
          columnWidths: const <int, pw.TableColumnWidth>{
            0: pw.FixedColumnWidth(28),
            1: pw.FlexColumnWidth(1.45),
            2: pw.FlexColumnWidth(1.05),
            3: pw.FlexColumnWidth(1.2),
            4: pw.FlexColumnWidth(1.45),
            5: pw.FlexColumnWidth(1.3),
            6: pw.FlexColumnWidth(1.5),
          },
          children: <pw.TableRow>[
            pw.TableRow(
              children: <pw.Widget>[
                _pdfCell('No', bold: true, align: pw.Alignment.center),
                _pdfCell('Nama Bull', bold: true, align: pw.Alignment.center),
                _pdfCell('Bangsa', bold: true, align: pw.Alignment.center),
                _pdfCell('Bahan', bold: true, align: pw.Alignment.center),
                _pdfCell('Alat', bold: true, align: pw.Alignment.center),
                _pdfCell('Tindakan', bold: true, align: pw.Alignment.center),
                _pdfCell('Keterangan', bold: true, align: pw.Alignment.center),
              ],
            ),
            for (int index = 0; index < _rowsPerPage; index++)
              _pdfDataRow(page, index),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Petugas: ${page.petugasLabel}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ],
    );
  }

  pw.Widget _pdfMetaTable({
    required int pageNumber,
    required int totalPages,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FixedColumnWidth(60),
        1: pw.FixedColumnWidth(8),
        2: pw.FlexColumnWidth(),
      },
      children: <pw.TableRow>[
        _pdfMetaRow('No Dok', 'SOP-6.3 k'),
        _pdfMetaRow('Revisi', '3'),
        _pdfMetaRow('Tgl Berlaku', '1 April 2019'),
        _pdfMetaRow('Halaman', '${pageNumber.toString().padLeft(2, '0')} dari ${totalPages.toString().padLeft(2, '0')}'),
        _pdfMetaRow('Paraf', ''),
      ],
    );
  }

  pw.TableRow _pdfMetaRow(String label, String value) {
    return pw.TableRow(
      children: <pw.Widget>[
        _pdfCell(label, fontSize: 8),
        _pdfCell(':', fontSize: 8, align: pw.Alignment.center),
        _pdfCell(value, fontSize: 8),
      ],
    );
  }

  pw.TableRow _pdfDataRow(_EktoparasitPage page, int rowIndex) {
    final _EktoparasitRow? row = rowIndex < page.rows.length ? page.rows[rowIndex] : null;
    return pw.TableRow(
      children: <pw.Widget>[
        _pdfCell(row == null ? '' : '${page.firstRowNumber + rowIndex}', align: pw.Alignment.center),
        _pdfCell(row?.bullName ?? ''),
        _pdfCell(row?.breed ?? ''),
        _pdfCell(row?.bahan ?? ''),
        _pdfCell(row?.alat ?? ''),
        _pdfCell(row?.tindakan ?? ''),
        _pdfCell(row?.keterangan ?? ''),
      ],
    );
  }

  pw.Widget _pdfCell(
    String text, {
    bool bold = false,
    pw.Alignment align = pw.Alignment.centerLeft,
    double fontSize = 7.5,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _documentXml({required ReportExportData data}) {
    final List<_EktoparasitPage> pages = _buildPages(data);
    final StringBuffer body = StringBuffer();

    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final _EktoparasitPage page = pages[pageIndex];
      body
        ..write(_wordLogoParagraph(pageIndex + 1))
        ..write(_wordParagraph(
          'FORMULIR PENCEGAHAN EKTOPARASIT',
          style: 'Title',
          center: true,
        ))
        ..write(_wordParagraph(
          'WAKTU PELAKSANAAN : 3 BULAN SEKALI',
          center: true,
          bold: true,
          fontSizeHalfPoints: 18,
        ))
        ..write(_wordParagraph(''))
        ..write(_wordParagraph('No Dok : SOP-6.3 k'))
        ..write(_wordParagraph('Revisi : 3'))
        ..write(_wordParagraph('Tgl Berlaku : 1 April 2019'))
        ..write(_wordParagraph(
          'Halaman : ${(pageIndex + 1).toString().padLeft(2, '0')} dari ${pages.length.toString().padLeft(2, '0')}',
        ))
        ..write(_wordParagraph('Paraf : '))
        ..write(_wordParagraph(''))
        ..write(_wordParagraph(
          'Waktu : ${_formatLongDate(page.date)}',
          bold: true,
        ))
        ..write(_wordParagraph(''))
        ..write(_wordTable(page))
        ..write(_wordParagraph(''))
        ..write(_wordParagraph('Petugas : ${page.petugasLabel}'));

      if (pageIndex < pages.length - 1) {
        body.write(_wordPageBreak());
      }
    }

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document
 xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
 xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
 xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
 xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
 <w:body>
  ${body.toString()}
  <w:sectPr>
   <w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/>
   <w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/>
  </w:sectPr>
 </w:body>
</w:document>''';
  }

  String _wordTable(_EktoparasitPage page) {
    final StringBuffer buffer = StringBuffer()
      ..write('<w:tbl>')
      ..write('<w:tblPr>')
      ..write('<w:tblW w:w="0" w:type="auto"/>')
      ..write('<w:tblBorders>')
      ..write('<w:top w:val="single" w:sz="8"/>')
      ..write('<w:left w:val="single" w:sz="8"/>')
      ..write('<w:bottom w:val="single" w:sz="8"/>')
      ..write('<w:right w:val="single" w:sz="8"/>')
      ..write('<w:insideH w:val="single" w:sz="8"/>')
      ..write('<w:insideV w:val="single" w:sz="8"/>')
      ..write('</w:tblBorders>')
      ..write('</w:tblPr>')
      ..write(_wordTableRow(
        <String>[
          'No',
          'Nama Bull',
          'Bangsa',
          'Bahan',
          'Alat',
          'Tindakan',
          'Keterangan',
        ],
        header: true,
      ));

    for (int rowIndex = 0; rowIndex < _rowsPerPage; rowIndex++) {
      final _EktoparasitRow? row =
          rowIndex < page.rows.length ? page.rows[rowIndex] : null;
      buffer.write(_wordTableRow(<String>[
        row == null ? '' : '${page.firstRowNumber + rowIndex}',
        row?.bullName ?? '',
        row?.breed ?? '',
        row?.bahan ?? '',
        row?.alat ?? '',
        row?.tindakan ?? '',
        row?.keterangan ?? '',
      ]));
    }

    buffer.write('</w:tbl>');
    return buffer.toString();
  }

  String _wordTableRow(List<String> cells, {bool header = false}) {
    final String cellColor = header ? 'F2F2F2' : 'FFFFFF';
    return '<w:tr>' +
        cells.map((String value) {
          return '''<w:tc><w:tcPr><w:shd w:val="clear" w:fill="$cellColor"/><w:tcMar><w:top w:w="50" w:type="dxa"/><w:left w:w="50" w:type="dxa"/><w:bottom w:w="50" w:type="dxa"/><w:right w:w="50" w:type="dxa"/></w:tcMar></w:tcPr>${_wordParagraph(value, bold: header, fontSizeHalfPoints: 16)}</w:tc>''';
        }).join() +
        '</w:tr>';
  }

  String _wordParagraph(
    String text, {
    String? style,
    bool bold = false,
    bool center = false,
    int fontSizeHalfPoints = 20,
  }) {
    final String safeText = _xmlEscape(text);
    final String styleXml = style == null ? '' : '<w:pStyle w:val="$style"/>';
    final String alignXml = center ? '<w:jc w:val="center"/>' : '';
    final String boldXml = bold ? '<w:b/><w:bCs/>' : '';
    return '<w:p><w:pPr>$styleXml$alignXml</w:pPr><w:r><w:rPr>$boldXml<w:sz w:val="$fontSizeHalfPoints"/><w:szCs w:val="$fontSizeHalfPoints"/></w:rPr><w:t xml:space="preserve">$safeText</w:t></w:r></w:p>';
  }

  String _wordLogoParagraph(int drawingId) {
    const int widthEmu = 411480;
    const int heightEmu = 579120;
    return '''<w:p>
 <w:pPr><w:jc w:val="left"/></w:pPr>
 <w:r><w:drawing>
  <wp:inline distT="0" distB="0" distL="0" distR="0">
   <wp:extent cx="$widthEmu" cy="$heightEmu"/>
   <wp:effectExtent l="0" t="0" r="0" b="0"/>
   <wp:docPr id="$drawingId" name="Logo Disbunnak $drawingId"/>
   <wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>
   <a:graphic>
    <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
     <pic:pic>
      <pic:nvPicPr><pic:cNvPr id="$drawingId" name="logo_disbunnak.png"/><pic:cNvPicPr/></pic:nvPicPr>
      <pic:blipFill><a:blip r:embed="rId2"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>
      <pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$widthEmu" cy="$heightEmu"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>
     </pic:pic>
    </a:graphicData>
   </a:graphic>
  </wp:inline>
 </w:drawing></w:r>
</w:p>''';
  }

  String _wordPageBreak() =>
      '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';

  List<_EktoparasitPage> _buildPages(ReportExportData data) {
    final List<ActivityRecord> records = data.records
        .where((ActivityRecord record) =>
            record.collectionName == 'pencegahan_ektoparasit')
        .toList()
      ..sort((ActivityRecord a, ActivityRecord b) {
        final int dateCompare = a.tanggal.compareTo(b.tanggal);
        if (dateCompare != 0) return dateCompare;
        final String bullA = _bullName(a, data).toLowerCase();
        final String bullB = _bullName(b, data).toLowerCase();
        return bullA.compareTo(bullB);
      });

    if (records.isEmpty) {
      return <_EktoparasitPage>[];
    }

    final Map<String, List<ActivityRecord>> grouped = <String, List<ActivityRecord>>{};
    for (final ActivityRecord record in records) {
      final DateTime day = DateTime(
        record.tanggal.year,
        record.tanggal.month,
        record.tanggal.day,
      );
      final String key = '${day.year}-${day.month}-${day.day}';
      grouped.putIfAbsent(key, () => <ActivityRecord>[]).add(record);
    }

    final List<String> sortedKeys = grouped.keys.toList()
      ..sort((String a, String b) {
        final List<int> aParts = a.split('-').map(int.parse).toList();
        final List<int> bParts = b.split('-').map(int.parse).toList();
        final DateTime aDate = DateTime(aParts[0], aParts[1], aParts[2]);
        final DateTime bDate = DateTime(bParts[0], bParts[1], bParts[2]);
        return aDate.compareTo(bDate);
      });

    final List<_EktoparasitPage> pages = <_EktoparasitPage>[];

    for (final String key in sortedKeys) {
      final List<int> parts = key.split('-').map(int.parse).toList();
      final DateTime date = DateTime(parts[0], parts[1], parts[2]);
      final List<_EktoparasitRow> rows = grouped[key]!
          .map((ActivityRecord record) => _EktoparasitRow(
                bullName: _bullName(record, data),
                breed: _bullBreed(record, data),
                bahan: _plainValue(record.data['bahan']),
                alat: _plainValue(record.data['alat']),
                tindakan: _plainValue(record.data['tindakan']),
                keterangan: _plainValue(record.data['keterangan']),
                petugas: _plainValue(record.data['nama_petugas']),
              ))
          .toList(growable: false);

      int firstRowNumber = 1;
      for (int start = 0; start < rows.length; start += _rowsPerPage) {
        final int end = (start + _rowsPerPage < rows.length)
            ? start + _rowsPerPage
            : rows.length;
        final List<_EktoparasitRow> slice = rows.sublist(start, end);
        final List<String> petugasNames = slice
            .map((row) => row.petugas.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        pages.add(
          _EktoparasitPage(
            date: date,
            rows: slice,
            firstRowNumber: firstRowNumber,
            petugasLabel:
                petugasNames.isEmpty ? '-' : petugasNames.join(', '),
          ),
        );
        firstRowNumber += slice.length;
      }
    }

    return pages;
  }

  String _bullName(ActivityRecord record, ReportExportData data) {
    final BullModel? bull = data.bulls[record.bull_id];
    if (bull == null) return 'Bull';
    final String nama = bull.nama.trim();
    if (nama.isNotEmpty) return nama;
    final String kodeBull = bull.kode_bull.trim();
    return kodeBull.isNotEmpty ? kodeBull : 'Bull';
  }

  String _bullBreed(ActivityRecord record, ReportExportData data) {
    return data.bulls[record.bull_id]?.bangsa.trim() ?? '';
  }

  String _plainValue(dynamic value) => value?.toString().trim() ?? '';

  String _formatLongDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return month.toString();
    }
  }

  String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static const String _contentTypesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
 <Default Extension="xml" ContentType="application/xml"/>
 <Default Extension="png" ContentType="image/png"/>
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
 <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/logo_disbunnak.png"/>
</Relationships>''';

  static const String _appPropertiesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
 <Application>BullCare</Application>
</Properties>''';

  static const String _stylesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
 <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:style>
 <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:bCs/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr></w:style>
</w:styles>''';

  String _corePropertiesXml(UserModel user, DateTime now) => '''<?xml version="1.0" encoding="UTF-8"?>
<cp:coreProperties
 xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:dcterms="http://purl.org/dc/terms/"
 xmlns:dcmitype="http://purl.org/dc/dcmitype/"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
 <dc:title>Formulir Pencegahan Ektoparasit</dc:title>
 <dc:creator>${_xmlEscape(user.nama.trim().isEmpty ? user.email : user.nama)}</dc:creator>
 <cp:lastModifiedBy>BullCare</cp:lastModifiedBy>
 <dcterms:created xsi:type="dcterms:W3CDTF">${now.toIso8601String()}</dcterms:created>
 <dcterms:modified xsi:type="dcterms:W3CDTF">${now.toIso8601String()}</dcterms:modified>
</cp:coreProperties>''';
}

class _EktoparasitPage {
  const _EktoparasitPage({
    required this.date,
    required this.rows,
    required this.firstRowNumber,
    required this.petugasLabel,
  });

  final DateTime date;
  final List<_EktoparasitRow> rows;
  final int firstRowNumber;
  final String petugasLabel;
}

class _EktoparasitRow {
  const _EktoparasitRow({
    required this.bullName,
    required this.breed,
    required this.bahan,
    required this.alat,
    required this.tindakan,
    required this.keterangan,
    required this.petugas,
  });

  final String bullName;
  final String breed;
  final String bahan;
  final String alat;
  final String tindakan;
  final String keterangan;
  final String petugas;
}
