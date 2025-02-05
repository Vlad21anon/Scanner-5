import 'dart:io';

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/scan_file.dart';

class ScanFilesCubit extends Cubit<List<ScanFile>> {
  ScanFilesCubit() : super([]);

  // Добавление файла в список
  void addFile(String path) {
    // Создаём File из пути
    final file = File(path);

    // Получаем размер файла в байтах (int)
    final bytes = file.lengthSync();

    // Переводим в мегабайты (double)
    final sizeInMb = bytes / (1024 * 1024);

    final uuid = const Uuid().v4();

    // Генерируем дату в нужном формате (ДДММГГ)
    final String formattedDate = DateFormat('ddMMyy').format(DateTime.now());

    final newFile = ScanFile(
      id: uuid,
      name: 'Scan $formattedDate',
      path: path,
      size: sizeInMb, // уже реальный размер, а не 1.5
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

  void clearState() {
    emit([]);
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

  // @override
  // List<ScanFile>? fromJson(Map<String, dynamic> json) {
  //   if (json['files'] == null) return [];
  //   final filesJson = json['files'] as List;
  //   return filesJson
  //       .map((e) => ScanFile.fromJson(e as Map<String, dynamic>))
  //       .toList();
  // }
  //
  // @override
  // Map<String, dynamic>? toJson(List<ScanFile> state) {
  //   return {
  //     'files': state.map((file) => file.toJson()).toList(),
  //   };
  // }
}
