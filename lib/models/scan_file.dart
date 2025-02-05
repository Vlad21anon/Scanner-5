class ScanFile {
  final String id;
  final String name;
  final DateTime created;
  final double size;
  /// Если файл одностраничный, то используется поле path.
  /// Если мультистраничный, то здесь хранятся пути ко всем страницам.
  final List<String> pages;
  final bool isSelected;

  ScanFile({
    required this.id,
    required this.name,
    required this.created,
    required this.size,
    required this.pages,
    this.isSelected = false,
  });

  // Метод для добавления новой страницы в мультистраничный файл
  ScanFile addPage(String pagePath, double additionalSize) {
    return ScanFile(
      id: id,
      name: name,
      created: created,
      size: size + additionalSize,
      pages: List<String>.from(pages)..add(pagePath),
      isSelected: isSelected,
    );
  }

  // Остальные методы (copyWith, toJson, fromJson) нужно обновить, чтобы учитывать pages.
  ScanFile copyWith({
    String? id,
    String? name,
    DateTime? created,
    double? size,
    List<String>? pages,
    bool? isSelected,
  }) {
    return ScanFile(
      id: id ?? this.id,
      name: name ?? this.name,
      created: created ?? this.created,
      size: size ?? this.size,
      pages: pages ?? this.pages,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created': created.toIso8601String(),
      'size': size,
      'pages': pages,
      'isSelected': isSelected,
    };
  }

  factory ScanFile.fromJson(Map<String, dynamic> json) {
    return ScanFile(
      id: json['id'],
      name: json['name'],
      created: DateTime.parse(json['created']),
      size: (json['size'] as num).toDouble(),
      pages: List<String>.from(json['pages'] as List),
      isSelected: json['isSelected'] ?? false,
    );
  }
}
