import '../models/models.dart';

class MockStore {
  MockStore._();
  static final MockStore instance = MockStore._();

  String inspectorName = 'Ramya';

  late final List<Assignment> assignments = _buildAssignments();

  List<Assignment> get pending => assignments
      .where((a) =>
  a.status == AssignmentStatus.upcoming ||
      a.status == AssignmentStatus.inProgress ||
      a.status == AssignmentStatus.overdue)
      .toList();

  List<Assignment> get drafts =>
      assignments.where((a) => a.pendingSync).toList();

  List<Assignment> get submitted =>
      assignments.where((a) => a.status == AssignmentStatus.submitted).toList();

  int get inProgressCount =>
      assignments.where((a) => a.status == AssignmentStatus.inProgress).length;
  int get pendingSyncCount => drafts.length;
  int get reportsReadyCount => submitted.length;

  List<Assignment> _buildAssignments() {
    return [
      Assignment(
        id: 'INS-2026-001',
        vesselName: 'MT Blue Horizon',
        imo: 'IMO 9456723',
        templateName: 'Vessel Safety Inspection v1.0',
        dueDate: DateTime.now(),
        port: 'Port of Fujairah',
        scope: 'standard',
        status: AssignmentStatus.inProgress,
        pendingSync: true,
        sections: _buildSections('BH', vesselName: 'MT Blue Horizon', imo: '9456723'),
      ),
      Assignment(
        id: 'INS-2026-002',
        vesselName: 'MT Blue Horizon',
        imo: 'IMO 9456723',
        templateName: 'Vessel Safety Inspection v2.0',
        dueDate: DateTime.now().subtract(const Duration(days: 20)),
        port: 'Port of Fujairah',
        scope: 'standard',
        status: AssignmentStatus.upcoming,
        sections: _buildSections('BH2', vesselName: 'MT Blue Horizon', imo: '9456723'),
      ),
      Assignment(
        id: 'INS-2026-003',
        vesselName: 'Test Vessel',
        imo: 'IMO 1234567',
        templateName: 'Test v1.0',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        port: 'Port of Mumbai',
        scope: 'standard',
        status: AssignmentStatus.upcoming,
        sections: _buildSections('TV1', vesselName: 'Test Vessel', imo: '1234567'),
      ),
      Assignment(
        id: 'INS-2026-004',
        vesselName: 'Test Vessel',
        imo: 'IMO 1234567',
        templateName: 'Test Inspection Template v1.0',
        dueDate: DateTime.now().subtract(const Duration(days: 30)),
        port: 'Port of Kochi',
        scope: 'standard',
        status: AssignmentStatus.submitted,
        sections: _buildSections('TV2',
            vesselName: 'Test Vessel', imo: '1234567', someAnswered: true),
      ),
      Assignment(
        id: 'INS-2026-005',
        vesselName: 'MV Star of Kerala',
        imo: 'IMO 9876543',
        templateName: 'PSC Readiness Audit',
        dueDate: DateTime.now().subtract(const Duration(days: 10)),
        port: 'Port of Kochi',
        scope: 'standard',
        status: AssignmentStatus.submitted,
        sections: _buildSections('SK',
            vesselName: 'MV Star of Kerala', imo: '9876543', someAnswered: true),
      ),
    ];
  }

  List<Section> _buildSections(String prefix,
      {required String vesselName,
        required String imo,
        bool someAnswered = false}) {
    return [
      Section(
        id: '${prefix}_general',
        title: 'Section 1: General Information',
        colorHex: 0xFF3B82F6,
        questions: [
          Question(
            id: '1.1',
            text: "Vessel's name as it appears on the Certificate of Registry",
            guide:
            "Enter the vessel's name exactly as it appears on the Certificate of Registry. This must match the official vessel documentation.",
            required: true,
            comment: someAnswered ? vesselName.toUpperCase() : vesselName.toUpperCase(),
            answer: AnswerValue.pass,
          ),
          Question(
            id: '1.2',
            text: "Vessel's IMO Number",
            guide:
            'The International Maritime Organization (IMO) number is a unique 7-digit identifier assigned to the vessel. It never changes throughout the vessel\'s lifetime.',
            required: true,
            comment: imo,
            answer: AnswerValue.pass,
          ),
          Question(
            id: '1.3',
            text: 'Flag',
            guide:
            'Country whose flag the vessel is flying. Determines regulatory authority for the vessel.',
            required: true,
            comment: someAnswered ? 'Marshall Islands' : '',
            answer: someAnswered ? AnswerValue.pass : null,
          ),
        ],
      ),
      Section(
        id: '${prefix}_safety',
        title: 'Section 2: Safety Management',
        colorHex: 0xFFF59E0B,
        questions: [
          Question(
            id: '2.1',
            text: 'Is the Safety Management Certificate valid?',
            guide:
            'Check that the SMC is currently valid, has not expired, and covers the vessel operations. Verify against the ISM Code requirements.',
            required: true,
            comment: someAnswered ? 'Valid until 2027-05-14' : '',
            answer: someAnswered ? AnswerValue.pass : null,
          ),
          Question(
            id: '2.2',
            text: 'Are safety drills conducted regularly per SOLAS?',
            guide:
            'SOLAS Chapter III requires abandon-ship drills every month and fire drills every month. Check drill records and confirm crew participation.',
            required: true,
            comment: someAnswered ? 'Last fire drill on 2026-01-08' : '',
            answer: someAnswered ? AnswerValue.pass : null,
          ),
          Question(
            id: '2.3',
            text: 'Are emergency escape routes clearly marked?',
            guide:
            'All escape routes must be clearly marked with photoluminescent signs. Check main routes from accommodation and engine room.',
            comment: someAnswered
                ? 'Escape route markings faded in stairwell A. Repainting scheduled.'
                : '',
            answer: someAnswered ? AnswerValue.fail : null,
          ),
        ],
      ),
      Section(
        id: '${prefix}_fire',
        title: 'Section 3: Fire Safety',
        colorHex: 0xFFEF4444,
        questions: [
          Question(
            id: '3.1',
            text: 'Are fire extinguishers serviced and in date?',
            guide:
            'Portable fire extinguishers must be inspected and serviced annually. Check the service tags on each extinguisher.',
            required: true,
            comment:
            someAnswered ? 'All 42 extinguishers serviced 2025-09' : '',
            answer: someAnswered ? AnswerValue.pass : null,
          ),
          Question(
            id: '3.2',
            text: 'Is the fixed fire-fighting system operational?',
            guide:
            'Test alarms and check pressure gauges on CO2/foam systems. Verify certificate of last servicing.',
            comment: '',
          ),
        ],
      ),
      Section(
        id: '${prefix}_lifeboat',
        title: 'Section 4: Lifesaving Appliances',
        colorHex: 0xFF22C55E,
        questions: [
          Question(
            id: '4.1',
            text: 'Are lifeboats and davits in good condition?',
            guide:
            'Visual inspection of lifeboat hull, davit hooks, release gear, and hydrostatic release units.',
            required: true,
            comment: '',
          ),
          Question(
            id: '4.2',
            text: 'Are life rafts within their inspection dates?',
            guide:
            'Inflatable life rafts require annual servicing at an approved service station. Check the label.',
            comment: '',
          ),
        ],
      ),
      Section(
        id: '${prefix}_pollution',
        title: 'Section 5: Pollution Prevention',
        colorHex: 0xFF8B5CF6,
        questions: [
          Question(
            id: '5.1',
            text: 'Is the Oil Record Book properly maintained?',
            guide:
            'Check that all entries in the Oil Record Book are complete, signed by the officer in charge and countersigned by the Master.',
            required: true,
            comment: '',
          ),
          Question(
            id: '5.2',
            text: 'Is the Garbage Management Plan followed?',
            guide:
            'MARPOL Annex V compliance. Check garbage record book and shipboard management plan.',
            comment: '',
          ),
        ],
      ),
    ];
  }
}