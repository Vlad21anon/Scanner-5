import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../models/note_data.dart';

class SignaturesCubit extends HydratedCubit<List<NoteData>> {
  SignaturesCubit() : super(const []);

  /// Добавляет новую подпись, если их меньше 4.
  /// Возвращает true, если добавление прошло успешно, иначе false.
  bool addSignature(NoteData signature) {
    if (state.length >= 4) return false;
    final newList = List<NoteData>.from(state)..add(signature);
    emit(newList);
    return true;
  }
  bool canDrawSign() {
    return state.length < 4;
  }

  /// Удаляет подпись по идентификатору.
  void removeSignature(String id) {
    final newList = state.where((signature) => signature.id != id).toList();
    emit(newList);
  }

  /// Очищает все сохранённые подписи.
  void clearSignatures() {
    emit([]);
  }

  @override
  List<NoteData>? fromJson(Map<String, dynamic> json) {
    final raw = json['signatures'] as List?;
    if (raw == null) return [];
    return raw.map((e) => NoteData.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Map<String, dynamic>? toJson(List<NoteData> state) {
    return {
      'signatures': state.map((e) => e.toMap()).toList(),
    };
  }
}
