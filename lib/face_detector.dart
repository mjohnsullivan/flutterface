// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show File;
import 'dart:math' show Point, Rectangle;
import 'dart:ui' show Offset, Rect;

import 'package:firebase_ml_vision/firebase_ml_vision.dart';

Future<List<Face>> findFaces(File image) async {
  final visionImage = FirebaseVisionImage.fromFile(image);
  final faceDetector = FirebaseVision.instance.faceDetector(FaceDetectorOptions(
      enableLandmarks: true, mode: FaceDetectorMode.accurate));
  return await faceDetector.detectInImage(visionImage);
}

Rect rectangleToRect(Rectangle rectangle) => Rect.fromLTRB(
    rectangle.left.toDouble(),
    rectangle.top.toDouble(),
    rectangle.right.toDouble(),
    rectangle.bottom.toDouble());

Offset pointToOffset(Point point) =>
    Offset(point.x.toDouble(), point.y.toDouble());
