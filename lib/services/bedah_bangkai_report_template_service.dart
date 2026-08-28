import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity_record.dart';
import '../models/bull_model.dart';
import '../models/report_export_data.dart';
import '../models/user_model.dart';
import '../utils/firestore_utils.dart';

/// Export Bedah Bangkai berdasarkan format formulir kantor yang diberikan.
///
/// Satu document aktivitas tetap mewakili satu kasus pada satu bull.
/// `peralatan` disimpan sebagai teks multiline. `pemeriksaan_organ` disimpan
/// sebagai teks multiline dengan format satu baris:
/// `Nama organ | Hasil pemeriksaan`.
/// Saat export, setiap pasangan organ/hasil dipecah menjadi baris tabel.
class BedahBangkaiReportTemplateService {
  const BedahBangkaiReportTemplateService();

  static const String _logoDisbunnakAsset =
      'assets/branding/kalsel_logo.png';

  Future<Uint8List> buildPdf({
    required ReportExportData data,
    required UserModel exportedBy,
  }) async {
    final ByteData logoData = await rootBundle.load(_logoDisbunnakAsset);
    final Uint8List logoBytes = logoData.buffer.asUint8List(
      logoData.offsetInBytes,
      logoData.lengthInBytes,
    );
    final pw.MemoryImage logo = pw.MemoryImage(logoBytes);
    final List<List<String>> rows = _reportRows(data);

    final pw.Document document = pw.Document(
      title: 'Formulir Bedah Bangkai',
      author:
          exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama,
      creator: 'BullCare',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(18, 16, 18, 18),
        header: (pw.Context context) => _pdfHeader(
          context: context,
          logo: logo,
          petugas: _petugasLabel(data),
        ),
        build: (pw.Context context) => <pw.Widget>[
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            data: <List<String>>[
              <String>[
                'No',
                'Jenis Bull',
                'Bangsa',
                'Tanggal mati',
                'Peralatan',
                'Sampel/Organ\nyang diambil',
                'Tanggal Pengiriman\nke Laboratorium',
                'Tanggal Jawaban',
                'Hasil Pemeriksaan',
                'Keterangan',
              ],
              ...rows,
            ],
            headerCount: 1,
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.45),
            headerStyle: pw.TextStyle(
              fontSize: 5.5,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 5.25, lineSpacing: 1),
            cellAlignment: pw.Alignment.topLeft,
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 3.5),
            columnWidths: <int, pw.TableColumnWidth>{
              0: const pw.FixedColumnWidth(22),
              1: const pw.FlexColumnWidth(0.75),
              2: const pw.FlexColumnWidth(0.8),
              3: const pw.FlexColumnWidth(1.05),
              4: const pw.FlexColumnWidth(1.15),
              5: const pw.FlexColumnWidth(1.2),
              6: const pw.FlexColumnWidth(1.25),
              7: const pw.FlexColumnWidth(1.05),
              8: const pw.FlexColumnWidth(2.25),
              9: const pw.FlexColumnWidth(1.5),
            },
          ),
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
      'word/document.xml': _documentXml(data),
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

  pw.Widget _pdfHeader({
    required pw.Context context,
    required pw.MemoryImage logo,
    required String petugas,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.SizedBox(
          width: 54,
          height: 62,
          child: pw.Center(
            child: pw.Image(
              logo,
              width: 38,
              height: 56,
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'FORMULIR BEDAH BANGKAI',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.SizedBox(
          width: 190,
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.4),
            columnWidths: const <int, pw.TableColumnWidth>{
              0: pw.FixedColumnWidth(62),
              1: pw.FixedColumnWidth(8),
              2: pw.FlexColumnWidth(),
            },
            children: <pw.TableRow>[
              _metaRow('No Dok', ''),
              _metaRow('Revisi', ''),
              _metaRow('Tgl Berlaku', '1 April 2019'),
              _metaRow(
                'Halaman',
                '${context.pageNumber} dari ${context.pagesCount}',
              ),
              _metaRow('Paraf', petugas),
            ],
          ),
        ),
      ],
    );
  }

  pw.TableRow _metaRow(String label, String value) {
    return pw.TableRow(
      children: <pw.Widget>[
        _metaCell(label),
        _metaCell(':', center: true),
        _metaCell(value),
      ],
    );
  }

  pw.Widget _metaCell(String value, {bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: pw.Text(
        value,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: const pw.TextStyle(fontSize: 6.5),
      ),
    );
  }

  List<List<String>> _reportRows(ReportExportData data) {
    final List<ActivityRecord> records = data.records
        .where((record) => record.collectionName == 'bedah_bangkai')
        .toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    final List<List<String>> rows = <List<String>>[];
    int number = 1;
    for (final ActivityRecord record in records) {
      final BullModel? bull = data.bulls[record.bull_id];
      final List<_OrganResult> organResults =
          _parseOrganResults(record.data['pemeriksaan_organ']);
      final List<_OrganResult> safeResults = organResults.isEmpty
          ? const <_OrganResult>[_OrganResult(organ: '', result: '')]
          : organResults;

      for (int index = 0; index < safeResults.length; index++) {
        final bool first = index == 0;
        rows.add(<String>[
          first ? '$number' : '',
          first ? 'Sapi' : '',
          first ? (bull?.bangsa.trim() ?? '') : '',
          first ? _dateValue(record.data['tanggal_mati']) : '',
          first ? _plain(record.data['peralatan']) : '',
          safeResults[index].organ,
          first
              ? _dateValue(record.data['tanggal_pengiriman_laboratorium'])
              : '',
          first ? _dateValue(record.data['tanggal_jawaban']) : '',
          safeResults[index].result,
          first ? _plain(record.data['keterangan']) : '',
        ]);
      }
      number++;
    }
    return rows;
  }

  List<_OrganResult> _parseOrganResults(dynamic raw) {
    final String text = _plain(raw);
    if (text.isEmpty) return <_OrganResult>[];
    return text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final int separator = line.indexOf('|');
          if (separator < 0) {
            return _OrganResult(organ: line, result: '');
          }
          return _OrganResult(
            organ: line.substring(0, separator).trim(),
            result: line.substring(separator + 1).trim(),
          );
        })
        .toList(growable: false);
  }

  String _documentXml(ReportExportData data) {
    final List<List<String>> rows = _reportRows(data);
    final StringBuffer body = StringBuffer()
      ..write(_wordHeader(data))
      ..write(_wordParagraph(''))
      ..write(_wordTable(rows));

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document
 xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
 xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
 xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
 xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
 <w:body>
  $body
  <w:sectPr>
   <w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/>
   <w:pgMar w:top="480" w:right="400" w:bottom="480" w:left="400"/>
  </w:sectPr>
 </w:body>
</w:document>''';
  }

  String _wordHeader(ReportExportData data) {
    return '''<w:tbl>
 <w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders><w:top w:val="single" w:sz="4"/><w:left w:val="single" w:sz="4"/><w:bottom w:val="single" w:sz="4"/><w:right w:val="single" w:sz="4"/><w:insideH w:val="single" w:sz="4"/><w:insideV w:val="single" w:sz="4"/></w:tblBorders></w:tblPr>
 <w:tr>
  <w:tc><w:tcPr><w:tcW w:w="1100" w:type="dxa"/></w:tcPr>${_wordLogoParagraph()}</w:tc>
  <w:tc><w:tcPr><w:tcW w:w="7300" w:type="dxa"/></w:tcPr>${_wordParagraph('FORMULIR BEDAH BANGKAI', bold: true, center: true, fontSizeHalfPoints: 28)}</w:tc>
  <w:tc><w:tcPr><w:tcW w:w="3600" w:type="dxa"/></w:tcPr>
   ${_wordParagraph('No Dok :', fontSizeHalfPoints: 14)}
   ${_wordParagraph('Revisi :', fontSizeHalfPoints: 14)}
   ${_wordParagraph('Tgl Berlaku : 1 April 2019', fontSizeHalfPoints: 14)}
   ${_wordParagraph('Halaman :', fontSizeHalfPoints: 14)}
   ${_wordParagraph('Paraf : ${_petugasLabel(data)}', fontSizeHalfPoints: 14)}
  </w:tc>
 </w:tr>
</w:tbl>''';
  }

  String _wordTable(List<List<String>> rows) {
    final List<String> headers = <String>[
      'No',
      'Jenis Bull',
      'Bangsa',
      'Tanggal mati',
      'Peralatan',
      'Sampel/Organ yang diambil',
      'Tanggal Pengiriman ke Laboratorium',
      'Tanggal Jawaban',
      'Hasil Pemeriksaan',
      'Keterangan',
    ];
    final StringBuffer buffer = StringBuffer()
      ..write('<w:tbl>')
      ..write('<w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblLayout w:type="fixed"/><w:tblBorders>')
      ..write('<w:top w:val="single" w:sz="5"/><w:left w:val="single" w:sz="5"/>')
      ..write('<w:bottom w:val="single" w:sz="5"/><w:right w:val="single" w:sz="5"/>')
      ..write('<w:insideH w:val="single" w:sz="5"/><w:insideV w:val="single" w:sz="5"/>')
      ..write('</w:tblBorders></w:tblPr>')
      ..write(_wordTableRow(headers, header: true));

    for (final List<String> row in rows) {
      buffer.write(_wordTableRow(row));
    }
    buffer.write('</w:tbl>');
    return buffer.toString();
  }

  String _wordTableRow(List<String> cells, {bool header = false}) {
    return '<w:tr>' +
        cells.map((value) {
          final String fill = header ? '<w:shd w:val="clear" w:fill="EDEDED"/>' : '';
          return '''<w:tc><w:tcPr>$fill<w:tcMar><w:top w:w="30" w:type="dxa"/><w:left w:w="30" w:type="dxa"/><w:bottom w:w="30" w:type="dxa"/><w:right w:w="30" w:type="dxa"/></w:tcMar></w:tcPr>${_wordParagraph(value, bold: header, center: header, fontSizeHalfPoints: 11)}</w:tc>''';
        }).join() +
        '</w:tr>';
  }

  String _wordParagraph(
    String text, {
    bool bold = false,
    bool center = false,
    int fontSizeHalfPoints = 18,
  }) {
    final List<String> lines = text.split('\n');
    final String safeRuns = lines.map((line) {
      return '<w:r><w:rPr>${bold ? '<w:b/><w:bCs/>' : ''}<w:sz w:val="$fontSizeHalfPoints"/><w:szCs w:val="$fontSizeHalfPoints"/></w:rPr><w:t xml:space="preserve">${_xmlEscape(line)}</w:t></w:r>';
    }).join('<w:r><w:br/></w:r>');
    return '<w:p><w:pPr>${center ? '<w:jc w:val="center"/>' : ''}</w:pPr>$safeRuns</w:p>';
  }

  String _wordLogoParagraph() {
    const int widthEmu = 411480;
    const int heightEmu = 579120;
    return '''<w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:drawing>
<wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="$widthEmu" cy="$heightEmu"/><wp:effectExtent l="0" t="0" r="0" b="0"/><wp:docPr id="1" name="Logo Disbunnak"/><wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic><pic:nvPicPr><pic:cNvPr id="1" name="logo_disbunnak.png"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="rId2"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$widthEmu" cy="$heightEmu"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline>
</w:drawing></w:r></w:p>''';
  }

  String _petugasLabel(ReportExportData data) {
    final List<String> names = data.records
        .where((record) => record.collectionName == 'bedah_bangkai')
        .map((record) => _plain(record.data['nama_petugas']))
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return names.isEmpty ? '' : names.join(', ');
  }

  String _dateValue(dynamic value) {
    if (value == null) return '';
    return _formatDate(dateTimeFromFirestore(value));
  }

  String _formatDate(DateTime date) =>
      '${date.day} ${_monthName(date.month)} ${date.year}';

  String _monthName(int month) {
    const List<String> names = <String>[
      '',
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
    return month >= 1 && month <= 12 ? names[month] : '$month';
  }

  String _plain(dynamic value) => value?.toString().trim() ?? '';

  String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

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
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>BullCare</Application></Properties>''';

  static const String _stylesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr></w:style></w:styles>''';

  String _corePropertiesXml(UserModel user, DateTime now) => '''<?xml version="1.0" encoding="UTF-8"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>Formulir Bedah Bangkai</dc:title><dc:creator>${_xmlEscape(user.nama.trim().isEmpty ? user.email : user.nama)}</dc:creator><dcterms:created xsi:type="dcterms:W3CDTF">${now.toIso8601String()}</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">${now.toIso8601String()}</dcterms:modified></cp:coreProperties>''';
}

class _OrganResult {
  const _OrganResult({required this.organ, required this.result});

  final String organ;
  final String result;
}
