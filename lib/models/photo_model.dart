class Photo {
  final String id;
  final String url;

  Photo({required this.id, required this.url});

  factory Photo.fromFirestore(Map<String, dynamic> data, String id) {
    return Photo(
      id: id,
      url: data['url'],
    );
  }
}
