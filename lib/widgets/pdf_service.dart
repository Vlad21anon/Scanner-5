import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PdfConverter {
  static Future<File> convertImagesToPdf(List<File> images) async {
    final pdf = pw.Document();
    final imageExtensions = ['.png', '.jpg', '.jpeg'];

    for (var imageFile in images) {
      final image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) continue;

      final pdfImage = pw.MemoryImage(
        await imageFile.readAsBytes(),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Image(pdfImage),
          ),
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/document_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}