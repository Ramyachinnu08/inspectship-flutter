import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart' show Icons, IconData;
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/models.dart';

/// Builds the downloadable PDF so that it looks the same as the in-app
/// report viewer (report_viewer_screen.dart), page by page:
///
///  1. Cover
///  2. Contents
///  3. General Information (cards)
///  4. Answered NO with comments (findings)
///  5. Answered NO without comments
///  6. Answered N/A with comments
///  7. Answered N/A without comments
///  8. Answered N/V with comments
///  9. Answered N/V without comments
/// 10. Answered YES with comments
/// 11. Answered YES without comments
/// 12. Evidence photo gallery
/// 13. Inspection summary
/// 14. Contact us
class ReportPdfGenerator {
  /// DEBUG: how many report parts to build (1 = cover only ... 14 = all).
  /// Used to find a part that makes the PDF engine hang. Keep 14 normally.
  static int debugParts = 14;

  // ── palette (same as app) ──
  static const _navy = PdfColor.fromInt(0xFF1A2A5E);
  static const _orange = PdfColor.fromInt(0xFFFF6B00);
  static const _red = PdfColor.fromInt(0xFFEF4444);
  static const _green = PdfColor.fromInt(0xFF22C55E);
  static const _text = PdfColor.fromInt(0xFF374151);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _line = PdfColor.fromInt(0xFFE5E7EB);
  static const _bgSoft = PdfColor.fromInt(0xFFF9FAFB);
  static const _orangeSoft = PdfColor.fromInt(0xFFFFF3EC);
  static const _orangeLine = PdfColor.fromInt(0xFFFFD9BF);
  static const _redSoft = PdfColor.fromInt(0xFFFEF2F2);
  static const _redLine = PdfColor.fromInt(0xFFFECACA);
  static const _redDark = PdfColor.fromInt(0xFF991B1B);
  static const _greenSoft = PdfColor.fromInt(0xFFF0FDF4);
  static const _greenLine = PdfColor.fromInt(0xFFBBF7D0);
  static const _greenDark = PdfColor.fromInt(0xFF166534);
  static const _amber = PdfColor.fromInt(0xFFB45309);
  static const _summaryBrown = PdfColor.fromInt(0xFF6B4423);

  static const _bannerUrl = 'https://i.ibb.co/zh2hKsVV/dash.png';

  static const _pageBg = PdfColor.fromInt(0xFFE8EAED);
  static const _cardLine = PdfColor.fromInt(0xFFECECEC);

  // Outer gap between grey page edge and white card, and inner card padding.
  static const double _cardInset = 16;
  static const double _cardPad = 24;
  static const _pageMargin = pw.EdgeInsets.all(_cardInset + _cardPad);

  /// Same look as the app's _Page widget: grey page, white rounded card,
  /// optional red left bar for the findings card.
  static pw.PageTheme _cardTheme({PdfColor? leftBar}) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: _pageMargin,
      buildBackground: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Container(
          color: _pageBg,
          padding: const pw.EdgeInsets.all(_cardInset),
          child: pw.Stack(children: [
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(14),
                border: pw.Border.all(color: _cardLine),
              ),
            ),
            // Red left bar drawn separately (library does not allow a
            // one-sided border together with rounded corners).
            if (leftBar != null)
              pw.Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: pw.Container(width: 5, color: leftBar),
              ),
          ]),
        ),
      ),
    );
  }
  static final double _contentWidth = PdfPageFormat.a4.width - 2 * (_cardInset + _cardPad);

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ════════════════════════ IMAGE LOADING ════════════════════════

  /// Loads an image from a data URL (base64) or a normal http URL.
  /// Returns null if it cannot be loaded so the PDF still generates.
  static Future<pw.MemoryImage?> _loadImage(String src) async {
    try {
      if (src.isEmpty) return null;
      Uint8List bytes;
      if (src.startsWith('data:image')) {
        bytes = base64Decode(src.split(',').last);
      } else if (src.startsWith('http')) {
        final r = await http
            .get(Uri.parse(src))
            .timeout(const Duration(seconds: 5));
        if (r.statusCode != 200) return null;
        bytes = r.bodyBytes;
      } else {
        return null;
      }
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  // ════════════════════════ ENTRY POINT ════════════════════════

  /// Progress callback: percent 0..100 and a short message.
  static void Function(int percent, String message)? _progress;

  static Future<void> _report(int pct, String msg) async {
    _progress?.call(pct, msg);
    // give the UI a moment to repaint
    await Future.delayed(const Duration(milliseconds: 1));
  }

  /// Generates the PDF and triggers a direct browser download.
  static Future<void> generateAndPrint(Assignment assignment,
      {void Function(int percent, String message)? onProgress}) async {
    _progress = onProgress;
    final pdf = await _buildDocument(assignment);
    await _report(92, 'Saving PDF file...');
    final bytes = await pdf.save();
    await _report(100, 'Done');
    _downloadInBrowser(bytes,
        '${assignment.vesselName.replaceAll(' ', '_')}_Inspection_Report.pdf');
  }

  /// Creates a Blob URL and triggers download via a temporary anchor element.
  static void _downloadInBrowser(List<int> bytes, String filename) {
    final base64 = base64Encode(bytes);
    final anchor = html.AnchorElement(
        href: 'data:application/pdf;base64,$base64')
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
  }

  // ════════════════════════ DOCUMENT ════════════════════════

  /// Roboto (same font as the Flutter app) + Material icon font.
  /// Falls back to the default PDF font if anything cannot be loaded.
  static bool _useItalic = false;
  static pw.ThemeData? _cachedTheme;
  static bool _themeLoaded = false;

  static Future<pw.ThemeData?> _loadTheme() async {
    if (_themeLoaded) return _cachedTheme; // fonts reused on next download
    try {
      const t = Duration(seconds: 6);
      // all 4 fonts in parallel
      final f = await Future.wait([
        PdfGoogleFonts.robotoRegular().timeout(t),
        PdfGoogleFonts.robotoBold().timeout(t),
        PdfGoogleFonts.robotoItalic().timeout(t),
        PdfGoogleFonts.robotoBoldItalic().timeout(t),
      ]);
      _cachedTheme = pw.ThemeData.withFont(
          base: f[0], bold: f[1], italic: f[2], boldItalic: f[3]);
    } catch (_) {
      _cachedTheme = null; // default PDF font
    }
    _themeLoaded = true;
    return _cachedTheme;
  }

  /// Material icons are not supported reliably by the PDF library,
  /// so card icons are omitted in the PDF (layout stays the same).
  static pw.Widget _icon(IconData i, {double size = 18, PdfColor color = _navy}) =>
      pw.SizedBox();

  static Future<pw.Document> _buildDocument(Assignment a) async {
    await _report(2, 'Loading fonts...');
    final theme = await _loadTheme();
    _useItalic = theme != null;
    final pdf = pw.Document(theme: theme);

    // Section 1 (General Information) is shown as its own card page,
    // so exclude its questions from the answer-grouped pages (same as app).
    Section? generalSec;
    for (final sec in a.sections) {
      if (sec.title.toLowerCase().contains('general information')) {
        generalSec = sec;
        break;
      }
    }
    generalSec ??= a.sections.isNotEmpty ? a.sections.first : null;
    final generalIds =
    (generalSec?.questions ?? const <Question>[]).map((q) => q.id).toSet();
    final all =
    a.allQuestions.where((q) => !generalIds.contains(q.id)).toList();

    bool hasObs(Question q) =>
        (q.commentByAnswer['__observation__'] ?? '').isNotEmpty;

    final noWithC = all
        .where((q) =>
    q.answer == AnswerValue.fail &&
        (q.comment.isNotEmpty || q.evidenceCount > 0 || hasObs(q)))
        .toList();
    final noNoC = all
        .where((q) =>
    q.answer == AnswerValue.fail &&
        q.comment.isEmpty &&
        q.evidenceCount == 0 &&
        !hasObs(q))
        .toList();
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

    // ── preload images in parallel (cover + every evidence photo) ──
    final urls = <String>{};
    for (final q in a.allQuestions) {
      for (final p in q.photos) urls.add(p.url);
      for (final list in q.photosByAnswer.values) {
        for (final p in list) urls.add(p.url);
      }
    }
    final coverSrc = a.coverImage.isNotEmpty ? a.coverImage : _bannerUrl;

    await _report(10, 'Loading ${urls.length} photo(s)...');
    final results = await Future.wait([
      _loadImage(coverSrc),
      for (final u in urls) _loadImage(u),
    ]);
    await _report(30, 'Building pages...');
    final cover = results.first;
    final Map<String, pw.MemoryImage> photoCache = {};
    var i = 1;
    for (final u in urls) {
      final img = results[i++];
      if (img != null) photoCache[u] = img;
    }

    // ── pages in the same order as the app viewer ──
    final parts = <pw.Page Function()>[
          () => _coverPage(a, cover),
          () => _indexPage(a),
          () => generalSec != null ? _generalInfoPage(generalSec) : _contactUsPage(),
          () => _answerPage(a,
          'ANSWERED NO WITH COMMENTS AND/OR ATTACHMENTS (FINDINGS)',
          _red, noWithC, 'N', photoCache,
          showFindings: true, showComment: true, borderRed: true),
          () => _answerPage(a, 'ANSWERED NO WITHOUT COMMENTS / ATTACHMENTS',
          _red, noNoC, 'N', photoCache,
          idsOnly: true, borderRed: true),
          () => _answerPage(a, 'ANSWERED N/A WITH COMMENTS AND/OR ATTACHMENTS',
          _orange, naWithC, 'N/A', photoCache,
          showComment: true),
          () => _answerPage(a, 'ANSWERED N/A WITHOUT COMMENTS / ATTACHMENTS',
          _orange, naNoC, 'N/A', photoCache,
          idsOnly: true),
          () => _answerPage(a,
          'ANSWERED NOT VIEWED WITH COMMENTS AND/OR ATTACHMENTS',
          _orange, nvWithC, 'N/V', photoCache,
          showComment: true),
          () => _answerPage(a,
          'ANSWERED NOT VIEWED WITHOUT COMMENTS / ATTACHMENTS',
          _orange, nvNoC, 'N/V', photoCache,
          idsOnly: true),
          () => _answerPage(a, 'ANSWERED YES WITH COMMENTS AND/OR ATTACHMENTS',
          _orange, yesWithC, 'Y', photoCache,
          showComment: true),
          () => _answerPage(a, 'ANSWERED YES WITHOUT COMMENTS / ATTACHMENTS',
          _orange, yesNoC, 'Y', photoCache,
          idsOnly: true),
          () => _evidencePage(a, photoCache),
          () => _summaryPage(a),
          () => _contactUsPage(),
    ];
    const names = [
      'Cover', 'Contents', 'General information', 'Findings', 'No answers',
      'N/A answers', 'N/A answers', 'Not viewed', 'Not viewed', 'Yes answers',
      'Yes answers', 'Evidence photos', 'Summary', 'Contact us'
    ];
    for (var i = 0; i < parts.length && i < debugParts; i++) {
      await _report(30 + (i * 60 ~/ parts.length), 'Building: ${names[i]}');
      pdf.addPage(parts[i]());
    }
    return pdf;
  }

  // ════════════════════════ SHARED WIDGETS ════════════════════════

  static pw.Widget _brandChip({double fontSize = 10}) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
          horizontal: fontSize * 1.2, vertical: 4),
      decoration: const pw.BoxDecoration(color: _orange),
      child: pw.Text('RIGHTKNOTS',
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
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _brandChip(),
          pw.Text('Inspection Report',
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy)),
        ],
      ),
    );
  }

  static pw.Widget _kv(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 9),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 180,
            child: pw.Text(label,
                style: const pw.TextStyle(color: _muted, fontSize: 11)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════ 1. COVER ════════════════════════

  static pw.Page _coverPage(
      Assignment a, pw.MemoryImage? cover) {
    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_cardInset),
        buildBackground: (_) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: _pageBg),
        ),
      ),
      build: (context) => pw.ClipRRect(
        horizontalRadius: 14,
        verticalRadius: 14,
        child: pw.Container(
          color: PdfColors.white,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Navy header strip with logo + brand chip
              pw.Container(
                color: _navy,
                padding: const pw.EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: pw.Row(
                  children: [
                    _brandChip(fontSize: 12),
                  ],
                ),
              ),
              // Cover banner (vessel photo or RightKnots ship banner)
              pw.Container(
                color: _navy,
                padding: const pw.EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: cover != null
                    ? pw.ClipRRect(
                    horizontalRadius: 8,
                    verticalRadius: 8,
                    child: pw.Container(
                        height: 210,
                        width: PdfPageFormat.a4.width - 2 * _cardInset - 40,
                        child: pw.Image(cover, fit: pw.BoxFit.cover)))
                    : pw.Container(
                    height: 120,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFF24386F),
                        borderRadius: pw.BorderRadius.circular(8)),
                    child: pw.Text('RightKnots Vessel Inspection',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold))),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RightKnots Inspection Report',
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: _navy)),
                    pw.SizedBox(height: 8),
                    pw.Text('${a.vesselName}  ${a.imo}',
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: _orange)),
                    pw.SizedBox(height: 20),
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
                          _kv('Technical Management', 'RightKnots Shipping'),
                          _kv('Inspector', 'Ramya Poojary'),
                          _kv('Date of Inspection', _formatDate(a.dueDate)),
                          _kv('Port of Inspection', a.port),
                          _kv('Overall Status',
                              a.findings > 0 ? 'Findings raised' : 'Satisfactory'),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Text('Confidential - For Internal Use Only',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColor.fromInt(0xFF9CA3AF))),
                  ],
                ),
              ),
              pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════ 2. CONTENTS ════════════════════════

  static pw.MultiPage _indexPage(Assignment a) {
    int page = 3;
    final rows = <pw.Widget>[];

    pw.Widget row(String title, String pg, {bool big = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(children: [
        pw.Expanded(
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: big ? 12 : 11.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy))),
        pw.Text(pg,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _orange)),
      ]),
    );

    for (final s in a.sections) {
      final start = page;
      final pages = (s.questions.length / 8).ceil().clamp(1, 99);
      final end = start + pages - 1;
      rows.add(row(s.title, start == end ? '$start' : '$start-$end', big: true));
      page = end + 1;
    }
    rows.add(pw.SizedBox(height: 10));
    rows.add(row('Evidence Photos', 'Page $page'));
    page += 1;
    rows.add(row('Inspection Summary', 'Page $page'));

    // MultiPage so a long contents list can flow onto a second page
    // (a single Page silently drops content that does not fit).
    return pw.MultiPage(
      maxPages: 20,
      pageTheme: _cardTheme(),
      build: (_) => [
        _reportHeader(),
        pw.Row(children: [
          _icon(Icons.list_alt, size: 16),
          pw.SizedBox(width: 8),
          pw.Text('CONTENTS',
              style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy,
                  letterSpacing: 1.5)),
        ]),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: pw.BoxDecoration(
            color: _bgSoft,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: _line),
          ),
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: rows),
        ),
      ],
    );
  }

  // ════════════════════════ 3. GENERAL INFORMATION ════════════════════════

  /// Mirrors _GeneralInfoBlock._classify in report_viewer_screen.dart.
  static (String, String) _classifyGeneral(Question q) {
    final t = q.text.toLowerCase();
    if (t.contains('imo')) return ('vessel', 'IMO');
    if (t.contains('flag')) return ('vessel', 'Flag');
    if (t.contains('name') && t.contains('vessel') && t.contains('certificate')) {
      return ('vessel', 'Vessel Name');
    }
    if (t.contains('deliver')) return ('vessel', 'Date Delivered');
    if (t.contains('deadweight')) return ('vessel', 'Maximum Deadweight');
    if (t.contains('layup') || t.contains('lay-up')) return ('vessel', 'Layup Date');
    if (t.contains('vessel type') || (t.contains('type') && t.contains('carrier'))) {
      return ('tech', 'Vessel Type');
    }
    if (t.contains('operation at the time') || t.contains('current operation')) {
      return ('tech', 'Current Operation');
    }
    if (t.contains('cargo')) return ('tech', 'Cargo being handled');
    if (t.contains('hull')) return ('tech', 'Hull Type');
    if (t.contains('port state control')) {
      return ('cert', 'Port State Control History (Last 12 Months)');
    }
    if (t.contains('classification society')) return ('cert', 'Classification Society');
    if (t.contains('class certificate')) return ('cert', 'Class Certificate Expiry');
    if (t.contains('special survey')) return ('cert', 'Last Special Survey');
    if (t.contains('dry dock') && t.contains('routine')) return ('cert', 'Last Routine Dry Dock');
    if (t.contains('unscheduled repair') || t.contains('dry dock')) {
      return ('cert', 'Unscheduled Repair');
    }
    if (t.contains('eedi')) return ('energy', 'EEDI');
    if (t.contains('eexi')) return ('energy', 'EEXI');
    if (t.contains('cii') || t.contains('carbon intensity')) {
      return ('energy', 'Carbon Intensity Indicator (CII)');
    }
    if (t.contains('doc manager') || (t.contains('manager') && t.contains('name'))) {
      return ('mgmt', 'Vessel Manager');
    }
    if (t.contains('took over') || t.contains('takeover')) return ('mgmt', 'Manager Takeover Date');
    if (t.contains('visits') && t.contains('manager')) return ('mgmt', 'Last Manager Visits');
    if (t.contains('p&i') || t.contains('p & i')) return ('mgmt', 'P&I Club');
    if (t.contains('port of inspection') || (t.contains('port') && !t.contains('report'))) {
      return ('insp', 'Port of Inspection');
    }
    if (t.contains('arriv')) return ('insp', 'Inspector Arrival');
    if (t.contains('left the vessel') || t.contains('departure')) return ('insp', 'Inspector Departure');
    if (t.contains('total') && t.contains('time')) return ('insp', 'Total Inspection Time');
    if (t.contains('inspection was completed') || t.contains('inspection completed')) {
      return ('insp', 'Inspection Completed');
    }
    if (t.contains('opening meeting')) return ('insp', 'Opening Meeting');
    if (t.contains('closing meeting')) return ('insp', 'Closing Meeting');
    if (t.contains('inspector') && t.contains('name')) return ('insp', 'Inspector Name');
    var label = q.text.trim();
    if (label.endsWith(':')) label = label.substring(0, label.length - 1);
    return ('other', label);
  }

  static pw.MultiPage _generalInfoPage(Section section) {
    final Map<String, List<(String, String)>> cards = {};
    for (final q in section.questions) {
      final v = q.comment.trim();
      if (v.isEmpty) continue;
      final (card, label) = _classifyGeneral(q);
      cards.putIfAbsent(card, () => []).add((label, v));
    }

    final defs = <(String, String, IconData, bool)>[
      ('vessel', 'Vessel Details', Icons.directions_boat_outlined, true),
      ('tech', 'Technical Specifications', Icons.description_outlined, false),
      ('cert', 'Certification & Classification', Icons.workspace_premium_outlined, false),
      ('energy', 'Energy Efficiency', Icons.bolt_outlined, false),
      ('mgmt', 'Management Information', Icons.business_outlined, false),
      ('insp', 'Inspection Details', Icons.info_outline, false),
      ('other', 'Other Information', Icons.notes_outlined, false),
    ];

    return pw.MultiPage(
      maxPages: 200,
      pageTheme: _cardTheme(),
      build: (_) => [
        _reportHeader(),
        pw.Text('1. General information',
            style: pw.TextStyle(
                fontSize: 17, fontWeight: pw.FontWeight.bold, color: _navy)),
        pw.SizedBox(height: 14),
        // Small cards are kept in one piece (Wrap). Very long cards are
        // allowed to split, otherwise the layout engine would loop forever.
        for (final d in defs)
          if ((cards[d.$1] ?? const []).isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: _generalCard(d.$2, d.$3, cards[d.$1]!, grid: d.$4),
            ),
      ],
    );
  }

  static pw.Widget _generalCard(
      String title, IconData icon, List<(String, String)> items,
      {bool grid = false}) {
    pw.Widget kv(String k, String v, {bool stacked = false}) {
      final key = pw.Text(k, style: const pw.TextStyle(fontSize: 9.5, color: _muted));
      final val = pw.Text(v.toUpperCase(),
          style: pw.TextStyle(
              fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _navy));
      if (stacked) {
        return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [key, pw.SizedBox(height: 3), val]);
      }
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 9),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(width: 170, child: key),
          pw.Expanded(child: val),
        ]),
      );
    }

    pw.Widget body;
    if (grid) {
      final rows = <pw.Widget>[];
      for (var i = 0; i < items.length; i += 3) {
        final chunk = items.sublist(i, i + 3 > items.length ? items.length : i + 3);
        rows.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final it in chunk)
                pw.Expanded(child: kv(it.$1, it.$2, stacked: true)),
              for (var j = chunk.length; j < 3; j++) pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        ));
      }
      body = pw.Column(children: rows);
    } else {
      body = pw.Column(children: [for (final it in items) kv(it.$1, it.$2)]);
    }

    return pw.Container(
      width: _contentWidth,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 1),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            _icon(icon),
            pw.SizedBox(width: 10),
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold, color: _navy)),
          ]),
          pw.SizedBox(height: 14),
          body,
        ],
      ),
    );
  }

  // ════════════════════════ 4-11. ANSWER PAGES ════════════════════════

  static pw.MultiPage _answerPage(
      Assignment a,
      String title,
      PdfColor titleColor,
      List<Question> questions,
      String highlight,
      Map<String, pw.MemoryImage> photoCache, {
        bool showFindings = false,
        bool showComment = false,
        bool idsOnly = false,
        bool borderRed = false,
      }) {
    final grouped = _groupBySection(a, questions);

    // Every item is its own top-level widget so MultiPage can break the
    // page between any two items (a single big container cannot be split
    // and makes the engine hang on long lists).
    final children = <pw.Widget>[
      _reportHeader(),
      pw.Text(title,
          style: pw.TextStyle(
              fontSize: 14, fontWeight: pw.FontWeight.bold, color: titleColor)),
      pw.SizedBox(height: 12),
      _answerIndicator(highlight),
      pw.SizedBox(height: 16),
    ];

    if (questions.isEmpty) {
      children.add(pw.Text(
          'No questions with the above answer found in any of the sections.',
          style: pw.TextStyle(
              fontSize: 11, fontWeight: pw.FontWeight.bold, color: _text)));
    } else {
      for (final e in grouped.entries) {
        children.add(pw.Container(
          margin: const pw.EdgeInsets.only(top: 12, bottom: 8),
          padding: const pw.EdgeInsets.only(bottom: 3),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _navy, width: 2)),
          ),
          child: pw.Text(e.key,
              style: pw.TextStyle(
                  fontSize: 12.5, fontWeight: pw.FontWeight.bold, color: _navy)),
        ));
        for (final q in e.value) {
          if (idsOnly) {
            children.add(pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 56,
                    child: pw.Text(q.number,
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _navy)),
                  ),
                  pw.Expanded(
                    child: pw.Text(q.text,
                        style: const pw.TextStyle(fontSize: 11, color: _text)),
                  ),
                ],
              ),
            ));
          } else {
            children.add(_questionRow(q, photoCache,
                showFindings: showFindings, showComment: showComment));
          }
        }
        children.add(pw.SizedBox(height: 8));
      }
    }

    return pw.MultiPage(
      maxPages: 2000,
      pageTheme: _cardTheme(leftBar: borderRed ? _red : null),
      build: (_) => children,
    );
  }

  static pw.Widget _answerIndicator(String highlight) {
    const opts = ['Y', 'N', 'N/A', 'N/V'];
    const fg = {
      'Y': _green,
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
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: sel ? bg[o] : PdfColors.white,
            border: pw.Border.all(
                color: sel ? fg[o]! : _line, width: sel ? 2 : 1),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(o,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: sel ? fg[o] : _muted)),
        );
      }).toList(),
    );
  }

  /// Same text as _questionSummary in report_viewer_screen.dart
  static String _questionSummary(Question q) {
    String status;
    switch (q.answer) {
      case AnswerValue.pass:
        status = 'Satisfactory';
        break;
      case AnswerValue.fail:
        status = 'Deficiency noted';
        break;
      case AnswerValue.na:
        status = 'Not applicable';
        break;
      case AnswerValue.nv:
        status = 'Not viewed';
        break;
      default:
        status = 'Not answered';
    }
    final photoCount = q.photos.length;
    final photoNote = photoCount > 0 ? ' $photoCount photo(s) attached.' : '';
    final commentNote = q.comment.isNotEmpty
        ? ' Inspector noted: ${q.comment.length > 60 ? "${q.comment.substring(0, 60)}..." : q.comment}'
        : '';
    return '$status.$commentNote$photoNote';
  }

  static pw.Widget _questionRow(Question q, Map<String, pw.MemoryImage> photoCache,
      {bool showFindings = false, bool showComment = false}) {
    final obs = q.commentByAnswer['__observation__'] ?? '';
    final photos = q.photos
        .where((p) => photoCache.containsKey(p.url))
        .take(6)
        .toList();

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
            child: pw.Text(q.number,
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
                // Inspector comment (what was checked and how)
                if ((showFindings || showComment) && q.comment.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text('Inspector Comments: ${q.comment}',
                        style: const pw.TextStyle(fontSize: 11, color: _text)),
                  ),
                // Findings = Observation text in red (same as app)
                if ((showFindings || showComment) && obs.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text('Findings: $obs',
                        style: const pw.TextStyle(fontSize: 11, color: _red)),
                  ),
                // Evidence thumbnails with the question
                if ((showFindings || showComment) && photos.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < photos.length; i += 3)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 10),
                            child: pw.Row(
                              children: [
                                for (final p in photos.sublist(
                                    i, i + 3 > photos.length ? photos.length : i + 3))
                                  pw.Container(
                                    width: 150,
                                    height: 110,
                                    margin: const pw.EdgeInsets.only(right: 10),
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(color: _line),
                                      borderRadius: pw.BorderRadius.circular(6),
                                    ),
                                    child: pw.ClipRRect(
                                      horizontalRadius: 6,
                                      verticalRadius: 6,
                                      child: pw.Image(photoCache[p.url]!,
                                          fit: pw.BoxFit.cover),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                // Auto summary line (same as app)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6),
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(7),
                    decoration: pw.BoxDecoration(
                      color: _orangeSoft,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _icon(Icons.auto_awesome, size: 9, color: _orange),
                          pw.SizedBox(width: 5),
                          pw.Expanded(
                            child: pw.Text('Summary: ${_questionSummary(q)}',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    color: _summaryBrown,
                                    fontStyle: _useItalic
                                        ? pw.FontStyle.italic
                                        : pw.FontStyle.normal)),
                          ),
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

  // ════════════════════════ 12. EVIDENCE PHOTO GALLERY ════════════════════════

  static pw.MultiPage _evidencePage(
      Assignment a, Map<String, pw.MemoryImage> photoCache) {
    // Collect all photos from all questions (across all answer slots)
    final items = <_EvidenceItem>[];
    for (final q in a.allQuestions) {
      for (final p in q.photos) {
        items.add(_EvidenceItem(
            questionId: q.number,
            questionText: q.text,
            url: p.url,
            caption: p.caption,
            questionComment: q.comment,
            answerKey: Question.keyFor(q.answer)));
      }
      q.photosByAnswer.forEach((ansKey, list) {
        for (final p in list) {
          final already = q.photos.any((ap) => ap.url == p.url);
          if (!already) {
            items.add(_EvidenceItem(
                questionId: q.number,
                questionText: q.text,
                url: p.url,
                caption: p.caption,
                answerKey: ansKey,
                questionComment: q.commentByAnswer[ansKey] ?? q.comment));
          }
        }
      });
    }

    return pw.MultiPage(
      maxPages: 500,
      pageTheme: _cardTheme(),
      build: (_) => [
        _reportHeader(),
        pw.Row(children: [
          pw.Expanded(
            child: pw.Text('EVIDENCE PHOTO GALLERY',
                style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy,
                    letterSpacing: 1.2)),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: pw.BoxDecoration(
              color: _orangeSoft,
              borderRadius: pw.BorderRadius.circular(20),
              border: pw.Border.all(color: _orangeLine),
            ),
            child: pw.Text(
                '${items.length} image${items.length == 1 ? '' : 's'}',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _orange)),
          ),
        ]),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, width: 60, color: _orange),
        pw.SizedBox(height: 16),
        if (items.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 30),
            child: pw.Text(
                'No evidence photos were captured for this inspection.',
                style: const pw.TextStyle(fontSize: 11, color: _muted)),
          )
        else
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              for (var i = 0; i < items.length; i += 2)
                pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 7, bottom: 14),
                    child: _photoTile(items[i], photoCache),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 7, bottom: 14),
                    child: i + 1 < items.length
                        ? _photoTile(items[i + 1], photoCache)
                        : pw.SizedBox(),
                  ),
                ]),
            ],
          ),
      ],
    );
  }

  static pw.Widget _photoTile(
      _EvidenceItem it, Map<String, pw.MemoryImage> photoCache) {
    final img = photoCache[it.url];

    // Keep each tile well under one page height, otherwise Wrap can never
    // place it and the layout engine hangs.
    String clip(String t, int n) => t.length > n ? '${t.substring(0, n)}...' : t;
    final qText = clip(it.questionText, 220);
    final qComment = clip(it.questionComment, 260);
    final caption = clip(it.caption, 320);

    // Answer badge: YES green, NO red, N/A & N/V orange
    final k = (it.answerKey ?? '').toLowerCase();
    String label;
    PdfColor bg, fg;
    if (k == 'yes') {
      label = 'YES';
      bg = const PdfColor.fromInt(0xFFDCFCE7);
      fg = _greenDark;
    } else if (k == 'no') {
      label = 'NO';
      bg = const PdfColor.fromInt(0xFFFEE2E2);
      fg = _redDark;
    } else if (k == 'na') {
      label = 'N/A';
      bg = _orangeSoft;
      fg = _amber;
    } else if (k == 'nv') {
      label = 'N/V';
      bg = _orangeSoft;
      fg = _amber;
    } else {
      label = '-';
      bg = const PdfColor.fromInt(0xFFF3F4F6);
      fg = _muted;
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.ClipRRect(
            horizontalRadius: 6,
            verticalRadius: 6,
            child: pw.Container(
              height: 160,
              color: _bgSoft,
              alignment: pw.Alignment.center,
              child: img != null
                  ? pw.Image(img, fit: pw.BoxFit.contain)
                  : pw.Text('Image unavailable',
                  style: const pw.TextStyle(fontSize: 9, color: _muted)),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(9),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: pw.BoxDecoration(
                        color: bg, borderRadius: pw.BorderRadius.circular(10)),
                    child: pw.Text(label,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: fg)),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text('Q ${it.questionId}',
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _navy)),
                ]),
                pw.SizedBox(height: 4),
                pw.Text(qText,
                    style: const pw.TextStyle(fontSize: 9.5, color: _text)),
                if (qComment.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Inspector Comment: $qComment',
                      style: const pw.TextStyle(fontSize: 9, color: _muted)),
                ],
                if (caption.isNotEmpty) ...[
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: _orangeSoft,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: _orangeLine),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('AI Analysis',
                            style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: _orange)),
                        pw.SizedBox(height: 2),
                        pw.Text(caption,
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: _text)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════ 13. INSPECTION SUMMARY ════════════════════════

  static pw.MultiPage _summaryPage(Assignment a) {
    final total = a.totalQuestions;
    final answered = a.answeredQuestions;
    final findings = a.findings;
    final findingQs =
    a.allQuestions.where((q) => q.answer == AnswerValue.fail).toList();

    pw.Widget stat(String label, String value, PdfColor color) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: _line),
        ),
        child: pw.Column(children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
          pw.SizedBox(height: 4),
          pw.Text(label,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  fontSize: 9.5,
                  color: _muted,
                  fontWeight: pw.FontWeight.bold)),
        ]),
      ),
    );

    return pw.MultiPage(
      maxPages: 200,
      pageTheme: _cardTheme(),
      build: (_) => [
        _reportHeader(),
        pw.Row(children: [
          _icon(Icons.summarize, size: 16),
          pw.SizedBox(width: 8),
          pw.Text('INSPECTION SUMMARY',
              style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy,
                  letterSpacing: 1.5)),
        ]),
        pw.SizedBox(height: 16),
        pw.Row(children: [
          stat('Total Questions', '$total', _navy),
          pw.SizedBox(width: 10),
          stat('Answered', '$answered', _green),
          pw.SizedBox(width: 10),
          stat('Findings', '$findings', _red),
        ]),
        pw.SizedBox(height: 20),
        pw.Text('Key Findings',
            style: pw.TextStyle(
                fontSize: 12.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black)),
        pw.SizedBox(height: 10),
        if (findingQs.isEmpty)
          pw.Text('No findings recorded. Vessel passed all inspected items.',
              style: const pw.TextStyle(fontSize: 11, color: _muted))
        else
          for (final q in findingQs)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _redSoft,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _redLine),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Q ${q.number}: ${q.text}',
                      style: pw.TextStyle(
                          fontSize: 10.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _redDark)),
                  if ((q.commentByAnswer['__observation__'] ?? '').isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(q.commentByAnswer['__observation__']!,
                        style: const pw.TextStyle(fontSize: 10, color: _red)),
                  ] else if (q.comment.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(q.comment,
                        style: const pw.TextStyle(fontSize: 10, color: _text)),
                  ],
                ],
              ),
            ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _greenSoft,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _greenLine),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Overall Assessment',
                  style: pw.TextStyle(
                      fontSize: 11.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _greenDark)),
              pw.SizedBox(height: 6),
              pw.Text(
                findings == 0
                    ? 'The vessel ${a.vesselName} (${a.imo}) was inspected and no significant deficiencies were identified. The vessel appears to be maintained in satisfactory condition.'
                    : 'The vessel ${a.vesselName} (${a.imo}) was inspected and $findings finding(s) were identified requiring attention. Corrective actions should be addressed as noted above.',
                style: const pw.TextStyle(fontSize: 10.5, color: _text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════ 14. CONTACT US ════════════════════════

  static pw.Page _contactUsPage() {
    pw.Widget line(String t, {bool bold = false, PdfColor color = _text}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(t,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: color)),
        );

    return pw.Page(
      pageTheme: _cardTheme(),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _reportHeader(),
          pw.SizedBox(height: 10),
          pw.Text('CONTACT US',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.SizedBox(height: 8),
          pw.Text(
              "If you're interested and would like to know more, get in touch with our team today.",
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 11, color: _muted)),
          pw.SizedBox(height: 24),
          line('www.inspectship.com'),
          line('info@seasecureshipping.com'),
          line('+971 555 570 855'),
          line('RightKnots Shipping'),
          pw.SizedBox(height: 24),
          pw.Container(
            width: _contentWidth,
            padding: const pw.EdgeInsets.all(24),
            color: const PdfColor.fromInt(0xFFF9FAFB),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                    child: _office('DUBAI', [
                      'Duqe Square Business Center',
                      'Mina Rashid, Dubai, UAE',
                      '+971 555 570 855',
                    ])),
                pw.Expanded(
                    child: _office('INDIA', [
                      'RightKnots India Office',
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
                fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: _navy)),
        pw.SizedBox(height: 8),
        for (final l in lines)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(l,
                style: const pw.TextStyle(fontSize: 10.5, color: _muted)),
          ),
      ],
    );
  }
}

class _EvidenceItem {
  final String questionId;
  final String questionText;
  final String url;
  final String caption;
  final String? answerKey;
  final String questionComment;
  _EvidenceItem({
    required this.questionId,
    required this.questionText,
    required this.url,
    this.caption = '',
    this.answerKey,
    this.questionComment = '',
  });
}