class Guidebook {
  final String name;
  final String url;
  final String storagePath;

  Guidebook({required this.name, required this.url, required this.storagePath});

  factory Guidebook.fromMap(Map<String, dynamic> map) {
    return Guidebook(
      name: map['name'] as String,
      url: map['url'] as String,
      storagePath: map['storagePath'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'url': url, 'storagePath': storagePath};
  }

  String get id => name; // Use name as ID for simplicity
}
