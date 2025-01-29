import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../gen/assets.gen.dart';
import '../../models/scan_file.dart';

class FilesCubit extends HydratedCubit<List<ScanFile>> {
  FilesCubit()
      : super([
          ScanFile(
            name: 'sdfasdf activdsfsdf',
            id: '3',
            created: DateTime.now(),
            size: 1.8,
            path: Assets.images.fileImage.path,
          ),
          ScanFile(
            name: 'oijoigbdbdtivsdfsdfsdfsdf',
            id: '2',
            created: DateTime.now(),
            size: 1.6,
            path: Assets.images.fileImage.path,
          ),
          ScanFile(
            name: '32197423d activsdfsdf',
            id: '1',
            created: DateTime.now(),
            size: 2.6,
            path: Assets.images.fileImage.path,
          ),
          ScanFile(
            name: '12370225_card activdsfsdf',
            id: '4',
            created: DateTime.now(),
            size: 5.8,
            path: Assets.images.fileImage.path,
          ),
          ScanFile(
            name: 'Scan 070225_card activsdfsdfsdfsdf',
            id: '5',
            created: DateTime.now(),
            size: 4.6,
            path: Assets.images.fileImage.path,
          ),
          ScanFile(
            name: 'nnbnnnn25_card activsdfsdf',
            id: '6',
            created: DateTime.now(),
            size: 23.6,
            path: Assets.images.fileImage.path,
          ),
          ScanFile(
            name: 'mmmmmmmmmmmkkkkkkkkvsdfsdf',
            id: '7',
            created: DateTime.now(),
            size: 56.6,
            path: Assets.images.fileImage.path,
          ),
          ScanFile(
            name: 'eeeeeeeeeeeeeeeeeeevsdfsdf',
            id: '8',
            created: DateTime.now(),
            size: 0.6,
            path: Assets.images.fileImage.path,
          ),
        ]);

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
  void addFile(String path) {
    // Генерация имени, id, времени, размера, и т.д. — для примера делаем упрощённо
    final uuid = const Uuid().v4();
    final newFile = ScanFile(
      id: uuid,
      name: 'Scan ${DateTime.now().millisecondsSinceEpoch}',
      path: path,
      size: 1.5,
      // условно
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
