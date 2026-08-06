import 'dart:convert';
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/models.dart';

class ReportPdfGenerator {
  static const _navy = PdfColor.fromInt(0xFF1A2A5E);
  static const _orange = PdfColor.fromInt(0xFFFF6B00);
  static const _red = PdfColor.fromInt(0xFFEF4444);
  static const _text = PdfColor.fromInt(0xFF374151);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _line = PdfColor.fromInt(0xFFE5E7EB);

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Generates the PDF and triggers a direct browser download.
  static Future<void> generateAndPrint(Assignment assignment) async {
    final pdf = await _buildDocument(assignment);
    final bytes = await pdf.save();
    _downloadInBrowser(bytes,
        '${assignment.vesselName.replaceAll(' ', '_')}_Inspection_Report.pdf');
  }

  /// Creates a Blob URL and triggers download via a temporary anchor element.
  /// Works reliably in Chrome, Edge, Safari, Firefox.
  static void _downloadInBrowser(List<int> bytes, String filename) {
    final base64 = base64Encode(bytes);
    final anchor = html.AnchorElement(
      href: 'data:application/pdf;base64,$base64',
    )
      ..download = filename
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
  }

  static Future<pw.Document> _buildDocument(Assignment a) async {
    final pdf = pw.Document();
    final all = a.allQuestions;

    final noQ = all.where((q) => q.answer == AnswerValue.fail).toList();
    final yesWithC = all
        .where((q) =>
    q.answer == AnswerValue.pass &&
        (q.comment.isNotEmpty || q.evidenceCount > 0))
        .toList();
    final yesNoC = all
        .where((q) =>
    q.answer == AnswerValue.pass &&
        q.comment.isEmpty &&
        q.evidenceCount == 0)
        .toList();
    final naWithC = all
        .where((q) =>
    q.answer == AnswerValue.na &&
        (q.comment.isNotEmpty || q.evidenceCount > 0))
        .toList();
    final naNoC = all
        .where((q) =>
    q.answer == AnswerValue.na &&
        q.comment.isEmpty &&
        q.evidenceCount == 0)
        .toList();
    final nvWithC = all
        .where((q) =>
    q.answer == AnswerValue.nv &&
        (q.comment.isNotEmpty || q.evidenceCount > 0))
        .toList();
    final nvNoC = all
        .where((q) =>
    q.answer == AnswerValue.nv &&
        q.comment.isEmpty &&
        q.evidenceCount == 0)
        .toList();

    pdf.addPage(_coverPage(a));
    pdf.addPage(_sectionCommentsPage());
    pdf.addPage(_answerPage(a,
        'ANSWERED NO WITH COMMENTS AND/OR ATTACHMENTS (FINDINGS)',
        _red, noQ, 'N',
        showFindings: true, showComment: true, borderRed: true));
    pdf.addPage(_answerPage(a, 'ANSWERED YES WITH COMMENTS AND/OR ATTACHMENTS',
        _orange, yesWithC, 'Y',
        showComment: true));
    pdf.addPage(_answerPage(a, 'ANSWERED YES WITHOUT COMMENTS / ATTACHMENTS',
        _orange, yesNoC, 'Y',
        idsOnly: true));
    pdf.addPage(_answerPage(a, 'ANSWERED N/A WITH COMMENTS AND/OR ATTACHMENTS',
        _orange, naWithC, 'N/A',
        showComment: true));
    pdf.addPage(_answerPage(a, 'ANSWERED N/A WITHOUT COMMENTS / ATTACHMENTS',
        _orange, naNoC, 'N/A',
        idsOnly: true));
    pdf.addPage(_answerPage(a,
        'ANSWERED NOT VIEWED WITH COMMENTS AND/OR ATTACHMENTS',
        _orange, nvWithC, 'N/V',
        showComment: true));
    pdf.addPage(_answerPage(a,
        'ANSWERED NOT VIEWED WITHOUT COMMENTS / ATTACHMENTS',
        _orange, nvNoC, 'N/V',
        idsOnly: true));
    pdf.addPage(_contactUsPage());
    return pdf;
  }

  static pw.Page _coverPage(Assignment a) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            height: 180,
            decoration: const pw.BoxDecoration(color: _navy),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: _seaSecureChip(fontSize: 12),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Sea Secure Inspection Report',
                    style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: _navy)),
                pw.SizedBox(height: 8),
                pw.Text('${a.vesselName}  ${a.imo}',
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: _orange)),
                pw.SizedBox(height: 24),
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border:
                    pw.Border(top: pw.BorderSide(color: _line, width: 2)),
                  ),
                  child: pw.Column(
                    children: [
                      _kv('Inspection ID', a.id),
                      _kv('Vessel Name (IMO Number)',
                          '${a.vesselName} (${a.imo})'),
                      _kv('Technical Management', 'Sea Secure Shipping'),
                      _kv('Inspector', 'Ramya Poojary'),
                      _kv('Date of Inspection', _formatDate(a.dueDate)),
                      _kv('Port of Inspection', a.port),
                      _kv(
                          'Overall Status',
                          a.findings > 0
                              ? 'Findings raised'
                              : 'Satisfactory'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 36),
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 20),
                  decoration: const pw.BoxDecoration(
                    border:
                    pw.Border(top: pw.BorderSide(color: _line, width: 1)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Sea Secure Shipping · inspectship.com',
                          style: pw.TextStyle(
                              fontSize: 11,
                              color: _navy,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('Confidential — For Internal Use Only',
                          style:
                          const pw.TextStyle(fontSize: 10, color: _muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _kv(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFF3F4F6))),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 200,
            child: pw.Text(label,
                style: const pw.TextStyle(color: _muted, fontSize: 12)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _seaSecureChip({double fontSize = 10}) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
          horizontal: fontSize * 1.2, vertical: 4),
      decoration: const pw.BoxDecoration(color: _orange),
      child: pw.Text('SEA SECURE',
          style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: fontSize,
              letterSpacing: 0.5)),
    );
  }

  static pw.Widget _reportHeader() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _seaSecureChip(),
          pw.Text('Inspection Report',
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy)),
        ],
      ),
    );
  }

  static pw.Page _sectionCommentsPage() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _reportHeader(),
          pw.Text('SECTION COMMENTS / GENERAL INFORMATION',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _orange)),
          pw.SizedBox(height: 16),
          pw.Text('No section comments recorded.',
              style: const pw.TextStyle(fontSize: 12, color: _muted)),
        ],
      ),
    );
  }

  static pw.Page _answerPage(
      Assignment a,
      String title,
      PdfColor titleColor,
      List<Question> questions,
      String highlight, {
        bool showFindings = false,
        bool showComment = false,
        bool idsOnly = false,
        bool borderRed = false,
      }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
      build: (_) => [
        pw.Container(
          decoration: borderRed
              ? const pw.BoxDecoration(
            border: pw.Border(
                left: pw.BorderSide(color: _red, width: 4)),
          )
              : null,
          padding: borderRed
              ? const pw.EdgeInsets.only(left: 8)
              : pw.EdgeInsets.zero,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _reportHeader(),
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: titleColor)),
              pw.SizedBox(height: 12),
              _answerIndicator(highlight),
              pw.SizedBox(height: 12),
              if (questions.isEmpty)
                pw.Text(
                    'No questions with the above answer found in any of the sections.',
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _text))
              else
                ..._groupBySection(a, questions).entries.expand((e) => [
                  _sectionSubHeader(e.key),
                  if (idsOnly)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 14),
                      child: pw.Text(
                          e.value.map((q) => q.id).join(', '),
                          style: const pw.TextStyle(
                              fontSize: 12, color: _text)),
                    )
                  else
                    ...e.value.map((q) => _questionRow(q,
                        showFindings: showFindings,
                        showComment: showComment)),
                ]),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _answerIndicator(String highlight) {
    const opts = ['Y', 'N', 'N/A', 'N/V'];
    const fg = {
      'Y': PdfColor.fromInt(0xFF22C55E),
      'N': _red,
      'N/A': PdfColor.fromInt(0xFF9CA3AF),
      'N/V': _muted,
    };
    const bg = {
      'Y': PdfColor.fromInt(0xFFDCFCE7),
      'N': PdfColor.fromInt(0xFFFEE2E2),
      'N/A': PdfColor.fromInt(0xFFF3F4F6),
      'N/V': PdfColor.fromInt(0xFFF3F4F6),
    };
    return pw.Row(
      children: opts.map((o) {
        final sel = o == highlight;
        return pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding:
          const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: sel ? bg[o] : PdfColors.white,
            border: pw.Border.all(
                color: sel ? fg[o]! : const PdfColor.fromInt(0xFFD1D5DB),
                width: sel ? 2 : 1),
          ),
          child: pw.Text(o,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight:
                  sel ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: sel
                      ? fg[o]!
                      : const PdfColor.fromInt(0xFF9CA3AF))),
        );
      }).toList(),
    );
  }

  static pw.Widget _sectionSubHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 18, bottom: 8),
      padding: const pw.EdgeInsets.only(bottom: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _navy, width: 2)),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 12, fontWeight: pw.FontWeight.bold, color: _navy)),
    );
  }

  static pw.Widget _questionRow(Question q,
      {bool showFindings = false, bool showComment = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 50,
            child: pw.Text(q.id,
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy)),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(q.text,
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _navy)),
                pw.SizedBox(height: 4),
                if (showFindings && q.comment.isNotEmpty)
                  pw.RichText(
                    text: pw.TextSpan(
                        style:
                        const pw.TextStyle(fontSize: 11, color: _text),
                        children: [
                          pw.TextSpan(
                              text: 'Findings: ',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold)),
                          pw.TextSpan(text: q.comment),
                        ]),
                  ),
                if (showComment && q.comment.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.RichText(
                      text: pw.TextSpan(
                          style: const pw.TextStyle(
                              fontSize: 11, color: _text),
                          children: [
                            pw.TextSpan(
                                text: 'Inspector Comments: ',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: q.comment),
                          ]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Map<String, List<Question>> _groupBySection(
      Assignment a, List<Question> qs) {
    final m = <String, List<Question>>{};
    for (final q in qs) {
      final section =
          a.sections.firstWhere((s) => s.questions.contains(q)).title;
      (m[section] ??= []).add(q);
    }
    return m;
  }

  static pw.Page _contactUsPage() {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _reportHeader(),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text('CONTACT US',
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy)),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
                "If you're interested and would like to know more, get in touch with our team today.",
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 12, color: _muted)),
          ),
          pw.SizedBox(height: 28),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text('www.inspectship.com',
                    style: const pw.TextStyle(fontSize: 12, color: _text)),
                pw.SizedBox(height: 6),
                pw.Text('info@seasecureshipping.com',
                    style: const pw.TextStyle(fontSize: 12, color: _text)),
                pw.SizedBox(height: 6),
                pw.Text('+971 555 570 855',
                    style: const pw.TextStyle(fontSize: 12, color: _text)),
                pw.SizedBox(height: 6),
                pw.Text('Sea Secure Shipping',
                    style: const pw.TextStyle(fontSize: 12, color: _text)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                    child: _office('DUBAI', [
                      'Duqe Square Business Center',
                      'Mina Rashid, Dubai, UAE',
                      '+971 555 570 855',
                    ])),
                pw.SizedBox(width: 16),
                pw.Expanded(
                    child: _office('INDIA', [
                      'Sea Secure India Office',
                      'Mumbai, Maharashtra',
                      '+91 888 477 7774',
                    ])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _office(String city, List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(city,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _navy)),
        pw.SizedBox(height: 4),
        for (final l in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(l,
                style: const pw.TextStyle(fontSize: 11, color: _muted)),
          ),
      ],
    );
  }
}