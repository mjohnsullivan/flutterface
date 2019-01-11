// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ml_vision/firebase_ml_vision.dart';

/// Detects a face in an image stored on the device
void detectFace(String imagePath) async {
  final FirebaseVisionImage visionImage =
      FirebaseVisionImage.fromFilePath(imagePath);
  final FaceDetector faceDetector = FirebaseVision.instance.faceDetector();
  final List<Face> faces = await faceDetector.detectInImage(visionImage);
  print('Detected ${faces.length} faces');
}
