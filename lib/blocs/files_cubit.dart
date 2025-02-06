import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../models/scan_file.dart';

class FilesCubit extends HydratedCubit<List<ScanFile>> {
  FilesCubit()
      : super([]);

  ScanFile? lastScanFile;

  /// Метод для удаления страницы по индексу из файла с идентификатором [fileId].
  void removePage(String fileId, int pageIndex) {
    final updatedList = state.map((file) {
      if (file.id == fileId) {
        // Проверка корректности индекса страницы
        if (pageIndex < 0 || pageIndex >= file.pages.length) return file;
        // Создаем новый список страниц без удаляемой страницы
        final updatedPages = List<String>.from(file.pages)..removeAt(pageIndex);
        // Создаем обновленный объект файла с обновленным списком страниц
        final updatedFile = file.copyWith(pages: updatedPages);
        // Если lastScanFile совпадает с редактируемым файлом, обновляем и его
        if (lastScanFile != null && lastScanFile!.id == fileId) {
          lastScanFile = updatedFile;
        }
        return updatedFile;
      }
      return file;
    }).toList();
    emit(updatedList);
  }

  void toggleSelection(String id) {
    final updatedList = state.map((file) {
      if (file.id == id) {
        return file.copyWith(isSelected: !file.isSelected);
      }
      return file;
    }).toList();
    emit(updatedList);
  }

  // Добавление файла в список
  void addFile(ScanFile file) {
    final updatedList = List<ScanFile>.from(state);
    updatedList.add(file);
    emit(updatedList);
  }

  // Удаление файла
  void removeFile(String id) {
    final updatedList = state.where((file) => file.id != id).toList();
    emit(updatedList);
  }

  // Метод редактирования, где передаём обновлённый объект
  void editFile(String id, ScanFile updatedFile) {
    final updatedList = state.map((file) {
      return file.id == id ? updatedFile : file;
    }).toList();
    emit(updatedList);
  }

  @override
  List<ScanFile>? fromJson(Map<String, dynamic> json) {
    if (json['files'] == null) return [];
    final filesJson = json['files'] as List;
    return filesJson
        .map((e) => ScanFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Map<String, dynamic>? toJson(List<ScanFile> state) {
    return {
      'files': state.map((file) => file.toJson()).toList(),
    };
  }
}
