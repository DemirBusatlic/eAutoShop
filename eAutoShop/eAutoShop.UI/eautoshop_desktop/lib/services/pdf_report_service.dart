import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  PdfReportService._();

  static const PdfColor _primaryBlue = PdfColor.fromInt(0xFF2848C7);

  static const PdfColor _headerBackground = PdfColor.fromInt(0xFFE8ECFA);

  static Future<bool> generateAndSave({
    required String title,
    required String fileName,
    required List<String> headers,
    required List<List<String>> rows,
    DateTime? startDate,
    DateTime? endDate,
    List<String> filters = const <String>[],
  }) async {
    final bytes = await _generatePdf(
      title: title,
      headers: headers,
      rows: rows,
      startDate: startDate,
      endDate: endDate,
      filters: filters,
    );

    final normalizedFileName = _normalizeFileName(fileName);

    const pdfType = XTypeGroup(label: 'PDF', extensions: <String>['pdf']);

    final location = await getSaveLocation(
      suggestedName: normalizedFileName,
      acceptedTypeGroups: const <XTypeGroup>[pdfType],
    );

    if (location == null) {
      return false;
    }

    final file = XFile.fromData(
      bytes,
      mimeType: 'application/pdf',
      name: normalizedFileName,
    );

    await file.saveTo(location.path);

    return true;
  }

  static Future<bool> generateAndPrint({
    required String title,
    required String fileName,
    required List<String> headers,
    required List<List<String>> rows,
    DateTime? startDate,
    DateTime? endDate,
    List<String> filters = const <String>[],
  }) async {
    final bytes = await _generatePdf(
      title: title,
      headers: headers,
      rows: rows,
      startDate: startDate,
      endDate: endDate,
      filters: filters,
    );

    return Printing.layoutPdf(
      name: _normalizeFileName(fileName),
      onLayout: (_) async => bytes,
    );
  }

  static Future<Uint8List> _generatePdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    DateTime? startDate,
    DateTime? endDate,
    List<String> filters = const <String>[],
  }) async {
    _validateReportData(headers: headers, rows: rows);

    final regularFontData = await rootBundle.load(
      'lib/assets/fonts/Roboto-Regular.ttf',
    );

    final boldFontData = await rootBundle.load(
      'lib/assets/fonts/Roboto-Bold.ttf',
    );

    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    final dateFormat = DateFormat('dd.MM.yyyy.');
    final dateTimeFormat = DateFormat('dd.MM.yyyy. HH:mm');

    final period = _formatPeriod(startDate, endDate, dateFormat);

    final pageFormat = headers.length > 5
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            'eAutoShop',
            style: pw.TextStyle(
              color: _primaryBlue,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Stranica ${context.pageNumber} '
            'od ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8),
          ),
        ),
        build: (context) => <pw.Widget>[
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _primaryBlue,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Period: $period'),
          pw.Text(
            'Generisano: '
            '${dateTimeFormat.format(DateTime.now())}',
          ),
          if (filters.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 4),
            pw.Text('Filteri: ${filters.join(', ')}'),
          ],
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerDecoration: const pw.BoxDecoration(color: _headerBackground),
            headerStyle: pw.TextStyle(
              color: _primaryBlue,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 4,
            ),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8F9FD),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static void _validateReportData({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (headers.isEmpty) {
      throw ArgumentError('PDF izvještaj mora imati najmanje jednu kolonu.');
    }

    if (rows.isEmpty) {
      throw StateError('Nema podataka za kreiranje PDF izvještaja.');
    }

    if (rows.any((row) => row.length != headers.length)) {
      throw ArgumentError(
        'Svaki red PDF izvještaja mora imati isti broj '
        'vrijednosti kao zaglavlje.',
      );
    }
  }

  static String _normalizeFileName(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf') ? fileName : '$fileName.pdf';
  }

  static String _formatPeriod(
    DateTime? startDate,
    DateTime? endDate,
    DateFormat formatter,
  ) {
    if (startDate == null && endDate == null) {
      return 'Svi dostupni podaci';
    }

    if (startDate != null && endDate != null) {
      return '${formatter.format(startDate)} - '
          '${formatter.format(endDate)}';
    }

    if (startDate != null) {
      return 'Od ${formatter.format(startDate)}';
    }

    return 'Do ${formatter.format(endDate!)}';
  }
}
