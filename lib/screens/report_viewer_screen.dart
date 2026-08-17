import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/pdf_generator.dart';

class ReportViewerScreen extends StatelessWidget {
  final Assignment assignment;
  const ReportViewerScreen({super.key, required this.assignment});

  static const _orange = Color(0xFFFF6B00);
  static const _pageBg = Color(0xFFE8EAED);

  @override
  Widget build(BuildContext context) {
    final all = assignment.allQuestions;
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

    return Scaffold(
      backgroundColor: _pageBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            await ReportPdfGenerator.generateAndPrint(assignment);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PDF error: $e')),
              );
            }
          }
        },
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.download),
        label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2A5E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${assignment.vesselName} — Inspection Report',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await ReportPdfGenerator.generateAndPrint(assignment);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download PDF',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CoverPage(assignment: assignment),
          const SizedBox(height: 8),
          _IndexPage(assignment: assignment),
          const SizedBox(height: 8),
          _SectionCommentsPage(),
          const SizedBox(height: 8),
          _AnswerBlock(
            title: 'ANSWERED NO WITH COMMENTS AND/OR ATTACHMENTS (FINDINGS)',
            titleColor: const Color(0xFFEF4444),
            borderLeftColor: const Color(0xFFEF4444),
            answerHighlight: 'N',
            questions: noQ,
            assignment: assignment,
            showFindings: true,
            showComment: true,
          ),
          const SizedBox(height: 8),
          _AnswerBlock(
            title: 'ANSWERED YES WITH COMMENTS AND/OR ATTACHMENTS',
            titleColor: _orange,
            answerHighlight: 'Y',
            questions: yesWithC,
            assignment: assignment,
            showComment: true,
          ),
          const SizedBox(height: 8),
          _AnswerBlock(
            title: 'ANSWERED YES WITHOUT COMMENTS / ATTACHMENTS',
            titleColor: _orange,
            answerHighlight: 'Y',
            questions: yesNoC,
            assignment: assignment,
            idsOnly: true,
          ),
          const SizedBox(height: 8),
          _AnswerBlock(
            title: 'ANSWERED N/A WITH COMMENTS AND/OR ATTACHMENTS',
            titleColor: _orange,
            answerHighlight: 'N/A',
            questions: naWithC,
            assignment: assignment,
            showComment: true,
          ),
          const SizedBox(height: 8),
          _AnswerBlock(
            title: 'ANSWERED N/A WITHOUT COMMENTS / ATTACHMENTS',
            titleColor: _orange,
            answerHighlight: 'N/A',
            questions: naNoC,
            assignment: assignment,
            idsOnly: true,
          ),
          const SizedBox(height: 8),
          _AnswerBlock(
            title: 'ANSWERED NOT VIEWED WITH COMMENTS AND/OR ATTACHMENTS',
            titleColor: _orange,
            answerHighlight: 'N/V',
            questions: nvWithC,
            assignment: assignment,
            showComment: true,
          ),
          const SizedBox(height: 8),
          _AnswerBlock(
            title: 'ANSWERED NOT VIEWED WITHOUT COMMENTS / ATTACHMENTS',
            titleColor: _orange,
            answerHighlight: 'N/V',
            questions: nvNoC,
            assignment: assignment,
            idsOnly: true,
          ),
          const SizedBox(height: 8),
          _EvidencePhotosPage(assignment: assignment),
          const SizedBox(height: 8),
          _SummaryPage(assignment: assignment),
          const SizedBox(height: 8),
          _ContactUsPage(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderLeftColor;
  const _Page({
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.borderLeftColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: borderLeftColor != null
            ? Border(left: BorderSide(color: borderLeftColor!, width: 5))
            : Border.all(color: const Color(0xFFECECEC)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _CoverPage extends StatelessWidget {
  final Assignment assignment;
  const _CoverPage({required this.assignment});

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    return _Page(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF1A2A5E),
            padding: const EdgeInsets.all(20),
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              color: const Color(0xFFFF6B00),
              child: const Text('RIGHTKNOT',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1)),
            ),
          ),
          if (a.coverImage.isNotEmpty)
            Container(
              width: double.infinity,
              color: const Color(0xFF1A2A5E),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: a.coverImage.startsWith('data:image')
                    ? Image.memory(base64Decode(a.coverImage.split(',').last),
                    width: double.infinity, fit: BoxFit.contain)
                    : Image.network(a.coverImage, width: double.infinity, fit: BoxFit.contain),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RightKnot Inspection Report',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2A5E))),
                const SizedBox(height: 8),
                Text('${a.vesselName}  ${a.imo}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B00))),
                const SizedBox(height: 20),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: Color(0xFFE5E7EB), width: 2)),
                  ),
                  child: Column(
                    children: [
                      _kv('Inspection ID', a.id),
                      _kv('Vessel Name (IMO Number)',
                          '${a.vesselName} (${a.imo})'),
                      _kv('Technical Management', 'RightKnot Shipping'),
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
                const SizedBox(height: 24),
                const Text('Confidential — For Internal Use Only',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF6B7280), fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111))),
          )
        ],
      ),
    );
  }
}

class _SectionCommentsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('SECTION COMMENTS / GENERAL INFORMATION',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF6B00))),
          SizedBox(height: 12),
          Text('No section comments recorded.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Color? borderLeftColor;
  final String answerHighlight;
  final List<Question> questions;
  final Assignment assignment;
  final bool showFindings;
  final bool showComment;
  final bool idsOnly;

  const _AnswerBlock({
    required this.title,
    required this.titleColor,
    this.borderLeftColor,
    required this.answerHighlight,
    required this.questions,
    required this.assignment,
    this.showFindings = false,
    this.showComment = false,
    this.idsOnly = false,
  });

  Map<String, List<Question>> _groupBySection() {
    final m = <String, List<Question>>{};
    for (final q in questions) {
      final section = assignment.sections
          .firstWhere((s) => s.questions.contains(q))
          .title;
      (m[section] ??= []).add(q);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return _Page(
      borderLeftColor: borderLeftColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: titleColor)),
          const SizedBox(height: 12),
          _answerIndicator(answerHighlight),
          const SizedBox(height: 16),
          if (questions.isEmpty)
            const Text(
                'No questions with the above answer found in any of the sections.',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151)))
          else
            ..._groupBySection().entries.map((e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  padding: const EdgeInsets.only(bottom: 3),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: Color(0xFF1A2A5E), width: 2)),
                  ),
                  child: Text(e.key,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A2A5E))),
                ),
                if (idsOnly)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                        e.value.map((q) => q.id).join(', '),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF374151))),
                  )
                else
                  ...e.value.map((q) => _questionRow(q)),
              ],
            )),
        ],
      ),
    );
  }

  Widget _answerIndicator(String highlight) {
    const opts = ['Y', 'N', 'N/A', 'N/V'];
    const fg = {
      'Y': Color(0xFF22C55E),
      'N': Color(0xFFEF4444),
      'N/A': Color(0xFF9CA3AF),
      'N/V': Color(0xFF6B7280),
    };
    const bg = {
      'Y': Color(0xFFDCFCE7),
      'N': Color(0xFFFEE2E2),
      'N/A': Color(0xFFF3F4F6),
      'N/V': Color(0xFFF3F4F6),
    };
    return Row(
      children: opts.map((o) {
        final sel = o == highlight;
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? bg[o] : Colors.white,
            border: Border.all(
                color: sel ? fg[o]! : const Color(0xFFD1D5DB),
                width: sel ? 2 : 1),
          ),
          child: Text(o,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w400,
                  color: sel ? fg[o] : const Color(0xFF9CA3AF))),
        );
      }).toList(),
    );
  }

  // Generate a short summary for a question based on its answer + comment
  String _questionSummary(Question q) {
    final ans = q.answer;
    String status;
    switch (ans) {
      case AnswerValue.pass: status = 'Satisfactory'; break;
      case AnswerValue.fail: status = 'Deficiency noted'; break;
      case AnswerValue.na: status = 'Not applicable'; break;
      case AnswerValue.nv: status = 'Not viewed'; break;
      default: status = 'Not answered';
    }
    final photoCount = q.photos.length;
    final photoNote = photoCount > 0 ? ' $photoCount photo(s) attached.' : '';
    final commentNote = q.comment.isNotEmpty ? ' Inspector noted: ${q.comment.length > 60 ? "${q.comment.substring(0, 60)}..." : q.comment}' : '';
    return '$status.$commentNote$photoNote';
  }

  Widget _questionRow(Question q) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(q.id,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2A5E))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.text,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: Color(0xFF1A2A5E))),
                if ((showFindings || showComment) && q.comment.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${showFindings ? "Findings" : "Inspector Comments"}: ${q.comment}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF374151)),
                    ),
                  ),
                // Auto summary line per question (generated in PDF)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome, size: 11, color: Color(0xFFFF6B00)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Summary: ${_questionSummary(q)}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF6B4423), fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidencePhotosPage extends StatelessWidget {
  final Assignment assignment;
  const _EvidencePhotosPage({required this.assignment});

  @override
  Widget build(BuildContext context) {
    // Collect all photos from all questions (across all answer slots)
    final List<_EvidenceItem> items = [];
    for (final q in assignment.allQuestions) {
      // active photos
      for (final p in q.photos) {
        items.add(_EvidenceItem(questionId: q.id, questionText: q.text, url: p.url, caption: p.caption));
      }
      // per-answer photos
      q.photosByAnswer.forEach((ansKey, list) {
        for (final p in list) {
          // avoid duplicating the active ones
          final already = q.photos.any((ap) => ap.url == p.url);
          if (!already) {
            items.add(_EvidenceItem(questionId: q.id, questionText: q.text, url: p.url, caption: p.caption, answerKey: ansKey));
          }
        }
      });
    }

    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EVIDENCE PHOTOS',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2A5E))),
          const SizedBox(height: 4),
          Container(height: 2, width: 60, color: const Color(0xFFFF6B00)),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Text('No evidence photos were captured for this inspection.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: items.map((it) => _photoTile(it)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _photoTile(_EvidenceItem it) {
    Widget img;
    if (it.url.startsWith('data:image')) {
      img = Image.memory(base64Decode(it.url.split(',').last),
          width: 300, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox(width: 300, height: 200,
              child: Icon(Icons.broken_image_outlined, size: 40, color: Color(0xFF9CA3AF))));
    } else if (it.url.startsWith('http')) {
      img = Image.network(it.url, width: 300, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox(width: 300, height: 200,
              child: Icon(Icons.image_outlined, size: 40, color: Color(0xFF9CA3AF))));
    } else {
      img = const SizedBox(width: 300, height: 200,
          child: Icon(Icons.image_outlined, size: 40, color: Color(0xFF9CA3AF)));
    }
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            child: img,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Q ${it.questionId}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A2A5E))),
                const SizedBox(height: 3),
                Text(it.questionText,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                if (it.caption.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFD9BF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.auto_awesome, size: 11, color: Color(0xFFFF6B00)),
                            SizedBox(width: 4),
                            Text('AI Analysis',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFFF6B00))),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(it.caption,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF374151))),
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
}

class _EvidenceItem {
  final String questionId;
  final String questionText;
  final String url;
  final String caption;
  final String? answerKey;
  _EvidenceItem({
    required this.questionId,
    required this.questionText,
    required this.url,
    this.caption = '',
    this.answerKey,
  });
}


class _IndexPage extends StatelessWidget {
  final Assignment assignment;
  const _IndexPage({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    int page = 3; // sections start after cover(1) + index(2)
    final blocks = <Widget>[];

    for (final s in a.sections) {
      final startPage = page;
      final pages = (s.questions.length / 8).ceil().clamp(1, 99);
      final endPage = startPage + pages - 1;
      // Section header with page range
      blocks.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(s.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2A5E))),
            ),
            Text(startPage == endPage ? '$startPage' : '$startPage-$endPage',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFF6B00))),
          ],
        ),
      ));
      page = endPage + 1;
    }

    // Fixed trailing entries
    blocks.add(const SizedBox(height: 10));
    blocks.add(_fixedRow('Evidence Photos', '$page'));
    page += 1;
    blocks.add(_fixedRow('Inspection Summary', '$page'));

    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.list_alt, size: 20, color: Color(0xFF1A2A5E)),
              SizedBox(width: 8),
              Text('CONTENTS',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1A2A5E), letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks),
          ),
        ],
      ),
    );
  }

  Widget _fixedRow(String title, String page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2A5E))),
          ),
          Text('Page $page',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFF6B00))),
        ],
      ),
    );
  }
}

class _SummaryPage extends StatelessWidget {
  final Assignment assignment;
  const _SummaryPage({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final total = a.totalQuestions;
    final answered = a.answeredQuestions;
    final findings = a.findings;
    // collect finding questions
    final findingQs = a.allQuestions.where((q) => q.answer == AnswerValue.fail).toList();

    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.summarize, size: 20, color: Color(0xFF1A2A5E)),
              SizedBox(width: 8),
              Text('INSPECTION SUMMARY',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1A2A5E), letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _stat('Total Questions', '$total', const Color(0xFF1A2A5E)),
              const SizedBox(width: 10),
              _stat('Answered', '$answered', const Color(0xFF22C55E)),
              const SizedBox(width: 10),
              _stat('Findings', '$findings', const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Key Findings',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111111))),
          const SizedBox(height: 10),
          if (findingQs.isEmpty)
            const Text('No findings recorded. Vessel passed all inspected items.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)))
          else
            ...findingQs.map((q) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q ${q.id}: ${q.text}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF991B1B))),
                  if (q.comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(q.comment, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
                  ],
                ],
              ),
            )),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Assessment',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF166534))),
                const SizedBox(height: 6),
                Text(
                  findings == 0
                      ? 'The vessel ${a.vesselName} (${a.imo}) was inspected and no significant deficiencies were identified. The vessel appears to be maintained in satisfactory condition.'
                      : 'The vessel ${a.vesselName} (${a.imo}) was inspected and $findings finding(s) were identified requiring attention. Corrective actions should be addressed as noted above.',
                  style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ContactUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Center(
            child: Text('CONTACT US',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2A5E))),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
                "If you're interested and would like to know more, get in touch with our team today.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Column(
              children: [
                Text('🌐  www.inspectship.com',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF374151))),
                SizedBox(height: 6),
                Text('✉️  info@seasecureshipping.com',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF374151))),
                SizedBox(height: 6),
                Text('📞  +971 555 570 855',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF374151))),
                SizedBox(height: 6),
                Text('💼  RightKnot Shipping',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF374151))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFF8FAFC),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DUBAI',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A2A5E))),
                      SizedBox(height: 4),
                      Text('Duqe Square Business Center',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
                      Text('Mina Rashid, Dubai, UAE',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
                      Text('+971 555 570 855',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INDIA',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A2A5E))),
                      SizedBox(height: 4),
                      Text('RightKnot India Office',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
                      Text('Mumbai, Maharashtra',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
                      Text('+91 888 477 7774',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
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

}