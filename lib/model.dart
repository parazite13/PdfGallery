import 'dart:typed_data';

class PdfCategory{
  String name = "";
  String path = "";
  List<PdfFile> files = <PdfFile>[];
}

class PdfFile {
  String name = "";
  String path = "";
  Uint8List? bytes;
}