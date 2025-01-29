class ScanFile {
  final String id;
  final String name;
  final DateTime created;
  final double size;
  final String path;
  final bool isSelected;

  ScanFile({
    required this.id,
    required this.name,
    required this.created,
    required this.size,
    required this.path,
    this.isSelected = false,
  });

  ScanFile copyWith({
    String? id,
    String? name,
    DateTime? created,
    double? size,
    String? path,
    bool? isSelected,
  }) {
    return ScanFile(
      id: id ?? this.id,
      name: name ?? this.name,
      created: created ?? this.created,
      size: size ?? this.size,
      path: path ?? this.path,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created': created.toIso8601String(),
      'size': size,
      'path': path,
      'isSelected': isSelected,
    };
  }

  factory ScanFile.fromJson(Map<String, dynamic> json) {
    return ScanFile(
      id: json['id'],
      name: json['name'],
      created: DateTime.parse(json['created']),
      size: (json['size'] as num).toDouble(),
      path: json['path'],
      isSelected: json['isSelected'] ?? false,
    );
  }
}