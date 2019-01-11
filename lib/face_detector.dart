import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void detectFace(String imagePath) async {
  final FirebaseVisionImage visionImage =
      FirebaseVisionImage.fromFilePath(imagePath);
  final FaceDetector faceDetector = FirebaseVision.instance.faceDetector();
  final List<Face> faces = await faceDetector.detectInImage(visionImage);
  print('Detected ${faces.length} faces');
}
