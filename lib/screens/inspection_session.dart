/// Holds the backend inspection_id for the inspection currently open,
/// so screens like Sign-Off can submit to the backend without threading
/// the id through every constructor.
class InspectionSession {
  InspectionSession._();
  static int? currentInspectionId;
  static Map<String, dynamic> currentAnswers = {};
}