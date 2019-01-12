// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'dart:math' show max;

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
    final faces = await _findFaces(image);
    setState(() {
      _image = image;
      _faces = faces;
    });
  }

  Future<List<Face>> _findFaces(File image) async {
    final visionImage = FirebaseVisionImage.fromFile(image);
    final faceDetector = FirebaseVision.instance.faceDetector();
    return await faceDetector.detectInImage(visionImage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Faces'),
      ),
      body: Center(
          child: _image == null
              ? NoImage()
              : ImageFaces(imageFile: _image, faces: _faces)),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}

/// Displays an image with faces highlighted
class ImageFaces extends StatelessWidget {
  ImageFaces({this.imageFile, this.faces});
  final File imageFile;
  final List<Face> faces;

  List<Widget> _getFaceBoxes(Size originalImageSize, Size newImageSize) {
    final faceBoundingBoxes = <Widget>[];
    faces.forEach((face) {
      print('Face detected: ${face.boundingBox}');
      print(
        'Face - top: ${face.boundingBox.top}, bottom: ${face.boundingBox.bottom}, left: ${face.boundingBox.left}, right: ${face.boundingBox.right}',
      );
      final top = face.boundingBox.top *
          (newImageSize.height / originalImageSize.height);
      final bottom = face.boundingBox.bottom *
          (newImageSize.height / originalImageSize.height);
      final left = face.boundingBox.left *
          (newImageSize.width / originalImageSize.width);
      final right = face.boundingBox.right *
          (newImageSize.width / originalImageSize.width);

      print(
        'Face box - top: $top, bottom: $bottom, left: $left, right: $right',
      );

      final center =
          Offset(((right - left) / 2) + left, ((bottom - top) / 2) + top);
      final radius = [bottom - top, right - left].reduce(max) / 2;

      print('Face center: $center, radius: $radius');
      /*
      faceBoundingBoxes.add(Positioned(
          top: top,
          height: bottom - top,
          left: left,
          width: right - left,
          child: Container(color: Colors.blue)));
      */
      faceBoundingBoxes.add(Circle(center: center, radius: radius));
    });

    return faceBoundingBoxes;
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.file(imageFile, fit: BoxFit.contain);
    final completer = Completer<ui.Image>();

    image.image.resolve(ImageConfiguration()).addListener(
        (ImageInfo info, bool _) => completer.complete(info.image));

    return FutureBuilder(
        future: completer.future,
        builder: (context, AsyncSnapshot<ui.Image> snapshot) {
          if (snapshot.hasData) {
            print('Image size: ${snapshot.data}');
            return LayoutBuilder(builder: (context, constraints) {
              print('Stack constraints: $constraints');
              final faceBoxes = _getFaceBoxes(
                Size(snapshot.data.width.toDouble(),
                    snapshot.data.height.toDouble()),
                Size(constraints.maxWidth, constraints.maxHeight),
              );
              return Stack(
                children: [
                  Positioned.fill(
                      child: LayoutBuilder(builder: (context, constraints) {
                    print('Image constraints: $constraints');
                    return image;
                  })),
                ]..addAll(faceBoxes),
              );
            });
          }
          return Center(child: CircularProgressIndicator());
        });
  }
}

class NoImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Please select an image'));
  }
}

class Circle extends StatelessWidget {
  Circle({@required this.center, @required this.radius, this.child});
  final Offset center;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CirclePainter(center, radius),
      child: Container(color: Colors.transparent),
    );
  }
}

class CirclePainter extends CustomPainter {
  CirclePainter(this.center, this.radius);
  final Offset center;
  final double radius;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    print('Paint size: $size');
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => false;
}
