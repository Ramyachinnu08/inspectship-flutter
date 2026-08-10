import 'package:flutter/material.dart';
import '../models/models.dart';
import '../api_service.dart';
import 'report_viewer_screen.dart';

/// Opens the existing ReportViewerScreen with real backend data.
class ReportLauncher {
  static Future<void> open(BuildContext context, Map<String, dynamic> a) async {
    final backendId = a['id'];
    final int assignmentId =
    backendId is int ? backendId : int.tryParse('$backendId') ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
    );

    final detail = await ApiService.getInspectionDetail(assignmentId);

    if (context.mounted) Navigator.pop(context); // close loader

    if (detail == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load report. Please re-login and retry.')),
        );
      }
      return;
    }

    final assignment = _build(a, detail);

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportViewerScreen(assignment: assignment)),
    );
  }

  static Assignment _build(Map<String, dynamic> a, Map<String, dynamic> detail) {
    final vessel = (detail['vessel'] ?? a['vessel'] ?? 'Unknown').toString();
    final imo = (detail['vessel_imo'] ?? a['vessel_imo'] ?? '').toString();
    final template = (detail['template'] ?? a['template'] ?? 'Inspection').toString();

    DateTime due = DateTime.now();
    if (a['due_date'] != null) {
      due = DateTime.tryParse(a['due_date']) ?? DateTime.now();
    }

    final answers = detail['answers'];
    String coverImage = '';
    if (answers is Map && answers['__cover_image__'] is Map) {
      coverImage = (answers['__cover_image__']['url'] ?? '').toString();
    }
    final Map<String, Map> savedById = {};
    if (answers is Map) {
      answers.forEach((k, v) {
        if (v is Map) savedById['$k'] = v;
      });
    }

    final sections = _buildSections(a['template_sections'], savedById);

    return Assignment(
      id: 'INS-${a['id']}',
      vesselName: vessel,
      imo: imo.isEmpty ? 'IMO —' : (imo.startsWith('IMO') ? imo : 'IMO $imo'),
      templateName: template,
      dueDate: due,
      port: 'Port',
      scope: 'standard',
      status: AssignmentStatus.submitted,
      sections: sections,
      masterSignName: (detail['master_name'] ?? '').toString(),
      masterSigned: true,
      inspectorSigned: true,
      coverImage: coverImage,
    );
  }

  static List<Section> _buildSections(dynamic templateSections, Map<String, Map> savedById) {
    List<dynamic>? structure;
    if (templateSections is Map && templateSections['draftVersions'] is List) {
      final drafts = templateSections['draftVersions'] as List;
      Map? chosen;
      for (final d in drafts) {
        if (d is Map && d['status'] == 'Published' && d['structure'] is List) {
          chosen = d;
          break;
        }
      }
      chosen ??= (drafts.isNotEmpty && drafts.last is Map) ? drafts.last as Map : null;
      if (chosen != null && chosen['structure'] is List) {
        structure = chosen['structure'] as List;
      }
    } else if (templateSections is List) {
      structure = templateSections;
    }

    if (structure == null || structure.isEmpty) {
      return [Section(id: 'sec_empty', title: 'No Questions', colorHex: 0xFF3B82F6, questions: [])];
    }

    final Map<String, List<Question>> byCategory = {};
    final List<String> order = [];

    for (final item in structure) {
      if (item is! Map) continue;
      final category = (item['category'] ?? 'General').toString().trim();
      final cat = category.isEmpty ? 'General' : category;
      if (!byCategory.containsKey(cat)) {
        byCategory[cat] = [];
        order.add(cat);
      }
      final qid = (item['sub_number'] ?? item['subNumber'] ?? item['id'] ?? '').toString();
      final text = (item['question'] ?? item['text'] ?? '').toString();
      final guide = (item['guide_to_inspection'] ?? item['inspectionGuide'] ?? '').toString();
      final required = item['evidence_required'] == true || item['evidenceRequired'] == true;

      AnswerValue? answer;
      String comment = '';
      final saved = savedById[qid];
      if (saved != null) {
        final ans = (saved['answer'] ?? '').toString();
        if (ans == 'yes') answer = AnswerValue.pass;
        if (ans == 'no') answer = AnswerValue.fail;
        if (ans == 'na') answer = AnswerValue.na;
        if (ans == 'nv') answer = AnswerValue.nv;
        comment = (saved['comment'] ?? '').toString();
      }

      final photoList = <EvidencePhoto>[];
      if (saved != null && saved['photos'] is List) {
        for (final url in saved['photos'] as List) {
          photoList.add(EvidencePhoto(
            id: DateTime.now().microsecondsSinceEpoch.toString() + url.hashCode.toString(),
            url: url.toString(),
          ));
        }
      }
      final Map<String, String> commentByAns = {};
      if (saved != null && saved['commentByAnswer'] is Map) {
        (saved['commentByAnswer'] as Map).forEach((k, v) {
          commentByAns['$k'] = v.toString();
        });
      }
      final Map<String, List<EvidencePhoto>> photosByAns = {};
      if (saved != null && saved['photosByAnswer'] is Map) {
        (saved['photosByAnswer'] as Map).forEach((k, v) {
          if (v is List) {
            photosByAns['$k'] = v.map((url) => EvidencePhoto(
              id: DateTime.now().microsecondsSinceEpoch.toString() + url.hashCode.toString(),
              url: url.toString(),
            )).toList();
          }
        });
      }
      byCategory[cat]!.add(Question(
        id: qid.isEmpty ? 'q${byCategory[cat]!.length + 1}' : qid,
        text: text,
        guide: guide,
        required: required,
        answer: answer,
        comment: comment,
        photos: photoList,
        commentByAnswer: commentByAns,
        photosByAnswer: photosByAns,
      ));
    }

    final palette = [0xFF3B82F6, 0xFFF59E0B, 0xFF22C55E, 0xFF8B5CF6, 0xFFEC4899, 0xFFEF4444];
    final sections = <Section>[];
    for (int i = 0; i < order.length; i++) {
      final cat = order[i];
      sections.add(Section(
        id: 'sec_$i',
        title: 'Section ${i + 1}: $cat',
        colorHex: palette[i % palette.length],
        questions: byCategory[cat]!,
      ));
    }
    return sections;
  }
}