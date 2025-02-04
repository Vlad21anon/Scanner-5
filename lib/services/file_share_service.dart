import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class FileShareService {
  /// Создаёт PDF-файл из изображения, путь к которому передан в [imageFilePath],
  /// и шарит его через share_plus.
  static Future<void> shareImageAsPdf(String imageFilePath, {String? text}) async {
    try {
      // Проверяем, существует ли файл
      final imageFile = File(imageFilePath);
      if (!await imageFile.exists()) {
        debugPrint("Файл не найден: $imageFilePath");
        return;
      }

      // Читаем байты изображения
      final imageBytes = await imageFile.readAsBytes();

      // Создаём PDF документ
      final pdf = pw.Document();

      // Загружаем изображение в PDF формате
      final pdfImage = pw.MemoryImage(imageBytes);

      // Добавляем страницу с изображением в PDF-документ
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      // Сохраняем PDF во временный файл
      final tempDir = await getTemporaryDirectory();
      final pdfPath =
          '${tempDir.path}/shared_file_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      // Шарим PDF-файл через share_plus
      await Share.shareXFiles([XFile(pdfPath)],
          text: text ?? 'Вот ваш PDF файл');
    } catch (e) {
      debugPrint("Ошибка при создании или шаринге PDF: $e");
    }
  }

  /// Универсальный метод для шаринга списка файлов по их путям.
  static Future<void> shareFiles(List<String> filePaths, {String? text}) async {
    try {
      final files = filePaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(files, text: text);
    } catch (e) {
      debugPrint("Ошибка при шаринге файлов: $e");
    }
  }
}
