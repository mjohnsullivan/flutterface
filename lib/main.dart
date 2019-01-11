// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
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

class ImageFaces extends StatelessWidget {
  ImageFaces({this.imageFile, this.faces});
  final File imageFile;
  final List<Face> faces;

  List<Widget> getFaceBoxes(double ratio) {
    final faceBoundingBoxes = <Widget>[];
    for (var face in faces) {
      print('Face detected: ${face.boundingBox}');
      print(
        'Face - top: ${face.boundingBox.top}, bottom: ${face.boundingBox.bottom}, left: ${face.boundingBox.left}, right: ${face.boundingBox.right}',
      );
      final top = face.boundingBox.top * ratio;
      final bottom = face.boundingBox.bottom * ratio;
      final left = face.boundingBox.left * ratio;
      final right = face.boundingBox.right * ratio;

      print(
        'Face Scaled - top: $top, bottom: $bottom, left: $left, right: $right',
      );

      faceBoundingBoxes.add(Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: 265.0,
        child: Container(color: Colors.green),
      ));
    }
    return faceBoundingBoxes;
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.file(imageFile);
    final completer = Completer<ui.Image>();

    image.image.resolve(ImageConfiguration()).addListener(
        (ImageInfo info, bool _) => completer.complete(info.image));

    final screenSize = MediaQuery.of(context).size;

    return FutureBuilder(
        future: completer.future,
        builder: (context, AsyncSnapshot<ui.Image> snapshot) {
          if (snapshot.hasData) {
            print('Image size: ${snapshot.data}');
            final imageRatio = screenSize.width / snapshot.data.width;
            print('Ratio: $imageRatio');
            print('Screen size: $screenSize');
            final children = <Widget>[image]..addAll(getFaceBoxes(imageRatio));
            return Stack(children: children);
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
