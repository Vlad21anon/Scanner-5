import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../models/scan_file.dart';

class FilesCubit extends HydratedCubit<List<ScanFile>> {
  FilesCubit()
      : super([]);

  ScanFile? lastScanFile;

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
