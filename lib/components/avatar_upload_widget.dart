import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarUploadWidget extends StatefulWidget {
  final String avatarUrl;
  final Function(String) onAvatarChanged;

  const AvatarUploadWidget({
    super.key,
    required this.avatarUrl,
    required this.onAvatarChanged,
  });

  @override
  State<AvatarUploadWidget> createState() => _AvatarUploadWidgetState();
}

class _AvatarUploadWidgetState extends State<AvatarUploadWidget> {
  String avatarUrl = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    avatarUrl = widget.avatarUrl;
  }

  Future<Uint8List> _resizeAndConvertImage(File file) async {
    // Read the image from the file
    img.Image? image = img.decodeImage(await file.readAsBytes());

    // Resize the image to 512x512
    img.Image resizedImage = img.copyResize(image!, width: 512, height: 512);

    // Convert the image to JPEG format
    return Uint8List.fromList(img.encodeJpg(resizedImage));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          width: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(avatarUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        IconButton(
          onPressed: () async {
            ImagePicker imagePicker = ImagePicker();
            XFile? file =
                await imagePicker.pickImage(source: ImageSource.gallery);
            if (file == null) {
              setState(() {
                _isUploading = false;
              });
              return;
            }

            setState(() {
              _isUploading = true;
            });

            try {
              // Resize and convert the image
              Uint8List resizedImageData =
                  await _resizeAndConvertImage(File(file.path));

              // Upload the resized image
              var ref = FirebaseStorage.instance.ref().child(
                  'avatars/${FirebaseAuth.instance.currentUser!.uid}.jpg');
              await ref.putData(resizedImageData,
                  SettableMetadata(contentType: 'image/jpeg'));

              var downloadUrl = await ref.getDownloadURL();
              setState(() {
                avatarUrl = downloadUrl;
                _isUploading = false;
              });
              widget.onAvatarChanged(downloadUrl);
            } catch (error) {
              debugPrint('error');
              setState(() {
                _isUploading = false;
              });
              // some error occurred
            }
          },
          icon: _isUploading
              ? const CircularProgressIndicator()
              : const Icon(Icons.camera_alt),
        ),
      ],
    );
  }
}
