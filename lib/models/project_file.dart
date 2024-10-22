class ProjectFile {
  final String id;
  final String name;
  final int size;
  final String downloadUrl;

  ProjectFile({
    required this.id,
    required this.name,
    required this.size,
    required this.downloadUrl,
  });

  // Método para converter do snapshot do Firebase
  factory ProjectFile.fromSnapshot(Map<String, dynamic> snapshot, String id) {
    return ProjectFile(
      id: id,
      name: snapshot['name'],
      size: snapshot['size'],
      downloadUrl: snapshot['downloadUrl'],
    );
  }
}
