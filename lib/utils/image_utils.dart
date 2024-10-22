import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<File?> pickImage() async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  return pickedFile != null ? File(pickedFile.path) : null;
}

Future<String> uploadImage(File imageFile) async {
  // Firebase Storage upload logic
  Reference storageReference = FirebaseStorage.instance.ref().child('your_path');
  UploadTask uploadTask = storageReference.putFile(imageFile);
  TaskSnapshot taskSnapshot = await uploadTask;
  return await taskSnapshot.ref.getDownloadURL();
}

Widget buildActionButtons(VoidCallback onPickImage, VoidCallback onUploadImage) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      ElevatedButton(onPressed: onPickImage, child: Text('Pick Image')),
      ElevatedButton(onPressed: onUploadImage, child: Text('Upload Image')),
    ],
  );
}
