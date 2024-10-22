/*import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:build_wise/models/project_model.dart';
import 'package:build_wise/utils/styles.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const ProjectCard({Key? key, required this.project}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getImageUrl(project.image),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Container(
          margin: const EdgeInsets.all(10),
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    snapshot.data!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/project_default_header.jpg',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(project.name!,
                      style: appWidget.boldLineTextFieldStyle()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> getImageUrl(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return 'assets/images/project_default_header.jpg';
    }
    try {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } catch (e) {
      return 'assets/images/project_default_header.jpg';
    }
  }
}
*/