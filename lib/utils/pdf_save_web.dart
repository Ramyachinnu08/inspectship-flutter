// Web implementation: trigger a browser download via a temporary anchor.
import 'dart:convert';
import 'dart:html' as html;

Future<void> savePdfFile(List<int> bytes, String filename) async {
  final base64 = base64Encode(bytes);
  final anchor = html.AnchorElement(href: 'data:application/pdf;base64,$base64')
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  html.document.body!.children.remove(anchor);
}