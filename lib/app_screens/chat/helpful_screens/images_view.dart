import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewScreen extends StatefulWidget {
  final String imagePath;

  ImageViewScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  _ImageViewScreenState createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<ImageViewScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: PhotoView(
            imageProvider: NetworkImage(widget.imagePath),
            enableRotation: true,
            initialScale: null,
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(),
            ),
            errorBuilder: (context, obj, stackTrace) => Center(
                child: Text(
              'Image not Found',
              style: TextStyle(
                fontSize: 22.0,
                color: Colors.red,
                letterSpacing: 1.0,
              ),
            )),
          ),
        ),
      ),
    );
  }
}
