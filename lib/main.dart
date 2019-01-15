// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_faces/face_detector.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Face Detector',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  List<Face> _faces;

  Future _getImage() async {
    final image = await ImagePicker.pickImage(source: ImageSource.gallery);
    final faces = await findFaces(image);
    if (mounted) {
      setState(() {
        _image = image;
        _faces = faces;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Face Detector'),
      ),
      body: _image == null ? NoImage() : ImageWithFaces(_image, _faces),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}

class NoImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Please select an image'));
  }
}

class ImageWithFaces extends StatelessWidget {
  ImageWithFaces(this.imageFilePath, this.faces);
  final File imageFilePath;
  final List<Face> faces;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
            child: FittedBox(
                fit: BoxFit.cover,
                child: FacialImageAnnotator(
                    imageFilePath: imageFilePath, faces: faces)))
      ],
    );
  }
}

/// Annotates an image
/// Using a StatefulWidget to manage loading of the image
class FacialImageAnnotator extends StatefulWidget {
  FacialImageAnnotator({@required this.imageFilePath, @required this.faces});
  final File imageFilePath;
  final List<Face> faces;

  @override
  createState() => FacialImageAnnotatorState();
}

class FacialImageAnnotatorState extends State<FacialImageAnnotator> {
  ui.Image image;

  @override
  void initState() {
    super.initState();
    _loadImage(widget.imageFilePath);
  }

  @override
  void didUpdateWidget(FacialImageAnnotator oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('Widget updated');
    _loadImage(widget.imageFilePath);
  }

  void _loadImage(File file) async {
    final List<int> data = await file.readAsBytes();
    if (data == null) throw 'Unable to read data';
    final loadedImage = await decodeImageFromList(data);
    setState(() => image = loadedImage);
    print('Imge state set');
    //final codec = await ui.instantiateImageCodec(data);
    //final frame = await codec.getNextFrame();
    //return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    // Use a FutureBuilder to retrieve the image info
    return FittedBox(
      // FittedBox to correctly size the SizedBox
      child: image != null
          ? SizedBox(
              // SizedBox to ensure canvas size is the same as the image's size
              width: image.width.toDouble(),
              height: image.height.toDouble(),
              child: CustomPaint(
                painter: AnnotatedImagePainter(image, widget.faces),
              ),
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

class AnnotatedImagePainter extends CustomPainter {
  AnnotatedImagePainter(this.image, this.faces);
  final ui.Image image;
  final List<Face> faces;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.longestSide / 100;
    canvas.drawImage(image, Offset.zero, Paint());
    highlightFacesCircle(canvas, paint);
    highlightLandmarks(canvas, paint);
  }

  void highlightFacesRect(Canvas canvas, Paint paint) => faces.forEach(
      (face) => canvas.drawRect(rectangleToRect(face.boundingBox), paint));

  void highlightFacesCircle(Canvas canvas, Paint paint) {
    for (var face in faces) {
      final left = face.boundingBox.left;
      final right = face.boundingBox.right;
      final top = face.boundingBox.top;
      final bottom = face.boundingBox.bottom;
      final center =
          Offset(((right - left) / 2) + left, ((bottom - top) / 2) + top);
      final radius = [bottom - top, right - left].reduce(max) / 2;
      canvas.drawCircle(center, radius, paint);
    }
  }

  void highlightLandmarks(Canvas canvas, Paint paint) => faces.forEach(
        (face) => [
              FaceLandmarkType.leftEye,
              FaceLandmarkType.rightEye,
              FaceLandmarkType.bottomMouth
            ].forEach((type) {
              final landmark = face.getLandmark(type);
              if (landmark != null) {
                canvas.drawCircle(pointToOffset(landmark.position), 100, paint);
              }
            }),
      );

  @override
  bool shouldRepaint(AnnotatedImagePainter oldDelegate) =>
      image != oldDelegate.image || faces != oldDelegate.faces;
}
