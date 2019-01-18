// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
      home: FacePage(),
    );
  }
}

class FacePage extends StatefulWidget {
  @override
  createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  File _imageFile;
  List<Face> _faces;

  void _getImageAndDetectFaces() async {
    final imageFile = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    final image = FirebaseVisionImage.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
        mode: FaceDetectorMode.accurate,
        enableLandmarks: true,
      ),
    );
    final faces = await faceDetector.detectInImage(image);
    if (mounted) {
      setState(() {
        _imageFile = imageFile;
        _faces = faces;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face Detector')),
      body: _imageFile == null ? NoImage() : ImageWithFaces(_imageFile, _faces),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImageAndDetectFaces,
        tooltip: 'Pick an image',
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
    return Container(
      constraints: BoxConstraints.expand(),
      child: FittedBox(
          fit: BoxFit.cover,
          child: FacialImageAnnotator(
            imageFilePath: imageFilePath,
            faces: faces,
          )),
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
  ui.Image _image;

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
    final data = await file.readAsBytes();
    if (data == null) {
      throw 'Unable to read data';
    }
    final image = await decodeImageFromList(data);
    setState(() => _image = image);
    // Pure Dart way to load and decode an image
    // final codec = await ui.instantiateImageCodec(data);
    // final frame = await codec.getNextFrame();
    // final image = frame.image;
  }

  @override
  Widget build(BuildContext context) {
    // Use a FutureBuilder to retrieve the image info
    return FittedBox(
      // FittedBox to correctly size the SizedBox
      child: _image != null
          ? SizedBox(
              // SizedBox to ensure canvas size is the same as the image's size
              width: _image.width.toDouble(),
              height: _image.height.toDouble(),
              child: CustomPaint(
                painter: AnnotatedImagePainter(_image, widget.faces),
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
    _highlightFacesCircle(canvas, paint);
    _highlightLandmarks(canvas, paint);
  }

  void _highlightFacesRect(Canvas canvas, Paint paint) {
    for (var face in faces) {
      canvas.drawRect(rectangleToRect(face.boundingBox), paint);
    }
  }

  void _highlightFacesCircle(Canvas canvas, Paint paint) {
    for (var face in faces) {
      final left = face.boundingBox.left;
      final right = face.boundingBox.right;
      final top = face.boundingBox.top;
      final bottom = face.boundingBox.bottom;
      final center =
          Offset(((right - left) / 2) + left, ((bottom - top) / 2) + top);
      final radius = max(bottom - top, right - left) / 2;
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _highlightLandmarks(Canvas canvas, Paint paint) => faces.forEach(
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
