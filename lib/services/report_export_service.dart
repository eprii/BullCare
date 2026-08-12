import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity_definition.dart';
import '../models/activity_record.dart';
import '../models/bull_model.dart';
import '../models/report_export_data.dart';
import '../models/user_model.dart';
import '../utils/app_date_utils.dart';
import 'activity_service_registry.dart';
import 'bull_service.dart';
import 'pemberian_pakan_report_template_service.dart';
import 'penimbangan_report_template_service.dart';
import 'pengukuran_report_template_service.dart';
import 'pemberian_obat_cacing_report_template_service.dart';
import 'pengobatan_report_template_service.dart';
import 'pemeriksaan_kesehatan_report_template_service.dart';
import 'pemotongan_bulu_report_template_service.dart';
import 'pemotongan_kuku_report_template_service.dart';
import 'penampungan_semen_report_template_service.dart';
import 'sanitasi_report_template_service.dart';

enum ReportFileFormat { pdf, word }

enum ReportPageOrientation { portrait, landscape }

class ReportExportService {
  const ReportExportService();

  static const MethodChannel _androidDownloadsChannel =
      MethodChannel('id.kalselprov.bib.bullcare/downloads');

  Future<ReportExportData> loadData({
    required Set<String> collections,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String sourceLabel,
    String? sanitasiField,
  }) async {
    if (collections.isEmpty) {
      throw StateError('Pilih minimal satu kategori aktivitas.');
    }

    final DateTime start = DateTime(
      periodStart.year,
      periodStart.month,
      periodStart.day,
    );
    final DateTime endExclusive = DateTime(
      periodEnd.year,
      periodEnd.month,
      periodEnd.day,
    ).add(const Duration(days: 1));

    final selectedServices = ActivityServiceRegistry.allServices
        .where((service) => collections.contains(service.collectionName))
        .toList(growable: false);

    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      Future.wait<List<ActivityRecord>>(
        selectedServices.map((service) => service.getAll()),
      ),
      BullService().getBulls(),
    ]);

    final List<List<ActivityRecord>> groups =
        results[0] as List<List<ActivityRecord>>;
    final List<BullModel> bulls = results[1] as List<BullModel>;

    final List<ActivityRecord> records = groups
        .expand((group) => group)
        .where((record) {
          final bool inPeriod = !record.tanggal.isBefore(start) &&
              record.tanggal.isBefore(endExclusive);
          if (!inPeriod) return false;
          if (sanitasiField != null && record.collectionName == 'sanitasi') {
            return record.data[sanitasiField] == true;
          }
          return true;
        })
        .toList();
    records.sort((a, b) => b.tanggal.compareTo(a.tanggal));

    return ReportExportData(
      records: records,
      bulls: <String, BullModel>{
        for (final BullModel bull in bulls) bull.id: bull,
      },
      periodStart: start,
      periodEnd: DateTime(periodEnd.year, periodEnd.month, periodEnd.day),
      sourceLabel: sourceLabel,
      sanitasiField: sanitasiField,
    );
  }

  Future<void> export({
    required ReportExportData data,
    required UserModel exportedBy,
    required String fileName,
    required ReportFileFormat format,
    required ReportPageOrientation orientation,
  }) async {
    if (data.records.isEmpty) {
      throw StateError('Tidak ada data aktivitas pada periode yang dipilih.');
    }

    final String safeName = _sanitizeFileName(fileName);
    final bool useSanitasiTemplate =
        data.sourceLabel.trim().toLowerCase() == 'sanitasi';
    final bool usePemberianPakanTemplate = data.records.every(
      (record) => record.collectionName == 'pemberian_pakan',
    );
    final bool usePenimbanganTemplate = data.records.every(
      (record) => record.collectionName == 'penimbangan',
    );
    final bool usePengukuranTemplate = data.records.every(
      (record) => record.collectionName == 'pengukuran',
    );
    final bool usePemberianObatCacingTemplate = data.records.every(
      (record) => record.collectionName == 'pemberian_obat_cacing',
    );
    final bool usePengobatanTemplate = data.records.every(
      (record) => record.collectionName == 'pengobatan',
    );
    final bool usePemeriksaanKesehatanTemplate = data.records.every(
      (record) => record.collectionName == 'pemeriksaan_kesehatan',
    );
    final bool usePemotonganBuluTemplate = data.records.every(
      (record) => record.collectionName == 'pemotongan_bulu',
    );
    final bool usePemotonganKukuTemplate = data.records.every(
      (record) => record.collectionName == 'pemotongan_kuku',
    );
    final bool usePenampunganSemenTemplate = data.records.every(
      (record) => record.collectionName == 'penampungan_semen',
    );

    if (format == ReportFileFormat.pdf) {
      final Uint8List bytes = useSanitasiTemplate
          ? await const SanitasiReportTemplateService().buildPdf(
              data: data,
              exportedBy: exportedBy,
            )
          : usePemberianPakanTemplate
              ? await const PemberianPakanReportTemplateService().buildPdf(
                  data: data,
                  exportedBy: exportedBy,
                )
              : usePenimbanganTemplate
                  ? await const PenimbanganReportTemplateService().buildPdf(
                      data: data,
                      exportedBy: exportedBy,
                    )
                  : usePengukuranTemplate
                      ? await const PengukuranReportTemplateService().buildPdf(
                          data: data,
                          exportedBy: exportedBy,
                        )
                      : usePemberianObatCacingTemplate
                          ? await const PemberianObatCacingReportTemplateService()
                              .buildPdf(
                              data: data,
                              exportedBy: exportedBy,
                            )
                          : usePengobatanTemplate
                              ? await const PengobatanReportTemplateService()
                                  .buildPdf(
                                  data: data,
                                  exportedBy: exportedBy,
                                )
                              : usePemeriksaanKesehatanTemplate
                                  ? await const PemeriksaanKesehatanReportTemplateService()
                                      .buildPdf(
                                      data: data,
                                      exportedBy: exportedBy,
                                    )
                                  : usePemotonganBuluTemplate
                                      ? await const PemotonganBuluReportTemplateService()
                                          .buildPdf(
                                          data: data,
                                          exportedBy: exportedBy,
                                        )
                                      : usePemotonganKukuTemplate
                                          ? await const PemotonganKukuReportTemplateService()
                                              .buildPdf(
                                              data: data,
                                              exportedBy: exportedBy,
                                            )
                                          : usePenampunganSemenTemplate
                                          ? await const PenampunganSemenReportTemplateService()
                                              .buildPdf(
                                              data: data,
                                              exportedBy: exportedBy,
                                            )
                                          : await _buildPdf(
                                              data: data,
                                              exportedBy: exportedBy,
                                              orientation: orientation,
                                            );
      await _saveFile(
        name: safeName,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
        androidMimeType: 'application/pdf',
      );
      return;
    }

    final Uint8List bytes = useSanitasiTemplate
        ? await const SanitasiReportTemplateService().buildDocx(
            data: data,
            exportedBy: exportedBy,
          )
        : usePemberianPakanTemplate
            ? await const PemberianPakanReportTemplateService().buildDocx(
                data: data,
                exportedBy: exportedBy,
              )
            : usePenimbanganTemplate
                ? await const PenimbanganReportTemplateService().buildDocx(
                    data: data,
                    exportedBy: exportedBy,
                  )
                : usePengukuranTemplate
                    ? await const PengukuranReportTemplateService().buildDocx(
                        data: data,
                        exportedBy: exportedBy,
                      )
                    : usePemberianObatCacingTemplate
                        ? await const PemberianObatCacingReportTemplateService()
                            .buildDocx(
                            data: data,
                            exportedBy: exportedBy,
                          )
                        : usePengobatanTemplate
                            ? await const PengobatanReportTemplateService()
                                .buildDocx(
                                data: data,
                                exportedBy: exportedBy,
                              )
                            : usePemeriksaanKesehatanTemplate
                                ? await const PemeriksaanKesehatanReportTemplateService()
                                    .buildDocx(
                                    data: data,
                                    exportedBy: exportedBy,
                                  )
                                : usePemotonganBuluTemplate
                                    ? await const PemotonganBuluReportTemplateService()
                                        .buildDocx(
                                        data: data,
                                        exportedBy: exportedBy,
                                      )
                                    : usePemotonganKukuTemplate
                                        ? await const PemotonganKukuReportTemplateService()
                                            .buildDocx(
                                            data: data,
                                            exportedBy: exportedBy,
                                          )
                                        : usePenampunganSemenTemplate
                                        ? await const PenampunganSemenReportTemplateService()
                                            .buildDocx(
                                            data: data,
                                            exportedBy: exportedBy,
                                          )
                                        : _buildDocx(
                                            data: data,
                                            exportedBy: exportedBy,
                                            orientation: orientation,
                                          );
    await _saveFile(
      name: safeName,
      bytes: bytes,
      fileExtension: 'docx',
      mimeType: MimeType.microsoftWord,
      androidMimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  }

  Future<void> _saveFile({
    required String name,
    required Uint8List bytes,
    required String fileExtension,
    required MimeType mimeType,
    required String androidMimeType,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final String? savedUri =
          await _androidDownloadsChannel.invokeMethod<String>(
        'saveWithPicker',
        <String, Object>{
          'fileName': '$name.$fileExtension',
          'bytes': bytes,
          'mimeType': androidMimeType,
        },
      );
      if (savedUri == null || savedUri.trim().isEmpty) {
        throw StateError('File belum tersimpan di perangkat.');
      }
      return;
    }

    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: fileExtension,
      mimeType: mimeType,
    );
  }

  Future<Uint8List> _buildPdf({
    required ReportExportData data,
    required UserModel exportedBy,
    required ReportPageOrientation orientation,
  }) async {
    final pw.Document document = pw.Document(
      title: 'Laporan Aktivitas BullCare',
      author: exportedBy.nama,
      creator: 'BullCare',
    );

    final PdfPageFormat pageFormat = orientation == ReportPageOrientation.portrait
        ? PdfPageFormat.a4
        : PdfPageFormat.a4.landscape;

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        maxPages: 200,
        margin: const pw.EdgeInsets.fromLTRB(30, 32, 30, 32),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.7),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                'BullCare',
                style: pw.TextStyle(
                  color: PdfColors.green800,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              pw.Text(
                'Laporan Aktivitas',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => <pw.Widget>[
          pw.SizedBox(height: 14),
          pw.Text(
            'LAPORAN AKTIVITAS BULLCARE',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Manajemen pemeliharaan bull Balai Inseminasi Buatan (BIB)',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Sumber data: ${data.sourceLabel}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.green800,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.green100),
            ),
            child: pw.Row(
              children: <pw.Widget>[
                pw.Expanded(
                  child: _pdfMeta(
                    'Periode',
                    '${AppDateUtils.formatDate(data.periodStart)} - ${AppDateUtils.formatDate(data.periodEnd)}',
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _pdfMeta(
                    'Jumlah aktivitas',
                    '${data.records.length} aktivitas',
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _pdfMeta(
                    'Diekspor oleh',
                    exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Daftar Aktivitas',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _buildPdfTable(data),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _pdfMeta(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTable(ReportExportData data) {
    final List<List<String>> rows = <List<String>>[
      <String>['No.', 'Tanggal', 'Bull', 'Aktivitas', 'Petugas', 'Rincian'],
      for (int index = 0; index < data.records.length; index++)
        _pdfRow(index + 1, data.records[index], data),
    ];

    return pw.TableHelper.fromTextArray(
      data: rows,
      headerCount: 1,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
      headerStyle: pw.TextStyle(
        fontSize: 6,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.green900,
      ),
      cellStyle: const pw.TextStyle(fontSize: 6, lineSpacing: 1.2),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      cellAlignment: pw.Alignment.topLeft,
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(1.3),
        2: const pw.FlexColumnWidth(1.25),
        3: const pw.FlexColumnWidth(1.4),
        4: const pw.FlexColumnWidth(1.25),
        5: const pw.FlexColumnWidth(2.4),
      },
    );
  }

  List<String> _pdfRow(
    int number,
    ActivityRecord record,
    ReportExportData data,
  ) {
    final BullModel? bull = data.bulls[record.bull_id];
    return <String>[
      number.toString(),
      AppDateUtils.formatDateTime(record.tanggal).replaceAll('•', '-'),
      _bullDisplay(bull),
      _activityDisplay(record, data),
      _petugasDisplay(record),
      _detailDisplay(record),
    ];
  }

  Uint8List _buildDocx({
    required ReportExportData data,
    required UserModel exportedBy,
    required ReportPageOrientation orientation,
  }) {
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
        orientation: orientation,
      ),
      'word/styles.xml': _stylesXml,
      'word/_rels/document.xml.rels': _documentRelationshipsXml,
    };

    for (final MapEntry<String, String> entry in files.entries) {
      archive.addFile(ArchiveFile.string(entry.key, entry.value));
    }

    return ZipEncoder().encodeBytes(archive);
  }

  String _documentXml({
    required ReportExportData data,
    required UserModel exportedBy,
    required ReportPageOrientation orientation,
  }) {
    final StringBuffer body = StringBuffer()
      ..write(_wordParagraph('LAPORAN AKTIVITAS BULLCARE', style: 'Title'))
      ..write(_wordParagraph(
        'Manajemen pemeliharaan bull Balai Inseminasi Buatan (BIB)',
        color: '667069',
      ))
      ..write(_wordParagraph(''))
      ..write(_wordParagraph('Sumber data: ${data.sourceLabel}', bold: true))
      ..write(_wordParagraph(
        'Periode: ${AppDateUtils.formatDate(data.periodStart)} - ${AppDateUtils.formatDate(data.periodEnd)}',
        bold: true,
      ))
      ..write(_wordParagraph('Jumlah aktivitas: ${data.records.length}'))
      ..write(_wordParagraph(
        'Diekspor oleh: ${exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama}',
      ))
      ..write(_wordParagraph(''))
      ..write(_wordParagraph('Daftar Aktivitas', style: 'Heading1'))
      ..write(_wordTable(data));

    final bool landscape = orientation == ReportPageOrientation.landscape;
    final String pageSize = landscape
        ? '<w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/>'
        : '<w:pgSz w:w="11906" w:h="16838"/>';

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $body
    <w:sectPr>
      $pageSize
      <w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720" w:header="360" w:footer="360" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>''';
  }

  String _wordTable(ReportExportData data) {
    final StringBuffer buffer = StringBuffer()
      ..write('''<w:tbl>
<w:tblPr>
  <w:tblW w:w="0" w:type="auto"/>
  <w:tblBorders>
    <w:top w:val="single" w:sz="4" w:color="D6DDD7"/>
    <w:left w:val="single" w:sz="4" w:color="D6DDD7"/>
    <w:bottom w:val="single" w:sz="4" w:color="D6DDD7"/>
    <w:right w:val="single" w:sz="4" w:color="D6DDD7"/>
    <w:insideH w:val="single" w:sz="4" w:color="D6DDD7"/>
    <w:insideV w:val="single" w:sz="4" w:color="D6DDD7"/>
  </w:tblBorders>
</w:tblPr>''')
      ..write(_wordTableRow(
        <String>['No.', 'Tanggal', 'Bull', 'Aktivitas', 'Petugas', 'Rincian'],
        header: true,
      ));

    for (int index = 0; index < data.records.length; index++) {
      final ActivityRecord record = data.records[index];
      final BullModel? bull = data.bulls[record.bull_id];
      buffer.write(
        _wordTableRow(<String>[
          '${index + 1}',
          AppDateUtils.formatDateTime(record.tanggal).replaceAll('•', '-'),
          _bullDisplay(bull),
          _activityDisplay(record, data),
          _petugasDisplay(record),
          _detailDisplay(record),
        ]),
      );
    }

    buffer.write('</w:tbl>');
    return buffer.toString();
  }

  String _wordTableRow(List<String> cells, {bool header = false}) {
    final String cellColor = header ? 'EAF7EC' : 'FFFFFF';
    final String content = cells.map((value) {
      return '''<w:tc>
<w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="$cellColor"/><w:tcMar><w:top w:w="80" w:type="dxa"/><w:left w:w="80" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/><w:right w:w="80" w:type="dxa"/></w:tcMar></w:tcPr>
${_wordParagraph(value, bold: header, fontSizeHalfPoints: 12)}
</w:tc>''';
    }).join();
    return '<w:tr>$content</w:tr>';
  }

  String _wordParagraph(
    String value, {
    String? style,
    bool bold = false,
    String? color,
    int fontSizeHalfPoints = 22,
  }) {
    final String safeValue = _xmlEscape(value.replaceAll('\n', ' '));
    final String styleXml = style == null ? '' : '<w:pStyle w:val="$style"/>';
    final String boldXml = bold ? '<w:b/><w:bCs/>' : '';
    final String colorXml = color == null ? '' : '<w:color w:val="$color"/>';
    return '''<w:p>
<w:pPr>$styleXml</w:pPr>
<w:r>
  <w:rPr>$boldXml$colorXml<w:sz w:val="$fontSizeHalfPoints"/><w:szCs w:val="$fontSizeHalfPoints"/></w:rPr>
  <w:t xml:space="preserve">$safeValue</w:t>
</w:r>
</w:p>''';
  }

  String _bullDisplay(BullModel? bull) {
    if (bull == null) return 'Bull tidak ditemukan';
    final String code = bull.kode_bull.trim();
    if (code.isEmpty) return bull.nama;
    return '${bull.nama} ($code)';
  }

  String _activityDisplay(ActivityRecord record, ReportExportData data) {
    if (record.collectionName == 'sanitasi' && data.sanitasiField != null) {
      return data.sourceLabel;
    }
    return record.definition.label;
  }

  String _petugasDisplay(ActivityRecord record) {
    final String nama = record.data['nama_petugas']?.toString().trim() ?? '';
    return nama.isEmpty ? 'Belum dicatat' : nama;
  }

  String _detailDisplay(ActivityRecord record) {
    final List<String> values = <String>[];
    for (final ActivityFieldDefinition field in record.definition.fields) {
      final dynamic value = record.data[field.key];
      if (field.type == ActivityFieldType.boolean) {
        if (value == true) values.add(field.label);
        continue;
      }
      if (value == null || value.toString().trim().isEmpty) continue;
      final String suffix = field.suffix == null ? '' : ' ${field.suffix}';
      values.add('${field.label}: $value$suffix');
    }
    return values.isEmpty ? 'Aktivitas tercatat' : values.join('; ');
  }

  String _sanitizeFileName(String value) {
    final String trimmed = value.trim();
    final String fallback = 'Laporan BullCare';
    final String source = trimmed.isEmpty ? fallback : trimmed;
    final String cleaned = source.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _corePropertiesXml(UserModel exportedBy, DateTime now) {
    final String timestamp = now.toIso8601String();
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Laporan Aktivitas BullCare</dc:title>
  <dc:subject>Manajemen pemeliharaan bull BIB</dc:subject>
  <dc:creator>${_xmlEscape(exportedBy.nama.trim().isEmpty ? exportedBy.email : exportedBy.nama)}</dc:creator>
  <cp:lastModifiedBy>BullCare</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$timestamp</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$timestamp</dcterms:modified>
</cp:coreProperties>''';
  }

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
  <Application>BullCare</Application>
  <AppVersion>1.0</AppVersion>
</Properties>''';

  static const String _stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
    <w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:rPr><w:b/><w:bCs/><w:color w:val="087C32"/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:qFormat/>
    <w:rPr><w:b/><w:bCs/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr>
  </w:style>
</w:styles>''';
}
