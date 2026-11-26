// Mobile/desktop implementation: share/save the PDF with the system dialog.
import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<void> savePdfFile(List<int> bytes, String filename) async {
  await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: filename);
}