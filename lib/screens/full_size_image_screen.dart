import 'package:flutter/material.dart';

class FullSizeImageScreen extends StatelessWidget {
  final String imageUrl;

  const FullSizeImageScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image"),
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
