import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../models/scan_file.dart';

class ScanFilesCubit extends HydratedCubit<List<ScanFile>> {
  ScanFilesCubit() : super([]);

  // Добавление файла в список
  void addFile(String path) {
    // Генерация имени, id, времени, размера, и т.д. — для примера делаем упрощённо
    final uuid = const Uuid().v4();
    final newFile = ScanFile(
      id: uuid,
      name: 'Scan ${DateTime.now().millisecondsSinceEpoch}',
      path: path,
      size: 1.5, // условно
      created: DateTime.now(),
    );

    final updatedList = List<ScanFile>.from(state);
    updatedList.add(newFile);
    emit(updatedList);
  }

  // Удаление файла
  void removeFile(String id) {
    final updatedList = state.where((file) => file.id != id).toList();
    emit(updatedList);
  }

  // Редактирование файла (например, переименование)
  void editFile(String id, String newName) {
    final updatedList = state.map((file) {
      if (file.id == id) {
        return ScanFile(
          id: file.id,
          name: newName,
          path: file.path,
          size: file.size,
          created: file.created,
        );
      }
      return file;
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
