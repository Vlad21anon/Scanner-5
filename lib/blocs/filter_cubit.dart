import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';

class FilterCubit extends Cubit<FilterState> {
  FilterCubit() : super(const FilterState());

  String _lastFilter = "A to Z";

  void updateNameFilter(String nameFilter) {
    emit(state.copyWith(nameFilter: nameFilter));
    _lastFilter = nameFilter;
  }

  void updateDateFilter(String dateFilter) {
    emit(state.copyWith(dateFilter: dateFilter));
    _lastFilter = dateFilter;
  }

  List<ScanFile> applyFilter(List<ScanFile> files) {
    List<ScanFile> sortedFiles = List.from(files);
    if (_lastFilter == "A to Z") {
      sortedFiles.sort((a, b) => _customSort(a.name, b.name));
    } else if (_lastFilter == "Z to A") {
      sortedFiles.sort((a, b) => _customSort(b.name, a.name));
    } else if (_lastFilter == "New files") {
      sortedFiles.sort((a, b) => b.created.compareTo(a.created));
    } else if (_lastFilter == "Old files") {
      sortedFiles.sort((a, b) => a.created.compareTo(b.created));
    }

    return sortedFiles;
  }

  int _customSort(String a, String b) {
    final regExp = RegExp(r'(\d+|\D+)');
    final aParts = regExp.allMatches(a).map((m) => m.group(0)!).toList();
    final bParts = regExp.allMatches(b).map((m) => m.group(0)!).toList();

    for (int i = 0; i < aParts.length && i < bParts.length; i++) {
      final aPart = aParts[i];
      final bPart = bParts[i];

      final aIsNum = int.tryParse(aPart);
      final bIsNum = int.tryParse(bPart);

      if (aIsNum != null && bIsNum != null) {
        // Сравнение как чисел
        final cmp = aIsNum.compareTo(bIsNum);
        if (cmp != 0) return cmp;
      } else {
        // Сравнение как строк (в нижнем регистре)
        final cmp = aPart.toLowerCase().compareTo(bPart.toLowerCase());
        if (cmp != 0) return cmp;
      }
    }

    // Если все части совпали, но длина разная
    return aParts.length.compareTo(bParts.length);
  }
}

class FilterState extends Equatable {
  final String nameFilter;
  final String dateFilter;

  const FilterState({
    this.nameFilter = "A to Z",
    this.dateFilter = "New files",
  });

  FilterState copyWith({String? nameFilter, String? dateFilter}) {
    return FilterState(
      nameFilter: nameFilter ?? this.nameFilter,
      dateFilter: dateFilter ?? this.dateFilter,
    );
  }

  @override
  List<Object> get props => [nameFilter, dateFilter];
}
